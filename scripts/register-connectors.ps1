# PowerShell script to register Debezium connectors
# Run this after the infrastructure is up (start.ps1)

Write-Host "Registering Debezium Connectors..." -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green

$connectUrl = "http://localhost:8083/connectors"
$connectorsPath = "$PSScriptRoot\..\connectors"

# Check if Kafka Connect is ready
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8083/" -Method Get -ErrorAction Stop
    Write-Host "[OK] Kafka Connect is available" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Kafka Connect is not available. Please run start.ps1 first." -ForegroundColor Red
    exit 1
}

# Function to register a connector
function Register-Connector {
    param (
        [string]$ConnectorFile,
        [string]$ConnectorName
    )
    
    Write-Host "`nRegistering $ConnectorName..." -ForegroundColor Yellow
    
    # Check if connector already exists
    try {
        $existing = Invoke-RestMethod -Uri "$connectUrl/$ConnectorName" -Method Get -ErrorAction Stop
        Write-Host "  Connector already exists. Updating..." -ForegroundColor Cyan
        
        # Delete existing connector
        Invoke-RestMethod -Uri "$connectUrl/$ConnectorName" -Method Delete -ErrorAction Stop
        Start-Sleep -Seconds 2
    }
    catch {
        # Connector doesn't exist, which is fine
    }
    
    # Register connector
    try {
        $connectorConfig = Get-Content $ConnectorFile -Raw
        $response = Invoke-RestMethod -Uri $connectUrl -Method Post -Body $connectorConfig -ContentType "application/json" -ErrorAction Stop
        Write-Host "[OK] $ConnectorName registered successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to register $ConnectorName : $_" -ForegroundColor Red
    }
}

# Register all source connectors
Register-Connector -ConnectorFile "$connectorsPath\source-connector-policies.json" -ConnectorName "source-connector-policies"
Register-Connector -ConnectorFile "$connectorsPath\source-connector-claims.json" -ConnectorName "source-connector-claims"
Register-Connector -ConnectorFile "$connectorsPath\source-connector-customers.json" -ConnectorName "source-connector-customers"

# Wait a moment for connectors to start
Start-Sleep -Seconds 5

# Check connector status
Write-Host "`n=============================================================" -ForegroundColor Green
Write-Host "Connector Status:" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green

$connectors = @("source-connector-policies", "source-connector-claims", "source-connector-customers")

foreach ($connector in $connectors) {
    try {
        $status = Invoke-RestMethod -Uri "$connectUrl/$connector/status" -Method Get -ErrorAction Stop
        $state = $status.connector.state
        $taskState = if ($status.tasks.Count -gt 0) { $status.tasks[0].state } else { "NO_TASKS" }
        
        if ($state -eq "RUNNING" -and $taskState -eq "RUNNING") {
            Write-Host "  $connector : $state (task: $taskState)" -ForegroundColor Green
        }
        else {
            Write-Host "  $connector : $state (task: $taskState)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  $connector : ERROR - $_" -ForegroundColor Red
    }
}

Write-Host "`n=============================================================" -ForegroundColor Green
Write-Host "CDC is now active! Changes to database tables will be captured." -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Write-Host "`nKafka Topics created:" -ForegroundColor Cyan
Write-Host "  - insurance.PolicyServiceDB.dbo.Policies" -ForegroundColor White
Write-Host "  - insurance.PolicyServiceDB.dbo.Coverage" -ForegroundColor White
Write-Host "  - insurance.PolicyServiceDB.dbo.Premiums" -ForegroundColor White
Write-Host "  - insurance.ClaimsServiceDB.dbo.Claims" -ForegroundColor White
Write-Host "  - insurance.ClaimsServiceDB.dbo.ClaimDocuments" -ForegroundColor White
Write-Host "  - insurance.ClaimsServiceDB.dbo.ClaimPayments" -ForegroundColor White
Write-Host "  - insurance.CustomerServiceDB.dbo.Customers" -ForegroundColor White
Write-Host "  - insurance.CustomerServiceDB.dbo.Addresses" -ForegroundColor White
Write-Host "  - insurance.CustomerServiceDB.dbo.Beneficiaries" -ForegroundColor White
Write-Host "`nView Kafka UI at: http://localhost:8080" -ForegroundColor Yellow
