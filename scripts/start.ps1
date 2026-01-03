# PowerShell script to start CDC-Kafka infrastructure
# Run this script from the project root directory

Write-Host "Starting CDC + Kafka Infrastructure for Insurance Microservices..." -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "[OK] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Start all containers
Write-Host "`nStarting Docker containers..." -ForegroundColor Yellow
docker compose up -d

# Wait for SQL Server to be ready
Write-Host "`nWaiting for SQL Server to be ready..." -ForegroundColor Yellow
$maxRetries = 30
$retryCount = 0
$sqlReady = $false

while (-not $sqlReady -and $retryCount -lt $maxRetries) {
    Start-Sleep -Seconds 5
    $retryCount++
    Write-Host "  Checking SQL Server (attempt $retryCount/$maxRetries)..."
    
    try {
        $result = docker exec sqlserver-cdc /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -Q "SELECT 1" 2>&1
        if ($result -match "1") {
            $sqlReady = $true
            Write-Host "[OK] SQL Server is ready!" -ForegroundColor Green
        }
    } catch {
        # Keep waiting
    }
}

if (-not $sqlReady) {
    Write-Host "[ERROR] SQL Server failed to start within expected time" -ForegroundColor Red
    exit 1
}

# Initialize databases
Write-Host "`nInitializing insurance databases..." -ForegroundColor Yellow
docker exec -i sqlserver-cdc /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -i /docker-entrypoint-initdb.d/init-databases.sql

Write-Host "[OK] Databases initialized with CDC enabled" -ForegroundColor Green

# Wait for Kafka Connect to be ready
Write-Host "`nWaiting for Kafka Connect to be ready..." -ForegroundColor Yellow
$maxRetries = 30
$retryCount = 0
$connectReady = $false

while (-not $connectReady -and $retryCount -lt $maxRetries) {
    Start-Sleep -Seconds 5
    $retryCount++
    Write-Host "  Checking Kafka Connect (attempt $retryCount/$maxRetries)..."
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8083/" -Method Get -ErrorAction Stop
        $connectReady = $true
        Write-Host "[OK] Kafka Connect is ready!" -ForegroundColor Green
    } catch {
        # Keep waiting
    }
}

if (-not $connectReady) {
    Write-Host "[ERROR] Kafka Connect failed to start within expected time" -ForegroundColor Red
    exit 1
}

Write-Host "`n=============================================================" -ForegroundColor Green
Write-Host "Infrastructure is ready!" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Write-Host "`nServices available at:" -ForegroundColor Cyan
Write-Host "  - SQL Server:      localhost:1433" -ForegroundColor White
Write-Host "  - Kafka:           localhost:9092" -ForegroundColor White
Write-Host "  - Kafka Connect:   http://localhost:8083" -ForegroundColor White
Write-Host "  - Schema Registry: http://localhost:8081" -ForegroundColor White
Write-Host "  - Kafka UI:        http://localhost:8080" -ForegroundColor White
Write-Host "`nNext step: Run .\scripts\register-connectors.ps1 to register Debezium connectors" -ForegroundColor Yellow
