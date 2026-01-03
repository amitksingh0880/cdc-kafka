#!/bin/bash
# Bash script to start CDC-Kafka infrastructure
# Run this script from the project root directory

set -e

echo -e "\033[32mStarting CDC + Kafka Infrastructure for Insurance Microservices...\033[0m"
echo "============================================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "\033[31m[ERROR] Docker is not running. Please start Docker first.\033[0m"
    exit 1
fi
echo -e "\033[32m[OK] Docker is running\033[0m"

# Start all containers
echo -e "\n\033[33mStarting Docker containers...\033[0m"
docker compose up -d

# Wait for SQL Server to be ready
echo -e "\n\033[33mWaiting for SQL Server to be ready...\033[0m"
max_retries=30
retry_count=0
sql_ready=false

while [ "$sql_ready" = false ] && [ $retry_count -lt $max_retries ]; do
    sleep 5
    retry_count=$((retry_count + 1))
    echo "  Checking SQL Server (attempt $retry_count/$max_retries)..."
    
    if docker exec sqlserver-cdc /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -Q "SELECT 1" 2>/dev/null | grep -q "1"; then
        sql_ready=true
        echo -e "\033[32m[OK] SQL Server is ready!\033[0m"
    fi
done

if [ "$sql_ready" = false ]; then
    echo -e "\033[31m[ERROR] SQL Server failed to start within expected time\033[0m"
    exit 1
fi

# Initialize databases
echo -e "\n\033[33mInitializing insurance databases...\033[0m"
docker exec -i sqlserver-cdc /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -i /docker-entrypoint-initdb.d/init-databases.sql

echo -e "\033[32m[OK] Databases initialized with CDC enabled\033[0m"

# Wait for Kafka Connect to be ready
echo -e "\n\033[33mWaiting for Kafka Connect to be ready...\033[0m"
max_retries=30
retry_count=0
connect_ready=false

while [ "$connect_ready" = false ] && [ $retry_count -lt $max_retries ]; do
    sleep 5
    retry_count=$((retry_count + 1))
    echo "  Checking Kafka Connect (attempt $retry_count/$max_retries)..."
    
    if curl -s http://localhost:8083/ > /dev/null 2>&1; then
        connect_ready=true
        echo -e "\033[32m[OK] Kafka Connect is ready!\033[0m"
    fi
done

if [ "$connect_ready" = false ]; then
    echo -e "\033[31m[ERROR] Kafka Connect failed to start within expected time\033[0m"
    exit 1
fi

echo -e "\n============================================================="
echo -e "\033[32mInfrastructure is ready!\033[0m"
echo "============================================================="
echo -e "\n\033[36mServices available at:\033[0m"
echo "  - SQL Server:      localhost:1433"
echo "  - Kafka:           localhost:9092"
echo "  - Kafka Connect:   http://localhost:8083"
echo "  - Schema Registry: http://localhost:8081"
echo "  - Kafka UI:        http://localhost:8080"
echo -e "\n\033[33mNext step: Run ./scripts/register-connectors.sh to register Debezium connectors\033[0m"
