#!/bin/bash
# Bash script to check status of all CDC services

echo -e "\033[32mCDC + Kafka Infrastructure Status\033[0m"
echo "============================================================="

# Check Docker containers
echo -e "\n\033[36m[Docker Containers]\033[0m"
docker compose ps

# Check Kafka Connect
echo -e "\n\033[36m[Kafka Connect]\033[0m"
if curl -s http://localhost:8083/ > /dev/null 2>&1; then
    version=$(curl -s http://localhost:8083/ | jq -r '.version')
    echo -e "  \033[32mStatus: RUNNING\033[0m"
    echo "  Version: $version"
else
    echo -e "  \033[31mStatus: NOT AVAILABLE\033[0m"
fi

# Check connectors
echo -e "\n\033[36m[Debezium Connectors]\033[0m"
connectors=$(curl -s http://localhost:8083/connectors 2>/dev/null)
if [ -n "$connectors" ] && [ "$connectors" != "[]" ]; then
    for connector in $(echo "$connectors" | jq -r '.[]'); do
        status=$(curl -s "http://localhost:8083/connectors/$connector/status" 2>/dev/null)
        state=$(echo "$status" | jq -r '.connector.state')
        task_state=$(echo "$status" | jq -r '.tasks[0].state // "NO_TASKS"')
        
        if [ "$state" = "RUNNING" ] && [ "$task_state" = "RUNNING" ]; then
            echo -e "  \033[32m$connector : $state (task: $task_state)\033[0m"
        else
            echo -e "  \033[33m$connector : $state (task: $task_state)\033[0m"
        fi
    done
else
    echo "  No connectors registered"
fi

# Check Kafka topics
echo -e "\n\033[36m[Kafka Topics]\033[0m"
topics=$(docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null | grep "insurance\." || true)
if [ -n "$topics" ]; then
    echo "$topics" | while read topic; do
        echo "  $topic"
    done
else
    echo "  No CDC topics found (run register-connectors.sh first)"
fi

# Check databases with CDC enabled
echo -e "\n\033[36m[SQL Server CDC Status]\033[0m"
databases=$(docker exec sqlserver-cdc /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -Q "SET NOCOUNT ON; SELECT name FROM sys.databases WHERE is_cdc_enabled = 1" -h -1 -W 2>/dev/null)
if [ -n "$databases" ]; then
    echo "$databases" | while read db; do
        if [ -n "$db" ]; then
            echo -e "  \033[32m$db : CDC Enabled\033[0m"
        fi
    done
else
    echo "  Cannot connect to SQL Server or no CDC-enabled databases"
fi

echo -e "\n============================================================="
echo -e "\033[36mService URLs:\033[0m"
echo "  Kafka UI:        http://localhost:8080"
echo "  Kafka Connect:   http://localhost:8083"
echo "  Schema Registry: http://localhost:8081"
