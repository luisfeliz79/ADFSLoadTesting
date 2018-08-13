###############################################################
#
#This Sample Code is provided for the purpose of illustration only
#and is not intended to be used in a production environment.  THIS
#SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED AS IS
#WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
#INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
#MERCHANTABILITY ANDOR FITNESS FOR A PARTICULAR PURPOSE.  We
#grant You a nonexclusive, royalty-free right to use and modify
#the Sample Code and to reproduce and distribute the object code
#form of the Sample Code, provided that You agree (i) to not use
#Our name, logo, or trademarks to market Your software product in
#which the Sample Code is embedded; (ii) to include a valid
#copyright notice on Your software product in which the Sample
#
#Code is embedded; and (iii) to indemnify, hold harmless, and
#defend Us and Our suppliers from and against any claims or
#lawsuits, including attorneys’ fees, that arise or result from
#the use or distribution of the Sample Code.
#Please note None of the conditions outlined in the disclaimer
#above will supersede the terms and conditions contained within
#the Premier Customer Services Description.
#
###############################################################



##########################################################################
# 
# ADFSTLoadTesting.ps1
# By Luis Feliz
# v1.1 BETA
#
# Function Invoke-ADFSSecurityTokenRequest Based on Josh Gavant's original work
# https://blogs.msdn.microsoft.com/besidethepoint/2012/10/17/request-adfs-security-token-with-powershell/
#
# 
# A basic approach for load testing of AD FS
#
# Notes: This testing method has not been officialy approved by Microsoft.
#        This will not work with Certificate auth
#        This will not work with Multi-Factor authentication
# 
# Calculation is 
#   Total number of tokens received (Success) / time ($howlonginseconds)
#
#
# 
#
############################################################################################################

param(


    #The AD FS Url
    [Parameter(mandatory=$true)]$ADFSUrl,
    
    #The RP or RPs to attempt authentications against. CASE SENSTIVE!
    $RPs=@("urn:federation:MicrosoftOnline"),

    #The number of seconds the script will continously attempt authentications
    $HowLongInSeconds=30,

    # In order to push the server the hardest, adjust the number of Jobs to run simulteniously
    # Increase this number until the server is hitting ~ 90-99% CPU
    $Jobs=8,

    #Set this to $true if you wish to use Kerberos instead
    #The Credentials parameter will be ignored unless you set this to $false
    $Kerberos=$False,

    # One or more sets of user/pass to use for auth
    # user accounts will be chosen at random during
    # each authentication

    $Credentials,


    # A file where Token request failures and errors will be saved to
    $ErrorsFileName="TokenErrors.txt",

    [Parameter()][ValidateSet('tls1.0','tls1.1','tls1.2')] $TLSMode="tls1.2"

    )

#validate ADFSURL
if ($adfsurl -notlike "*https://*") {$ADFSUrl="https://$ADFSUrl"}

#Some credential validation, first ask, and then check again just in case of cancel
if ((-not $Kerberos) -and ($Credentials.count -lt 1)) {$($Credentials=@();$count=0;do { $count=$Credentials.count;$Credentials+=Get-Credential -Message "Enter Credentials #$($count+1)$([char]13)$([char]10)Username should be in DOMAIN\User format$([char]13)$([char]10)Click CANCEL when done"} until ($Credentials.count -eq $count))}
if ((-not $Kerberos) -and ($Credentials.count -lt 1)) {"No credentials specified.  Provide credentials, or set Kerberos=$true";break } 

#TLS mode
switch ($TLSMode) {
"tls1.2" {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12}
"tls1.1" {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls11}
"tls1.0" {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls}
}


##########################################################################
# 
# This script has 3 sections
#    1) The main loop, which controls the jobs
#    2) The Program code.  This is code each job will run
#    3) The code for reporting the results
#
##########################################################################



#region Main Loop
$LTJobs=@()

Write-host "AD FS Load Testing"
Write-host "------------------------------------`n"
Write-host "Farm URL: $ADFSURL"
Write-host "Using " -nonewline;write-host "$jobs" -ForegroundColor cyan -NoNewline;write-host " job(s), running for " -NoNewline
write-host "$HowLongInSeconds" -ForegroundColor cyan -NoNewline;write-host " second(s) each"
Write-host "Using " -NoNewline;$(if ($Kerberos) {write-host "Kerberos" -ForegroundColor cyan -nonewline} else {write-host "$($Credentials.count) accounts for" -Foregroundcolor cyan -nonewline})
write-host " authentication"
write-host "TLS Mode: $tlsmode"
write-host "Against these RPs: $RPs`n"



foreach ($i in 1..$jobs) {

write-host "Starting Job $i"

    #region ProgramCode
    $ProgramCode = {

            param(
            $ADFSURL,
            $HowLongInSeconds,
            $RPs,
            $Credentials,
            $Kerberos,
            $ErrorsFileName
            )


            ##########################################################################
            # 
            # Function Invoke-ADFSSecurityTokenRequest
            #    Based on Josh Gavant's script
            #    https://blogs.msdn.microsoft.com/besidethepoint/2012/10/17/request-adfs-security-token-with-powershell/
            #     
            #    Gets SAML tokens using Kerberos or Username authentication
            #
            ##########################################################################
                        
            function Invoke-ADFSSecurityTokenRequest {
            param(
                [Parameter()][ValidateSet('Kerberos','UserName')] $ClientCredentialType,
                [Parameter()] $ADFSBaseUri,
                [Parameter()] $AppliesTo,
                [Parameter()] $Username,
                [Parameter()] $Password,
                [Parameter()][ValidateSet('1','2')] $SAMLVersion = 1,
                [Parameter()][ValidateSet('Token','RSTR')] $OutputType = 'Token',
                [Parameter()][Switch] $IgnoreCertificateErrors
            )

            #Load needed .NET types
            Add-Type -AssemblyName 'System.ServiceModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
            Add-Type -AssemblyName 'System.IdentityModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'

 


            $ADFSTrustPath = 'adfs/services/trust/2005'
            $SecurityMode = 'TransportWithMessageCredential'

            $ADFSBaseUri = $ADFSBaseUri.TrimEnd('/')


            #Kerberos vs Username auth, different endpoints and methods
            switch ($ClientCredentialType) {
                'Kerberos' {
                    $MessageCredential = 'Windows'
                    $ADFSTrustEndpoint = 'windowstransport'
                    $Binding = new-object -typename System.ServiceModel.WShttpbinding -ArgumentList ([System.ServiceModel.BasicHttpsSecurityMode] $SecurityMode)
                    $Binding.Security.Transport.ClientCredentialType = $MessageCredential
                    $EP = New-Object -TypeName System.ServiceModel.EndpointAddress -ArgumentList ('{0}/{1}/{2}' -f $ADFSBaseUri,$ADFSTrustPath,$ADFSTrustEndpoint)
                    $WSTrustChannelFactory = New-Object -TypeName System.ServiceModel.Security.WSTrustChannelFactory -ArgumentList $Binding, $EP
                    $WSTrustChannelFactory.TrustVersion = [System.ServiceModel.Security.TrustVersion]::WSTrustFeb2005
                    $WSTrustChannelFactory.Credentials.Windows.ClientCredential = [System.Net.CredentialCache]::DefaultNetworkCredentials
                    $WSTrustChannelFactory.Credentials.Windows.AllowedImpersonationLevel = [System.Security.Principal.TokenImpersonationLevel]::Impersonation
                }
                'UserName' {
                    $MessageCredential = 'UserName'
                    $ADFSTrustEndpoint = 'usernamemixed'
                    $Binding = New-Object -TypeName System.ServiceModel.WS2007HttpBinding -ArgumentList ([System.ServiceModel.SecurityMode] $SecurityMode)
                    $Binding.Security.Message.EstablishSecurityContext = $false
                    $Binding.Security.Message.ClientCredentialType = $MessageCredential
                    $Binding.Security.Transport.ClientCredentialType = 'None'
                    $EP = New-Object -TypeName System.ServiceModel.EndpointAddress -ArgumentList ('{0}/{1}/{2}' -f $ADFSBaseUri,$ADFSTrustPath,$ADFSTrustEndpoint)
                    $WSTrustChannelFactory = New-Object -TypeName System.ServiceModel.Security.WSTrustChannelFactory -ArgumentList $Binding, $EP
                    $WSTrustChannelFactory.TrustVersion = [System.ServiceModel.Security.TrustVersion]::WSTrustFeb2005
                    $Credential = New-Object System.Net.NetworkCredential -ArgumentList $Username,$Password
                    $WSTrustChannelFactory.Credentials.Windows.ClientCredential = $Credential
                    $WSTrustChannelFactory.Credentials.UserName.UserName = $Credential.UserName
                    $WSTrustChannelFactory.Credentials.UserName.Password = $Credential.Password

                }
            }

            $Channel = $WSTrustChannelFactory.CreateChannel()


            $TokenType = @{
                SAML11 = 'urn:oasis:names:tc:SAML:1.0:assertion'
                SAML2 = 'urn:oasis:names:tc:SAML:2.0:assertion'
            }

            $RST = New-Object -TypeName System.IdentityModel.Protocols.WSTrust.RequestSecurityToken -Property @{
                RequestType   = [System.IdentityModel.Protocols.WSTrust.RequestTypes]::Issue
                AppliesTo     = $AppliesTo
                KeyType       = [System.IdentityModel.Protocols.WSTrust.KeyTypes]::Bearer
                TokenType     = if ($SAMLVersion -eq '2') {$TokenType.SAML2} else {$TokenType.SAML11}
            }
 
            #Request the Token
            $RSTR = New-Object -TypeName System.IdentityModel.Protocols.WSTrust.RequestSecurityTokenResponse

            try {
                $OriginalCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
                if ($IgnoreCertificateErrors.IsPresent) {[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {return $true}}
                $Token = $Channel.Issue($RST, [ref] $RSTR)
            }
            finally {
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OriginalCallback
            }

            $Token

            }

            ##########################################################################
            # 
            # Continously calls the Invoke-ADFSSecurityTokenRequest function, for the
            # period of time specified, against the RPs specified, and using the 
            # user accounts specified
            #
            ##########################################################################

            $RPs | % {
                $Counter=0
                $Bad=0
                $TimeStart = Get-Date
                $TimeEnd = $timeStart.AddSeconds($HowLongInSeconds)
                $RPName=$_
          

                Do { 
                 $TimeNow = Get-Date
                 if ($TimeNow -ge $TimeEnd) {

                   New-Object psobject -Property ([ORDERED]@{
   
                       "RelyingPartyTrust"=$_
                       "Request"=$(if(($counter-$bad) -eq 0) {0} else {($Counter-$Bad)/$HowLongInSeconds})
                       "Failed"=$Bad
                       "Success"=$Counter-$Bad
                       "Total"=$Counter
                       "FailedMessage"=$FailMessage
    
                   })

                
                 } else {
                

  
                  $Counter++

                  try {


                    if ($Kerberos) { 
                        $AuthType='Kerberos'
                        } 
                    else {
                        $AuthType='UserName'
                        $Random=$(get-random -Maximum $Credentials.count -Minimum 0)
                        $Creds=@{
                            Username=($Credentials[$Random]).username
                            Password=($Credentials[$Random]).password

                    }
                    }

    
                    Invoke-ADFSSecurityTokenRequest `
                    -ClientCredentialType $AuthType `
                    -ADFSBaseUri $ADFSURL `
                    -AppliesTo $_ `
                    -UserName $Creds.UserName `
                    -Password  $Creds.Password `
                    -OutputType Token `
                    -SAMLVersion 2 `
                    -IgnoreCertificateErrors 
                    }
                    catch {
                    $Bad++
                    $FailMessage="--------------------------------------------------------------------" 
                    $FailMessage+=$creds.username 
                    $FailMessage+=$error[0] 
                    $FailMessage+=$RPName 
                   
                    }
 
                 }

                }
                Until ($TimeNow -ge $TimeEnd)
                } #RPs

       } # End Program Code 
    #endregion

$LTJobs+=start-job -ScriptBlock $ProgramCode -ArgumentList $ADFSURL, $HowLongInSeconds,$RPs,$Credentials, $Kerberos,$ErrorsFileName

} # End Main Loop
#endregion


#region Report


##########################################################################
# 
# Tally up the authentications count, and failures, and presents as 
# a powershell object
#
##########################################################################

$WhenStart = Get-Date
$ETA = $WhenStart.AddSeconds($HowLongInSeconds+($jobs*4.5))


Write-host "`nEstimated completion time: $ETA `n`nRunning ..."

start-sleep $HowLongInSeconds

    Do {
    $JobsPending=$false
    $JobCount=0
        $LTJobs | % {
            if ((Get-job $_.id).State -ne "Completed") { $JobsPending=$true;$JobCount++ }
        } 
    start-sleep 5
    "Waiting for $Jobcount job(s) to complete ..."
    }
    Until ($JobsPending -eq $false)


$JobResults=Receive-job $LTJobs
Remove-Job $LTJobs

#Calculate Totals

    $JobReport=New-Object psobject -Property ([ORDERED]@{
   
        "RelyingPartyTrust"="Total"
        "Request"=($JobResults | Measure Request -Sum).sum
        "Failed"=($JobResults | Measure Failed -Sum).sum
        "Success"=($JobResults | Measure Success -Sum).sum
        "Total"=($JobResults | Measure Total -Sum).sum
    
    })

$JobResults.failedmessage | out-file $ErrorsFileName

$JobReport | ft RelyingPartyTrust,@{l="Tokens Per Second";e={($_.Request).tostring("#.##")}},Failed,Total

#endregion


