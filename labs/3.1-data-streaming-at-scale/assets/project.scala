//> using scala 3.3.3

// Flink DataStream Java API (Flink dropped its native Scala API in 2.x;
// use the Java API directly from Scala)
//> using dep org.apache.flink:flink-streaming-java:2.2.0
//> using dep org.apache.flink:flink-clients:2.2.0

// File source connector (FileSource, FileSystem, StreamFormat)
//> using dep org.apache.flink:flink-connector-files:2.2.0

// JSON format for file and table connectors
//> using dep org.apache.flink:flink-json:2.2.0

// Logging (Flink expects SLF4J + Log4j2 at runtime)
//> using dep org.apache.logging.log4j:log4j-slf4j2-impl:2.25.3
//> using dep org.apache.logging.log4j:log4j-core:2.25.3
