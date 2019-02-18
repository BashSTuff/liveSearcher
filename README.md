# liveSearcher

Uses BASH to check if IPv4 hosts are up

Mainly created this because I got tired of manually pinging hosts during CTFs, etc. I built this little gadget to help if nmap or otherwise is not available/can't be used. Specifically when deep in segmented networks to look for lateral targets. 

Users are able to conduct three types of ping recon:
1. Single ping of a single host
   1. for example, 10.10.10.10
  
2. Subnet ping of a subnet via cidr notation
   1. for example, 10.10.10.10/16
   2. for example, 192.168.1.1/24
  
3. Range ping of a specific IPv4 range*
   1. for example, 10.10.10.10-11.11.11 (ping a range of 3 octets)
   2. for example, 192.168.1.1-254      (ping a range with in 1 octet)
   3. for example, 172.16.0.1-1.230     (ping a range of 2 octets)
  
For range searches: user entered range MUST be at least 1 higher in the desired octet. For example, 

if two entered:
- 192.168.0.0-**0.1**  ==   0.0   -   0.1     illegal  (first range octet must be at least 1 higher)
- 192.168.0.0-**1.1**  ==   0.0   -   1.1     legal (first range octet is at least 1 higher)
- 192.168.1.0-**1.1**  ==   1.0   -   1.1     illegal  (first range octet must be at least 1 higher)
- 192.168.1.0-**3.230**  == 1.0   -   3.230   legal (first range octet is at least 1 higher)

if three entered:
- 192.168.200.210-**168.200.215**  ==   168.200.210   - 168.200.215   illegal  (first range octet must be at least 1 higher)
- 192.168.230.254-**200.0.1**  ==   168.230.254   -   200.0.1       legal (first range octet is at least 1 higher)


***NOTE**<br>
Range pinging does not discriminate against any IPv4 address. Be careful.
