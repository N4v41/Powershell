#Simple funcion to translate Folder ID acquired in exchange to the format accepted in E-discovery
function Encode-FID ($Id)
{
    $fid = $Id
    $fid = [Convert]::FromBase64String($fid)
    $encoding = [System.Text.Encoding]::GetEncoding("us-ascii")
    $nibbler = $encoding.GetBytes("0123456789ABCDEF")
    $indexIdBytes = New-Object byte[] 48;$indexIdIdx=0;
    $fid | select -Skip 23 -First 24 | % { $indexIdBytes[$indexIdIdx++] = $nibbler[$_ -shr 4]; $indexIdBytes[$indexIdIdx++] = $nibbler[$_ -band 0xf]}
    return $encoding.GetString($indexIdBytes)  
}
