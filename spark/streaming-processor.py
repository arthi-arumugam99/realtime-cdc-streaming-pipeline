#!/usr/bin/env python3
"""
Real-time CDC Event Processing with Apache Spark Streaming

This application processes Change Data Capture events from Kafka topics
and applies real-time transformations, enrichments, and analytics.

Author: Data Engineering Team
Version: 1.0.0
"""

import json
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.functions import (
    col, from_json, to_json, struct, when, lit, 
    current_timestamp, window, count, sum as spark_sum,
    avg, max as spark_max, min as spark_min, 
    regexp_replace, split, explode, collect_list,
    udf, broadcast
)
from pyspark.sql.types import (
    StructType, StructField, StringType, IntegerType, 
    DoubleType, TimestampType, BooleanType, MapType
)
from pyspark.sql.streaming import StreamingQuery
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class CDCStreamProcessor:
    """Main class for processing CDC events from Kafka streams."""
    
    def __init__(self, kafka_servers: str = "kafka:29092"):
        """Initialize the CDC stream processor."""
        self.kafka_servers = kafka_servers
        self.spark = self._create_spark_session()
        self.checkpoint_location = "/tmp/spark-checkpoints"
        
        # Define schemas for different event types
        self.schemas = self._define_schemas()
        
        # Business rules and configurations
        self.config = {
            "low_stock_threshold": 10,
            "high_value_order_threshold": 500.0,
            "fraud_detection_enabled": True,
            "notification_webhook": "http://localhost:8080/notifications"
        }
    
    def _create_spark_session(self) -> SparkSession:
        """Create and configure Spark session for streaming."""
        return SparkSession.builder \
            .appName("CDC-Stream-Processor") \
            .config("spark.sql.streaming.checkpointLocation", self.checkpoint_location) \
            .config("spark.sql.streaming.stateStore.maintenanceInterval", "60s") \
            .config("spark.sql.adaptive.enabled", "true") \
            .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
            .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
            .getOrCreate()
    
    def _define_schemas(self) -> Dict[str, StructType]:
        """Define schemas for different CDC event types."""
        return {
            "customers": StructType([
                StructField("id", IntegerType(), True),
                StructField("first_name", StringType(), True),
                StructField("last_name", StringType(), True),
                StructField("email", StringType(), True),
                StructField("phone", StringType(), True),
                StructField("city", StringType(), True),
                StructField("state", StringType(), True),
                StructField("country", StringType(), True),
                StructField("created_at", TimestampType(), True),
                StructField("updated_at", TimestampType(), True)
            ]),
            "products": StructType([
                StructField("id", IntegerType(), True),
                StructField("name", StringType(), True),
                StructField("category", StringType(), True),
                StructField("price", DoubleType(), True),
                StructField("stock_quantity", IntegerType(), True),
                StructField("sku", StringType(), True),
                StructField("created_at", TimestampType(), True),
                StructField("updated_at", TimestampType(), True)
            ]),
            "orders": StructType([
                StructField("id", IntegerType(), True),
                StructField("customer_id", IntegerType(), True),
                StructField("status", StringType(), True),
                StructField("total_amount", DoubleType(), True),
                StructField("payment_method", StringType(), True),
                StructField("order_date", TimestampType(), True),
                StructField("created_at", TimestampType(), True),
                StructField("updated_at", TimestampType(), True)
            ]),
            "order_items": StructType([
                StructField("id", IntegerType(), True),
                StructField("order_id", IntegerType(), True),
                StructField("product_id", IntegerType(), True),
                StructField("quantity", IntegerType(), True),
                StructField("unit_price", DoubleType(), True),
                StructField("total_price", DoubleType(), True),
                StructField("created_at", TimestampType(), True)
            ])
        }
    
    def read_kafka_stream(self, topics: str) -> DataFrame:
        """Read streaming data from Kafka topics."""
        return self.spark \
            .readStream \
            .format("kafka") \
            .option("kafka.bootstrap.servers", self.kafka_servers) \
            .option("subscribe", topics) \
            .option("startingOffsets", "latest") \
            .option("failOnDataLoss", "false") \
            .option("maxOffsetsPerTrigger", "1000") \
            .load()
    
    def parse_cdc_events(self, kafka_df: DataFrame) -> DataFrame:
        """Parse CDC events from Kafka messages."""
        # Extract the CDC payload
        cdc_df = kafka_df.select(
            col("topic"),
            col("partition"),
            col("offset"),
            col("timestamp").alias("kafka_timestamp"),
            from_json(col("value").cast("string"), 
                     StructType([
                         StructField("payload", StructType([
                             StructField("before", MapType(StringType(), StringType()), True),
                             StructField("after", MapType(StringType(), StringType()), True),
                             StructField("op", StringType(), True),
                             StructField("ts_ms", StringType(), True),
                             StructField("source", MapType(StringType(), StringType()), True)
                         ]), True)
                     ])).alias("cdc_data")
        )
        
        # Extract relevant fields
        return cdc_df.select(
            col("topic"),
            col("partition"),
            col("offset"),
            col("kafka_timestamp"),
            col("cdc_data.payload.before").alias("before_data"),
            col("cdc_data.payload.after").alias("after_data"),
            col("cdc_data.payload.op").alias("operation"),
            col("cdc_data.payload.ts_ms").cast("long").alias("change_timestamp"),
            col("cdc_data.payload.source.table").alias("table_name")
        ).filter(col("operation").isNotNull())
    
    def process_customer_events(self, cdc_df: DataFrame) -> DataFrame:
        """Process customer-related CDC events."""
        customer_events = cdc_df.filter(col("table_name") == "customers")
        
        # Extract customer data based on operation type
        processed_customers = customer_events.select(
            col("operation"),
            col("change_timestamp"),
            when(col("operation") == "d", col("before_data"))
            .otherwise(col("after_data")).alias("customer_data")
        ).select(
            col("operation"),
            col("change_timestamp"),
            col("customer_data.id").cast("int").alias("customer_id"),
            col("customer_data.first_name").alias("first_name"),
            col("customer_data.last_name").alias("last_name"),
            col("customer_data.email").alias("email"),
            col("customer_data.city").alias("city"),
            col("customer_data.state").alias("state"),
            current_timestamp().alias("processed_at")
        )
        
        return processed_customers
    
    def process_order_events(self, cdc_df: DataFrame) -> DataFrame:
        """Process order-related CDC events with business logic."""
        order_events = cdc_df.filter(col("table_name") == "orders")
        
        # Extract order data
        processed_orders = order_events.select(
            col("operation"),
            col("change_timestamp"),
            when(col("operation") == "d", col("before_data"))
            .otherwise(col("after_data")).alias("order_data")
        ).select(
            col("operation"),
            col("change_timestamp"),
            col("order_data.id").cast("int").alias("order_id"),
            col("order_data.customer_id").cast("int").alias("customer_id"),
            col("order_data.status").alias("status"),
            col("order_data.total_amount").cast("double").alias("total_amount"),
            col("order_data.payment_method").alias("payment_method"),
            current_timestamp().alias("processed_at")
        )
        
        # Add business logic flags
        enriched_orders = processed_orders.withColumn(
            "is_high_value",
            col("total_amount") > self.config["high_value_order_threshold"]
        ).withColumn(
            "requires_review",
            (col("total_amount") > 1000) | (col("payment_method") == "wire_transfer")
        ).withColumn(
            "priority_level",
            when(col("total_amount") > 1000, "high")
            .when(col("total_amount") > 500, "medium")
            .otherwise("normal")
        )
        
        return enriched_orders
    
    def process_inventory_events(self, cdc_df: DataFrame) -> DataFrame:
        """Process product inventory changes."""
        product_events = cdc_df.filter(col("table_name") == "products")
        
        # Extract product data
        processed_products = product_events.select(
            col("operation"),
            col("change_timestamp"),
            col("before_data.stock_quantity").cast("int").alias("old_stock"),
            col("after_data.stock_quantity").cast("int").alias("new_stock"),
            col("after_data.id").cast("int").alias("product_id"),
            col("after_data.name").alias("product_name"),
            col("after_data.category").alias("category"),
            col("after_data.sku").alias("sku"),
            current_timestamp().alias("processed_at")
        ).filter(col("operation") == "u")  # Only updates
        
        # Detect low stock situations
        low_stock_alerts = processed_products.filter(
            (col("new_stock") <= self.config["low_stock_threshold"]) &
            (col("old_stock") > self.config["low_stock_threshold"])
        ).withColumn("alert_type", lit("low_stock"))
        
        return low_stock_alerts
    
    def calculate_real_time_metrics(self, order_df: DataFrame) -> DataFrame:
        """Calculate real-time business metrics."""
        # Windowed aggregations for real-time metrics
        metrics = order_df \
            .filter(col("operation") == "c") \
            .withWatermark("processed_at", "10 minutes") \
            .groupBy(
                window(col("processed_at"), "5 minutes", "1 minute"),
                col("status")
            ).agg(
                count("*").alias("order_count"),
                spark_sum("total_amount").alias("total_revenue"),
                avg("total_amount").alias("avg_order_value"),
                spark_max("total_amount").alias("max_order_value"),
                spark_min("total_amount").alias("min_order_value")
            ).select(
                col("window.start").alias("window_start"),
                col("window.end").alias("window_end"),
                col("status"),
                col("order_count"),
                col("total_revenue"),
                col("avg_order_value"),
                col("max_order_value"),
                col("min_order_value"),
                current_timestamp().alias("calculated_at")
            )
        
        return metrics
    
    def send_notification(self, alert_data: Dict[str, Any]) -> None:
        """Send notification via webhook."""
        try:
            response = requests.post(
                self.config["notification_webhook"],
                json=alert_data,
                timeout=5
            )
            if response.status_code == 200:
                logger.info(f"Notification sent successfully: {alert_data['type']}")
            else:
                logger.warning(f"Failed to send notification: {response.status_code}")
        except Exception as e:
            logger.error(f"Error sending notification: {str(e)}")
    
    def write_to_console(self, df: DataFrame, query_name: str) -> StreamingQuery:
        """Write streaming DataFrame to console for debugging."""
        return df.writeStream \
            .outputMode("append") \
            .format("console") \
            .option("truncate", "false") \
            .option("numRows", "20") \
            .queryName(query_name) \
            .trigger(processingTime="30 seconds") \
            .start()
    
    def write_to_kafka(self, df: DataFrame, topic: str, query_name: str) -> StreamingQuery:
        """Write processed data back to Kafka."""
        kafka_df = df.select(
            to_json(struct("*")).alias("value")
        )
        
        return kafka_df.writeStream \
            .format("kafka") \
            .option("kafka.bootstrap.servers", self.kafka_servers) \
            .option("topic", topic) \
            .option("checkpointLocation", f"{self.checkpoint_location}/{query_name}") \
            .queryName(query_name) \
            .trigger(processingTime="10 seconds") \
            .start()
    
    def run_streaming_pipeline(self):
        """Main method to run the complete streaming pipeline."""
        logger.info("Starting CDC streaming pipeline...")
        
        try:
            # Read from all CDC topics
            kafka_stream = self.read_kafka_stream("customers,orders,products,order_items")
            
            # Parse CDC events
            cdc_events = self.parse_cdc_events(kafka_stream)
            
            # Process different event types
            customer_stream = self.process_customer_events(cdc_events)
            order_stream = self.process_order_events(cdc_events)
            inventory_stream = self.process_inventory_events(cdc_events)
            
            # Calculate real-time metrics
            metrics_stream = self.calculate_real_time_metrics(order_stream)
            
            # Start streaming queries
            queries = []
            
            # Console outputs for monitoring
            queries.append(self.write_to_console(customer_stream, "customer_events"))
            queries.append(self.write_to_console(order_stream, "order_events"))
            queries.append(self.write_to_console(inventory_stream, "inventory_alerts"))
            queries.append(self.write_to_console(metrics_stream, "real_time_metrics"))
            
            # Kafka outputs for downstream processing
            queries.append(self.write_to_kafka(order_stream, "processed_orders", "orders_sink"))
            queries.append(self.write_to_kafka(inventory_stream, "inventory_alerts", "alerts_sink"))
            queries.append(self.write_to_kafka(metrics_stream, "business_metrics", "metrics_sink"))
            
            logger.info(f"Started {len(queries)} streaming queries")
            
            # Wait for all queries to complete
            for query in queries:
                query.awaitTermination()
                
        except Exception as e:
            logger.error(f"Error in streaming pipeline: {str(e)}")
            raise
        finally:
            self.spark.stop()

def main():
    """Main entry point for the application."""
    processor = CDCStreamProcessor()
    processor.run_streaming_pipeline()

if __name__ == "__main__":
    main()

