# CHANGELOG

## W10ANDW11-NETWORK-TCP-BACKSUBOPTIMIZATION.ps1 

### v2.01

- The change to the DatacenterCustom TCP profile was discarded because this led to problems on some Windows 10 systems whose MinRTO in the Datacenter and DatacenterCustom profile is set too low by default and cannot be increased manually afterwards. :-(
- Instead, however, I simply applied the optimizations (switch from CUBIC to DCTCP & enable ECN) I previously made to the DatacenterCustom profile to the Internet TCP profile. :-)

In other words, the optimization effect remains the same on W11 and the script should no longer cause any problems on W10. ;-)

### v2.02

Extension of the script to remove the "TCP Connection Limit".
I actually thought that this limiter would be disabled since Windows Vista SP2.
However, various articles on the Internet, such as the following one ... 

https://zditect.com/blog/413110.html

prove exactly the opposite. :-(

I find it a sham that Microsoft restricts the number of simultaneous connections, depending on the license, without even mentioning it with a word anywhere.

Many thanks at this point to @rugabunda, who drew my attention to this topic again in the following discussion.
https://github.com/MysticFoxDE/WINDOWS-OPTIMIZATIONS/issues/17