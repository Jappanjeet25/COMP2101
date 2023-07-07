#!/bin/bash

# Function: cpureport
# Description: Generates a report for CPU information
function cpureport {
  echo "CPU Report"
  echo "-----------"
  echo "CPU Manufacturer and Model: $(lscpu | grep 'Model name' | awk -F': ' '{print $2}')"
  echo "CPU Architecture: $(lscpu | grep 'Architecture' | awk -F': ' '{print $2}')"
  echo "CPU Core Count: $(lscpu | grep 'Core(s) per socket' | awk -F': ' '{print $2}')"
  echo "CPU Maximum Speed: $(lscpu | grep 'CPU max MHz' | awk -F': ' '{printf "%.2f GHz\n", $2/1000}')"
  echo "Sizes of Caches:"
  echo "$(lscpu | grep -E 'L1d cache|L1i cache|L2 cache|L3 cache')"
  echo
}

# Function: computerreport
# Description: Generates a report for computer information
function computerreport {
  echo "Computer Report"
  echo "---------------"
  echo "Computer Manufacturer: $(dmidecode -s system-manufacturer)"
  echo "Computer Description or Model: $(dmidecode -s system-product-name)"
  echo "Computer Serial Number: $(dmidecode -s system-serial-number)"
  echo
}

# Function: osreport
# Description: Generates a report for OS information
function osreport {
  echo "OS Report"
  echo "---------"
  echo "Linux Distro: $(lsb_release -ds)"
  echo "Distro Version: $(lsb_release -rs)"
  echo
}

# Function: ramreport
# Description: Generates a report for RAM information
function ramreport {
  echo "RAM Report"
  echo "----------"
  echo "Installed Memory Components:"
  echo "Manufacturer | Model | Size | Speed | Location"
  echo "---------------------------------------------"
  dmidecode -t memory | awk -F': ' '/Manufacturer|Part Number|Size|Speed|Locator/ { printf "%s |", $2 } /^(Size|Speed|Locator):/ { print $2 }'
  echo
  echo "Total Installed RAM: $(free -h | awk '/^Mem:/ { print $2 }')"
  echo
}

# Function: videoreport
# Description: Generates a report for video card/chipset information
function videoreport {
  echo "Video Report"
  echo "------------"
  echo "Video Card/Chipset Manufacturer: $(lspci | awk -F': ' '/VGA compatible controller/ { print $3 }')"
  echo "Video Card/Chipset Description or Model: $(lspci | awk -F': ' '/VGA compatible controller/ { print $4 }')"
  echo
}

# Function: diskreport
# Description: Generates a report for disk drive information
function diskreport {
  echo "Disk Report"
  echo "-----------"
  echo "Installed Disk Drives:"
  echo "Manufacturer | Model | Size | Partition | Mount Point | Filesystem Size | Filesystem Free Space"
  echo "----------------------------------------------------------------------------------------------"
  lsblk -bo NAME,VENDOR,MODEL,SIZE,FSTYPE,MOUNTPOINT,SIZE,USED | awk 'NR>1 && $1 !~ /^[0-9]*$/ { printf "%s | %s | %s | %s | %s | %s | %s\n", $2, $3, $4, $1, $6, $7, $8 }'
  echo
}

# Function: networkreport
# Description: Generates a report for network interface information
function networkreport {
  echo "Network Report"
  echo "--------------"
  echo "Installed Network Interfaces:"
  echo "Manufacturer | Model/Description | Link State | Current Speed | IP Addresses | Bridge Master | DNS Servers/Search Domain"
  echo "--------------------------------------------------------------------------------------------------------------------"
  ip -o addr show | awk -F': ' '/^[0-9]+:/{print $2}' | while read -r iface; do
    manufacturer=$(ethtool -i "$iface" | awk -F': ' '/driver:/ {print $2}')
    model=$(ethtool -i "$iface" | awk -F': ' '/bus-info:/ {print $2}')
    link_state=$(cat "/sys/class/net/$iface/operstate")
    speed=$(ethtool "$iface" | awk -F': ' '/Speed:/ {print $2}')
    ip_addresses=$(ip -o -4 addr show dev "$iface" | awk '{print $4}')
    bridge_master=$(cat "/sys/class/net/$iface/brport/bridge")
    dns_servers=$(nmcli -g IP4.DNS device show "$iface" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
    search_domain=$(nmcli -g IP4.DOMAIN device show "$iface" 2>/dev/null)

    echo "$manufacturer | $model | $link_state | $speed | $ip_addresses | $bridge_master | $dns_servers/$search_domain"
  done
  echo
}

# Function: errormessage
# Description: Saves the error message with a timestamp into a logfile named /var/log/systeminfo.log
#              and displays the error message to the user on stderr.
function errormessage {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local error_message="$1"
  echo "[$timestamp] $error_message" >> /var/log/systeminfo.log
  echo "Error: $error_message" >&2
}
