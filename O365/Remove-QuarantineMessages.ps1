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
        $SenderAddress = $null, #This parameter define expression to handle in the sender Addresses in the action selected
        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$false,
        Position=4)]
        $Subject = $null #This parameter define expression to match in the subject value
    )
    #Variable of the counter
    $i = 1

#Process
#Get the messages from quarantine and put in the variable $Emails with a limitation of 3000 e-mails
    $Emails = Get-QuarantineMessage -Type $Type -PageSize 1000 -Page 1
if ($Emails.count -eq 1000){$Emails += Get-QuarantineMessage -Type $Type -PageSize 1000 -Page 2}
if ($Emails.count -eq 2000){$Emails += Get-QuarantineMessage -Type $Type -PageSize 1000 -Page 3}

#Filter the e-mails acoarding to the filters
# If the neither the sender and the subject are defined all the messages of that type are selected
if ($null -eq $SenderAddress -and $null -eq $Subject){$Ids = $emails | Select-Object -ExpandProperty Identity}
#If the sender addres is defined and the subject isn't select the messages that matches the sender filter
elseif($null -ne $SenderAddress -and $null -eq $Subject){$Ids = $emails | Where-Object SenderAddress -match $SenderAddress | Select-Object -ExpandProperty Identity}
#If the subject is defined and the sender isn't select the messages that matches the Subject filter 
elseif($null -ne $Subject -and $null -eq $SenderAddress){$Ids = $emails | Where-Object Subject -match $Subject | Select-Object -ExpandProperty Identity}
#If both the filters are defined select the messages accoarding to the sender addres filter and after filter according to the subject
else{$Ids = $emails | Where-Object SenderAddress -match $SenderAddress | Where-Object Subject -match $Subject  | Select-Object -ExpandProperty Identity}
#Define the variable with the total amount of processing e-mails to show the progress
$Progresstotal = $Ids.count

#Structure for loop in each e-mail
Foreach ($mail in $Ids){
#Command to show the progress of the action
Write-Progress -Activity $Action -Status "$i of $Progresstotal" -PercentComplete ($i/$Progresstotal*100)
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