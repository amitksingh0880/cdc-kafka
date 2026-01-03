# PowerShell script to check status of all CDC services

Write-Host "CDC + Kafka Infrastructure Status" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green

# Check Docker containers
Write-Host "`n[Docker Containers]" -ForegroundColor Cyan
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Check Kafka Connect
Write-Host "`n[Kafka Connect]" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8083/" -Method Get -ErrorAction Stop
    Write-Host "  Status: RUNNING" -ForegroundColor Green
    Write-Host "  Version: $($response.version)" -ForegroundColor White
}
catch {
    Write-Host "  Status: NOT AVAILABLE" -ForegroundColor Red
}

# Check connectors
Write-Host "`n[Debezium Connectors]" -ForegroundColor Cyan
try {
    $connectors = Invoke-RestMethod -Uri "http://localhost:8083/connectors" -Method Get -ErrorAction Stop
    
    if ($connectors.Count -eq 0) {
        Write-Host "  No connectors registered" -ForegroundColor Yellow
    }
    else {
        foreach ($connector in $connectors) {
            $status = Invoke-RestMethod -Uri "http://localhost:8083/connectors/$connector/status" -Method Get -ErrorAction Stop
            $state = $status.connector.state
            $taskState = if ($status.tasks.Count -gt 0) { $status.tasks[0].state } else { "NO_TASKS" }
            
            $color = if ($state -eq "RUNNING" -and $taskState -eq "RUNNING") { "Green" } else { "Yellow" }
            Write-Host "  $connector : $state (task: $taskState)" -ForegroundColor $color
        }
    }
}
catch {
    Write-Host "  Cannot retrieve connector status" -ForegroundColor Red
}

# Check Kafka topics
Write-Host "`n[Kafka Topics]" -ForegroundColor Cyan
try {
    $topics = docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>$null
    $cdcTopics = $topics | Where-Object { $_ -match "insurance\." }
    
    if ($cdcTopics.Count -eq 0) {
        Write-Host "  No CDC topics found (run register-connectors.ps1 first)" -ForegroundColor Yellow
    }
    else {
        foreach ($topic in $cdcTopics) {
            Write-Host "  $topic" -ForegroundColor White
        }
    }
}
catch {
    Write-Host "  Cannot retrieve Kafka topics" -ForegroundColor Red
}

# Check databases with CDC enabled
Write-Host "`n[SQL Server CDC Status]" -ForegroundColor Cyan
try {
    $result = docker exec sqlserver-cdc /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -Q "SELECT name FROM sys.databases WHERE is_cdc_enabled = 1" -h -1 -W 2>$null
    $databases = $result | Where-Object { $_ -and $_.Trim() }
    
    if ($databases.Count -eq 0) {
        Write-Host "  No CDC-enabled databases found" -ForegroundColor Yellow
    }
    else {
        foreach ($db in $databases) {
            Write-Host "  $($db.Trim()) : CDC Enabled" -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "  Cannot connect to SQL Server" -ForegroundColor Red
}

Write-Host "`n=============================================================" -ForegroundColor Green
Write-Host "Service URLs:" -ForegroundColor Cyan
Write-Host "  Kafka UI:        http://localhost:8080" -ForegroundColor White
Write-Host "  Kafka Connect:   http://localhost:8083" -ForegroundColor White
Write-Host "  Schema Registry: http://localhost:8081" -ForegroundColor White
