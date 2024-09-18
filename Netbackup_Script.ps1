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
    Write-Host "1. Check Mapping"
    Write-Host "2. Check Connection"
    Write-Host "3. Stop Veritas and NetBackup Services"
    Write-Host "4. Clean track folder (C:\Program Files\Veritas\Netbackup\track)"
    Write-Host "5. Start Veritas and NetBackup Services"
    Write-Host "6. Check Certificates"
    Write-Host "7. Renew Certificate"
    Write-Host "8. Exit`n"
}

# Define functions for each task
function Stop-Services {
    # Replace 'VeritasServiceName' and 'NetBackupServiceName' with actual service names
    Stop-Service -Name "VRTSpbx" -Force
    Stop-Service -Name "NetBackup*" -Force
    Write-Host "Services stopped successfully." -ForegroundColor Green
}

function Clean-TrackFolder {
    $trackFolderPath = "C:\Program Files\Veritas\Netbackup\track"
    Remove-Item -Path "$trackFolderPath\*" -Recurse -Force
    Write-Host "Track folder cleaned." -ForegroundColor Green
}

function Start-Services {
    # Replace 'VeritasServiceName' and 'NetBackupServiceName' with actual service names
    Start-Service -Name "VRTSpbx"
    Start-Service -Name "NetBackup*"
    Write-Host "Services started successfully." -ForegroundColor Green
}

function Check-Certificates {
    $bpclntcmd = "C:\Program Files\Veritas\NetBackup\bin\bpclntcmd"
    $nbcertcmd = "C:\Program Files\Veritas\NetBackup\bin\nbcertcmd"

    # Execute the commands and capture the output
    try {
        Write-Host "Clearing host cache..."
        $clearHostCacheOutput = & "$bpclntcmd" -clear_host_cache
        Write-Host $clearHostCacheOutput -ForegroundColor Green

        Write-Host "Getting CA Certificate..."
        $getCACertificateOutput = & "$nbcertcmd" -getCACertificate
        Write-Host $getCACertificateOutput -ForegroundColor Green

        Write-Host "Getting Certificate with force..."
        $getCertificateOutput = & "$nbcertcmd" -getCertificate -force
        Write-Host $getCertificateOutput -ForegroundColor Green

    } catch {
        Write-Host "An error occurred while checking certificates: $_" -ForegroundColor Red
    }
}

# Define the new function for getting a certificate with a token
function Get-Certificate-With-Token {
    $nbcertcmd2 = "C:\Program Files\Veritas\NetBackup\bin\nbcertcmd"

    try {
        $tokenValue = Read-Host "Enter the token value"
        Write-Host "Renewing the Certificate..."
        $getCertificateRenewOutput = & "$nbcertcmd2" -getCertificate -force -token $tokenValue
        Write-Host $getCertificateRenewOutput -ForegroundColor Green

    } catch {
        Write-Host "An error occurred while getting the certificate with token: $_" -ForegroundColor Red
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
        Write-Host "An error occurred while checking mapping: $_" -ForegroundColor Red
    }
}

function Check-Connection {
    Write-Host "Enter hostnames or IP addresses one at a time to ping them. Type 'done' when finished." -ForegroundColor Cyan

    # Loop to collect hostnames or IP addresses from the user
    $hostsToPing = @()
    do {
        $inputHost = Read-Host "Enter a hostname or IP address (or type 'done' to finish)"
        if ($inputHost -ne 'done') {
            $hostsToPing += $inputHost
        }
    } while ($inputHost -ne 'done')

    # Ping each host with four attempts
    foreach ($inputHost in $hostsToPing) {
        Write-Host "`nPinging $inputHost..." -ForegroundColor Cyan
        try {
            Test-Connection -ComputerName $inputHost -Count 4 -ErrorAction Stop | ForEach-Object {
                Write-Host "Reply from $($_.Address): Bytes=$($_.BufferSize) Time=$($_.ResponseTime)ms TTL=$($_.TimeToLive)"
            }
        } catch {
            Write-Host "Ping to $inputHost failed: $_" -ForegroundColor Red
        }
    }
}

# Main loop for interacting with the user
do {
    Show-Menu
    $selection = Read-Host "Please enter a number to choose an option"

    switch ($selection) {
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
