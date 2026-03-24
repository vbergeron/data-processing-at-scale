// Portfolio analytics pipeline — Flink DataStream API
// Run with: scala-cli run . --main-class lab

import com.fasterxml.jackson.databind.{DeserializationFeature, ObjectMapper}
import com.fasterxml.jackson.module.scala.DefaultScalaModule
import org.apache.flink.api.common.eventtime.*
import org.apache.flink.api.common.functions.{AggregateFunction, FlatMapFunction}
import org.apache.flink.api.common.state.*
import org.apache.flink.api.common.typeinfo.TypeInformation
import org.apache.flink.connector.file.src.FileSource
import org.apache.flink.connector.file.src.reader.TextLineInputFormat
import org.apache.flink.core.fs.Path
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.streaming.api.functions.co.KeyedBroadcastProcessFunction
import org.apache.flink.streaming.api.functions.windowing.ProcessWindowFunction
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows
import org.apache.flink.streaming.api.windowing.windows.TimeWindow
import org.apache.flink.util.{Collector, OutputTag}
import java.io.File
import java.time.{Duration, Instant}
import scala.jdk.CollectionConverters.*
import scala.util.Try

// ─── Data model ─────────────────────────────────────────────────────────────

case class Trade(
  symbol: String,
  side: String,
  quantity: Long,
  price: Double,
  ts: String
):
  def epochMillis: Long = Instant.parse(ts).toEpochMilli
  def delta: Long       = if side == "buy" then quantity else -quantity

case class PriceTick(symbol: String, price: Double, ts: String):
  def epochMillis: Long = Instant.parse(ts).toEpochMilli

case class WindowResult(symbol: String, windowStart: Long, windowEnd: Long, netQty: Long, notional: Double)

// ─── JSON helpers ────────────────────────────────────────────────────────────

val mapper = ObjectMapper()
  .registerModule(DefaultScalaModule)
  .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)

def parseTrade(line: String): Option[Trade]         = Try(mapper.readValue(line, classOf[Trade])).toOption
def parsePriceTick(line: String): Option[PriceTick] = Try(mapper.readValue(line, classOf[PriceTick])).toOption

// ─── File source builder ─────────────────────────────────────────────────────
// Watches a directory and picks up new JSONL files every 2 seconds.

def fileSource(dir: String): FileSource[String] =
  FileSource
    .forRecordStreamFormat(new TextLineInputFormat(), new Path(new File(dir).toURI))
    .monitorContinuously(Duration.ofSeconds(2))
    .build()

// ─── Step 2: Running net position ────────────────────────────────────────────
// Use ValueState[Long] to track net quantity per symbol.
// Emit an updated position string after every trade.

class NetPositionTracker extends KeyedProcessFunction[String, Trade, String]:
  type Self = KeyedProcessFunction[String, Trade, String]

  lazy val position: ValueState[Long] = getRuntimeContext.getState(
    new ValueStateDescriptor("position", classOf[Long])
  )

  override def processElement(t: Trade, ctx: Self#Context, out: Collector[String]): Unit =
    ???

// ─── Step 3: Windowed notional ───────────────────────────────────────────────
// AggregateFunction accumulates netQty and notional incrementally.
// ProcessWindowFunction attaches window metadata to the result.
// Allowed lateness: 15 s. Truly late records → side output.

val lateTag = new OutputTag[Trade]("late-trades") {}

case class Acc(netQty: Long = 0L, notional: Double = 0.0)

class NotionalAgg extends AggregateFunction[Trade, Acc, Acc]:
  def createAccumulator(): Acc = Acc()
  def add(t: Trade, acc: Acc): Acc = ???
  def getResult(acc: Acc): Acc     = acc
  def merge(a: Acc, b: Acc): Acc   = ???

class WindowLabel extends ProcessWindowFunction[Acc, WindowResult, String, TimeWindow]:
  type Self = ProcessWindowFunction[Acc, WindowResult, String, TimeWindow]

  override def process(key: String, ctx: Self#Context, elements: java.lang.Iterable[Acc], out: Collector[WindowResult]): Unit = ???

// ─── Step 4: Broadcast join — live market value ───────────────────────────────
// Price ticks are broadcast to every sub-task via MapStateDescriptor.
// Each trade is enriched with the latest known price for its symbol.

val priceStateDesc = new MapStateDescriptor("prices", classOf[String], classOf[Double])

class PortfolioEnricher extends KeyedBroadcastProcessFunction[String, Trade, PriceTick, String]:
  type Self = KeyedBroadcastProcessFunction[String, Trade, PriceTick, String]

  override def processBroadcastElement(tick: PriceTick, ctx: Self#Context, out: Collector[String]): Unit = ???

  override def processElement(t: Trade, ctx: Self#ReadOnlyContext, out: Collector[String]): Unit = ???

// ─── Step 5: Inactivity alert ─────────────────────────────────────────────────
// Register an event-time timer on each trade.
// In onTimer, emit an alert if the symbol has been silent for ALERT_HORIZON_MS.

val ALERT_HORIZON_MS = 20_000L

class InactivityAlert extends KeyedProcessFunction[String, Trade, String]:
  type Self = KeyedProcessFunction[String, Trade, String]

  lazy val lastSeen: ValueState[Long] = getRuntimeContext.getState(
    new ValueStateDescriptor("lastSeen", classOf[Long])
  )

  override def processElement(t: Trade, ctx: Self#Context, out: Collector[String]): Unit = ???

  override def onTimer(ts: Long, ctx: Self#OnTimerContext, out: Collector[String]): Unit = ???

// ─── Main ─────────────────────────────────────────────────────────────────────

@main def lab(): Unit =
  val env = StreamExecutionEnvironment.getExecutionEnvironment
  env.setParallelism(2)
  env.enableCheckpointing(10_000)

  // ── Sources ───────────────────────────────────────────────────────────────

  val tradeWatermarks = WatermarkStrategy
    .forBoundedOutOfOrderness[Trade](Duration.ofSeconds(15))
    .withTimestampAssigner((t, _) => t.epochMillis)

  val priceWatermarks = WatermarkStrategy
    .forBoundedOutOfOrderness[PriceTick](Duration.ofSeconds(15))
    .withTimestampAssigner((p, _) => p.epochMillis)

  val rawTrades = env.fromSource(fileSource("data/trades"), WatermarkStrategy.noWatermarks(), "trade-files")
  val rawPrices = env.fromSource(fileSource("data/prices"), WatermarkStrategy.noWatermarks(), "price-files")

  given TypeInformation[Trade]     = TypeInformation.of(classOf[Trade])
  given TypeInformation[PriceTick] = TypeInformation.of(classOf[PriceTick])

  val trades = rawTrades
    .flatMap(new FlatMapFunction[String, Trade]:
      override def flatMap(line: String, out: Collector[Trade]): Unit =
        parseTrade(line).foreach(out.collect)
    )
    .assignTimestampsAndWatermarks(tradeWatermarks)

  val prices = rawPrices
    .flatMap(new FlatMapFunction[String, PriceTick]:
      override def flatMap(line: String, out: Collector[PriceTick]): Unit =
        parsePriceTick(line).foreach(out.collect)
    )
    .assignTimestampsAndWatermarks(priceWatermarks)

  // ── Step 2: Running net position ──────────────────────────────────────────

  trades
    .keyBy(_.symbol)
    .process(new NetPositionTracker())
    .print()

  // ── Step 3: Windowed notional + side output for truly late trades ─────────

  val windowedResult = trades
    .keyBy(_.symbol)
    .window(TumblingEventTimeWindows.of(Duration.ofSeconds(30)))
    .allowedLateness(Duration.ofSeconds(15))
    .sideOutputLateData(lateTag)
    .aggregate(new NotionalAgg(), new WindowLabel())

  windowedResult.map(r =>
    f"[window] ${r.symbol}%-5s  [${r.windowStart}..${r.windowEnd}]  net=${r.netQty}%+6d  notional=${r.notional}%10.2f"
  ).print()

  windowedResult.getSideOutput(lateTag).map(t =>
    s"[LATE] ${t.symbol} ${t.side} ${t.quantity} @ ${t.price}  ts=${t.ts}"
  ).print()

  // ── Step 4: Broadcast join — live market value ────────────────────────────

  val broadcastPrices = prices.broadcast(priceStateDesc)

  trades
    .keyBy(_.symbol)
    .connect(broadcastPrices)
    .process(new PortfolioEnricher())
    .print()

  // ── Step 5: Inactivity alert via event-time timer ─────────────────────────

  trades
    .keyBy(_.symbol)
    .process(new InactivityAlert())
    .print()

  env.execute("portfolio-analytics")
