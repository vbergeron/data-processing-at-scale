import java.nio.file.*
import java.time.Instant
import scala.util.Random

@main def generateTrades(): Unit =
  val outDir = Path.of("data/trades")

  if Files.exists(outDir) then
    Files.walk(outDir)
      .sorted(java.util.Comparator.reverseOrder())
      .forEach(Files.delete)
  Files.createDirectories(outDir)

  val symbols = List("AAPL", "GOOG", "MSFT", "AMZN", "TSLA", "NVDA", "META")
  val basePrices = Map(
    "AAPL" -> 182.0, "GOOG" -> 140.0, "MSFT" -> 375.0,
    "AMZN" -> 178.0, "TSLA" -> 245.0, "NVDA" -> 875.0, "META" -> 485.0
  )

  val totalRows = 20 + Random.nextInt(31)
  var written   = 0
  var fileIdx   = 0

  println(s"Generating $totalRows trade records into $outDir …")
  println(s"  (≈20 % of events will carry a late timestamp, up to ${MAX_LATE_SEC}s behind wall clock)")

  while written < totalRows do
    Thread.sleep(1000 + Random.nextInt(3001))

    val batchSize = math.min(1 + Random.nextInt(3), totalRows - written)
    val fileName  = f"trades-${fileIdx}%04d-${Instant.now().toEpochMilli}.jsonl"
    val file      = outDir.resolve(fileName)

    val lines = (0 until batchSize).map { _ =>
      val symbol      = symbols(Random.nextInt(symbols.size))
      val side        = if Random.nextBoolean() then "buy" else "sell"
      val qty         = 10 + Random.nextInt(991)
      val price       = basePrices(symbol) * (0.99 + Random.nextDouble() * 0.02)
      val (ts, late)  = eventTimestamp()
      val lateMarker  = if late then " [LATE]" else ""
      println(s"    $symbol $side $qty @ ${"%.2f".format(price)}  ts=$ts$lateMarker")
      s"""{"symbol":"$symbol","side":"$side","quantity":$qty,"price":${"%.2f".format(price)},"ts":"$ts"}"""
    }

    Files.writeString(file, lines.mkString("\n") + "\n")
    written += batchSize
    fileIdx  += 1
    println(s"  [$written/$totalRows] ${lines.size} record(s) → $fileName")

  println("Done.")
