# CHANGELOG

## W10ANDW11-NETWORK-TCP-BACKSUBOPTIMIZATION.ps1 

### v2.01

- The change to the DatacenterCustom TCP profile was discarded because this led to problems on some Windows 10 systems whose MinRTO in the Datacenter and DatacenterCustom profile is set too low by default and cannot be increased manually afterwards. :-(
- Instead, however, I simply applied the optimizations (switch from CUBIC to DCTCP & enable ECN) I previously made to the DatacenterCustom profile to the Internet TCP profile. :-)

In other words, the optimization effect remains the same on W11 and the script should no longer cause any problems on W10. ;-)