$instancenumber = Read-Host -Prompt  "Digite o numero da Instancia"
$ResourceGroupName = "kali" + $instancenumber
Remove-AzureRmResourceGroup -Name $ResourceGroupName