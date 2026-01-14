param(
    [string]$InstanceId,
    [switch]$Background
)

$BASE_NAME = "CoC_Bot"

if (-not $InstanceId) {
    $InstanceId = Read-Host "Enter instance ID"
}

$SESSION_NAME = "${BASE_NAME}_${InstanceId}"

# Check if instance is already running
$existingProcess = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*main.py*" -and $_.CommandLine -like "*--id $InstanceId*"
}

if ($existingProcess) {
    Write-Host "CoC Bot instance '$InstanceId' is already running (PID: $($existingProcess.Id))"
    if (-not $Background) {
        Read-Host "Press Enter to exit"
    }
    exit
}

Write-Host "Starting CoC Bot instance: $InstanceId"
Write-Host "Using ADB address for instance: $InstanceId"

if ($Background) {
    # Start in background
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Split-Path -Parent $scriptPath
    $scriptBlock = {
        param($id, $projectPath)
        try {
            Set-Location $projectPath
            & python "src\main.py" --id $id
        } catch {
            Write-Host "Error starting instance $id: $_"
        }
    }

    Start-Job -ScriptBlock $scriptBlock -ArgumentList $InstanceId, $projectRoot -Name $SESSION_NAME
    Write-Host "$SESSION_NAME started in background"

    # Give it a moment to start
    Start-Sleep -Seconds 2

    # Check if job is running
    $job = Get-Job -Name $SESSION_NAME
    if ($job.State -eq "Running") {
        Write-Host "Background job started successfully"
    } else {
        Write-Host "Failed to start background job"
        Receive-Job -Job $job
    }
} else {
    # Start in foreground
    try {
        & python "src\main.py" --id $InstanceId
    } catch {
        Write-Host "Error: $_"
        Read-Host "Press Enter to exit"
    }
}
