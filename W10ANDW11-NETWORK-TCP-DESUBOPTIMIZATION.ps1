<# 
.SYNOPSIS
    This Script desuboptimize a lot W10 & W11 TCP Settings.   
 
 .NOTES 
    Version:        1.0
    Author:         MysticFoxDE (Alexander Fuchs)
    Creation Date:  23.01.2023

.LINK 
    https://administrator.de/tutorial/wie-man-das-windows-10-und-11-tcp-handling-wieder-desuboptimieren-kann-5529700198.html#comment-5584260697
    https://community.spiceworks.com/topic/post/10299845
#>

#Get-NetTCPSetting
#Get-NetTCPConnection
#netsh int tcp show global
#Get-NetConnectionProfile
#Get-NetTransportFilter

# DISABLE RSS
#Get-NetAdapterRss
Set-NetOffloadGlobalSetting -ReceiveSideScaling Disabled
$NICs = Get-NetAdapter -Physical | Select-Object Name
foreach ($adapter in $NICs) 
  {
    $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
    $NICRSSSTATUS = Get-NetAdapterRss -Name "$NICNAME" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Select-Object Enabled | Select Enabled -ExpandProperty Enabled | Out-String -Stream 
    if ($NICRSSSTATUS -eq "True")
      {Disable-NetAdapterRss -Name "$NICNAME"}
  }

# DISABLE RSC
#Get-NetAdapterRsc
Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled
$NICs = Get-NetAdapter -Physical | Select-Object Name
foreach ($adapter in $NICs) 
  {
    $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
    $NICRSCIPV4STATUS = Get-NetAdapterRsc -Name "$NICNAME" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Select-Object IPv4Enabled | Select IPv4Enabled -ExpandProperty IPv4Enabled | Out-String -Stream
    $NICRSCIPV6STATUS = Get-NetAdapterRsc -Name "$NICNAME" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Select-Object IPv6Enabled | Select IPv6Enabled -ExpandProperty IPv6Enabled | Out-String -Stream 
    if ($NICRSCIPV4STATUS -eq "True")
      {Disable-NetAdapterRsc -Name "$NICNAME" -IPv4}
    if ($NICRSCIPV6STATUS -eq "True")
      {Disable-NetAdapterRsc -Name "$NICNAME" -IPv6}
  }

# DISABLE PACKET COALESCING
Set-NetOffloadGlobalSetting -PacketCoalescingFilter Disabled

# DISABLE FLOW CONTROL
# Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*FlowControl"} 
$NICs = Get-Netadapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*FlowControl"} 
foreach ($adapter in $NICs) 
  {
    $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
    Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*FlowControl" -RegistryValue 0
  }

# DISABLE INTERRUPT MODERATION
# Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*InterruptModeration"} 
$NICs = Get-Netadapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*InterruptModeration"} 
foreach ($adapter in $NICs) 
  {
    $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
    Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*InterruptModeration" -RegistryValue 0
  }

# DISABLE ENERGY-EFFICIENT-ETHERNET
# Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*EEE"} 
$NICs = Get-Netadapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*EEE"} 
foreach ($adapter in $NICs) 
  {
    $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
    Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*EEE" -RegistryValue 0
  }

# OPTIMIZE TCP CONGESTION CONTROL
netsh int tcp set supplemental template=Datacenter congestionprovider=DCTCP
netsh int tcp set supplemental template=Datacentercustom congestionprovider=DCTCP
netsh int tcp set global ECN=Enabled

# OPTIMIZE SEND- & RECEIVEBUFFERS
# Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*ReceiveBuffers"} 
$NICs = Get-Netadapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*ReceiveBuffers"} 
foreach ($adapter in $NICs) 
  {
    $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
    Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*ReceiveBuffers" -RegistryValue 2048
  }

# Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*TransmitBuffers"} 
$NICs = Get-Netadapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*TransmitBuffers"} 
foreach ($adapter in $NICs) 
  {
    $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
    Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*TransmitBuffers" -RegistryValue 2048
  }

# ENABLE DATACENTERCUSTOM TCP PROFILE
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nsi\{eb004a03-9b1a-11d4-9123-0050047759bc}\27\" -Name "06000000" -PropertyType Binary -Value (([byte[]](0x03,0x00,0x00,0x00,0xff,0xff,0xff,0xff))) -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nsi\{eb004a03-9b1a-11d4-9123-0050047759bc}\27\" -Name "06000000" -Value (([byte[]](0x03,0x00,0x00,0x00,0xff,0xff,0xff,0xff))) -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

# OPTIMIZE TCPACKFREQUENCY
$NICs = Get-NetAdapter -Physical | Select-Object DeviceID
foreach ($adapter in $NICs) 
  {
    $NICGUID = $adapter | Select-Object DeviceID | Select DeviceID -ExpandProperty DeviceID | Out-String -Stream
    $REGKEYPATH = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NICGUID\" | Out-String -Stream 
    New-ItemProperty -Path "$REGKEYPATH" -Name 'TcpAckFrequency' -Value '1' -PropertyType DWORD
  }

# DISABLE TCPDELAY
$NICs = Get-NetAdapter -Physical | Select-Object DeviceID
foreach ($adapter in $NICs) 
  {
    $NICGUID = $adapter | Select-Object DeviceID | Select DeviceID -ExpandProperty DeviceID | Out-String -Stream
    $REGKEYPATH = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NICGUID\" | Out-String -Stream 
    New-ItemProperty -Path "$REGKEYPATH" -Name 'TcpNoDelay' -Value '1' -PropertyType DWORD
  }
