//> using scala 3.3.3

import java.time.Instant
import java.time.temporal.ChronoUnit
import scala.util.Random

// 20 % of events carry a late timestamp (up to MAX_LATE_SEC behind wall clock).
// This is intentional: it makes watermark behaviour observable in Flink.
val MAX_LATE_SEC = 15

def eventTimestamp(): (Instant, Boolean) =
  if Random.nextInt(5) == 0 then
    val lagSec = 1 + Random.nextInt(MAX_LATE_SEC)
    (Instant.now().minus(lagSec, ChronoUnit.SECONDS), true)
  else
    (Instant.now(), false)
