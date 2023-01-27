<# 
.SYNOPSIS
    This Script desuboptimize a lot W10 & W11 TCP Settings.   
 
 .NOTES 
    Version:        1.03
    Author:         MysticFoxDE (Alexander Fuchs)
    Creation Date:  27.01.2023

.LINK 
    https://administrator.de/tutorial/wie-man-das-windows-10-und-11-tcp-handling-wieder-desuboptimieren-kann-5529700198.html#comment-5584260697
    https://community.spiceworks.com/topic/post/10299845
#>

# DETAILED SCRIPTDEBUGING ON=Enabled OFF=Disabled
$DEDAILEDDEBUG = "OFF"

#BASIC VARIABLES
$FULLYCOMPLETED = $true

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


# OPTIMIZE RECEIVE-BUFFERS
# Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*ReceiveBuffers"}
$RECEIVEBUFFERSIZES = @(8192, 8184, 4096, 2048, 1024, 512, 256, 128)  
Write-Host "Start Receive-Buffer optimization" -ForegroundColor Cyan
$NICs = Get-Netadapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*ReceiveBuffers"} 
foreach ($adapter in $NICs) 
  {
  $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
  $CHANGERBOK = "NO"
  foreach ($RECEIVEBUFFESIZE in $RECEIVEBUFFERSIZES) 
    {
    if ($CHANGERBOK -eq "NO")
      {
      try
        {
        Write-Host ("  Try to set receive buffer size of NIC " + $NICNAME + " to " + $RECEIVEBUFFESIZE + "KB.") -ForegroundColor Gray
        Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*ReceiveBuffers" -RegistryValue $RECEIVEBUFFESIZE -ErrorAction Stop
        $CHANGERBOK = "YES"
        Write-Host ("  The receive buffer size of NIC " + $NICNAME + " was successfully configured to " + $RECEIVEBUFFESIZE + "KB. :-)") -ForegroundColor Green
        }
      catch
        {
        Write-Host ("  Oops, the NIC " + $NICNAME + " does not accept a receive buffer size of " + $RECEIVEBUFFESIZE + "KB ... :-( ... never mind ... try with a smaller buffer next.") -ForegroundColor Yellow
        $CHANGERBOK = "NO"
        if ($DEDAILEDDEBUG -eq "ON") 
          {Write-Host $_ -ForegroundColor Red}
        }
      }
    }
  }
Write-Host "Receive-Buffer optimization is complitly finished." -ForegroundColor Cyan

 
# OPTIMIZE TRANSMIT-BUFFERS
# Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*TransmitBuffers"}
$TRANSMITBUFFERSIZES = @(8192, 8184, 4096, 2048, 1024, 512, 256, 128)  
Write-Host "Start Transmit-Buffer optimization" -ForegroundColor Cyan
$NICs = Get-Netadapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*TransmitBuffers"} 
foreach ($adapter in $NICs) 
  {
  $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
  $CHANGETBOK = "NO"
  foreach ($TRANSMITBUFFESIZE in $TRANSMITBUFFERSIZES) 
    {
    if ($CHANGETBOK -eq "NO")
      {
      try
        {
        Write-Host ("  Try to set transmit buffer size of NIC " + $NICNAME + " to " + $TRANSMITBUFFESIZE + "KB.") -ForegroundColor Gray
        Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*TransmitBuffers" -RegistryValue $TRANSMITBUFFESIZE -ErrorAction Stop
        $CHANGETBOK = "YES"
        Write-Host ("  The transmit buffer size of NIC " + $NICNAME + " was successfully configured to " + $TRANSMITBUFFESIZE + "KB. :-)") -ForegroundColor Green
        }
      catch
        {
        Write-Host ("  Oops, the NIC " + $NICNAME + " does not accept a transmit buffer size of " + $TRANSMITBUFFESIZE + "KB ... :-( ... never mind ... try with a smaller buffer next.") -ForegroundColor Yellow
        $CHANGETBOK = "NO"
        if ($DEDAILEDDEBUG -eq "ON") 
          {Write-Host $_ -ForegroundColor Red}
        }
      }
    }
  }
Write-Host "Transmit-Buffer optimization is complitly finished." -ForegroundColor Cyan

# CHANGE TCP PROFILE TO DATACENTERCUSTOM 
Write-Host "Start TCP profile optimization" -ForegroundColor Cyan
Write-Host "  Check if the key already exists in the registry." -ForegroundColor Gray
$CHANGETCPPROFILEOK = $false
$TARGETVALUE = @([byte[]](0x03,0x00,0x00,0x00,0xff,0xff,0xff,0xff))
$CHECKVALUE =  @([byte[]](Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nsi\{eb004a03-9b1a-11d4-9123-0050047759bc}\27\" -Name "06000000" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "06000000"))
if (($CHECKVALUE -ne $null) -or ($CHECKVALUE.Length -ne 0))
  {$AREEQUAL = @(Compare-Object $TARGETVALUE $CHECKVALUE -SyncWindow 0).Length -eq 0}
else
  {$AREEQUAL = $false}
if (($CHECKVALUE -ne $null) -or ($CHECKVALUE.Length -ne 0))
  {
  Write-Host "  The value is present in the registry." -ForegroundColor Yellow
  Write-Host "  Checking the already existing parameter." -ForegroundColor Gray
  if ($AREEQUAL -eq $true)
    {
    Write-Host "  The settings are already set correctly, no further measures are required." -ForegroundColor Green
    $CHANGETCPPROFILEOK = $true
    }
  else
    {
    Write-Host "  The current registry entry does not match the desired value and therefore needs to be updated." -ForegroundColor Yellow
    try
      {
      Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nsi\{eb004a03-9b1a-11d4-9123-0050047759bc}\27\" -Name "06000000" -Value (([byte[]](0x03,0x00,0x00,0x00,0xff,0xff,0xff,0xff))) -ErrorAction Stop
      Write-Host "  The corresponding registry entry has now been successfully updated." -ForegroundColor Green
      $CHANGETCPPROFILEOK = $true
      }
    catch
      {
      Write-Host ("  The registry key could not be updated due to an error. :-(") -ForegroundColor Red
      if ($DEDAILEDDEBUG -eq "ON") 
          {Write-Host $_ -ForegroundColor Red}
      }
    }
  }
else
  {
  Write-Host "  The corresponding registry entry does not exist and is now being created." -ForegroundColor Yellow
  try
    {
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nsi\{eb004a03-9b1a-11d4-9123-0050047759bc}\27\" -Name "06000000" -PropertyType Binary -Value (([byte[]](0x03,0x00,0x00,0x00,0xff,0xff,0xff,0xff))) -ErrorAction Stop
    Write-Host "  The corresponding registry entry has been created successfully. :-)" -ForegroundColor Green
    $CHANGETCPPROFILEOK = $true
    }
  catch
    {
    Write-Host ("  The registry key could not be created due to an error. :-(") -ForegroundColor Red
    if ($DEDAILEDDEBUG -eq "ON") 
      {Write-Host $_ -ForegroundColor Red}
    }
  }
if ($CHANGETCPPROFILEOK -eq $true)
  {
  Write-Host "TCP profile optimization is finished successfully. :-)" -ForegroundColor Cyan
  }
else
  {
  $FULLYCOMPLETED = $false
  Write-Host "TCP profile optimization can't finished successfully. :-(" -ForegroundColor Red
  }

# OPTIMIZE TCPACKFREQUENCY 
Write-Host "Start ACK-Frequency optimization" -ForegroundColor Cyan
$NICs = Get-NetAdapter -Physical | Select-Object DeviceID, Name
$CHANGETCPACKFREQUENCYOK = $true
foreach ($adapter in $NICs) 
  {
  $NICGUID = $adapter | Select-Object DeviceID | Select DeviceID -ExpandProperty DeviceID | Out-String -Stream
  $NICNAME = $adapter | Select-Object Name | Select Neme -ExpandProperty Name | Out-String -Stream
  $REGKEYPATH = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NICGUID\" | Out-String -Stream 

  Write-Host ("  Check if the key already exists in the registry for NIC " + $NICNAME + " .") -ForegroundColor Gray
  $TARGETVALUE = 1
  $CHECKVALUE = Get-ItemProperty -Path "$REGKEYPATH" -Name "TcpAckFrequency" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "TcpAckFrequency"
  if (($CHECKVALUE -ne $null) -or ($CHECKVALUE.Length -ne 0))
    {$AREEQUAL = @(Compare-Object $TARGETVALUE $CHECKVALUE -SyncWindow 0).Length -eq 0}
  else
    {$AREEQUAL = $false}
  if (($CHECKVALUE -ne $null) -or ($CHECKVALUE.Length -ne 0))
    {
    Write-Host ("    The key for NIC " + $NICNAME + " is present in the registry.") -ForegroundColor Yellow
    Write-Host ("    Checking the already existing key of NIC " + $NICNAME + ".") -ForegroundColor Gray
    if ($AREEQUAL -eq $true)
      {
      Write-Host ("  The settings of NIC " + $NICNAME + " are already set correctly, no further measures are required.") -ForegroundColor Green
      }
    else
      {
      Write-Host "    The current registry key of NIC " + $NICNAME + " does not match the desired value and therefore needs to be updated." -ForegroundColor Yellow
      try
        {
        Set-ItemProperty -Path "$REGKEYPATH" -Name "TcpAckFrequency" -Value 1
        Write-Host "  The corresponding registry entry for NIC " + $NICNAME + " has now been successfully updated." -ForegroundColor Green
        }
      catch
        {
        $CHANGETCPPROFILEOK = $false
        Write-Host ("  The registry key for NIC " + $NICNAME + " could not be updated due to an error. :-(") -ForegroundColor Red
        if ($DEDAILEDDEBUG -eq "ON") 
          {Write-Host $_ -ForegroundColor Red}
        }
      }
    }
  else
    {
    Write-Host "    The corresponding registry key for NIC " + $NICNAME + " does not exist and is now being created." -ForegroundColor Yellow
    try
      {
      New-ItemProperty -Path "$REGKEYPATH" -Name "TcpAckFrequency" -PropertyType DWord  -Value "1"
      Write-Host "  The corresponding registry key for NIC " + $NICNAME + " has been created successfully. :-)" -ForegroundColor Green
      }
    catch
      {
      $CHANGETCPPROFILEOK = $false
      Write-Host ("  The registry key could not be created due to an error. :-(") -ForegroundColor Red
      if ($DEDAILEDDEBUG -eq "ON") 
        {Write-Host $_ -ForegroundColor Red}
      }
    }
  }
if ($CHANGETCPPROFILEOK -eq $true)
    {
    Write-Host "ACK-Frequency optimization optimization is finished successfully. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "ACK-Frequency optimization can't finished successfully. :-(" -ForegroundColor Red
    }

# OPTIMIZE TCPDELAY 
Write-Host "Start TCP-Delay optimization" -ForegroundColor Cyan
$NICs = Get-NetAdapter -Physical | Select-Object DeviceID, Name
$CHANGETCPDELAYOK = $true
foreach ($adapter in $NICs) 
  {
  $NICGUID = $adapter | Select-Object DeviceID | Select DeviceID -ExpandProperty DeviceID | Out-String -Stream
  $NICNAME = $adapter | Select-Object Name | Select Neme -ExpandProperty Name | Out-String -Stream
  $REGKEYPATH = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NICGUID\" | Out-String -Stream 

  Write-Host ("  Check if the key already exists in the registry for NIC " + $NICNAME + " .") -ForegroundColor Gray
  $TARGETVALUE = 1
  $CHECKVALUE = Get-ItemProperty -Path "$REGKEYPATH" -Name "TcpNoDelay" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "TcpNoDelay"
  if (($CHECKVALUE -ne $null) -or ($CHECKVALUE.Length -ne 0))
    {$AREEQUAL = @(Compare-Object $TARGETVALUE $CHECKVALUE -SyncWindow 0).Length -eq 0}
  else
    {$AREEQUAL = $false}
  if (($CHECKVALUE -ne $null) -or ($CHECKVALUE.Length -ne 0))
    {
    Write-Host ("    The key for NIC " + $NICNAME + " is present in the registry.") -ForegroundColor Yellow
    Write-Host ("    Checking the already existing key of NIC " + $NICNAME + ".") -ForegroundColor Gray
    if ($AREEQUAL -eq $true)
      {
      Write-Host ("  The settings of NIC " + $NICNAME + " are already set correctly, no further measures are required.") -ForegroundColor Green
      }
    else
      {
      Write-Host "    The current registry key of NIC " + $NICNAME + " does not match the desired value and therefore needs to be updated." -ForegroundColor Yellow
      try
        {
        Set-ItemProperty -Path "$REGKEYPATH" -Name "TcpNoDelay" -Value 1
        Write-Host "  The corresponding registry entry for NIC " + $NICNAME + " has now been successfully updated." -ForegroundColor Green
        }
      catch
        {
        $CHANGETCPDELAYOK = $false
        Write-Host ("  The registry key for NIC " + $NICNAME + " could not be updated due to an error. :-(") -ForegroundColor Red
        if ($DEDAILEDDEBUG -eq "ON") 
          {Write-Host $_ -ForegroundColor Red}
        }
      }
    }
  else
    {
    Write-Host "    The corresponding registry key for NIC " + $NICNAME + " does not exist and is now being created." -ForegroundColor Yellow
    try
      {
      New-ItemProperty -Path "$REGKEYPATH" -Name "TcpNoDelay" -PropertyType DWord  -Value "1"
      Write-Host "  The corresponding registry key for NIC " + $NICNAME + " has been created successfully. :-)" -ForegroundColor Green
      }
    catch
      {
      $CHANGETCPDELAYOK = $false
      Write-Host ("  The registry key could not be created due to an error. :-(") -ForegroundColor Red
      if ($DEDAILEDDEBUG -eq "ON") 
        {Write-Host $_ -ForegroundColor Red}
      }
    }
  }
if ($CHANGETCPDELAYOK -eq $true)
    {
    Write-Host "TCP-Delay optimization optimization is finished successfully. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "TCP-Delay optimization can't finished successfully. :-(" -ForegroundColor Red
    }