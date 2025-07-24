#!/bin/bash

# Start the CDC Streaming Pipeline
# This script starts the Spark streaming application

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=========================================="
echo "Starting CDC Streaming Pipeline"
echo "=========================================="

# Check if infrastructure is running
check_infrastructure() {
    print_status "Checking infrastructure services..."
    
    services=("postgres" "kafka" "kafka-connect" "spark-master")
    for service in "${services[@]}"; do
        if ! docker ps | grep -q "$service"; then
            print_error "Service $service is not running. Please run setup.sh first."
            exit 1
        fi
    done
    print_status "All infrastructure services are running"
}

# Start Spark worker if not running
start_spark_worker() {
    if ! docker ps | grep -q "spark-worker"; then
        print_status "Starting Spark worker..."
        docker-compose up -d spark-worker
        sleep 10
    fi
}

# Install Python dependencies in Spark containers
install_dependencies() {
    print_status "Installing Python dependencies..."
    
    # Install dependencies in Spark master
    docker exec spark-master pip install -r /opt/spark-apps/requirements.txt
    
    # Install dependencies in Spark worker
    docker exec spark-worker pip install -r /opt/spark-apps/requirements.txt
    
    print_status "Dependencies installed successfully"
}

# Submit Spark streaming job
submit_spark_job() {
    print_status "Submitting Spark streaming job..."
    
    docker exec -d spark-master spark-submit \
        --master spark://spark-master:7077 \
        --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.3.2 \
        --driver-memory 1g \
        --executor-memory 1g \
        --executor-cores 2 \
        --total-executor-cores 4 \
        --conf spark.sql.streaming.checkpointLocation=/tmp/spark-checkpoints \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.sql.adaptive.coalescePartitions.enabled=true \
        /opt/spark-apps/streaming-processor.py
    
    print_status "Spark streaming job submitted successfully"
}

# Monitor job status
monitor_job() {
    print_status "Monitoring Spark job status..."
    sleep 5
    
    # Check if the application is running
    app_id=$(docker exec spark-master curl -s http://localhost:8080/json/ | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ -n "$app_id" ]; then
        print_status "Spark application started with ID: $app_id"
        echo ""
        echo "Monitor the application at: http://localhost:8080"
        echo "View streaming queries at: http://localhost:4040"
    else
        print_warning "Could not determine application ID. Check Spark Master UI manually."
    fi
}

# Generate some test data
generate_test_data() {
    print_status "Generating initial test data..."
    
    # Insert some test records to trigger CDC events
    docker exec postgres psql -U postgres -d inventory -c "
        INSERT INTO customers (first_name, last_name, email, phone, city, state, country) 
        VALUES ('Test', 'User', 'test.user@example.com', '555-TEST', 'Test City', 'TS', 'USA');
        
        UPDATE products SET stock_quantity = stock_quantity - 1 WHERE id = 1;
        
        INSERT INTO orders (customer_id, status, total_amount, payment_method) 
        VALUES (1, 'pending', 99.99, 'credit_card');
    "
    
    print_status "Test data generated successfully"
}

# Display monitoring information
display_monitoring_info() {
    echo ""
    echo "=========================================="
    echo "Pipeline Monitoring"
    echo "=========================================="
    echo "Spark Master UI:    http://localhost:8080"
    echo "Spark Application:  http://localhost:4040"
    echo "Kafka UI:          http://localhost:8090"
    echo "Prometheus:        http://localhost:9090"
    echo "Grafana:          http://localhost:3000"
    echo ""
    echo "To view streaming output:"
    echo "docker logs spark-master -f"
    echo ""
    echo "To stop the pipeline:"
    echo "./scripts/stop-pipeline.sh"
    echo ""
}

# Main execution
main() {
    check_infrastructure
    start_spark_worker
    install_dependencies
    submit_spark_job
    monitor_job
    generate_test_data
    display_monitoring_info
    
    print_status "CDC Streaming Pipeline started successfully!"
}

# Run main function
main "$@"

