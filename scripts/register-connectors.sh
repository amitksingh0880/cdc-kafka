#!/bin/bash
# Bash script to register Debezium connectors
# Run this after the infrastructure is up (start.sh)

set -e

echo -e "\033[32mRegistering Debezium Connectors...\033[0m"
echo "============================================================="

CONNECT_URL="http://localhost:8083/connectors"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONNECTORS_PATH="$SCRIPT_DIR/../connectors"

# Check if Kafka Connect is ready
if ! curl -s http://localhost:8083/ > /dev/null 2>&1; then
    echo -e "\033[31m[ERROR] Kafka Connect is not available. Please run start.sh first.\033[0m"
    exit 1
fi
echo -e "\033[32m[OK] Kafka Connect is available\033[0m"

# Function to register a connector
register_connector() {
    local connector_file=$1
    local connector_name=$2
    
    echo -e "\n\033[33mRegistering $connector_name...\033[0m"
    
    # Check if connector already exists and delete it
    if curl -s "$CONNECT_URL/$connector_name" > /dev/null 2>&1; then
        echo "  Connector already exists. Updating..."
        curl -s -X DELETE "$CONNECT_URL/$connector_name" > /dev/null
        sleep 2
    fi
    
    # Register connector
    if curl -s -X POST -H "Content-Type: application/json" -d @"$connector_file" "$CONNECT_URL" > /dev/null 2>&1; then
        echo -e "\033[32m[OK] $connector_name registered successfully\033[0m"
    else
        echo -e "\033[31m[ERROR] Failed to register $connector_name\033[0m"
    fi
}

# Register all source connectors
register_connector "$CONNECTORS_PATH/source-connector-policies.json" "source-connector-policies"
register_connector "$CONNECTORS_PATH/source-connector-claims.json" "source-connector-claims"
register_connector "$CONNECTORS_PATH/source-connector-customers.json" "source-connector-customers"

# Wait a moment for connectors to start
sleep 5

# Check connector status
echo -e "\n============================================================="
echo -e "\033[32mConnector Status:\033[0m"
echo "============================================================="

connectors=("source-connector-policies" "source-connector-claims" "source-connector-customers")

for connector in "${connectors[@]}"; do
    status=$(curl -s "$CONNECT_URL/$connector/status" 2>/dev/null)
    if [ -n "$status" ]; then
        state=$(echo "$status" | jq -r '.connector.state')
        task_state=$(echo "$status" | jq -r '.tasks[0].state // "NO_TASKS"')
        
        if [ "$state" = "RUNNING" ] && [ "$task_state" = "RUNNING" ]; then
            echo -e "  \033[32m$connector : $state (task: $task_state)\033[0m"
        else
            echo -e "  \033[33m$connector : $state (task: $task_state)\033[0m"
        fi
    else
        echo -e "  \033[31m$connector : ERROR\033[0m"
    fi
done

echo -e "\n============================================================="
echo -e "\033[32mCDC is now active! Changes to database tables will be captured.\033[0m"
echo "============================================================="
echo -e "\n\033[36mKafka Topics created:\033[0m"
echo "  - insurance.PolicyServiceDB.dbo.Policies"
echo "  - insurance.PolicyServiceDB.dbo.Coverage"
echo "  - insurance.PolicyServiceDB.dbo.Premiums"
echo "  - insurance.ClaimsServiceDB.dbo.Claims"
echo "  - insurance.ClaimsServiceDB.dbo.ClaimDocuments"
echo "  - insurance.ClaimsServiceDB.dbo.ClaimPayments"
echo "  - insurance.CustomerServiceDB.dbo.Customers"
echo "  - insurance.CustomerServiceDB.dbo.Addresses"
echo "  - insurance.CustomerServiceDB.dbo.Beneficiaries"
echo -e "\n\033[33mView Kafka UI at: http://localhost:8080\033[0m"
