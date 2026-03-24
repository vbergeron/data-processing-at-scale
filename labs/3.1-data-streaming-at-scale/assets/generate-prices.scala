import java.nio.file.*
import java.time.Instant
import scala.util.Random

val symbols = List("AAPL", "GOOG", "MSFT", "AMZN", "TSLA", "NVDA", "META")

val initialPrices: Map[String, Double] = Map(
  "AAPL" -> 182.0, "GOOG" -> 140.0, "MSFT" -> 375.0,
  "AMZN" -> 178.0, "TSLA" -> 245.0, "NVDA" -> 875.0, "META" -> 485.0
)

@main def generatePrices(): Unit =
  val dataDir = Path.of("data")
  val outDir  = dataDir.resolve("prices")

  if Files.exists(outDir) then
    Files.walk(outDir)
      .sorted(java.util.Comparator.reverseOrder())
      .forEach(Files.delete)
  Files.createDirectories(dataDir)
  Files.createDirectories(outDir)

  // Write baseline prices to a standalone reference file
  val baselineFile = dataDir.resolve("prices-baseline.json")
  val baselineJson = symbols
    .map(s => s"""  "$s": ${"%.2f".format(initialPrices(s))}""")
    .mkString("{\n", ",\n", "\n}")
  Files.writeString(baselineFile, baselineJson + "\n")
  println(s"Baseline prices written → $baselineFile")

  var prices   = initialPrices
  val totalRows = 20 + Random.nextInt(31)
  var written   = 0
  var fileIdx   = 1

  println(s"Generating $totalRows price updates into $outDir …")
  println(s"  (≈20 % of ticks will carry a late timestamp, up to ${MAX_LATE_SEC}s behind wall clock)")

  while written < totalRows do
    Thread.sleep(1000 + Random.nextInt(3001))

    val batchSize = math.min(1 + Random.nextInt(3), totalRows - written)
    val fileName  = f"prices-${fileIdx}%04d-${Instant.now().toEpochMilli}.jsonl"
    val file      = outDir.resolve(fileName)

    val lines = (0 until batchSize).map { _ =>
      val symbol      = symbols(Random.nextInt(symbols.size))
      val newPrice    = prices(symbol) * (1.0 + (Random.nextDouble() - 0.5) * 0.04)
      prices = prices.updated(symbol, newPrice)
      val (ts, late)  = eventTimestamp()
      val lateMarker  = if late then " [LATE]" else ""
      println(s"    $symbol ${"%.2f".format(newPrice)}  ts=$ts$lateMarker")
      s"""{"symbol":"$symbol","price":${"%.2f".format(newPrice)},"ts":"$ts"}"""
    }

    Files.writeString(file, lines.mkString("\n") + "\n")
    written += batchSize
    fileIdx  += 1
    println(s"  [$written/$totalRows] ${lines.size} update(s) → $fileName")

  println("Done.")
