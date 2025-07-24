#!/bin/bash

# Generate Test Data for CDC Pipeline
# This script generates realistic test data to demonstrate CDC events

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "=========================================="
echo "CDC Pipeline Test Data Generator"
echo "=========================================="

# Database connection function
execute_sql() {
    docker exec postgres psql -U postgres -d inventory -c "$1"
}

# Generate customer data
generate_customers() {
    print_status "Generating customer data..."
    
    customers=(
        "('Alice', 'Cooper', 'alice.cooper@email.com', '555-0201', '100 Rock St', 'Detroit', 'MI', '48201', 'USA')"
        "('Bob', 'Dylan', 'bob.dylan@email.com', '555-0202', '200 Folk Ave', 'Nashville', 'TN', '37201', 'USA')"
        "('Carol', 'King', 'carol.king@email.com', '555-0203', '300 Song Rd', 'New York', 'NY', '10002', 'USA')"
        "('David', 'Bowie', 'david.bowie@email.com', '555-0204', '400 Space Dr', 'London', 'UK', 'SW1A', 'UK')"
        "('Elvis', 'Presley', 'elvis.presley@email.com', '555-0205', '500 Graceland Blvd', 'Memphis', 'TN', '38116', 'USA')"
    )
    
    for customer in "${customers[@]}"; do
        execute_sql "INSERT INTO customers (first_name, last_name, email, phone, address, city, state, zip_code, country) VALUES $customer;"
        sleep 1
    done
    
    print_status "Generated ${#customers[@]} new customers"
}

# Update product inventory
update_inventory() {
    print_status "Updating product inventory..."
    
    # Simulate inventory changes
    updates=(
        "UPDATE products SET stock_quantity = stock_quantity - 5 WHERE id = 1;"
        "UPDATE products SET stock_quantity = stock_quantity + 20 WHERE id = 2;"
        "UPDATE products SET stock_quantity = stock_quantity - 3 WHERE id = 3;"
        "UPDATE products SET price = price * 1.05 WHERE id = 4;"
        "UPDATE products SET stock_quantity = 5 WHERE id = 5;"  # Low stock alert
        "UPDATE products SET stock_quantity = stock_quantity - 10 WHERE id = 6;"
    )
    
    for update in "${updates[@]}"; do
        execute_sql "$update"
        sleep 2
    done
    
    print_status "Updated inventory for ${#updates[@]} products"
}

# Generate orders
generate_orders() {
    print_status "Generating new orders..."
    
    # Get customer IDs
    customer_ids=$(execute_sql "SELECT id FROM customers ORDER BY id DESC LIMIT 5;" | grep -E '^\s*[0-9]+' | tr -d ' ')
    
    order_count=0
    for customer_id in $customer_ids; do
        # Create order
        order_sql="INSERT INTO orders (customer_id, status, total_amount, payment_method, shipping_address, billing_address) 
                   VALUES ($customer_id, 'pending', 0, 'credit_card', '123 Test St', '123 Test St') RETURNING id;"
        
        order_id=$(execute_sql "$order_sql" | grep -E '^\s*[0-9]+' | tr -d ' ')
        
        if [ -n "$order_id" ]; then
            # Add order items
            items=(
                "($order_id, 1, 1, 199.99, 199.99)"
                "($order_id, 2, 2, 24.99, 49.98)"
            )
            
            total=0
            for item in "${items[@]}"; do
                execute_sql "INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price) VALUES $item;"
                item_total=$(echo "$item" | grep -o '[0-9]*\.[0-9]*' | tail -1)
                total=$(echo "$total + $item_total" | bc -l)
            done
            
            # Update order total
            execute_sql "UPDATE orders SET total_amount = $total WHERE id = $order_id;"
            
            order_count=$((order_count + 1))
            sleep 3
        fi
    done
    
    print_status "Generated $order_count new orders"
}

# Update order statuses
update_order_statuses() {
    print_status "Updating order statuses..."
    
    # Get recent orders
    recent_orders=$(execute_sql "SELECT id FROM orders WHERE status = 'pending' ORDER BY id DESC LIMIT 3;" | grep -E '^\s*[0-9]+' | tr -d ' ')
    
    statuses=("processing" "shipped" "completed")
    status_index=0
    
    for order_id in $recent_orders; do
        status=${statuses[$status_index]}
        execute_sql "UPDATE orders SET status = '$status' WHERE id = $order_id;"
        
        # Add tracking number for shipped orders
        if [ "$status" = "shipped" ]; then
            tracking="TRK$(date +%s)$order_id"
            execute_sql "UPDATE orders SET tracking_number = '$tracking' WHERE id = $order_id;"
        fi
        
        status_index=$(((status_index + 1) % ${#statuses[@]}))
        sleep 2
    done
    
    print_status "Updated statuses for orders"
}

# Generate customer activity
generate_customer_activity() {
    print_status "Generating customer activity..."
    
    activities=(
        "(1, 'page_view', '{\"page\": \"/products/new-headphones\", \"duration\": 67}', '192.168.1.150')"
        "(2, 'search', '{\"query\": \"wireless speakers\", \"results\": 12}', '10.0.0.75')"
        "(3, 'add_to_cart', '{\"product_id\": 3, \"quantity\": 1}', '172.16.0.50')"
        "(4, 'checkout', '{\"order_id\": 15, \"total\": 299.99}', '192.168.2.100')"
        "(5, 'page_view', '{\"page\": \"/categories/sports\", \"duration\": 145}', '10.1.1.25')"
    )
    
    for activity in "${activities[@]}"; do
        execute_sql "INSERT INTO customer_activity (customer_id, activity_type, activity_data, ip_address) VALUES $activity;"
        sleep 1
    done
    
    print_status "Generated ${#activities[@]} customer activities"
}

# Simulate real-time data stream
simulate_realtime_stream() {
    print_status "Starting real-time data simulation..."
    print_warning "Press Ctrl+C to stop the simulation"
    
    counter=0
    while true; do
        case $((counter % 4)) in
            0)
                # Random inventory update
                product_id=$((RANDOM % 15 + 1))
                change=$((RANDOM % 10 - 5))
                execute_sql "UPDATE products SET stock_quantity = GREATEST(0, stock_quantity + $change) WHERE id = $product_id;"
                print_status "Updated inventory for product $product_id (change: $change)"
                ;;
            1)
                # Random customer activity
                customer_id=$((RANDOM % 20 + 1))
                activities=("page_view" "search" "add_to_cart")
                activity=${activities[$((RANDOM % 3))]}
                execute_sql "INSERT INTO customer_activity (customer_id, activity_type, activity_data, ip_address) VALUES ($customer_id, '$activity', '{\"timestamp\": \"$(date -Iseconds)\"}', '192.168.1.$((RANDOM % 255))');"
                print_status "Added $activity for customer $customer_id"
                ;;
            2)
                # Random order status update
                execute_sql "UPDATE orders SET status = 'processing' WHERE status = 'pending' AND id = (SELECT id FROM orders WHERE status = 'pending' ORDER BY RANDOM() LIMIT 1);"
                print_status "Updated random order status"
                ;;
            3)
                # Random price update
                product_id=$((RANDOM % 15 + 1))
                price_change=$(echo "scale=2; (($RANDOM % 20) - 10) / 100" | bc)
                execute_sql "UPDATE products SET price = GREATEST(1.00, price * (1 + $price_change)) WHERE id = $product_id;"
                print_status "Updated price for product $product_id"
                ;;
        esac
        
        counter=$((counter + 1))
        sleep $((RANDOM % 5 + 3))  # Random delay between 3-7 seconds
    done
}

# Display menu
show_menu() {
    echo ""
    echo "Select an option:"
    echo "1. Generate batch test data"
    echo "2. Start real-time simulation"
    echo "3. Generate customers only"
    echo "4. Update inventory only"
    echo "5. Generate orders only"
    echo "6. Exit"
    echo ""
}

# Main execution
main() {
    # Check if database is accessible
    if ! docker exec postgres psql -U postgres -d inventory -c "SELECT 1;" &> /dev/null; then
        print_error "Cannot connect to database. Make sure the pipeline is running."
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Enter your choice (1-6): " choice
        
        case $choice in
            1)
                generate_customers
                update_inventory
                generate_orders
                update_order_statuses
                generate_customer_activity
                print_status "Batch test data generation completed!"
                ;;
            2)
                simulate_realtime_stream
                ;;
            3)
                generate_customers
                ;;
            4)
                update_inventory
                ;;
            5)
                generate_orders
                ;;
            6)
                print_status "Exiting..."
                exit 0
                ;;
            *)
                print_warning "Invalid choice. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Handle script interruption
trap 'echo ""; print_status "Data generation stopped"; exit 0' INT TERM

# Run main function
main "$@"

