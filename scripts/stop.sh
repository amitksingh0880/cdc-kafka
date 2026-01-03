#!/bin/bash
# Bash script to stop and clean up CDC infrastructure

REMOVE_VOLUMES=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--volumes) REMOVE_VOLUMES=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo -e "\033[33mStopping CDC + Kafka Infrastructure...\033[0m"

if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "\033[31mWARNING: This will remove all data volumes!\033[0m"
    read -p "Are you sure? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
    docker compose down -v
    echo -e "\033[32m[OK] All containers and volumes removed\033[0m"
else
    docker compose down
    echo -e "\033[32m[OK] All containers stopped (data preserved)\033[0m"
fi

echo -e "\n\033[36mTo restart, run: ./scripts/start.sh\033[0m"
