# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    # Relauch the script as administrator
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

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

# Function to check all importnat services status for the netbackup
function Check-ServiceStatus {
    try {
        # Specify the actual service names
        $services = @("VRTSpbx", "NetBackup Client Service", "NetBackup Legacy Client Service", "NetBackup Legacy Network Service") # Replace with actual service names
        
        # Array to store service status information
        $serviceStatusList = @()

        foreach ($service in $services) {
            $serviceStatus = Get-Service -Name $service -ErrorAction Stop
            $serviceStatusList += [PSCustomObject]@{
                ServiceName = $serviceStatus.DisplayName
                Status      = $serviceStatus.Status
            }
        }

        # Display the status of the services in a table
        Write-Host "Service Status:" -ForegroundColor Cyan
        $serviceStatusList | Format-Table -Property ServiceName, Status -AutoSize

    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error checking service status: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Check-ServiceStatus" -ErrorMessage $errorMessage
    }
}


# Functions to stop the Netbackup services and provide status to confirm.
function Stop-Services {
    try {
        # Specify the actual service names
        $services = @("VRTSpbx", "NetBackup Client Service", "NetBackup Legacy Client Service", "NetBackup Legacy Network Service") # Replace with actual service names
        
        # Array to store service status information
        $stoppedServices = @()

        foreach ($service in $services) {
            # Attempt to stop each service and collect status
            Stop-Service -Name $service -Force -ErrorAction Stop
            $serviceStatus = Get-Service -Name $service
            $stoppedServices += [PSCustomObject]@{
                ServiceName = $serviceStatus.DisplayName
                Status      = $serviceStatus.Status
            }
        }

        # Display the status of stopped services in a table
        Write-Host "Stopped Services:" -ForegroundColor Cyan
        $stoppedServices | Format-Table -Property ServiceName, Status -AutoSize
        #Error Loging
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error stopping services: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Stop-Services" -ErrorMessage $errorMessage
    }
}
#Deleting everything from the track folder
function Clean-TrackFolder {
    try {
        $trackFolderPath = "C:\Program Files\Veritas\Netbackup\track"
        Remove-Item -Path "$trackFolderPath\*" -Recurse -Force -ErrorAction Stop
        Write-Host "Track folder cleaned." -ForegroundColor Green
        }
        #Error Loging
    catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error while cleaning track: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Clean-TrackFolder" -ErrorMessage $errorMessage
        }
}

# Function to start the Netbackup services and provide status to confirm.
function Start-Services {
    try {
        # Specify the actual service names
        $services = @("VRTSpbx", "NetBackup Client Service", "NetBackup Legacy Client Service", "NetBackup Legacy Network Service") # Replace with actual service names
        
        # Array to store service status information
        $startedServices = @()

        foreach ($service in $services) {
            # Attempt to start each service and collect status
            Start-Service -Name $service -ErrorAction Stop
            $serviceStatus = Get-Service -Name $service
            $startedServices += [PSCustomObject]@{
                ServiceName = $serviceStatus.DisplayName
                Status      = $serviceStatus.Status
            }
        }

        # Display the status of started services in a table
        Write-Host "Started Services:" -ForegroundColor Cyan
        $startedServices | Format-Table -Property ServiceName, Status -AutoSize
        #Error Loging
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error starting services: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Start-Services" -ErrorMessage $errorMessage
    }
}

#function Start-Services {
    # Replace 'VeritasServiceName' and 'NetBackupServiceName' with actual service names
 #   Start-Service -Name "VRTSpbx"
  #  Start-Service -Name "NetBackup*"
   # Write-Host "Services started successfully." -ForegroundColor Green
#}
# REWORK THE FUNCTION FOR CERTIFICATES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

<#function Check-Certificates {
    $bpclntcmd = "C:\Program Files\Veritas\NetBackup\bin\bpclntcmd"
    $nbcertcmd = "C:\Program Files\Veritas\NetBackup\bin\nbcertcmd"

    # Execute the commands and capture the output
    try {
        Write-Host "Clearing host cache..."
        $clearHostCacheOutput = & "$bpclntcmd" -clear_host_cache
        #$clearHostCacheOutput = '"C:\Program Files\Veritas\NetBackup\bin\bpclntcmd" -clear_host_cache'
        Write-Host $clearHostCacheOutput -ForegroundColor Green
        #Invoke-Expression $clearHostCacheOutput

        Write-Host "Getting CA Certificate..."
        $getCACertificateOutput = & "$nbcertcmd" -getCACertificate
        #$getCACertificateOutput = '"C:\Program Files\Veritas\NetBackup\bin\nbcertcmd" -getCACertificate'
        Write-Host $getCACertificateOutput -ForegroundColor Green
        #Invoke-Expression $getCACertificateOutput

        Write-Host "Getting Certificate with force..."
        $getCertificateOutput = & "$nbcertcmd" -getCertificate -force
        #$getCertificateOutput = '"C:\Program Files\Veritas\NetBackup\bin\nbcertcmd" -getCertificate -force'
        Write-Host $getCertificateOutput -ForegroundColor Green
        #Invoke-Expression $getCertificateOutput
        #Error Loging
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error checking the certificate: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Check-Certificates" -ErrorMessage $errorMessage
    }
}#>

# Function to refresh the cach and revowke both CA and Client Certificate.
function Check-Certificates {
    try {
        # Path to the directory containing nbcertcmd
        $nbcertcmdPath = "C:\Program Files\Veritas\NetBackup\bin"

        # Change directory to the bin path
        Push-Location -Path $nbcertcmdPath

        # Define commands to execute
        $commands = @(
            ".\bpclntcmd.exe -clear_host_cache",
            ".\nbcertcmd.exe -getCACertificate",
            ".\nbcertcmd.exe -getCertificate -force"
        )

        foreach ($command in $commands) {
            # Execute the command and capture the output
            $output = Invoke-Expression $command
            Write-Host "`nExecuting: $command" -ForegroundColor Cyan
            Write-Host "Output: $output"

            # Check if the output indicates success
            if ($output -notmatch "successful") {
                $errorMessage = "Command failed or output did not confirm success for '$command'. Output: $output"
                Write-Host $errorMessage -ForegroundColor Red
                Log-Error -FunctionName "Check-Certificates" -ErrorMessage $errorMessage
            } else {
                Write-Host "Command executed successfully for '$command'." -ForegroundColor Green
            }
        }

    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error executing certificates check: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Check-Certificates" -ErrorMessage $errorMessage
    } finally {
        # Return to the original directory
        Pop-Location
    }
}

# Define the new function for getting a certificate with a token (logging not working properly)
<#function Get-Certificate-With-Token {
	$nbcertcmd2 = "C:\Program Files\Veritas\NetBackup\bin\nbcertcmd"
    try {
        $tokenValue = Read-Host "Enter the token value"
        $renewCertificate = & "$nbcertcmd2" -getCertificate -force -token $tokenValue
		Write-Host $renewCertificate -ForegroundColor Green
        
        #Error Loging
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error getting certificate with token: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Get-Certificate-With-Token" -ErrorMessage $errorMessage
    }
}#>

#Fixed functionallity and error loging.
function Get-Certificate-With-Token {
    try {
        # Path to the directory containing nbcertcmd
        $nbcertcmdPath = "C:\Program Files\Veritas\NetBackup\bin"

        # Change directory to the bin path
        Push-Location -Path $nbcertcmdPath

        # Prompt for token value
        $tokenValue = Read-Host "Enter the token value"

        # Command to execute with token
        $command = ".\nbcertcmd.exe -getCertificate -force -token $tokenValue"

        # Execute the command and capture the output
        $output = Invoke-Expression $command

        # Check if the output includes "successful"
        if ($output -match "successful") {
            Write-Host "Certificate successfully retrieved." -ForegroundColor Green
        } else {
            $errorMessage = "Certificate retrieval failed or output did not confirm success. Output: $output"
            Write-Host $errorMessage -ForegroundColor Red
            Log-Error -FunctionName "Get-Certificate-With-Token" -ErrorMessage $errorMessage
        }

    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error executing command in Get-Certificate-With-Token: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Get-Certificate-With-Token" -ErrorMessage $errorMessage
    } finally {
        # Return to the original directory
        Pop-Location
    }
}

function Check-Mapping {
    try {
        # Define the path to the hosts file
        $hostsFilePath = "C:\Windows\System32\drivers\etc\hosts"
        
        # Check and display contents of the hosts file
        if (Test-Path $hostsFilePath) {
            Write-Host "Contents of the hosts file:" -ForegroundColor Cyan
            Get-Content -Path $hostsFilePath | ForEach-Object { Write-Host $_ }
        } else {
            Write-Host "Hosts file not found at $hostsFilePath" -ForegroundColor Red
        }

        # Registry path for NetBackup Server configuration
        $registryPath = "HKLM:\SOFTWARE\Veritas\NetBackup\CurrentVersion\Config"

        if (Test-Path $registryPath) {
            # Retrieve the registry value for "Server"
            $serverValues = Get-ItemProperty -Path $registryPath -Name "Server" -ErrorAction Stop
            
            Write-Host "`nNetBackup Server Registry Configurations:" -ForegroundColor Cyan
            $serverDetails = $serverValues.Server

            # Use different display options depending on the type of the Server value
            if ($serverDetails -is [Array]) {
                # If the Server value is an array (multi-line/multi-valued), display each line
                $serverDetails | ForEach-Object {
                    Write-Host $_
                }
            } else {
                # Otherwise, display it directly
                Write-Host $serverDetails
            }

        } else {
            Write-Host "Registry path not found: $registryPath" -ForegroundColor Red
        }
        #Error Loging
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error checking mapping: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Check-Mapping" -ErrorMessage $errorMessage
    }
}

#Loop trough user input then use 'done' to initiate 4 pings per input. Work for both IP and hostname.
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
                #Error Loging
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

function Exit-Script {
    try {
        # Confirm with the user if they want to delete the log file and directory
        $response = Read-Host "Do you want to delete the log file and directory? (yes/no)"
        
        if ($response -eq "yes") {
            if (Test-Path -Path $logFilePath) {
                Remove-Item -Path $logFilePath -Force
                Write-Host "Log file deleted." -ForegroundColor Green
            }

            if (Test-Path -Path $logDirectory) {
                Remove-Item -Path $logDirectory -Recurse -Force
                Write-Host "Log directory deleted." -ForegroundColor Green
            }
        }

        Write-Host "Exiting script." -ForegroundColor Cyan
        exit
#Error Loging
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error during exit: $errorMessage" -ForegroundColor Red
        Log-Error -FunctionName "Exit-Script" -ErrorMessage $errorMessage
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
        '8' { Exit-Script }
        default { Write-Host "Invalid option, please try again." -ForegroundColor Red }
    }

    Pause

} while ($true)
