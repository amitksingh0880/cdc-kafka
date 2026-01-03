# CDC + Kafka Database Synchronization for Insurance Microservices

Real-time Change Data Capture (CDC) based database synchronization using Apache Kafka, Debezium, and SQL Server for an insurance platform.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Insurance Microservices                       │
├─────────────────┬─────────────────┬─────────────────────────────┤
│ PolicyServiceDB │ ClaimsServiceDB │ CustomerServiceDB           │
│ - Policies      │ - Claims        │ - Customers                 │
│ - Coverage      │ - ClaimDocuments│ - Addresses                 │
│ - Premiums      │ - ClaimPayments │ - Beneficiaries             │
└────────┬────────┴────────┬────────┴────────┬────────────────────┘
         │                 │                 │
         └────────────────┬┴─────────────────┘
                          ▼
              ┌───────────────────────┐
              │   SQL Server CDC      │
              │   (Change Capture)    │
              └───────────┬───────────┘
                          ▼
              ┌───────────────────────┐
              │   Debezium Connect    │
              │   (CDC Connectors)    │
              └───────────┬───────────┘
                          ▼
              ┌───────────────────────┐
              │    Apache Kafka       │
              │   (Event Streaming)   │
              └───────────────────────┘
```

## 📋 Prerequisites

- **Docker Desktop** (Windows/Mac) or Docker Engine (Linux)
- **Docker Compose** v2.0+
- **PowerShell** (Windows) or **Bash** (Linux/Mac)
- At least **8GB RAM** available for Docker
- Ports available: 1433, 2181, 8080, 8081, 8083, 9092

## 🚀 Quick Start

### Windows (PowerShell)

```powershell
# 1. Start infrastructure
.\scripts\start.ps1

# 2. Register Debezium connectors (after infrastructure is ready)
.\scripts\register-connectors.ps1

# 3. Check status
.\scripts\check-status.ps1
```

### Linux/Mac (Bash)

```bash
# Make scripts executable
chmod +x scripts/*.sh

# 1. Start infrastructure
./scripts/start.sh

# 2. Register Debezium connectors
./scripts/register-connectors.sh

# 3. Check status
./scripts/check-status.sh
```

## 📁 Project Structure

```
cdc-kafka/
├── docker-compose.yml          # Docker infrastructure
├── README.md                   # This file
├── db-init/
│   └── init-databases.sql      # Database schemas + CDC setup
├── connectors/
│   ├── source-connector-policies.json
│   ├── source-connector-claims.json
│   ├── source-connector-customers.json
│   └── sink-connector-sync.json
└── scripts/
    ├── start.ps1 / start.sh
    ├── register-connectors.ps1 / .sh
    ├── check-status.ps1 / .sh
    └── test-sync.sql
```

## 🔧 Services

| Service | Port | Description |
|---------|------|-------------|
| SQL Server | 1433 | Main database server with CDC enabled |
| Kafka | 9092 | Event streaming platform |
| Zookeeper | 2181 | Kafka coordination |
| Kafka Connect | 8083 | Debezium connector management |
| Schema Registry | 8081 | Avro schema management |
| Kafka UI | 8080 | Web UI for monitoring Kafka |

## 📊 Kafka Topics

After registering connectors, these topics are created:

| Topic | Source Table |
|-------|--------------|
| `insurance.PolicyServiceDB.dbo.Policies` | Policies |
| `insurance.PolicyServiceDB.dbo.Coverage` | Coverage |
| `insurance.PolicyServiceDB.dbo.Premiums` | Premiums |
| `insurance.ClaimsServiceDB.dbo.Claims` | Claims |
| `insurance.ClaimsServiceDB.dbo.ClaimDocuments` | Claim Documents |
| `insurance.ClaimsServiceDB.dbo.ClaimPayments` | Claim Payments |
| `insurance.CustomerServiceDB.dbo.Customers` | Customers |
| `insurance.CustomerServiceDB.dbo.Addresses` | Addresses |
| `insurance.CustomerServiceDB.dbo.Beneficiaries` | Beneficiaries |

## 🧪 Testing CDC

### 1. Insert Test Data

```powershell
# Run test SQL script
docker exec -i sqlserver-cdc /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -i /docker-entrypoint-initdb.d/../scripts/test-sync.sql
```

Or connect directly to SQL Server:
```powershell
docker exec -it sqlserver-cdc /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C
```

### 2. Watch Kafka Messages

```powershell
# Watch policy changes
docker exec -it kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic insurance.PolicyServiceDB.dbo.Policies --from-beginning
```

### 3. Use Kafka UI

Open [http://localhost:8080](http://localhost:8080) to:
- Browse topics and messages
- Monitor connector status
- View consumer groups

## 🔌 Database Connection

| Property | Value |
|----------|-------|
| Server | `localhost,1433` |
| User | `sa` |
| Password | `YourStrong@Password123` |
| Databases | `PolicyServiceDB`, `ClaimsServiceDB`, `CustomerServiceDB` |

## 🛠️ Management Commands

```powershell
# Stop all services
docker compose down

# Stop and remove volumes (clean start)
docker compose down -v

# View logs
docker compose logs -f kafka-connect

# Restart a specific service
docker compose restart kafka-connect

# List connectors
curl http://localhost:8083/connectors

# Get connector status
curl http://localhost:8083/connectors/source-connector-policies/status

# Delete a connector
curl -X DELETE http://localhost:8083/connectors/source-connector-policies
```

## 🔍 Troubleshooting

### Kafka Connect not starting
- Wait 60+ seconds after `docker compose up`
- Check logs: `docker compose logs kafka-connect`

### CDC not capturing changes
1. Verify CDC is enabled: 
   ```sql
   SELECT name, is_cdc_enabled FROM sys.databases
   ```
2. Check SQL Agent is running
3. Verify connector status in Kafka UI

### Connector in FAILED state
```powershell
# Check error details
curl http://localhost:8083/connectors/source-connector-policies/status | jq

# Restart connector task
curl -X POST http://localhost:8083/connectors/source-connector-policies/tasks/0/restart
```

## 📝 License

Internal use only - Insurance Platform CDC Infrastructure
