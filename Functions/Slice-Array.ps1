#Function to slice arrays into a subset of arrays
function Slice-Array
{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$True)]
        [String[]]$Item,
        [int]$Size=10
    )
    BEGIN { $Items=@()}
    PROCESS {
        foreach ($i in $Item ) { $Items += $i }
    }
    END {
        0..[math]::Floor($Items.count/$Size) | ForEach-Object { 
            $x, $Items = $Items[0..($Size-1)], $Items[$Size..$Items.Length]; ,$x
        } 
    }
}