= Interoperability & the Modern Stack

== ClickHouse integrations

ClickHouse has a *rich ecosystem* of integrations with other systems. \
https://clickhouse.com/docs/engines/table-engines/integrations

- *Kafka*
- HDFS / S3 / Iceberg
- MySQL / PostgreSQL
- Arrow Flight SQL (Client and Server)


== Tiered storage

Storage tiering is configured in two sections: *disks* (the physical media) and *policies* (how parts move between them). Each table then declares which policy it uses.

```sql
CREATE TABLE events (...) ENGINE = MergeTree
ORDER BY ts
SETTINGS storage_policy = 'tiered';
```

== \

#align(center + horizon,
  image("../assets/bioh.png", height: 50%)
)

== Tiered storage — disks

```xml
<storage_configuration>
  <disks>
    <hot>
      <type>local</type><path>/nvme/clickhouse/</path>
    </hot>
    <warm>
      <type>local</type><path>/hdd/clickhouse/</path>
    </warm>
    <cold>
      <type>s3</type><endpoint>https://s3.amazonaws.com/my-bucket/ch/</endpoint>
    </cold>
  </disks>
  <!-- policies go here -->
</storage_configuration>
```
== Tiered storage — policies

```xml
  <policies>
    <tiered>
      <volumes>
        <hot><disk>hot</disk>
          <max_data_part_size_bytes>10737418240</max_data_part_size_bytes>
        </hot>
        <warm><disk>warm</disk>
          <max_data_part_size_bytes>107374182400</max_data_part_size_bytes>
        </warm>
        <cold><disk>cold</disk>
        </cold>
      </volumes>
      <move_factor>0.2</move_factor>
    </tiered>
  </policies>
```

== Tiered storage — TTL-driven moves

Space pressure is reactive. For predictable archival, use `TTL … TO VOLUME` to move parts by age regardless of disk usage.

```sql
ALTER TABLE events MODIFY TTL
    ts + INTERVAL 7  DAY  TO VOLUME 'warm',
    ts + INTERVAL 90 DAY  TO VOLUME 'cold';
```

== Tiered storage — TTL-driven moves

Both mechanisms compose: TTL handles planned archival, `move_factor` handles unexpected load spikes. Manual overrides are also possible:

```sql
ALTER TABLE events MOVE PART '20240101_1_1_0' TO DISK 'cold';
ALTER TABLE events MOVE PARTITION '2024-01'   TO DISK 'cold';
```

== Tiered storage — trade-offs

Blob storage is slower than local disk, but it is cheaper and more scalable.

#v(0.6em)

For analytical workloads this is acceptable: a query that scans 10 GB from S3 at 1 GB/s takes ~10 seconds — fine for a scheduled report, not for a live dashboard.

ClickHouse caches recently accessed S3 parts on local disk (`remote_filesystem_local_cache`). Repeated access to the same cold part pays S3 latency only once.

