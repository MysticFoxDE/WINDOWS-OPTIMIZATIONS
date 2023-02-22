<# 
.SYNOPSIS
    This script change all settings to default, that are optimized by the "W10ANDW11-NETWORK-TCP-DESUBOPTIMIZATION" skript.   
 
 .NOTES 
    Version:        0.09
    Author:         MysticFoxDE (Alexander Fuchs)
    Creation Date:  22.02.2023

.LINK 
    https://administrator.de/tutorial/wie-man-das-windows-10-und-11-tcp-handling-wieder-desuboptimieren-kann-5529700198.html#comment-5584260697
    https://community.spiceworks.com/topic/post/10299845
    https://www.golem.de/news/tcp-die-versteckte-netzwerkbremse-in-windows-10-und-11-2302-172043.html
#>

#SET ALL NIC ADVANCED SETTINGS TO DEFAULT
Get-Netadapter -Physical | Reset-NetAdapterAdvancedProperty -DisplayName "*"

# SET RSS TO DEFAULT
netsh int tcp set global RSS=Enabled
Set-NetOffloadGlobalSetting -ReceiveSideScaling Enabled

# SET RSC TO DEFAULT
netsh int tcp set global RSC=Enabled
Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Enabled

# SET PACKET COALESCING TO DEFAULT
Set-NetOffloadGlobalSetting -PacketCoalescingFilter Enabled

# SET TCP CONGESTION CONTROL TO DEFAULT
netsh int tcp set supplemental template=Datacenter congestionprovider=CUBIC
netsh int tcp set supplemental template=Datacentercustom congestionprovider=CUBIC
netsh int tcp set global ECN=Disabled

# SET TCP PROFILE TO DEFAULT (Internet)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nsi\{eb004a03-9b1a-11d4-9123-0050047759bc}\27\" -Name "06000000" -Value (([byte[]](0x00,0x00,0x00,0x00,0xff,0xff,0xff,0xff)))


# SET TCPACKFREQUENCY TO DEFAULT
$NICs = Get-NetAdapter -Physical | Select-Object DeviceID
foreach ($adapter in $NICs) 
  {
    $NICGUID = $adapter | Select-Object DeviceID | Select DeviceID -ExpandProperty DeviceID | Out-String -Stream
    $REGKEYPATH = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NICGUID\" | Out-String -Stream
    Remove-ItemProperty -Path "$REGKEYPATH" -Name 'TcpAckFrequency'
  }


# SET TCPDELAY TO DEFAULT
$NICs = Get-NetAdapter -Physical | Select-Object DeviceID
foreach ($adapter in $NICs) 
  {
    $NICGUID = $adapter | Select-Object DeviceID | Select DeviceID -ExpandProperty DeviceID | Out-String -Stream
    $REGKEYPATH = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NICGUID\" | Out-String -Stream
        Remove-ItemProperty -Path "$REGKEYPATH" -Name 'TcpNoDelay'
  }