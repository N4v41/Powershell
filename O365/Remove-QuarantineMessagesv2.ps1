function Remove-QuarantineMessages {
    param (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)][ValidateSet('spam','bulk','phish','transportrule','malware')]
        $Type = $null,
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)][ValidateSet('Realease and Delete','Delete')]
        $Action,
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=3)]
        $SenderAddress = $null,
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=4)]
        $Subject = $null,
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=5)]
        $MessageId = $null,
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=6)][ValidateSet('True','False')]
        $GetMessages = 'False'
    )


    #Variaveis de inicio do Script
    $i = 0

#pega todas as mensagens da quarentena
if ($Getmessages -eq 'True'){
$pagen = 1
$QuarantineMessages = Get-QuarantineMessage -PageSize 1000 -Page $pagen
Do{
$pagen++
$QuarantineMessages += Get-QuarantineMessage -PageSize 1000 -Page $pagen
Write-Output $QuarantineMessages.count
}while( $QuarantineMessages.Count -eq ($pagen * 1000))
$QuarantineMessages | Export-Clixml C:\temp\var\QuarantineMessages.xml
}else{$QuarantineMessages = Import-Clixml C:\temp\var\QuarantineMessages.xml}

$QMessagesrun = $QuarantineMessages
$QMessagessave = $QuarantineMessages
#Testa se existem filtros de remetente e assunto e message Id
if ($null -ne $Type ){
    $QMessagesrun = $QMessagesrun | Where-Object QuarantineTypes -EQ $Type
$QMessagessave = $QMessagessave | Where-Object QuarantineTypes -ne $Type  
}

#filtra por remetente
if($null -ne $SenderAddress){
    $QMessagesrun = $QMessagesrun | Where-Object SenderAddress -match $SenderAddress
$QMessagessave = $QMessagessave | Where-Object SenderAddress -notmatch $SenderAddress
}

#filtra pelo assunto
if($null -ne $Subject){
    $QMessagesrun = $QMessagesrun | Where-Object Subject -match $Subject
$QMessagessave = $QMessagessave | Where-Object Subject -notmatch $Subject
}

#se o filtro de MessageId for definido filtra apenas essa propriedade
if($null -ne $MessageId){
    $QMessagesrun = $QMessagesrun | Where-Object MessageId -match $MessageId
$QMessagessave = $QMessagessave | Where-Object MessageId -notmatch $MessageId
}

$Ids = $QMessagesrun | Select-Object -ExpandProperty Identity

$Progresstotal = $Ids.count

Foreach ($mail in $Ids){
Write-Progress -Activity $Action -Status "Progress $i of $Progresstotal" -PercentComplete ($i/$Progresstotal*100)
if ($Action -eq 'Realease and Delete'){Release-QuarantineMessage -Identity $mail -ReleaseToAll -confirm:$false}
Delete-QuarantineMessage -Identity $mail -confirm:$false
$i += 1
}
if ($null -eq $Type){ $Type = "Todas as categorias"}
Write-Output "Processo Finalizado  ($i de $Progresstotal)  mensagens  ( $Action )  processados em  ( $Type )"

$QMessagessave | Export-Clixml C:\temp\var\QuarantineMessages.xml
}