# Define the menu-driven function
function Show-Menu {
    Clear-Host
    Write-Host "----------------------------------" -ForegroundColor Cyan
    Write-Host " NetBackup and Veritas Service Menu" -ForegroundColor Cyan
    Write-Host " Tips: Make sure the mapping and the connection is working before:" -ForegroundColor Red
    Write-Host " Tips: Restarting services" -ForegroundColor Yellow
    Write-Host " Tips: Clean /track" -ForegroundColor Yello
    Write-Host " Tips: Check/Renew certificates" -ForegroundColor Yellow
    Write-Host "----------------------------------`n" -ForegroundColor Cyan
    Write-Host "0. Check Netbackup Services Status"
    Write-Host "1. Check Mapping"
    Write-Host "2. Check Connection"
    Write-Host "3. Stop Veritas and NetBackup Services"
    Write-Host "4. Clean track folder (C:\Program Files\Veritas\Netbackup\track)"
    Write-Host "5. Start Veritas and NetBackup Services"
    Write-Host "6. Check Certificates"
    Write-Host "7. Renew Certificate"
    Write-Host "8. Exit`n"
}

# Define the directory and log file path
$logDirectory = "C:\Netbackup-Script-Log"
$logFilePath = Join-Path -Path $logDirectory -ChildPath "logfile.txt"

# Ensure the directory exists
if (-not (Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory | Out-Null
    Write-Host "Log directory created at $logDirectory" -ForegroundColor Green
}

# Ensure the log file exists
if (-not (Test-Path -Path $logFilePath)) {
    New-Item -Path $logFilePath -ItemType File | Out-Null
    Write-Host "Log file created at $logFilePath" -ForegroundColor Green
}

# Function to log errors
function Log-Error {
    param (
        [string]$FunctionName,
        [string]$ErrorMessage
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] Error in function '$FunctionName': $ErrorMessage`n"
    
    try {
        Add-Content -Path $logFilePath -Value $logMessage
        Write-Host "Logged an error to $logFilePath" -ForegroundColor Yellow
    } catch {
        Write-Host "Failed to write to log file: $_" -ForegroundColor Red
    }
}

function Check-ServiceStatus {
    try {
        # Specify the actual service names you want to check
        $services = @("VRTSpbx", "NetBackup*") # Replace these with actual service names
        
        # Check the status of each service
        foreach ($service in $services) {
            $serviceStatus = Get-Service -Name $service -ErrorAction Stop
            Write-Host "Service: $($serviceStatus.DisplayName)"
            Write-Host "Status: $($serviceStatus.Status)`n" -ForegroundColor Green
        }
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error checking service status: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Check-ServiceStatus" -ErrorMessage $errorMessage
    }
}

# Define functions for each task
function Stop-Services {
    try {
        $services = @("VRTSpbx", "NetBackup*")
        foreach ($service in $services) {
            $serviceStop = Stop-Service -Name $service -Force -ErrorAction Stop
            Write-Host "Service: $($serviceStop.DisplayName)"
            Write-Host "Stop: $($serviceStop.Status)`n" -ForegroundColor Green
            }
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error stopping services: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Stop-Services" -ErrorMessage $errorMessage
        }
}

function Clean-TrackFolder {
    try {
        $trackFolderPath = "C:\Program Files\Veritas\Netbackup\track"
        Remove-Item -Path "$trackFolderPath\*" -Recurse -Force -ErrorAction Stop
        Write-Host "Track folder cleaned." -ForegroundColor Green
        }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error while cleaning track: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Clean-TrackFolder" -ErrorMessage $errorMessage
        }
}

function Start-Services {
    try {
        $services = @("VRTSpbx", "NetBackup*")
        foreach ($service in $services) {
            $serviceStop = Start-Service -Name $service -ErrorAction Stop
            Write-Host "Service: $($serviceStart.DisplayName)"
            Write-Host "Start: $($serviceStart.Status)`n" -ForegroundColor Green
            }
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error stopping services: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Start-Services" -ErrorMessage $errorMessage
        }
}

#function Start-Services {
    # Replace 'VeritasServiceName' and 'NetBackupServiceName' with actual service names
 #   Start-Service -Name "VRTSpbx"
  #  Start-Service -Name "NetBackup*"
   # Write-Host "Services started successfully." -ForegroundColor Green
#}

function Check-Certificates {
    $bpclntcmd = "C:\Program Files\Veritas\NetBackup\bin\bpclntcmd"
    $nbcertcmd = "C:\Program Files\Veritas\NetBackup\bin\nbcertcmd"

    # Execute the commands and capture the output
    try {
        Write-Host "Clearing host cache..."
        $clearHostCacheOutput = & "$bpclntcmd" -clear_host_cache -ErrorAction Stop
        Write-Host $clearHostCacheOutput -ForegroundColor Green

        Write-Host "Getting CA Certificate..."
        $getCACertificateOutput = & "$nbcertcmd" -getCACertificate -ErrorAction Stop
        Write-Host $getCACertificateOutput -ForegroundColor Green

        Write-Host "Getting Certificate with force..."
        $getCertificateOutput = & "$nbcertcmd" -getCertificate -force -ErrorAction Stop
        Write-Host $getCertificateOutput -ForegroundColor Green

    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error checking the certificate: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Check-Certificates" -ErrorMessage $errorMessage
    }
}

# Define the new function for getting a certificate with a token
function Get-Certificate-With-Token {
    try {
        $tokenValue = Read-Host "Enter the token value"
        $command = '"C:\Program Files\Veritas\NetBackup\bin\nbcertcmd" -getCertificate -force -token ' + $tokenValue

        Invoke-Expression $command

    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error getting certificate with token: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Get-Certificate-With-Token" -ErrorMessage $errorMessage
    }
}

function Check-Mapping {
    try {
        # List the content of the hosts file
        $hostsFilePath = "C:\Windows\System32\drivers\etc\hosts"
        if (Test-Path $hostsFilePath) {
            Write-Host "Contents of the hosts file:" -ForegroundColor Cyan
            Get-Content -Path $hostsFilePath | ForEach-Object { Write-Host $_ }
        } else {
            Write-Host "Hosts file not found at $hostsFilePath" -ForegroundColor Red
        }

        Write-Host "`nRetrieving NetBackup Server registry config:" -ForegroundColor Cyan
        # Access the specified registry key
        $registryPath = "HKLM:\SOFTWARE\Veritas\NetBackup\CurrentVersion\Config"
        if (Test-Path $registryPath) {
            # Get the specific registry value for 'Server'
            $serverValue = Get-ItemProperty -Path $registryPath -Name "Server" -ErrorAction Stop
            
            # Display the 'Server' value name and data in a table
            [PSCustomObject]@{
                Name = "Server"
                Data = $serverValue.Server
            } | Format-Table -AutoSize
        } else {
            Write-Host "Registry path not found: $registryPath" -ForegroundColor Red
        }
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error checking mapping: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Check-Mapping" -ErrorMessage $errorMessage
    }
}

function Check-Connection {
    try {
        Write-Host "Enter hostnames or IP addresses one at a time to ping them. Type 'done' when finished." -ForegroundColor Cyan

        $hostsToPing = @()
        do {
            $inputHost = Read-Host "Enter a hostname or IP address (or type 'done' to finish)"
            if ($inputHost -ne 'done') {
                $hostsToPing += $inputHost
            }
        } while ($inputHost -ne 'done')

        foreach ($inputHost in $hostsToPing) {
            Write-Host "`nPinging $inputHost..." -ForegroundColor Cyan
            try {
                Test-Connection -ComputerName $inputHost -Count 4 -ErrorAction Stop | ForEach-Object {
                    Write-Host "Reply from $($_.Address): Bytes=$($_.BufferSize) Time=$($_.ResponseTime)ms TTL=$($_.TimeToLive)"
                }
            } catch {
                $innerErrorMessage = $_.Exception.Message
                Write-Host "Ping to $inputHost failed: $innerErrorMessage" -ForegroundColor Red
                Log-Error -FunctionName "Check-Connection" -ErrorMessage "Ping to $inputHost failed: $innerErrorMessage"
            }
        }
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error during check connection process: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Check-Connection" -ErrorMessage $errorMessage
    }
} 

# Main loop for interacting with the user
do {
    Show-Menu
    $selection = Read-Host "Please enter a number to choose an option"

    switch ($selection) {
        '0' {Check-ServiceStatus}
        '3' { Stop-Services }
        '4' { Clean-TrackFolder }
        '5' { Start-Services }
        '6' { Check-Certificates }
        '7' { Get-Certificate-With-Token }
        '1' { Check-Mapping }
        '2' { Check-Connection }
        '8' { exit }
        default { Write-Host "Invalid option, please try again." -ForegroundColor Red }
    }

    Pause

} while ($true)
