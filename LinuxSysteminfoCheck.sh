#!/bin/bash

# Function to display system load and top 5 processes
function system_load {
    echo "System Load:"
    uptime
    echo -e "\nTop 5 processes by CPU usage:"
    ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6
    echo -e "\nTop 5 processes by Memory usage:"
    ps -eo pid,comm,%mem --sort=-%mem | head -n 6
    free -g
}

# Function to check the status of a service
function check_service {
    read -p "Enter the service name: " service_name
    echo -e "\nService Status for $service_name:"
    systemctl status $service_name
}

# Function to grep an entry from /etc/hosts
function grep_hosts {
    read -p "Enter the entry to grep from /etc/hosts: " grep_entry
    echo -e "\nGrep results from /etc/hosts for '$grep_entry':"
    grep "$grep_entry" /etc/hosts
}

# Function to perform a traceroute
function traceroute_ip {
    read -p "Enter the IP address for traceroute: " ip_address
    echo -e "\nTraceroute to $ip_address:"
    traceroute $ip_address
}

# Function to check ping
function ping_ip {
    read -p "Enter the IP address to ping: " ip_address
    echo -e "\nPinging $ip_address:"
    ping -c 4 $ip_address
}

# Function to display filesystem utilization above 30%
function filesystem_utilization {
    echo -e "\nFilesystem Utilization (above 30%):"
    df -h | awk '$5 > 30 {print $0}'
}

# Display the menu
while true; do
    echo -e "\nSelect an option:"
    echo "1. System Load and Top 5 Processes"
    echo "2. Check Service Status"
    echo "3. Grep Entry from /etc/hosts"
    echo "4. Traceroute to IP"
    echo "5. Ping an IP"
    echo "6. Filesystem Utilization Above 30%"
    echo "7. Exit"

    read -p "Enter your choice [1-7]: " choice

    case $choice in
        1)
            system_load |tee -a systeminfo.log
            ;;
        2)
            check_service |tee -a systeminfo.log
            ;;
        3)
            grep_hosts | tee -a systeminfo.log
            ;;
        4)
            traceroute_ip | tee -a systeminfo.log
            ;;
        5)
            ping_ip | tee -a systeminfo.log
            ;;
        6)
            filesystem_utilization | tee -a systeminfo.log
            ;;
        7)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid option, please try again."
            ;;
    esac
done
