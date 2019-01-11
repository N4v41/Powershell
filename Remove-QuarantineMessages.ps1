#this is a function to handle quarantine messages in mass
function Remove-QuarantineMessages {
    param (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)][ValidateSet('spam','bulk','phish','transportrule')]
        $Type,#this parameter passes the quarantine mode you want to manage
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)][ValidateSet('Realease and Delete','Delete')]
        $Action,#Difine the Action you want to do, only delete the messages or release them First
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=3)]
        $SenderAddress = $null #This parameter define a unique sender Address to act in
    )
    #Variable of the counter
    $i = 1

#Process
#Get the messages from quarantine and put in the variable $Emails with a limitation of 3000 e-mails
    $Emails = Get-QuarantineMessage -Type $Type -PageSize 1000 -Page 1
if ($Emails.count -eq 1000){$Emails += Get-QuarantineMessage -Type $Type -PageSize 1000 -Page 2}
if ($Emails.count -eq 2000){$Emails += Get-QuarantineMessage -Type $Type -PageSize 1000 -Page 3}

#Filter the e-mails by the Sender addres if this parameter was used and get the property to handle the actions and put in the variable $Ids
if ($SenderAddress -eq $null){$Ids = $emails | select -ExpandProperty Identity}
else{$Ids = $emails | Where SenderAddress -eq $SenderAddress | select -ExpandProperty Identity}

#Define the variable with the total amount of processing e-mails to show the progress
$Progresstotal = $Ids.count

#Structure for loop in each e-mail
Foreach ($mail in $Ids){
#Command to show the progress of the action
Write-Progress -Activity "Processing Messages" -Status "$i of $Progresstotal" -PercentComplete ($i/$Progresstotal*100)
#Release the message first if the parameter to release the messages first was used
if ($Action -eq 'Realease and Delete'){Release-QuarantineMessage -Identity $mail -ReleaseToAll -confirm:$false}
#Delete the message from quarantine
Delete-QuarantineMessage -Identity $mail -confirm:$false
#Increase the couter variable
$i += 1
}
#Write an end message
Write-Output "Process Ended $i of $Progresstotal Messages Processed"
}
