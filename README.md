# ADFSLoadTesting.ps1

 A basic approach for load testing of AD FS<br>
 <br>
 By Luis Feliz
 v1.1 BETA

 Portions based on Josh Gavant's original work<br>
 https://blogs.msdn.microsoft.com/besidethepoint/2012/10/17/request-adfs-security-token-with-powershell/
 <br>
<br>
 <b>Notes:</b><br>
        This testing method has not been officialy approved by Microsoft.<br>
        This will not work with Certificate auth<br>
        This will not work with Multi-Factor authentication<br>
 <br>
<br>
 <b>How to use it:</b>
 <br><br>
 .\ADFSLoadTesting.ps1 -ADFSUrl https://sts.contoso.com
 <br><br>
 <b>Available Parameters:</b><br>
 <br>
   <b>RPs</b>
  <br> 
   One or more Relaying part trusts identifiers to test against.
   <br>Default is urn:federation:MicrosoftOnline
  <br> <br>
   <b>HowLongInSeconds</b><br>
   Amount of time to test for.<br>Default is 30 seconds
 <br>  
   <b>Jobs</b>
  <br> 
   Number of Jobs to run when testing.<br>Default is 8 jobs
 <br><br>
   <b>Note:</b> In order to push the server the hardest, adjust the number of Jobs to run simulteniously
   Increase this number until the server is hitting ~ 90-99% CPU
 <br>  
   <b>Kerberos</b>
 <br>
   Set this to $true if you wish to use Kerberos authentication.<br>Default is $false<br>
   When this setting is $false, the Credentials parameter will be ignored.
 <br>  
   <b>Credentials</b>
 <br>
   One or more sets of credentials to use for authentication.<br>Default is to ask for Credentials.<br>
   When multiple credentials are specified, the script will choose at random for each authentication.<br>
 <br>
   <b>TLSMode</b>
 <br>
   The TLS mode to use. Valid input is tls1.0, tls1.1 or tls1.2.<br>Default is tls1.2
 <br>
 
 
 
 
 

 


