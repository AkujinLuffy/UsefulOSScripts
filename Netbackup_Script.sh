#!/bin/bash

# Define a function to display the menu
show_menu() {
    echo "Select an option:"
    echo "1. Stop NetBackup and Service vxpbx_exchanged"
    echo "2. Clear inside of Track folder (/usr/openv/netbackup/track)"
    echo "3. Start NetBackup and Service vxpbx_exchanged"
    echo "4. Check Certificates"
    echo "5. Renew Certificate"
    echo "6. Check Mapping"
    echo "7. Check Connection"
    echo "8. Exit"
}

# Define a function for each menu option
stop_services() {
    echo "Stopping NetBackup and Service vxpbx_exchanged..."
    # Add the actual command to stop NetBackup here
    systemctl stop netbackup
    # Add the actual command to stop vxpbx_exchanged here
    /opt/VRTSpbx/bin/vxpbx_exchanged stop
    echo "Services stopped."
    echo "!!!!! NETBACKUP SERVICE STATUS !!!!!"
    systemctl status netbackup
    echo "!!!!! VXPBX SERVICE STATUS !!!!!"
    /opt/VRTSpbx/bin/vxpbx_exchanged status
}

clear_track_folder() {
    echo "Clearing the Track folder..."
    rm -rf /usr/openv/netbackup/track/*
    echo "Track folder cleared."
}

start_services() {
    echo "Starting NetBackup and Service vxpbx_exchanged..."
    # Add the actual command to start NetBackup here
    systemctl start netbackup
    # Add the actual command to start vxpbx_exchanged here
    /opt/VRTSpbx/bin/vxpbx_exchanged start
    echo "Services started."
    systemctl status netbackup
    /opt/VRTSpbx/bin/vxpbx_exchanged status
}


check_certificates() {
    echo "Clearing cache ..."
    /usr/openv/netbackup/bin/bpclntcmd -clear_host_cache
    echo "Checking CA Certificates..."
    /usr/openv/netbackup/bin/nbcertcmd -getCACertificate
    echo "Checking client Certificates..."
    /usr/openv/netbackup/bin/nbcertcmd -getCertificate -force
    echo "Certificate check complete."
}

renew_certificates() {
    read -p "Enter the token generated from the master: " token

    echo "Start of renew of the Certificate ..."
    if /usr/openv/netbackup/bin/nbcertcmd -getCertificate -force -token $token; then
        echo "Certificate Successfully renewed!"
    else
        echo "Failed check the token and the mapping ..."
    fi
}


check_mapping() {
    echo "Checking Mapping..."
    echo "Review hosts file below..."
    cat /etc/hosts
    echo "Review bp.config below..."
    cat /usr/openv/netbackup/bp.conf
    echo "Mapping check listed above."
}

check_connection() {
    read -p "Enter first master server hostname or IP address: " host1
    read -p "Enter second media server hostname or IP address: " host2
    read -p "Enter third server hostname including FQDN or IP address: " host3

    echo "Pinging $host1..."
    if ping -c 4 "$host1"; then
        echo "Successfully pinged $host1."
    else
        echo "Failed to ping $host1."
    fi

    echo "Pinging $host2..."
    if ping -c 4 "$host2"; then
        echo "Successfully pinged $host2."
    else
        echo "Failed to ping $host2."
    fi

    echo "Pinging $host3..."
    if ping -c 4 "host3"; then
        echo "Successfully pinged $host3."
    else
        echo "Failed to ping $host3."
    fi
}

# Main loop to show the menu and handle user input
while true; do
    show_menu
    read -p "Enter your choice: " choice
    case $choice in
        1) stop_services ;;
        2) clear_track_folder ;;
        3) start_services ;;
        4) check_certificates ;;
        5) renew_certificates ;;
        6) check_mapping ;;
        7) check_connection ;;
        8) echo "Exiting..."; break ;;
        *) echo "Invalid option, please try again." ;;
    esac
done
