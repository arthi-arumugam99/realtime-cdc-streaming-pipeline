#!/bin/bash

# Stop the CDC Streaming Pipeline
# This script gracefully stops all pipeline components

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
echo "Stopping CDC Streaming Pipeline"
echo "=========================================="

# Stop Spark applications
stop_spark_applications() {
    print_status "Stopping Spark streaming applications..."
    
    # Get running application IDs
    app_ids=$(docker exec spark-master curl -s http://localhost:8080/json/ 2>/dev/null | grep -o '"id":"[^"]*"' | cut -d'"' -f4 || true)
    
    if [ -n "$app_ids" ]; then
        for app_id in $app_ids; do
            print_status "Stopping Spark application: $app_id"
            docker exec spark-master curl -X POST "http://localhost:8080/app/kill/" -d "id=$app_id" || true
        done
    else
        print_status "No running Spark applications found"
    fi
}

# Remove Debezium connector
remove_debezium_connector() {
    print_status "Removing Debezium connector..."
    
    if curl -s http://localhost:8083/connectors/postgres-connector &> /dev/null; then
        curl -X DELETE http://localhost:8083/connectors/postgres-connector
        print_status "Debezium connector removed"
    else
        print_status "Debezium connector not found or Connect not running"
    fi
}

# Stop Docker services
stop_docker_services() {
    print_status "Stopping Docker services..."
    
    # Stop in reverse order of dependencies
    services=(
        "spark-worker"
        "spark-master" 
        "kafka-connect"
        "kafka-ui"
        "grafana"
        "prometheus"
        "kafka"
        "zookeeper"
        "postgres"
    )
    
    for service in "${services[@]}"; do
        if docker ps | grep -q "$service"; then
            print_status "Stopping $service..."
            docker-compose stop "$service"
        fi
    done
}

# Clean up resources
cleanup_resources() {
    print_status "Cleaning up resources..."
    
    # Remove stopped containers
    docker-compose rm -f
    
    # Clean up Spark checkpoints (optional)
    read -p "Do you want to remove Spark checkpoints? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removing Spark checkpoints..."
        rm -rf /tmp/spark-checkpoints/*
        docker exec spark-master rm -rf /tmp/spark-checkpoints/* 2>/dev/null || true
    fi
    
    # Clean up Docker volumes (optional)
    read -p "Do you want to remove Docker volumes (this will delete all data)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Removing Docker volumes..."
        docker-compose down -v
        print_warning "All data has been removed"
    fi
}

# Display cleanup status
display_status() {
    echo ""
    echo "=========================================="
    echo "Pipeline Status"
    echo "=========================================="
    
    running_containers=$(docker ps --filter "name=realtime-cdc" --format "table {{.Names}}\t{{.Status}}" | tail -n +2)
    
    if [ -n "$running_containers" ]; then
        print_warning "Some containers are still running:"
        echo "$running_containers"
        echo ""
        echo "To force stop all containers:"
        echo "docker-compose down -f"
    else
        print_status "All pipeline containers have been stopped"
    fi
    
    echo ""
    echo "To restart the pipeline:"
    echo "1. ./scripts/setup.sh"
    echo "2. ./scripts/start-pipeline.sh"
}

# Main execution
main() {
    stop_spark_applications
    sleep 5
    remove_debezium_connector
    sleep 2
    stop_docker_services
    cleanup_resources
    display_status
    
    print_status "CDC Streaming Pipeline stopped successfully!"
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"

