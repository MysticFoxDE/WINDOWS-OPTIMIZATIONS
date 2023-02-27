<#
.SYNOPSIS
    This Script desuboptimize a lot W10 & W11 TCP Settings.

 .NOTES
    Version:        1.12
    Author:         MysticFoxDE (Alexander Fuchs)
    Creation Date:  22.02.2023

.LINK
    https://www.golem.de/news/tcp-die-versteckte-netzwerkbremse-in-windows-10-und-11-2302-172043.html
    https://www.borncity.com/blog/2023/01/30/microsofts-tcp-murks-in-windows-10-und-11-optimierung-ist-mglich
    https://www.borncity.com/blog/2023/02/14/windows-10-11-grottige-netzwerktransfer-leistung-hohe-windows-11-cpu-last-teil-1
    https://www.borncity.com/blog/2023/02/14/windows-11-netzwerktransfer-leistung-und-cpu-last-optimieren-teil-2
    https://administrator.de/tutorial/wie-man-das-windows-10-und-11-tcp-handling-wieder-desuboptimieren-kann-5529700198.html#comment-5584260697
    https://community.spiceworks.com/topic/post/10299845
#>

# PROMPT THE USER TO ELEVATE THE SCRIPT
# Great thanks to "Karl Wester-Ebbinghaus/Karl-WE" for this very useful aid.
if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  $arguments = "-NoExit -ExecutionPolicy Bypass -File `"$($myInvocation.MyCommand.Definition)`""
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  exit
}

# DETAILED SCRIPTDEBUGING ON=Enabled OFF=Disabled
$DEDAILEDDEBUG = "OFF"

#BASIC VARIABLES
$FULLYCOMPLETED = $true

# CREATE A BACKUP OF THE EXISTING SETTINGS
$BAKLOGPATH = "C:\BACKUP"
$BAKLOGFILENAME = "WINDOWS10AND11-NETWORK-DESUBOPTIMIZATION.log"
$BAKLOGDATE = Get-Date
if (!(Test-Path $BAKLOGPATH))
  {New-Item -Path $BAKLOGPATH -ItemType Directory}

Write-Host ("Create a backup of the existing configuration under " + $BAKLOGPATH + "\" + $BAKLOGFILENAME) -ForegroundColor Cyan
"************************************************************************************************************" >> $BAKLOGPATH\$BAKLOGFILENAME
"*** Beginning of the configuration-backup from " + $BAKLOGDATE >> $BAKLOGPATH\$BAKLOGFILENAME
"************************************************************************************************************" >> $BAKLOGPATH\$BAKLOGFILENAME
" " >> $BAKLOGPATH\$BAKLOGFILENAME
"Get-NetOffloadGlobalSetting: " >> $BAKLOGPATH\$BAKLOGFILENAME
Get-NetOffloadGlobalSetting >> $BAKLOGPATH\$BAKLOGFILENAME
"------------------------------------------------------------------------------------------------------------" >> $BAKLOGPATH\$BAKLOGFILENAME
"netsh int tcp show global: " >> $BAKLOGPATH\$BAKLOGFILENAME
netsh int tcp show global >> $BAKLOGPATH\$BAKLOGFILENAME
"------------------------------------------------------------------------------------------------------------" >> $BAKLOGPATH\$BAKLOGFILENAME
"netsh int tcp show supplemental:" >> $BAKLOGPATH\$BAKLOGFILENAME
netsh int tcp show supplemental >> $BAKLOGPATH\$BAKLOGFILENAME
"------------------------------------------------------------------------------------------------------------" >> $BAKLOGPATH\$BAKLOGFILENAME
"Get-NetAdapterAdvancedProperty:" >> $BAKLOGPATH\$BAKLOGFILENAME
Get-NetAdapterAdvancedProperty | FT -AutoSize >> $BAKLOGPATH\$BAKLOGFILENAME
"------------------------------------------------------------------------------------------------------------" >> $BAKLOGPATH\$BAKLOGFILENAME
"Get-NetAdapterRsc:" >> $BAKLOGPATH\$BAKLOGFILENAME
Get-NetAdapterRsc | FT -AutoSize >> $BAKLOGPATH\$BAKLOGFILENAME
"------------------------------------------------------------------------------------------------------------" >> $BAKLOGPATH\$BAKLOGFILENAME
"Get-NetAdapterRss:" >> $BAKLOGPATH\$BAKLOGFILENAME
Get-NetAdapterRss >> $BAKLOGPATH\$BAKLOGFILENAME
"------------------------------------------------------------------------------------------------------------" >> $BAKLOGPATH\$BAKLOGFILENAME
"Status TCP-Profile: (Registry)" >> $BAKLOGPATH\$BAKLOGFILENAME
$TARGETVALUE = @([byte[]](0x03,0x00,0x00,0x00,0xff,0xff,0xff,0xff))
$CHECKVALUE =  @([byte[]](Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nsi\{eb004a03-9b1a-11d4-9123-0050047759bc}\27\" -Name "06000000" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "06000000"))
if (($CHECKVALUE -ne $null) -and ($CHECKVALUE.Length -gt 0))
  {
    ("The 06000000 Key is present in the registry with value " + $CHECKVALUE + ".") >> $BAKLOGPATH\$BAKLOGFILENAME
  }
else
  {
    ("The 06000000 Key is NOT present in the registry.") >> $BAKLOGPATH\$BAKLOGFILENAME
  }
"------------------------------------------------------------------------------------------------------------" >> $BAKLOGPATH\$BAKLOGFILENAME
"Status ACK-Frequency: (Registry)" >> $BAKLOGPATH\$BAKLOGFILENAME
$NICs = Get-NetAdapter -Physical | Select-Object DeviceID, Name
foreach ($adapter in $NICs)
  {
  $NICGUID = $adapter | Select-Object DeviceID | Select DeviceID -ExpandProperty DeviceID | Out-String -Stream
  $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
  $REGKEYPATH = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NICGUID\" | Out-String -Stream
  $TARGETVALUE = 1
  $CHECKVALUE = Get-ItemProperty -Path "$REGKEYPATH" -Name "TcpAckFrequency" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "TcpAckFrequency"
  if (($CHECKVALUE -ne $null) -and ($CHECKVALUE.Length -gt 0))
    {
    ("The TcpAckFrequency Key for NIC " + $NICNAME + " is present in the registry with value " + $CHECKVALUE + ".") >> $BAKLOGPATH\$BAKLOGFILENAME
    }
  else
    {
    ("The TcpAckFrequency Key for NIC " + $NICNAME + " is NOT present in the registry.") >> $BAKLOGPATH\$BAKLOGFILENAME
    }
  }
"------------------------------------------------------------------------------------------------------------" >> $BAKLOGPATH\$BAKLOGFILENAME
"Status TCP-Delay: (Registry)" >> $BAKLOGPATH\$BAKLOGFILENAME
$NICs = Get-NetAdapter -Physical | Select-Object DeviceID, Name
foreach ($adapter in $NICs)
  {
  $NICGUID = $adapter | Select-Object DeviceID | Select DeviceID -ExpandProperty DeviceID | Out-String -Stream
  $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
  $REGKEYPATH = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NICGUID\" | Out-String -Stream
  $TARGETVALUE = 1
  $CHECKVALUE = Get-ItemProperty -Path "$REGKEYPATH" -Name "TcpNoDelay" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "TcpNoDelay"
  if (($CHECKVALUE -ne $null) -and ($CHECKVALUE.Length -gt 0))
    {
    ("The TcpNoDelay Key for NIC " + $NICNAME + " is present in the registry with value " + $CHECKVALUE + ".") >> $BAKLOGPATH\$BAKLOGFILENAME
    }
  else
    {
    ("The TcpNoDelay Key for NIC " + $NICNAME + " is NOT present in the registry.") >> $BAKLOGPATH\$BAKLOGFILENAME
    }
  }
"------------------------------------------------------------------------------------------------------------" >> $BAKLOGPATH\$BAKLOGFILENAME
"************************************************************************************************************" >> $BAKLOGPATH\$BAKLOGFILENAME
"*** End of the configuration-backup from " + $BAKLOGDATE >> $BAKLOGPATH\$BAKLOGFILENAME
"************************************************************************************************************" >> $BAKLOGPATH\$BAKLOGFILENAME
Write-Host ("Backup of the existing configuration is finished. :-)") -ForegroundColor Cyan

# DISABLE PACKET COALESCING FILTER ON WINDOWS TCP-STACK
$DISABLEPCFOK = $true
Write-Host "Start disabling PACKET COALESCING FILTER on Windows TCP-Stack" -ForegroundColor Cyan
Write-Host "  Check current state of PACKET COALESCING FILTER" -ForegroundColor Gray
$STATUSPCF = Get-NetOffloadGlobalSetting | Select-Object PacketCoalescingFilter | Select PacketCoalescingFilter -ExpandProperty PacketCoalescingFilter | Out-String -Stream
if ($STATUSPCF -eq "Disabled")
  {
  Write-Host "  The PACKET COALESCING FILTER is already disabled, so nothing to do. :-)" -ForegroundColor Green
  }
else
  {
  Write-Host "  The PACKET COALESCING FILTER is enabled, try next to disable it." -ForegroundColor Yellow
  try
    {
    Set-NetOffloadGlobalSetting -PacketCoalescingFilter Disabled -ErrorAction Stop
    Write-Host "    The PACKET COALESCING FILTER is successfully set to disabled. :-)" -ForegroundColor Green
    }
  catch
    {
    $DISABLEPCFOK = $false
    Write-Host ("  The PACKET COALESCING FILTER could not set to disabled. :-(") -ForegroundColor Red
    if ($DEDAILEDDEBUG -eq "ON")
      {Write-Host $_ -ForegroundColor Red}
    }
  }
if ($DISABLEPCFOK -eq $true)
    {
    Write-Host "Disabling PACKET COALESCING FILTER has been finished successfully. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "Disabling PACKET COALESCING FILTER can't finished successfully. :-(" -ForegroundColor Red
    }

# DISABLE RECEIVE SIDE SCALING ON WINDOWS TCP-STACK
$DISABLERSSOK = $true
Write-Host "Start disabling RECEIVE SIDE SCALING on Windows TCP-Stack" -ForegroundColor Cyan
Write-Host "  Check current state of RECEIVE SIDE SCALING" -ForegroundColor Gray
$STATUSRSS = Get-NetOffloadGlobalSetting | Select-Object ReceiveSideScaling | Select ReceiveSideScaling -ExpandProperty ReceiveSideScaling | Out-String -Stream
if ($STATUSRSS -eq "Disabled")
  {
  Write-Host "  The RECEIVE SIDE SCALING is already disabled, so nothing to do. :-)" -ForegroundColor Green
  }
else
  {
  Write-Host "  The RECEIVE SIDE SCALING is enabled, try next to disable it." -ForegroundColor Yellow
  try
    {
    Set-NetOffloadGlobalSetting -ReceiveSideScaling Disabled -ErrorAction Stop
    Write-Host "    The RECEIVE SIDE SCALING is successfully set to disabled. :-)" -ForegroundColor Green
    }
  catch
    {
    $DISABLERSSOK = $false
    Write-Host ("  The RECEIVE SIDE SCALING could not set to disabled. :-(") -ForegroundColor Red
    if ($DEDAILEDDEBUG -eq "ON")
      {Write-Host $_ -ForegroundColor Red}
    }
  }
if ($DISABLERSSOK -eq $true)
    {
    Write-Host "Disabling RECEIVE SIDE SCALING has been finished successfully. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "Disabling RECEIVE SIDE SCALING can't finished successfully. :-(" -ForegroundColor Red
    }

# DISABLE RECEIVE SEGMENT COALESCING ON WINDOWS TCP-STACK
$DISABLERSCOK = $true
Write-Host "Start disabling RECEIVE SEGMENT COALESCING on Windows TCP-Stack" -ForegroundColor Cyan
Write-Host "  Check current state of RECEIVE SEGMENT COALESCING" -ForegroundColor Gray
$STATUSRSC = Get-NetOffloadGlobalSetting | Select-Object ReceiveSegmentCoalescing | Select ReceiveSegmentCoalescing -ExpandProperty ReceiveSegmentCoalescing | Out-String -Stream
if ($STATUSRSC -eq "Disabled")
  {
  Write-Host "  The RECEIVE SEGMENT COALESCING is already disabled, so nothing to do. :-)" -ForegroundColor Green
  }
else
  {
  Write-Host "  The RECEIVE SEGMENT COALESCING is enabled, try next to disable it." -ForegroundColor Yellow
  try
    {
    Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled -ErrorAction Stop
    Write-Host "    The RECEIVE SEGMENT COALESCING is successfully set to disabled. :-)" -ForegroundColor Green
    }
  catch
    {
    $DISABLERSCOK = $false
    Write-Host ("  The RECEIVE SEGMENT COALESCING could not set to disabled. :-(") -ForegroundColor Red
    if ($DEDAILEDDEBUG -eq "ON")
      {Write-Host $_ -ForegroundColor Red}
    }
  }
if ($DISABLERSCOK -eq $true)
    {
    Write-Host "Disabling RECEIVE SEGMENT COALESCING has been finished successfully. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "Disabling RECEIVE SEGMENT COALESCING can't finished successfully. :-(" -ForegroundColor Red
    }

# OPTIMIZE TCP CONGESTION CONTROL
$CHANGETCPCCOK = $true
Write-Host "Start TCP congestion control optimization" -ForegroundColor Cyan
Write-Host "  Try to set the congestionprovider of the Datacenter TCP profile to DCTCP" -ForegroundColor Gray
try
  {
  $COMMANDOUTPUT = Invoke-Expression -Command "netsh int tcp set supplemental template=DatacenterCustom congestionprovider=DCTCP" -ErrorAction Stop | Out-String -Stream
  if ($COMMANDOUTPUT -eq "OK.")
    {
    Write-Host "  Try to set the congestionprovider of the Datacenter TCP profile to DCTCP was successfully. :-)" -ForegroundColor Green
    }
  else
    {
    $CHANGETCPCCOK = $false
    Write-Host "  The Update of the congestionprovider of the Datacenter TCP profile to DCTCP was NOT successfully. :-(" -ForegroundColor Red
    Write-Host ("  " + $COMMANDOUTPUT) -ForegroundColor Red
    }
  }
catch
  {
  $CHANGETCPCCOK = $false
  Write-Host ("  The Update of the congestionprovider of the Datacenter TCP profile to DCTCP was NOT successfully. :-(") -ForegroundColor Red
  if ($DEDAILEDDEBUG -eq "ON")
    {Write-Host $_ -ForegroundColor Red}
  }

Write-Host "  Try to enable ECN" -ForegroundColor Gray
try
  {
  $COMMANDOUTPUT = Invoke-Expression -Command "netsh int tcp set global ECN=Enabled" -ErrorAction Stop | Out-String -Stream
  if ($COMMANDOUTPUT -eq "OK.")
    {
    Write-Host "  Enable ECN was successfully. :-)" -ForegroundColor Green
    }
  else
    {
    $CHANGETCPCCOK = $false
    Write-Host "  Try to enable ECN was NOT successfully. :-(" -ForegroundColor Red
    Write-Host ("  " + $COMMANDOUTPUT) -ForegroundColor Red
    }
  }
catch
  {
  $CHANGETCPCCOK = $false
  Write-Host ("  Try to enable ECN was NOT successfully was NOT successfully. :-(") -ForegroundColor Red
  if ($DEDAILEDDEBUG -eq "ON")
    {Write-Host $_ -ForegroundColor Red}
  }


if ($CHANGETCPCCOK -eq $true)
    {
    Write-Host "TCP congestion control optimization is finished successfully. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "TCP congestion control can't finished successfully. :-(" -ForegroundColor Red
    }

# CHANGE TCP PROFILE TO DATACENTERCUSTOM
Write-Host "Start TCP profile optimization" -ForegroundColor Cyan
Write-Host "  Check if the key already exists in the registry." -ForegroundColor Gray
$CHANGETCPPROFILEOK = $false
$TARGETVALUE = @([byte[]](0x03,0x00,0x00,0x00,0xff,0xff,0xff,0xff))
$CHECKVALUE =  @([byte[]](Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nsi\{eb004a03-9b1a-11d4-9123-0050047759bc}\27\" -Name "06000000" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "06000000"))
if (($CHECKVALUE -ne $null) -and ($CHECKVALUE.Length -gt 0))
  {
  Write-Host "  The value is present in the registry." -ForegroundColor Yellow
  Write-Host "  Checking the already existing parameter." -ForegroundColor Gray
  $AREEQUAL = @(Compare-Object $TARGETVALUE $CHECKVALUE -SyncWindow 0).Length -eq 0
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

# DISABLE RSS ON ALL NIC's
$DISABLERSSOK = $true
Write-Host "Start disabling RSS on all NIC's" -ForegroundColor Cyan
Write-Host "  Check if NIC's with RSS support are available on this System." -ForegroundColor Gray
$NICs = Get-NetAdapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*RSS"}
$NICsWITHRSS = $NICs | Measure-Object -Line | Select-Object Lines | Select Lines -ExpandProperty Lines

if ($NICsWITHRSS -eq 0)
  {
      Write-Host ("  No NIC's installed in this system which support RSS, so, nothing to do. :-)") -ForegroundColor Green
  }
else
  {
  Write-Host ("  " + $NICsWITHRSS + " NIC's found on this System that support RSS") -ForegroundColor Yellow
  foreach ($adapter in $NICs)
    {
    $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
    $RSSVALUE = $adapter | Select-Object RegistryValue | Select RegistryValue -ExpandProperty RegistryValue | Out-String -Stream

    Write-Host ("    Check RSS Status of NIC " + $NICNAME + " .") -ForegroundColor Gray

    if ($RSSVALUE -eq "0")
      {
      Write-Host ("    RSS on NIC " + $NICNAME + " is already disabled, so, nothing to do. :-)") -ForegroundColor Green
      }
    else
      {
      Write-Host ("    RSS on NIC " + $NICNAME + " is enabled, try next to disable it.") -ForegroundColor Yellow
      try
        {
        Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*RSS" -RegistryValue 0 -ErrorAction Stop
        Write-Host "    RSS on NIC " + $NICNAME + ", has been successfully set to disabled. :-)" -ForegroundColor Green
        }
      catch
        {
        $DISABLERSSOK = $false
        Write-Host ("  The RSS on NIC " + $NICNAME + ", could not set to disabled. :-(") -ForegroundColor Red
        if ($DEDAILEDDEBUG -eq "ON")
          {Write-Host $_ -ForegroundColor Red}
        }
      }
    }
  }
if ($DISABLERSSOK -eq $true)
    {
    Write-Host "RSS has been successfully disabled on all corresponding NIC's or there is nothing to do. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "Disabling RSS can't finished successfully. :-(" -ForegroundColor Red
    }

# DISABLE RSC-IPv4 FOR ALL NIC's
$DISABLERSCIPV4OK = $true
Write-Host "Start disabling RSC-IPv4 on all NIC's" -ForegroundColor Cyan
Write-Host "  Check if NIC's with RSC-IPv4 support are available on this System." -ForegroundColor Gray
$NICs = Get-NetAdapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*RscIPv4"}
$NICsWITHRSCIPV4 = $NICs | Measure-Object -Line | Select-Object Lines | Select Lines -ExpandProperty Lines

if ($NICsWITHRSCIPV4 -eq 0)
  {
      Write-Host ("  No NIC's installed in this system which support RSC-IPv4, so, nothing to do. :-)") -ForegroundColor Green
  }
else
  {
  Write-Host ("  " + $NICsWITHRSCIPV4 + " NIC's found on this System that support RSC-IPv4") -ForegroundColor Yellow
  foreach ($adapter in $NICs)
    {
    $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
    $RSCVALUE = $adapter | Select-Object RegistryValue | Select RegistryValue -ExpandProperty RegistryValue | Out-String -Stream

    Write-Host ("    Check RSC-IPv4 Status of NIC " + $NICNAME + " .") -ForegroundColor Gray

    if ($RSCVALUE -eq "0")
      {
      Write-Host ("    RSC-IPv4 on NIC " + $NICNAME + " is already disabled, so, nothing to do. :-)") -ForegroundColor Green
      }
    else
      {
      Write-Host ("    RSC-IPv4 on NIC " + $NICNAME + " is enabled, try next to disable it.") -ForegroundColor Yellow
      try
        {
        Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*RscIPv4" -RegistryValue 0 -ErrorAction Stop
        Write-Host "    RSC-IPv4 on NIC " + $NICNAME + ", has been successfully set to disabled. :-)" -ForegroundColor Green
        }
      catch
        {
        $DISABLERSCIPV4OK = $false
        Write-Host ("  The RSC-IPv4 on NIC " + $NICNAME + ", could not set to disabled. :-(") -ForegroundColor Red
        if ($DEDAILEDDEBUG -eq "ON")
          {Write-Host $_ -ForegroundColor Red}
        }
      }
    }
  }
if ($DISABLERSCIPV4OK -eq $true)
    {
    Write-Host "RSC-IPv4 has been successfully disabled on all corresponding NIC's or there is nothing to do. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "Disabling RSC-IPv4 can't finished successfully. :-(" -ForegroundColor Red
    }

# DISABLE RSC-IPv6 FOR ALL NIC's
$DISABLERSCIPV6OK = $true
Write-Host "Start disabling RSC-IPv6 on all NIC's" -ForegroundColor Cyan
Write-Host "  Check if NIC's with RSC-IPv6 support are available on this System." -ForegroundColor Gray
$NICs = Get-NetAdapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*RscIPv6"}
$NICsWITHRSCIPV6 = $NICs | Measure-Object -Line | Select-Object Lines | Select Lines -ExpandProperty Lines

if ($NICsWITHRSCIPV6 -eq 0)
  {
      Write-Host ("  No NIC's installed in this system which support RSC-IPv6, so, nothing to do. :-)") -ForegroundColor Green
  }
else
  {
  Write-Host ("  " + $NICsWITHRSCIPV6 + " NIC's found on this System that support RSC-IPv6") -ForegroundColor Yellow
  foreach ($adapter in $NICs)
    {
    $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
    $RSCVALUE = $adapter | Select-Object RegistryValue | Select RegistryValue -ExpandProperty RegistryValue | Out-String -Stream

    Write-Host ("    Check RSC-IPv6 Status of NIC " + $NICNAME + " .") -ForegroundColor Gray

    if ($RSCVALUE -eq "0")
      {
      Write-Host ("    RSC-IPv6 on NIC " + $NICNAME + " is already disabled, so, nothing to do. :-)") -ForegroundColor Green
      }
    else
      {
      Write-Host ("    RSC-IPv6 on NIC " + $NICNAME + " is enabled, try next to disable it.") -ForegroundColor Yellow
      try
        {
        Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*RscIPv6" -RegistryValue 0 -ErrorAction Stop
        Write-Host "    RSC-IPv6 on NIC " + $NICNAME + ", has been successfully set to disabled. :-)" -ForegroundColor Green
        }
      catch
        {
        $DISABLERSCIPV6OK = $false
        Write-Host ("  The RSC-IPv6 on NIC " + $NICNAME + ", could not set to disabled. :-(") -ForegroundColor Red
        if ($DEDAILEDDEBUG -eq "ON")
          {Write-Host $_ -ForegroundColor Red}
        }
      }
    }
  }
if ($DISABLERSCIPV6OK -eq $true)
    {
    Write-Host "RSC-IPv6 has been successfully disabled on all corresponding NIC's or there is nothing to do. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "Disabling RSC-IPv6 can't finished successfully. :-(" -ForegroundColor Red
    }

# DISABLE FLOW CONTROL ON ALL NIC's
Write-Host "Start disabling FLOW CONTROL on all NIC's" -ForegroundColor Cyan
Write-Host "  Identify the NICs that actually support FLOW CONTROL." -ForegroundColor Gray
$NICs = Get-NetAdapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*FlowControl"}
$DISABLEFCOK = $true
foreach ($adapter in $NICs)
  {
  $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
  $EEEVALUE = $adapter | Select-Object RegistryValue | Select RegistryValue -ExpandProperty RegistryValue | Out-String -Stream

  Write-Host ("    Check FLOW CONTROL Status of NIC " + $NICNAME + " .") -ForegroundColor Gray

  if ($EEEVALUE -eq "0")
    {
    Write-Host ("    The FLOW CONTROL is already disabled on NIC " + $NICNAME + ", so, nothing to do. :-)") -ForegroundColor Green
    }
  else
    {
    Write-Host "    The FLOW CONTROL is enabled on NIC " + $NICNAME + ", try next to disable it." -ForegroundColor Yellow
    try
      {
      Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*FlowControl" -RegistryValue 0 -ErrorAction Stop
      Write-Host "    The FLOW CONTROL on NIC " + $NICNAME + ", has been successfully set to disabled. :-)" -ForegroundColor Green
      }
    catch
      {
      $DISABLEFCOK = $false
      Write-Host ("  The FLOW CONTROL on NIC " + $NICNAME + ", could not set to disabled. :-(") -ForegroundColor Red
      if ($DEDAILEDDEBUG -eq "ON")
        {Write-Host $_ -ForegroundColor Red}
      }
    }
  }
if ($DISABLEFCOK -eq $true)
    {
    Write-Host "FLOW CONTROL has been successfully disabled on all corresponding NIC's. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "Disabling FLOW CONTROL can't finished successfully. :-(" -ForegroundColor Red
    }

# DISABLE INTERRUPT MODERATION ON ALL NIC's
Write-Host "Start disabling INTERRUPT MODERATION on all NIC's" -ForegroundColor Cyan
Write-Host "  Identify the NICs that actually support INTERRUPT MODERATION." -ForegroundColor Gray
$NICs = Get-NetAdapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*InterruptModeration"}
$DISABLEIMOK = $true
foreach ($adapter in $NICs)
  {
  $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
  $EEEVALUE = $adapter | Select-Object RegistryValue | Select RegistryValue -ExpandProperty RegistryValue | Out-String -Stream

  Write-Host ("    Check INTERRUPT MODERATION Status of NIC " + $NICNAME + " .") -ForegroundColor Gray

  if ($EEEVALUE -eq "0")
    {
    Write-Host ("    The INTERRUPT MODERATION is already disabled on NIC " + $NICNAME + ", so, nothing to do. :-)") -ForegroundColor Green
    }
  else
    {
    Write-Host "    The INTERRUPT MODERATION is enabled on NIC " + $NICNAME + ", try next to disable it." -ForegroundColor Yellow
    try
      {
      Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*InterruptModeration" -RegistryValue 0 -ErrorAction Stop
      Write-Host "    The INTERRUPT MODERATION on NIC " + $NICNAME + ", has been successfully set to disabled. :-)" -ForegroundColor Green
      }
    catch
      {
      $DISABLEIMOK = $false
      Write-Host ("  The INTERRUPT MODERATION on NIC " + $NICNAME + ", could not set to disabled. :-(") -ForegroundColor Red
      if ($DEDAILEDDEBUG -eq "ON")
        {Write-Host $_ -ForegroundColor Red}
      }
    }
  }
if ($DISABLEIMOK -eq $true)
    {
    Write-Host "INTERRUPT MODERATION has been successfully disabled on all corresponding NIC's. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "Disabling INTERRUPT MODERATION can't finished successfully. :-(" -ForegroundColor Red
    }

# DISABLE ENERGY-EFFICIENT-ETHERNET ON ALL NIC's
Write-Host "Start disabling ENERGY-EFFICIENT-ETHERNET on all NIC's" -ForegroundColor Cyan
Write-Host "  Identify the NICs that actually support ENERGY-EFFICIENT-ETHERNET." -ForegroundColor Gray
$NICs = Get-NetAdapter -Physical | Get-NetAdapterAdvancedProperty | Where-Object -FilterScript {$_.RegistryKeyword -Like "*EEE"}
$DISABLEEEEEOK = $true
foreach ($adapter in $NICs)
  {
  $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
  $EEEVALUE = $adapter | Select-Object RegistryValue | Select RegistryValue -ExpandProperty RegistryValue | Out-String -Stream

  Write-Host ("    Check EEE Status of NIC " + $NICNAME + " .") -ForegroundColor Gray

  if ($EEEVALUE -eq "0")
    {
    Write-Host ("    The EEE is already disabled on NIC " + $NICNAME + ", so, nothing to do. :-)") -ForegroundColor Green
    }
  else
    {
    Write-Host "    The EEE is enabled on NIC " + $NICNAME + ", try next to disable it." -ForegroundColor Yellow
    try
      {
      Set-NetAdapterAdvancedProperty -Name "$NICNAME" -RegistryKeyword "*EEE" -RegistryValue 0 -ErrorAction Stop
      Write-Host "    The EEE on NIC " + $NICNAME + ", has been successfully set to disabled. :-)" -ForegroundColor Green
      }
    catch
      {
      $DISABLEEEEEOK = $false
      Write-Host ("  The EEE on NIC " + $NICNAME + ", could not set to disabled. :-(") -ForegroundColor Red
      if ($DEDAILEDDEBUG -eq "ON")
        {Write-Host $_ -ForegroundColor Red}
      }
    }
  }
if ($DISABLEEEEEOK -eq $true)
    {
    Write-Host "ENERGY-EFFICIENT-ETHERNET has been successfully disabled on all corresponding NIC's. :-)" -ForegroundColor Cyan
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host "Disabling ENERGY-EFFICIENT-ETHERNET can't finished successfully. :-(" -ForegroundColor Red
    }

# OPTIMIZE RECEIVE-BUFFERS ON ALL NIC's
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
      Write-Host ("  Try to set receive buffer size of NIC " + $NICNAME + " to " + $RECEIVEBUFFESIZE + "KB.") -ForegroundColor Gray
      try
        {
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
Write-Host "Receive-Buffer optimization is completely finished." -ForegroundColor Cyan

# OPTIMIZE TRANSMIT-BUFFERS ON ALL NIC's
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
      Write-Host ("  Try to set transmit buffer size of NIC " + $NICNAME + " to " + $TRANSMITBUFFESIZE + "KB.") -ForegroundColor Gray
      try
        {
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
Write-Host "Transmit-Buffer optimization is completely finished." -ForegroundColor Cyan

# OPTIMIZE TCPACKFREQUENCY
Write-Host "Start ACK-Frequency optimization" -ForegroundColor Cyan
$NICs = Get-NetAdapter -Physical | Select-Object DeviceID, Name
$CHANGETCPACKFREQUENCYOK = $true
foreach ($adapter in $NICs)
  {
  $NICGUID = $adapter | Select-Object DeviceID | Select DeviceID -ExpandProperty DeviceID | Out-String -Stream
  $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
  $REGKEYPATH = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NICGUID\" | Out-String -Stream

  Write-Host ("  Check if the key already exists in the registry for NIC " + $NICNAME + " .") -ForegroundColor Gray
  $TARGETVALUE = 1
  $CHECKVALUE = Get-ItemProperty -Path "$REGKEYPATH" -Name "TcpAckFrequency" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "TcpAckFrequency"
  if (($CHECKVALUE -ne $null) -and ($CHECKVALUE.Length -gt 0))
    {
    Write-Host ("    The key for NIC " + $NICNAME + " is present in the registry.") -ForegroundColor Yellow
    Write-Host ("    Checking the already existing key of NIC " + $NICNAME + ".") -ForegroundColor Gray
    $AREEQUAL = @(Compare-Object $TARGETVALUE $CHECKVALUE -SyncWindow 0).Length -eq 0
    if ($AREEQUAL -eq $true)
      {
      Write-Host ("  The settings of NIC " + $NICNAME + " are already set correctly, no further measures are required.") -ForegroundColor Green
      }
    else
      {
      Write-Host "    The current registry key of NIC " + $NICNAME + " does not match the desired value and therefore needs to be updated." -ForegroundColor Yellow
      try
        {
        Set-ItemProperty -Path "$REGKEYPATH" -Name "TcpAckFrequency" -Value 1 -ErrorAction Stop
        Write-Host "  The corresponding registry entry for NIC " + $NICNAME + " has now been successfully updated." -ForegroundColor Green
        }
      catch
        {
        $CHANGETCPACKFREQUENCYOK = $false
        Write-Host ("  The registry key for NIC " + $NICNAME + " could not be updated due to an error. :-(") -ForegroundColor Red
        if ($DEDAILEDDEBUG -eq "ON")
          {Write-Host $_ -ForegroundColor Red}
        }
      }
    }
  else
    {
    Write-Host ("    The corresponding registry key for NIC " + $NICNAME + " does not exist and is now being created.") -ForegroundColor Yellow
    try
      {
      New-ItemProperty -Path "$REGKEYPATH" -Name "TcpAckFrequency" -PropertyType DWord  -Value "1" -ErrorAction Stop
      Write-Host ("  The corresponding registry key for NIC " + $NICNAME + " has been created successfully. :-)") -ForegroundColor Green
      }
    catch
      {
      $CHANGETCPACKFREQUENCYOK = $false
      Write-Host ("  The registry key could not be created due to an error. :-(") -ForegroundColor Red
      if ($DEDAILEDDEBUG -eq "ON")
        {Write-Host $_ -ForegroundColor Red}
      }
    }
  }
if ($CHANGETCPACKFREQUENCYOK -eq $true)
    {
    Write-Host "ACK-Frequency optimization is finished successfully. :-)" -ForegroundColor Cyan
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
  $NICNAME = $adapter | Select-Object Name | Select Name -ExpandProperty Name | Out-String -Stream
  $REGKEYPATH = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NICGUID\" | Out-String -Stream

  Write-Host ("  Check if the key already exists in the registry for NIC " + $NICNAME + " .") -ForegroundColor Gray
  $TARGETVALUE = 1
  $CHECKVALUE = Get-ItemProperty -Path "$REGKEYPATH" -Name "TcpNoDelay" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "TcpNoDelay"
  if (($CHECKVALUE -ne $null) -and ($CHECKVALUE.Length -gt 0))
    {
    Write-Host ("    The key for NIC " + $NICNAME + " is present in the registry.") -ForegroundColor Yellow
    Write-Host ("    Checking the already existing key of NIC " + $NICNAME + ".") -ForegroundColor Gray
    $AREEQUAL = @(Compare-Object $TARGETVALUE $CHECKVALUE -SyncWindow 0).Length -eq 0
    if ($AREEQUAL -eq $true)
      {
      Write-Host ("  The settings of NIC " + $NICNAME + " are already set correctly, no further measures are required.") -ForegroundColor Green
      }
    else
      {
      Write-Host ("    The current registry key of NIC " + $NICNAME + " does not match the desired value and therefore needs to be updated.") -ForegroundColor Yellow
      try
        {
        Set-ItemProperty -Path "$REGKEYPATH" -Name "TcpNoDelay" -Value 1 -ErrorAction Stop
        Write-Host ("  The corresponding registry entry for NIC " + $NICNAME + " has now been successfully updated.") -ForegroundColor Green
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
    Write-Host ("    The corresponding registry key for NIC " + $NICNAME + " does not exist and is now being created.") -ForegroundColor Yellow
    try
      {
      New-ItemProperty -Path "$REGKEYPATH" -Name "TcpNoDelay" -PropertyType DWord  -Value "1" -ErrorAction Stop
      Write-Host ("  The corresponding registry key for NIC " + $NICNAME + " has been created successfully. :-)") -ForegroundColor Green
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
    Write-Host "TCP-Delay optimization is finished successfully. :-)" -ForegroundColor Cyan
    Write-Host "!!! To ensure that all changes are applied, the computer must be restarted. !!!" -ForegroundColor Magenta
    }
  else
    {
    $FULLYCOMPLETED = $false
    Write-Host ("TCP-Delay optimization can't finished successfully. :-(") -ForegroundColor Red
    Write-Host ("!!! And even if not everything went through cleanly, the computer should still be restarted so that at least what could be optimized works properly. ;-) !!!") -ForegroundColor Magenta
    }
