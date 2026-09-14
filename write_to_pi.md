





scp -r fc_version_2-0 axel@192.168.137.22:Drone_Integration_Program/

## How to set up direct ethernet connection with raspberry pi

### Step 1: Set up subnet between PC and Pi.

Type windows + R and search `ncpa.cpl`



Click on your Wi-Fi connection and go to Properties->Sharing and check 'allow users to connect to this device through network sharing'.



From the dropdown menu just below select the Ethernet channel corresponding to the connection to the Pi (for me it was Ethernet 6).

Your PC now acts as a default gateway for the Pi through the usage of a subnet. For me this subnet was 192.168.137.0/24

An easy way to find the pi's IP address is to nmap the subnet. For me, the command was:
```Bash
nmap -sn 192.168.137.0/24
```

Obviously nmap must be installed to do this, so install it on Windows if you haven't already.

Then you can SSH to the pi directly through the IP address in Powershell.

### Step 2: Set up Mirrored Networking on WSL

The thing about WSL is that it connects via its own virtual network interface. It's great for connecting to the internet but the problem is it doesn't have access to your PCs direct Ethernet connections.

This can be fixed with mirrored networking. To enable it, in Powershell run

```PowerShell
notepad $env:USERPROFILE\.wslconfig
```

Then in the notepad paste this text

```
[wsl2]
networkingMode=mirrored
```

After that restart WSL with

```PowerShell
wsl --shutdown
wsl
```

Then test that it works by trying to SSH to the Pi from WSL. Hopefully it does :).