# ADFSLoadTesting.ps1
 By Luis Feliz
 v1.1 BETA

 Function Invoke-ADFSSecurityTokenRequest Based on Josh Gavant's original work
 https://blogs.msdn.microsoft.com/besidethepoint/2012/10/17/request-adfs-security-token-with-powershell/
<br>
 A basic approach for load testing of AD FS
<br>
 Notes: This testing method has not been officialy approved by Microsoft.
        This will not work with Certificate auth
        This will not work with Multi-Factor authentication
 <br>
 Calculation is 
   Total number of tokens received (Success) / time ($howlonginseconds)
<br>
   <br>
 How to use it:
 <br>
 .\ADFSLoadTesting.ps1 -ADFSUrl https://sts.contoso.com
 <br>
 Other Parameters
 <br>
   <b>RPs</b>
  <br> 
   One or more Relaying part trusts identifiers to test against.
   Default is urn:federation:MicrosoftOnline
  <br> 
   <b>HowLongInSeconds</b>
 <br>  
   Amount of time to test for. Default is 30 seconds
 <br>  
   <b>Jobs</b>
  <br> 
   Number of Jobs to run when testing. Default is 8 jobs
  <br> 
   Note: In order to push the server the hardest, adjust the number of Jobs to run simulteniously
   Increase this number until the server is hitting ~ 90-99% CPU
 <br>  
   <b>Kerberos</b> $true|$false
  <br> 
   Set this to $true if you wish to use Kerberos authentication.  Default is $false
   When this setting is $false, the Credentials parameter will be ignored.
 <br>  
   <b>Credentials</b>
  <br> 
   One or more sets of credentials to use for authentication. Default is to ask for Credentials.
   When multiple credentials are specified, the script will choose at random for each authentication.
<br>
   <b>TLSMode</b>
 <br>
   The TLS mode to use. Valid input is tls1.0, tls1.1 or tls1.2.  Default is tls1.2
 <br>
 
 
 
 
 

 


A PowerShell script that will provide you the Regex syntax for matching an IP range

To use this script:

To get regex syntax for a Single IP:<br>
&nbsp;&nbsp;&nbsp;.\IPrangeRegex.ps1 -IPRange 192.168.10.1
<br><br>
To get regex syntax for a range in format startrange-endrange<br>
&nbsp;&nbsp;&nbsp;.\IPrangeRegex.ps1 -IPRange 192.168.10.0-192.168.10.255
<br><br>
To get Regex syntax for a range in CIDR Format<br>
&nbsp;&nbsp;&nbsp;.\IPrangeRegex.ps1 -IPRange 192.168.10.0/21
<br><br>
Note: Subnet masks < 19 may take some time to calculate. 

