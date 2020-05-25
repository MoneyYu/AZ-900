Install-WindowsFeature -name Web-Server -IncludeManagementTools

New-NetFirewallRule –DisplayName "Allow ICMPv4-In" –Protocol ICMPv4