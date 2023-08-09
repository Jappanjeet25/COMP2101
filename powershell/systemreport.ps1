# PARAMETERS
#
# It must accept but not require the following parameters on the command line:
#	 -system  : System displays the cpu, OS, RAM, Video reports ony 
#	 -disks   : Disks displays the disks report only
#	 -network : Network displays the network report only
# If your script is run without any parameters, it should generate the full report with all sections included

param(
      [switch]$system, 
	  [switch]$disks,
      [switch]$network
      )

if($system)
{
    Get-ProcessorDetails
    Get-OSDetails
    Get-RAMSummary
    Get-VideoCardDetails
}elseif($disks)
{
    Get-PhysicalDrivesSummary
}elseif($network)
{
    Get-NetworkSummary
}else
{
    Get-SystemHardwareDetail
    Get-OSDetails
    Get-ProcessorDetails 
    Get-RAMSummary
    Get-PhysicalDrivesSummary
    Get-NetworkSummary
    Get-VideoCardDetails
}


# FUNCTIONS
#
# Include the system hardware description (win32_computersystem)

function Get-SystemHardwareDetail
{
	Write-Host "......................................................"
	Write-Host "SYSTEM HARDWARE DETAILS :"
	Write-Host "......................................................"

	$SystemInfo = Get-CIMInstance win32_computersystem
	$SystemInfo | Select-Object -Property Name, Model, Manufacturer, Description | Format-List
}

# Include the operating system name and version number (win32_operatingsystem)

function Get-OSDetails
{
	Write-Host "......................................................"
	Write-Host "OS DETAILS :"
	Write-Host "......................................................"

	$OSInfo = Get-CIMInstance win32_operatingsystem
	$OSInfo | Select-Object -Property @{l='Operating System Name';e={$_.Caption}}, 
                                      @{l='Version Number';e={$_.Version}} | Format-List
}

# Include processor description with speed, number of cores, and sizes of the L1, L2, and L3 caches if they are present (win32_processor)

function Get-ProcessorDetails
{
	Write-Host "......................................................"
	Write-Host "PROCESSOR DETAILS :"
	Write-Host "......................................................"

	$ProcessorDesc = Get-CIMInstance win32_processor
    $L1Cache = Get-CIMInstance win32_cachememory 
	$ProcessorDesc | Select-Object -Property Description,
                                             @{l='Maximum Clock Speed';e={"$($_.MaxClockSpeed) MHz"}}, 
                                             NumberOfCores,
                                             @{l='L1 Cache Size';e={if($_.L1Cache.MaxCacheSize)
                                                               {
                                                                    "$($_.L1Cache.MaxCacheSize) KBs" 
                                                               }else{
                                                                    "N/A"
                                                               }
                                                               }}, 
                                             @{l='L2 Cache Size';e={if($_.L2CacheSize)
                                                               {
                                                                    "$($_.L2CacheSize) KBs" 
                                                               }else{
                                                                    "N/A"
                                                               }
                                                               }}, 
                                             @{l='L3 Cache Size';e={if($_.L3CacheSize)
                                                               {
                                                                    "$($_.L3CacheSize) KBs" 
                                                               }else{
                                                                    "N/A"
                                                               }
                                                               }} | Format-List
}

# Include a summary of the RAM installed with the vendor, description, size, and bank and slot for each DIMM 
# as a table and the total RAM installed in the computer as a summary line after the table (win32_physicalmemory)

function Get-RAMSummary
{
	Write-Host "......................................................"
	Write-Host "RAM SUMMARY :"
	Write-Host "......................................................"

    $SysInfo = Get-CIMInstance win32_computersystem 
	
    $RAMInfo = Get-CIMInstance win32_physicalmemory
	$RAMInfo | Select-Object -Property @{l='Vendor';e={$_.Manufacturer}}, 
									   Description, 
									   @{l='Size';e={"$($_.Capacity / 1GB -as [int]) GB(s)"}},
                                       @{l='Bank';e={$_.BankLabel}}, 
									   @{l='Slot';e={$_.DeviceLocator}} | Format-Table -AutoSize

	
    $TotalRAM = "{0:N2}" -f ($SysInfo.TotalPhysicalMemory / 1GB)
    Write-Host "Total Installed Ram is : $TotalRAM GB(s) `n"

}

# Include a summary of the physical disk drives with their vendor, model, size, and space usage (size, free space, and percentage free)
# of the logical disks on them as a single table with one logical disk per output line (win32_diskdrive, win32_diskpartition, win32_logicaldisk)

function Get-PhysicalDrivesSummary
{
	Write-Host "......................................................"
	Write-Host "PHYSICAL DRIVES SUMMARY :"
	Write-Host "......................................................"

	$diskDrives = Get-CIMInstance CIM_diskdrive
	$diskInfo = @()

	  foreach ($disk in $diskDrives) {
		  
		  $partitions = $disk|Get-CimAssociatedInstance -resultclassname CIM_diskpartition
		  foreach ($partition in $partitions) {
				
				$logicaldisks = $partition | Get-CimAssociatedInstance -resultclassname CIM_logicaldisk
				foreach ($logicaldisk in $logicaldisks) {
						 
									$diskInfo += [PSCustomObject]@{"Vendor"= $disk.Model.Split(" ")[0]
																   "Model"= $disk.Model
																   "Size(GB)"= $logicaldisk.Size / 1GB -as [int]
																   "Free Space(GB)" = $logicalDisk.FreeSpace / 1GB -as [int]
																   "Percentage Free(in %)" = (($logicalDisk.FreeSpace / $logicalDisk.Size) * 100) -as [int]
																   }
			   }
		  }
	  }

	$diskInfo | Format-Table -AutoSize
}

function Get-NetworkSummary
{
# Include your network adapter configuration report from lab 3

Write-Host "......................................................"
Write-Host "Network Summary :"
Write-Host "......................................................"


$netReport = get-ciminstance win32_networkadapterconfiguration 
$netReport | Where-Object ipenabled -EQ True | Format-Table Description,
                                                            Index, 
                                                            @{l='DNS Domain Name';e={$_.DNSHostName}},
                                                            @{l='DNS Server';e={if($_.DNSDomain)
                                                                                {
                                                                                    $_.DNSDomain
                                                                                }else
                                                                                {
                                                                                    "N/A"
                                                                                }
                                                                                }},
                                                            @{l='Subnet Mask(s)';e={$_.IPSubnet -join "`n" }},
                                                            @{l='IP Address(es)';e={$_.IPAddress -join "`n"}} -AutoSize -Wrap

}

# Include the video card vendor, description, and current screen resolution in this format: horizontalpixels x verticalpixels (win32_videocontroller)

function Get-VideoCardDetails
{
	Write-Host "......................................................"
	Write-Host "VIDEO CARD DETAILS :"
	Write-Host "......................................................"

	$videoDetails = Get-CimInstance win32_videocontroller 
	$videoDetails | Select-Object -Property @{l='Vendor';e={$_.AdapterCompatibility}}, 
											Description, 
											@{l='Current Screen Resoultion';e={
																			   if($_.CurrentHorizontalResolution){
																					"$($_.CurrentHorizontalResolution) X $($_.CurrentVerticalResolution)"
																			   }else{
																					"N/A"
																			   }
																			   }} | Format-List
}