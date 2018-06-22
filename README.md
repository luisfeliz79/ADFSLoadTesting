# ADFSLoadTesting.ps1
 By Luis Feliz
 v1.1 BETA

 Portions based Josh Gavant's original work
 https://blogs.msdn.microsoft.com/besidethepoint/2012/10/17/request-adfs-security-token-with-powershell/
 <br>
 <br>
 A basic approach for load testing of AD FS
<br>
 <b>Notes:</b> This testing method has not been officialy approved by Microsoft.<br>
        This will not work with Certificate auth<br>
        This will not work with Multi-Factor authentication<br>
 <br>
 Calculation is 
   Total number of tokens received (Success) / time ($howlonginseconds)
   <br>
   <br>
 How to use it:
 <br>
 .\ADFSLoadTesting.ps1 -ADFSUrl https://sts.contoso.com
 <br><br>
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
 
 
 
 
 

 


