param(
    [string]$Action = "list",
    [string]$InstanceId
)

$BASE_NAME = "CoC_Bot"

function Get-BotInstances {
    $processes = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*main.py*" -and $_.CommandLine -like "*--id*"
    }

    $instances = @()
    foreach ($proc in $processes) {
        $cmdLine = $proc.CommandLine
        # Match --id followed by either quoted or unquoted value
        if ($cmdLine -match '--id\s+("([^"]+)"|''([^'']+)''|([^\s]+))') {
            $id = $matches[2] + $matches[3] + $matches[4]  # One of these will have the value
            $instances += @{
                Id = $id
                PID = $proc.Id
                StartTime = $proc.StartTime
                CPU = $proc.CPU
                Memory = [math]::Round($proc.WorkingSet64 / 1MB, 2)
            }
        }
    }
    return $instances
}

function Start-Instance {
    param([string]$Id)

    if (-not $Id) {
        Write-Host "Usage: .\manage_instances.ps1 -Action start -InstanceId <id>"
        return
    }

    $existing = Get-BotInstances | Where-Object { $_.Id -eq $Id }
    if ($existing) {
        Write-Host "Instance '$Id' is already running (PID: $($existing.PID))"
        return
    }

    Write-Host "Starting instance '$Id'..."
    try {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $projectRoot = Split-Path -Parent $scriptPath
        $job = Start-Job -ScriptBlock {
            param($instanceId, $projectPath)
            Set-Location $projectPath
            & python "src\main.py" --id $instanceId
        } -ArgumentList $Id, $projectRoot -Name "CoC_Bot_$Id"

        Start-Sleep -Seconds 2

        if ((Get-Job -Name "CoC_Bot_$Id").State -eq "Running") {
            Write-Host "Instance '$Id' started successfully in background"
        } else {
            Write-Host "Failed to start instance '$Id'"
            Receive-Job -Job (Get-Job -Name "CoC_Bot_$Id")
        }
    } catch {
        Write-Host "Error starting instance '$Id': $_"
    }
}

function Stop-Instance {
    param([string]$Id)

    if (-not $Id) {
        Write-Host "Usage: .\manage_instances.ps1 -Action stop -InstanceId <id>"
        return
    }

    $instances = Get-BotInstances | Where-Object { $_.Id -eq $Id }
    if (-not $instances) {
        Write-Host "Instance '$Id' is not running"
        return
    }

    Write-Host "Stopping instance '$Id' (PID: $($instances.PID))..."
    try {
        Stop-Process -Id $instances.PID -Force
        Write-Host "Instance '$Id' stopped"
    } catch {
        Write-Host "Error stopping instance '$Id': $_"
    }
}

function Start-AllInstances {
    # Read instance IDs from configs.py
    $configPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\src\configs.py"
    $configContent = Get-Content $configPath -Raw

    # Extract INSTANCE_IDS using regex
    if ($configContent -match 'INSTANCE_IDS\s*=\s*\[([^\]]+)\]') {
        $idsString = $matches[1]
        # Parse the Python list format
        $ids = $idsString -split ',' | ForEach-Object {
            $_.Trim().Trim('"').Trim("'")
        }
    } else {
        Write-Host "Could not parse INSTANCE_IDS from configs.py"
        return
    }

    foreach ($id in $ids) {
        Start-Instance -Id $id
        Start-Sleep -Seconds 1
    }
}

function Stop-AllInstances {
    $instances = Get-BotInstances

    foreach ($instance in $instances) {
        Write-Host "Stopping instance '$($instance.Id)' (PID: $($instance.PID))..."
        try {
            Stop-Process -Id $instance.PID -Force
        } catch {
            Write-Host "Error stopping instance '$($instance.Id)': $_"
        }
    }

    Write-Host "All instances stopped"
}

switch ($Action.ToLower()) {
    "list" {
        $instances = Get-BotInstances
        if ($instances.Count -eq 0) {
            Write-Host "No CoC Bot instances are currently running"
        } else {
            Write-Host "Running CoC Bot instances:"
            Write-Host "ID`tPID`tStart Time`t`tCPU`tMemory (MB)"
            Write-Host "------------------------------------------------------------"
            foreach ($instance in $instances) {
                Write-Host "$($instance.Id)`t$($instance.PID)`t$($instance.StartTime)`t$($instance.CPU)`t$($instance.Memory)"
            }
        }
    }
    "start" {
        if ($InstanceId) {
            Start-Instance -Id $InstanceId
        } else {
            Start-AllInstances
        }
    }
    "stop" {
        if ($InstanceId) {
            Stop-Instance -Id $InstanceId
        } else {
            Stop-AllInstances
        }
    }
    "restart" {
        if (-not $InstanceId) {
            Write-Host "InstanceId required for restart action"
            return
        }

        Stop-Instance -Id $InstanceId
        Start-Sleep -Seconds 2
        Start-Instance -Id $InstanceId
    }
    default {
        Write-Host "Usage: .\manage_instances.ps1 -Action <list|start|stop|restart> [-InstanceId <id>]"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\manage_instances.ps1 -Action list"
        Write-Host "  .\manage_instances.ps1 -Action start -InstanceId TheLethalLeaf2"
        Write-Host "  .\manage_instances.ps1 -Action stop -InstanceId NBBoss"
        Write-Host "  .\manage_instances.ps1 -Action start  # starts all instances"
        Write-Host "  .\manage_instances.ps1 -Action stop   # stops all instances"
    }
}
