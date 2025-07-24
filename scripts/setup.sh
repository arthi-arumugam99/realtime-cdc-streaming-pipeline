#!/bin/bash

# Real-time CDC Streaming Pipeline Setup Script
# This script initializes the complete infrastructure for the CDC pipeline

set -e

echo "=========================================="
echo "CDC Streaming Pipeline Setup"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    print_status "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    print_status "Docker is running successfully"
}

# Check if Docker Compose is available
check_docker_compose() {
    print_status "Checking Docker Compose installation..."
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    print_status "Docker Compose is available"
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    mkdir -p data/postgres
    mkdir -p data/kafka
    mkdir -p data/prometheus
    mkdir -p data/grafana
    mkdir -p logs
    mkdir -p /tmp/spark-checkpoints
    print_status "Directories created successfully"
}

# Set proper permissions
set_permissions() {
    print_status "Setting proper permissions..."
    chmod +x scripts/*.sh
    chmod 755 spark/streaming-processor.py
    print_status "Permissions set successfully"
}

# Pull Docker images
pull_images() {
    print_status "Pulling required Docker images..."
    docker-compose pull
    print_status "Docker images pulled successfully"
}

# Start infrastructure services
start_infrastructure() {
    print_status "Starting infrastructure services..."
    docker-compose up -d postgres zookeeper kafka
    
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Check if Kafka is ready
    print_status "Checking Kafka readiness..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list &> /dev/null; then
            print_status "Kafka is ready"
            break
        fi
        sleep 2
        timeout=$((timeout-2))
    done
    
    if [ $timeout -le 0 ]; then
        print_error "Kafka failed to start within timeout"
        exit 1
    fi
}

# Create Kafka topics
create_kafka_topics() {
    print_status "Creating Kafka topics..."
    
    topics=(
        "customers"
        "orders" 
        "products"
        "order_items"
        "inventory_movements"
        "customer_activity"
        "processed_orders"
        "inventory_alerts"
        "business_metrics"
    )
    
    for topic in "${topics[@]}"; do
        docker exec kafka kafka-topics --create \
            --bootstrap-server localhost:9092 \
            --topic "$topic" \
            --partitions 3 \
            --replication-factor 1 \
            --if-not-exists
        print_status "Created topic: $topic"
    done
}

# Start Kafka Connect
start_kafka_connect() {
    print_status "Starting Kafka Connect..."
    docker-compose up -d kafka-connect
    
    print_status "Waiting for Kafka Connect to be ready..."
    timeout=120
    while [ $timeout -gt 0 ]; do
        if curl -s http://localhost:8083/connectors &> /dev/null; then
            print_status "Kafka Connect is ready"
            break
        fi
        sleep 5
        timeout=$((timeout-5))
    done
    
    if [ $timeout -le 0 ]; then
        print_error "Kafka Connect failed to start within timeout"
        exit 1
    fi
}

# Configure Debezium connector
configure_debezium() {
    print_status "Configuring Debezium PostgreSQL connector..."
    
    # Wait a bit more for Connect to be fully ready
    sleep 10
    
    curl -X POST \
        -H "Content-Type: application/json" \
        --data @kafka/connect/debezium-connector.json \
        http://localhost:8083/connectors
    
    if [ $? -eq 0 ]; then
        print_status "Debezium connector configured successfully"
    else
        print_warning "Failed to configure Debezium connector. You can configure it manually later."
    fi
}

# Start monitoring services
start_monitoring() {
    print_status "Starting monitoring services..."
    docker-compose up -d prometheus grafana kafka-ui
    print_status "Monitoring services started"
}

# Display service URLs
display_urls() {
    echo ""
    echo "=========================================="
    echo "Service URLs"
    echo "=========================================="
    echo "Kafka UI:           http://localhost:8090"
    echo "Kafka Connect:      http://localhost:8083"
    echo "Prometheus:         http://localhost:9090"
    echo "Grafana:           http://localhost:3000 (admin/admin)"
    echo "Spark Master UI:   http://localhost:8080"
    echo ""
    echo "Database Connection:"
    echo "Host: localhost"
    echo "Port: 5432"
    echo "Database: inventory"
    echo "Username: postgres"
    echo "Password: postgres"
    echo ""
}

# Main execution
main() {
    print_status "Starting CDC Streaming Pipeline setup..."
    
    check_docker
    check_docker_compose
    create_directories
    set_permissions
    pull_images
    start_infrastructure
    create_kafka_topics
    start_kafka_connect
    configure_debezium
    start_monitoring
    
    print_status "Setup completed successfully!"
    display_urls
    
    echo ""
    print_status "Next steps:"
    echo "1. Run './scripts/start-pipeline.sh' to start the Spark streaming application"
    echo "2. Use './scripts/generate-test-data.sh' to generate test CDC events"
    echo "3. Monitor the pipeline using the provided web interfaces"
}

# Run main function
main "$@"

