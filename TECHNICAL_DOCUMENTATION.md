# Real-time CDC Streaming Pipeline - Technical Documentation

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Component Details](#component-details)
3. [Data Flow](#data-flow)
4. [Configuration](#configuration)
5. [Deployment](#deployment)
6. [Monitoring](#monitoring)
7. [Troubleshooting](#troubleshooting)
8. [Performance Tuning](#performance-tuning)
9. [Security Considerations](#security-considerations)
10. [Scaling Guidelines](#scaling-guidelines)

## Architecture Overview

This project implements a production-ready Change Data Capture (CDC) streaming pipeline that captures real-time database changes and processes them through a distributed event-driven architecture.

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │───▶│    Debezium     │───▶│   Apache Kafka  │
│   (Source DB)   │    │  (CDC Capture)  │    │ (Message Broker)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Sinks    │◀───│  Apache Spark   │◀───│  Kafka Topics   │
│ (Analytics/ML)  │    │ (Stream Process)│    │ (Event Streams) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Monitoring    │
                       │ (Prometheus/    │
                       │   Grafana)      │
                       └─────────────────┘
```

### Key Components

1. **PostgreSQL Database**: Source system with logical replication enabled
2. **Debezium Connector**: Captures database changes using PostgreSQL's WAL
3. **Apache Kafka**: Distributed message broker for event streaming
4. **Apache Spark**: Stream processing engine for real-time analytics
5. **Monitoring Stack**: Prometheus and Grafana for observability

## Component Details

### PostgreSQL Configuration

The PostgreSQL instance is configured for logical replication:

```sql
-- Required configuration parameters
wal_level = logical
max_replication_slots = 4
max_wal_senders = 4
```

**Key Features:**
- Logical replication enabled for CDC
- Sample e-commerce schema with realistic data
- Triggers for automatic timestamp updates
- Referential integrity constraints
- Optimized indexes for query performance

### Debezium CDC Connector

Debezium captures changes from PostgreSQL's Write-Ahead Log (WAL):

**Configuration Highlights:**
- Plugin: `pgoutput` (native PostgreSQL logical replication)
- Snapshot mode: `initial` (captures existing data first)
- Topic routing: Table-based topic naming
- Schema evolution support
- Exactly-once delivery semantics

**Monitored Tables:**
- `customers` - Customer information
- `products` - Product catalog
- `orders` - Order transactions
- `order_items` - Order line items
- `inventory_movements` - Stock changes
- `customer_activity` - User behavior tracking

### Apache Kafka

Kafka serves as the central message broker:

**Topic Configuration:**
- 3 partitions per topic for parallelism
- Replication factor of 1 (single broker setup)
- Retention policy: 7 days
- Compression: Snappy

**Key Topics:**
- Source topics: `customers`, `orders`, `products`, etc.
- Processed topics: `processed_orders`, `inventory_alerts`
- Metrics topics: `business_metrics`

### Apache Spark Streaming

Spark processes CDC events in real-time:

**Processing Features:**
- Structured Streaming with Kafka integration
- Watermarking for late data handling
- Stateful aggregations with checkpointing
- Multiple output sinks (console, Kafka, files)

**Business Logic:**
- Order enrichment with customer data
- Inventory level monitoring
- Real-time metrics calculation
- Fraud detection patterns
- Customer behavior analysis

## Data Flow

### 1. Change Capture
```
Database Change → WAL Entry → Debezium → Kafka Topic
```

### 2. Stream Processing
```
Kafka Topic → Spark Streaming → Business Logic → Output Sinks
```

### 3. Event Types

**Insert Events (op: 'c')**
- New customer registrations
- Order creation
- Product additions

**Update Events (op: 'u')**
- Customer profile changes
- Order status updates
- Inventory adjustments

**Delete Events (op: 'd')**
- Customer account deletions
- Order cancellations

### 4. Message Format

CDC events follow Debezium's standard format:

```json
{
  "payload": {
    "before": { ... },      // Previous state (null for inserts)
    "after": { ... },       // New state (null for deletes)
    "op": "c|u|d",         // Operation type
    "ts_ms": 1234567890,   // Timestamp
    "source": {
      "table": "customers",
      "db": "inventory"
    }
  }
}
```

## Configuration

### Environment Variables

```bash
# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=kafka:29092
KAFKA_AUTO_OFFSET_RESET=latest

# Database Configuration
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=inventory
POSTGRES_USER=debezium
POSTGRES_PASSWORD=dbz

# Spark Configuration
SPARK_MASTER_URL=spark://spark-master:7077
SPARK_EXECUTOR_MEMORY=2g
SPARK_DRIVER_MEMORY=1g

# Monitoring Configuration
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
```

### Tuning Parameters

**Kafka Connect:**
```json
{
  "max.batch.size": "2048",
  "max.queue.size": "8192",
  "poll.interval.ms": "1000"
}
```

**Spark Streaming:**
```python
spark.conf.set("spark.sql.streaming.checkpointLocation", "/checkpoints")
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
```

## Deployment

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 8GB RAM minimum
- 20GB disk space

### Quick Deployment

```bash
# 1. Setup infrastructure
./scripts/setup.sh

# 2. Start streaming pipeline
./scripts/start-pipeline.sh

# 3. Generate test data
./scripts/generate-test-data.sh
```

### Production Deployment

For production environments:

1. **Use external databases** instead of containerized PostgreSQL
2. **Deploy Kafka cluster** with multiple brokers and proper replication
3. **Configure SSL/TLS** for all inter-service communication
4. **Set up proper monitoring** with alerting rules
5. **Implement backup strategies** for Kafka topics and checkpoints

## Monitoring

### Key Metrics

**Throughput Metrics:**
- Messages per second processed
- End-to-end latency
- Processing lag

**Error Metrics:**
- Failed message count
- Connector restart count
- Processing errors

**Resource Metrics:**
- CPU and memory utilization
- Disk I/O and network traffic
- JVM garbage collection

### Grafana Dashboards

Pre-configured dashboards monitor:

1. **Pipeline Overview**: High-level health and throughput
2. **Kafka Metrics**: Topic lag, partition distribution
3. **Spark Streaming**: Job progress, batch processing times
4. **Database Metrics**: Connection count, replication lag

### Alerting Rules

Critical alerts configured for:
- Pipeline failures or high error rates
- Processing lag exceeding thresholds
- Resource utilization above 80%
- Database connectivity issues

## Troubleshooting

### Common Issues

**1. Connector Fails to Start**
```bash
# Check connector status
curl -s http://localhost:8083/connectors/postgres-connector/status

# View logs
docker logs kafka-connect
```

**2. High Processing Lag**
```bash
# Check consumer lag
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group spark-streaming
```

**3. Database Connection Issues**
```bash
# Test connectivity
docker exec postgres psql -U debezium -d inventory -c "SELECT 1;"
```

**4. Spark Job Failures**
```bash
# Check Spark logs
docker logs spark-master

# View application UI
# http://localhost:4040
```

### Debug Mode

Enable debug logging:

```bash
# Kafka Connect
export CONNECT_LOG_LEVEL=DEBUG

# Spark
export SPARK_LOG_LEVEL=DEBUG
```

## Performance Tuning

### Kafka Optimization

```properties
# Producer settings
batch.size=16384
linger.ms=5
compression.type=snappy

# Consumer settings
fetch.min.bytes=1024
fetch.max.wait.ms=500
```

### Spark Optimization

```python
# Increase parallelism
spark.conf.set("spark.sql.shuffle.partitions", "200")

# Optimize memory
spark.conf.set("spark.executor.memory", "4g")
spark.conf.set("spark.executor.memoryFraction", "0.8")

# Enable adaptive query execution
spark.conf.set("spark.sql.adaptive.enabled", "true")
```

### Database Optimization

```sql
-- Optimize WAL settings
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET checkpoint_segments = 32;
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
```

## Security Considerations

### Network Security

- Use VPC/private networks in cloud deployments
- Implement firewall rules for service communication
- Enable SSL/TLS for all connections

### Authentication & Authorization

```yaml
# Kafka SASL configuration
security.protocol: SASL_SSL
sasl.mechanism: PLAIN
sasl.jaas.config: |
  org.apache.kafka.common.security.plain.PlainLoginModule required
  username="kafka-user"
  password="kafka-password";
```

### Data Encryption

- Enable encryption at rest for Kafka topics
- Use encrypted database connections
- Implement field-level encryption for sensitive data

## Scaling Guidelines

### Horizontal Scaling

**Kafka:**
- Add more brokers to the cluster
- Increase topic partition count
- Distribute partitions across brokers

**Spark:**
- Add more worker nodes
- Increase executor count per node
- Optimize resource allocation

**Database:**
- Implement read replicas
- Use connection pooling
- Consider database sharding

### Vertical Scaling

**Memory:**
- Increase JVM heap sizes
- Optimize garbage collection
- Use off-heap storage where possible

**CPU:**
- Increase core count per node
- Optimize thread pool sizes
- Use CPU-optimized instance types

**Storage:**
- Use SSD storage for better I/O
- Increase disk space for retention
- Optimize file system settings

### Auto-scaling

Implement auto-scaling based on:
- Message queue depth
- Processing lag metrics
- Resource utilization thresholds
- Time-based patterns

## Best Practices

### Development

1. **Schema Evolution**: Plan for backward-compatible schema changes
2. **Error Handling**: Implement comprehensive error handling and retry logic
3. **Testing**: Use test containers for integration testing
4. **Documentation**: Maintain up-to-date documentation and runbooks

### Operations

1. **Monitoring**: Implement comprehensive monitoring and alerting
2. **Backup**: Regular backups of configurations and state
3. **Disaster Recovery**: Plan for failure scenarios and recovery procedures
4. **Capacity Planning**: Monitor growth trends and plan capacity accordingly

### Security

1. **Access Control**: Implement least-privilege access principles
2. **Audit Logging**: Enable comprehensive audit logging
3. **Vulnerability Management**: Regular security updates and patches
4. **Data Privacy**: Implement data masking for sensitive information

