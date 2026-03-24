#import "../style.typ": *

#show: lab-theme.with(
  title: [Lab 3.1 — Building a Reliable Portfolio Aggregator],
  session: [Session 3.1 — Data Streaming at Scale],
  format: [Guided lab],
  tools: [Scala CLI, Apache Flink 2.2, Flink SQL Client],
)

= Objective

Build a streaming portfolio aggregator in five incremental steps. Each step adds one concern — positions, then time windows, then late events, then live valuation, then fault tolerance — so that at every stage you understand exactly what problem the next step solves.

= Setup

== Prerequisites

- Scala CLI (`scala-cli`) installed and on `PATH`
- Apache Flink 2.2 distribution, started locally:

```
./bin/start-cluster.sh
```

- Flink Web UI at `http://localhost:8081`

== Data generators

Two generators are provided in the lab folder. Both clear their output directory on start, then emit between 20 and 50 records at 1–4 second random intervals. About 20 % of records carry a backdated `ts` (up to 15 s late) to simulate out-of-order delivery.

*`generate-trades.scala`* — buy/sell orders:
```json
{"symbol":"AAPL","side":"buy","quantity":350,"price":182.14,"ts":"…"}
{"symbol":"TSLA","side":"sell","quantity":80,"price":244.91,"ts":"…"}
```

*`generate-prices.scala`* — writes `data/prices-baseline.json` with the reference price for all symbols, then streams live price ticks (±2 % per update):
```json
{"symbol":"NVDA","price":876.32,"ts":"…"}
```

Start both in separate terminals before opening the SQL client:
```
scala-cli generate-trades.scala
scala-cli generate-prices.scala
```

Output directories: `data/trades/` and `data/prices/`.

== SQL client and table definitions

Open the Flink SQL Client and paste the two table definitions below. Keep them in the session throughout the lab — every step builds on them.

```
./bin/sql-client.sh
```

```sql
CREATE TABLE trades (
  symbol   STRING,
  side     STRING,
  quantity BIGINT,
  price    DOUBLE,
  ts       TIMESTAMP(3),
  WATERMARK FOR ts AS ts - INTERVAL '15' SECOND
) WITH (
  'connector'              = 'filesystem',
  'path'                   = 'file:///absolute/path/to/data/trades',
  'format'                 = 'json',
  'source.monitor-interval'= '2s'
);

CREATE TABLE prices (
  symbol STRING,
  price  DOUBLE,
  ts     TIMESTAMP(3),
  WATERMARK FOR ts AS ts - INTERVAL '15' SECOND
) WITH (
  'connector'              = 'filesystem',
  'path'                   = 'file:///absolute/path/to/data/prices',
  'format'                 = 'json',
  'source.monitor-interval'= '2s'
);
```

The watermark lag is set to 15 s — matching the maximum late-arrival delay in the generators.

= Walkthrough

== Step 1 — Raw positions (no time)

*Goal:* see trades arriving and compute a naïve running net position per symbol.

```sql
SELECT
  symbol,
  SUM(CASE WHEN side = 'buy'  THEN  quantity ELSE 0 END) AS bought,
  SUM(CASE WHEN side = 'sell' THEN  quantity ELSE 0 END) AS sold,
  SUM(CASE WHEN side = 'buy'  THEN  quantity ELSE -quantity END) AS net_qty
FROM trades
GROUP BY symbol;
```

Watch the result table update as new files land. Note that this is an *unbounded aggregation* — Flink keeps state for every symbol indefinitely. There are no windows, so results update with every arriving record regardless of its `ts`.

*Observe:* open `data/trades/` in another terminal (`watch -n1 ls -lh data/trades/`) and compare file arrival time with when results change in the SQL client.

== Step 2 — Windowed notional (tumbling windows)

*Goal:* measure activity over fixed time intervals, not since the beginning of time.

```sql
SELECT
  symbol,
  TUMBLE_START(ts, INTERVAL '30' SECOND) AS window_start,
  TUMBLE_END  (ts, INTERVAL '30' SECOND) AS window_end,
  SUM(CASE WHEN side = 'buy'  THEN  quantity ELSE -quantity END) AS net_qty,
  SUM(quantity * price)                                           AS notional
FROM trades
GROUP BY symbol, TUMBLE(ts, INTERVAL '30' SECOND);
```

Results only appear when a window *closes* — that is, when the watermark advances past `window_end`. Because 20 % of records are late by up to 15 s and the watermark lag is 15 s, Flink waits before closing each window to give late events a chance to arrive.

*Observe in the Web UI (`http://localhost:8081`):*
- find the running job → operator graph → window operator
- watch the "watermark" metric on the source operator advance in steps, not continuously
- notice that window results arrive in bursts, not one per record

*Discuss:* what would happen if you set the watermark lag to 0? What if you set it to 60 s?

== Step 3 — Late events made visible

*Goal:* confirm that late events are included in the correct window, not dropped.

Add a column that flags whether each record's `ts` is more than 5 s behind the current wall clock:

```sql
SELECT
  symbol,
  ts,
  CURRENT_TIMESTAMP                                     AS processing_time,
  TIMESTAMPDIFF(SECOND, ts, CURRENT_TIMESTAMP)          AS lag_sec,
  side,
  quantity
FROM trades
ORDER BY ts;
```

Compare `ts` and `processing_time` for rows where `lag_sec > 5`. These are the records the generators deliberately backdated. Verify that they appear in the correct 30-second window in the Step 2 query (re-run it alongside this one).

*Discuss:* the watermark is a *promise* — once Flink advances it past time $T$, any record with `ts < T` that arrives later is dropped as truly late. The 15 s lag is the budget you give the system to absorb network jitter.

== Step 4 — Live portfolio valuation (stream–stream join)

*Goal:* attach the latest market price to each position so you can compute unrealised P&L.

```sql
SELECT
  t.symbol,
  SUM(CASE WHEN t.side = 'buy' THEN  t.quantity ELSE -t.quantity END)   AS net_qty,
  LAST_VALUE(p.price)                                                     AS last_price,
  SUM(CASE WHEN t.side = 'buy' THEN  t.quantity ELSE -t.quantity END)
    * LAST_VALUE(p.price)                                                 AS market_value
FROM trades t
JOIN prices p ON t.symbol = p.symbol
GROUP BY t.symbol;
```

This is an *unbounded stream–stream join*. Flink must buffer all trade and price records in state to evaluate future join conditions — state grows without bound.

*Observe:*
- in the Web UI, inspect the "managed memory" metric on the join operator — it grows over time
- stop the generators; the join state remains in memory until the job is cancelled

*Discuss:* for a production portfolio system you would use a *temporal table join* (lookup join on the latest price) instead. That keeps only the latest price per symbol in state, not the full history.

== Step 5 — Fault tolerance

*Goal:* verify that the aggregation survives a TaskManager failure without losing or duplicating any position.

Enable checkpointing before starting the final query:

```sql
SET 'execution.checkpointing.interval' = '10s';
SET 'execution.checkpointing.mode'     = 'EXACTLY_ONCE';
```

Re-run the Step 2 windowed query. While it is running, kill one TaskManager process:

```
# find the pid
jps | grep TaskManager
kill <pid>
```

Watch the Web UI:
- the job transitions to *RESTARTING*
- after recovery it resumes from the last checkpoint
- file offsets are part of the checkpoint — already-seen files are not reprocessed
- window accumulators are restored — partial sums are not lost

*Discuss:* exactly-once here applies to *internal state*. Making the output exactly-once end-to-end would additionally require a transactional sink (e.g., writing to a database with a two-phase commit connector).

= Key Takeaways

- An unbounded aggregation (`GROUP BY` without a window) updates continuously but keeps state forever — fine for small key spaces, dangerous at scale
- Tumbling windows bound state and emit results periodically; they only close when the watermark says all late events for that window have arrived
- The watermark lag is a trade-off: larger lag tolerates more out-of-order delivery but increases result latency
- Stream–stream joins are stateful by nature; temporal table (lookup) joins are the production pattern for enriching events with the latest dimension value
- Checkpointing persists operator state *and* source offsets atomically — recovery is exactly-once for internal state at no extra application code
