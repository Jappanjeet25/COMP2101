# Your report output should be a table showing for each adapter that is configured: 
# the adapter description, index, ip address(es), subnet mask(s), dns domain name, and dns server.

Write-Host "......................................................"
Write-Host "Network Summary :"
Write-Host "......................................................"


$netReport = get-ciminstance win32_networkadapterconfiguration 
$netReport | Where-Object ipenabled -EQ True | Format-Table Description,
                                                            Index, 
                                                            @{l='IP Address(es)';e={$_.IPAddress}}, 
                                                            @{l='Subnet Mask(s)';e={$_.IPSubnet}}, 
                                                            @{l='DNS Domain Name';e={$_.DNSHostName}},
                                                            @{l='DNS Server';e={if($_.DNSDomain)
                                                                                {
                                                                                    $_.DNSDomain
                                                                                }else
                                                                                {
                                                                                    "NULL"
                                                                                }
                                                                                }} -AutoSize   

