#!/bin/bash

LOG_FILE="script-netbackup.log"

# Check if the log file exists, and delete it if it does, then create a new file
if [ -e "$LOG_FILE" ]; then
    rm "$LOG_FILE"
fi

# Create a new log file
touch "$LOG_FILE"


# Function to log messages
log_failure() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Define a function to display the menu
show_menu() {
    echo "----------------------------------"
    echo " NetBackup and Veritas Service Menu"
    echo " Tips: Make sure the mapping and the connection is working before:"
    echo " Tips: Restarting services"
    echo " Tips: Clean /track"
    echo " Tips: Check/Renew certificates"
    echo "----------------------------------"
    echo "Select an option:"
    echo "0. Check Services Status"
    echo "1. Check Mapping"
    echo "2. Check Connection"
    echo "3. Stop NetBackup and Service vxpbx_exchanged"
    echo "4. Clear inside of Track folder (/usr/openv/netbackup/track)"
    echo "5. Start NetBackup and Service vxpbx_exchanged"
    echo "6. Check Certificates"
    echo "7. Renew Certificate"
    echo "8. Exit"
}

# Function to check the status of the services

check_services() {
    echo "*************" | tee -a "$LOG_FILE"
    echo "Checking NetBackup Service Status ..." | tee -a "$LOG_FILE"
    if ! (systemctl status netbackup 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed: NetBackup service may not be working." | tee -a "$LOG_FILE"
    fi

    echo "*************" | tee -a "$LOG_FILE"
    echo "Checking VXPBX Service Status ..." | tee -a "$LOG_FILE"
    if ! (/opt/VRTSpbx/bin/vxpbx_exchanged status 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed: VXPBX service may not be working." | tee -a "$LOG_FILE"
    fi
    echo "*************" | tee -a "$LOG_FILE"
}

#check_services() {
#    echo "Checking Netbackup Service Status ..."
#    if ! systemctl status netbackups 2>&1 | tee -a "$LOG_FILE"; then
#        log_failure "Failed NetBackup service may not be working."
#    fi
#    echo "Checking VXPBX Service Status ..."
#    if ! /opt/VRTSpbx/bin/vxpbx_exchanged status 2>&1 | tee -a "$LOG_FILE"; then
#        log_failure "Failed VXPBX service may not be working."
#    fi
#}

# Function to stop the services
stop_services() {
    echo "*************" | tee -a "$LOG_FILE"
    echo "Stopping NetBackup and Service vxpbx_exchanged..."
    if ! (systemctl stop netbackup 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed to stop NetBackup service." | tee -a "$LOG_FILE"
    fi

    echo "*************" | tee -a "$LOG_FILE"
    if ! (/opt/VRTSpbx/bin/vxpbx_exchanged stop 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed to stop VXPBX service." | tee -a "$LOG_FILE"
    fi

    echo "*************" | tee -a "$LOG_FILE"
    echo "Services stopped."
    echo "************************************"
    echo "===== NETBACKUP SERVICE STATUS ====="
    systemctl status netbackup
    echo "===== NETBACKUP SERVICE STATUS ====="
    echo "************************************"
    echo "===== VXPBX SERVICE STATUS ====="
    /opt/VRTSpbx/bin/vxpbx_exchanged status
    echo "===== VXPBX SERVICE STATUS ====="
    echo "************************************"
}

# Function to clear track folder
clear_track_folder() {
    echo "*************" | tee -a "$LOG_FILE"
    echo "Clearing the Track folder..."
    TRACK_FOLDER="/usr/openv/netbackup/track/*"
    if (rm -rf "$TRACK_FOLDER" 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Track folder cleared."
    else
        echo "Failed to clear the Track folder." | tee -a "$LOG_FILE"
    fi
    echo "*************" | tee -a "$LOG_FILE"
}

#Function to start the services
start_services() {
    echo "*************" | tee -a "$LOG_FILE"
    echo "Starting NetBackup and Service vxpbx_exchanged..."
    if ! (systemctl start netbackup 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed to start NetBackup service." | tee -a "$LOG_FILE"
    fi

    echo "*************" | tee -a "$LOG_FILE"
    if ! (/opt/VRTSpbx/bin/vxpbx_exchanged start 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed to start VXPBX service." | tee -a "$LOG_FILE"
    fi
    echo "*************" | tee -a "$LOG_FILE"

    echo "Services started."
    echo "************************************"
    echo "===== NETBACKUP SERVICE STATUS ====="
    systemctl status netbackup
    echo "===== NETBACKUP SERVICE STATUS ====="
    echo "************************************"
    echo "===== NETBACKUP VXPBX STATUS ====="
    /opt/VRTSpbx/bin/vxpbx_exchanged status
    echo "===== NETBACKUP VXPBX STATUS ====="
    echo "************************************"
}

#Function to check certificates
check_certificates() {
    echo "*************" | tee -a "$LOG_FILE"
    echo "Clearing cache ..."
    /usr/openv/netbackup/bin/bpclntcmd -clear_host_cache || log_failure "Failed to clear host cache."

    echo "*************" | tee -a "$LOG_FILE"
    echo "Checking CA Certificates..."
    if ! (/usr/openv/netbackup/bin/nbcertcmd -getCACertificate 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed to get CA certificates. Check if mapping and connection is working." | tee -a "$LOG_FILE"
    fi

    echo "*************" | tee -a "$LOG_FILE"
    echo "Checking client Certificates..."
    if ! (/usr/openv/netbackup/bin/nbcertcmd -getCertificate -force 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed to get client certificates. Try to renew the certificate" | tee -a "$LOG_FILE"
    fi

    echo "*************" | tee -a "$LOG_FILE"
    echo "Certificate check complete."
}

#Function to renew certificates
renew_certificates() {
    read -p "Enter the token generated from the master: " token

    echo "*************" | tee -a "$LOG_FILE"
    echo "Start of renew of the Certificate ..."
    if ! (/usr/openv/netbackup/bin/nbcertcmd -getCertificate -force -token "$token" 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed to renew certificate. Check the token and mapping." | tee -a "$LOG_FILE"
    fi
    echo "*************" | tee -a "$LOG_FILE"
}

Function to check the mapping
check_mapping() {
    echo "Checking Mapping..."
    echo "*************" | tee -a "$LOG_FILE"
    echo "Review hosts file below..."
    if ! (cat /etc/hosts 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed to review the hosts file." | tee -a "$LOG_FILE"
    fi

    echo "*************" | tee -a "$LOG_FILE"
    echo "Review bp.config below..."
    if ! (cat /usr/openv/netbackup/bp.conf 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
        echo "Failed to review bp.conf." | tee -a "$LOG_FILE"
    fi
    echo "*************" | tee -a "$LOG_FILE"

    echo "Mapping check listed above."
}

Function to check connection
check_connection() {
    read -p "Enter first master server hostname or IP address: " host1
    read -p "Enter second media server hostname or IP address: " host2
    read -p "Enter third server hostname including FQDN or IP address: " host3

    echo "*************" | tee -a "$LOG_FILE"
    for host in "$host1" "$host2" "$host3"; do
        echo "Pinging $host..."
        if ! (ping -c 4 "$host" 2>&1 | sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') - /" | tee -a "$LOG_FILE"); then
            echo "Failed to ping $host."
            echo "Failed to ping $host. Make sure the mapping is correct." | tee -a "$LOG_FILE"
        fi
    echo "*************" | tee -a "$LOG_FILE"
    done
}

# Function to prompt user for log file deletion
delete_log_on_exit() {
    echo "Do you want to delete the log file ($LOG_FILE)? (y/n)"
    read -r delete_log_choice
    if [[ "$delete_log_choice" == "y" || "$delete_log_choice" == "Y" ]]; then
        rm -f "$LOG_FILE"
        echo "Log file deleted."
    else
        echo "Log file retained."
    fi
}

# Main loop to show the menu and handle user input
while true; do
    show_menu
    read -p "Enter your choice: " choice
    case $choice in
        0) check_services ;;
        1) check_mapping ;;
        2) check_connection ;;
        3) stop_services ;;
        4) clear_track_folder ;;
        5) start_services ;;
        6) check_certificates ;;
        7) renew_certificates ;;
        8)
           delete_log_on_exit
           echo "Exiting..."
           break
           ;;
        *) echo "Invalid option, please try again." ;;
    esac
done
