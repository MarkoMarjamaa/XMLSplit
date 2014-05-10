
param([string]$source_file = "foo", [long]$records="10", [string]$element_name = "bar")
#,[string]$prefix_file = "bar", [string]$postfix_file = "bar"
# source_file
# records
# prefix_file
# postfix_file
 
$ErrorActionPreference = "Stop"
 
Write-Host "Num Args: $($args.Length)";
Write-Output $source_file $records $element_name
# $prefix_file $postfix_file
 
Write-Host "Opening source file and seeking prefix"
if(Test-Path "$($source_file).PreFix.xml"){
  Remove-Item "$($source_file).PreFix.xml"
}
$line = $null
# Open file
$reader = [System.IO.File]::OpenText($source_file)
# first read prefix
try {
    for(;;) {
        # read new line
        if ($line -eq $null) {
            $line = $reader.ReadLine()
            if ($line -eq $null) {
                # End of file
                break
            }
        }
        # process the line
        if($line.Contains("<$($element_name)>")){
            Write-Host "First element found"
            $pos = $line.IndexOf("<$($element_name)>")
            $StartOfLine = $line.Substring(0, $pos)
            $line = $line.Substring($pos)
 
            try
                {
                    Add-Content "$($source_file).PreFix.xml" "$($StartOfLine)" -Encoding UTF8
                }
                catch
                {
                   Add-Content -path "$($source_file).Errors.log" -value $_.Exception
                   Add-Content -path "$($source_file).Errors.log" -value $_.Exception.Message
                }
           
            break;
        } else {
            try
                {
            Add-Content "$($source_file).PreFix.xml" "$($line)" -Encoding UTF8
                }
                catch
                {
                   Add-Content -path "$($source_file).Errors.log" -value $_.Exception
                   Add-Content -path "$($source_file).Errors.log" -value $_.Exception.Message
                }
            $line =$null
        }
    }
}
finally {
#    $reader.Close()
}
Write-Host "Prefix file created"
 
# Make first file name
[long]$filenumber = 0;
$DestFileName = "$($source_file).$("{0:D4}" -f $filenumber).xml" 
if(Test-Path $DestFileName){
    Remove-Item $DestFileName
}
# Add Prefix to first file
Write-Host "Starting new output file $($DestFileName)"
Get-Content "$($source_file).PreFix.xml" | %{
    try
        {
          Add-Content $DestFileName $_  -Encoding UTF8
        }
        catch
        {
           Add-Content -path "$($source_file).Errors.log" -value $_.Exception
           Add-Content -path "$($source_file).Errors.log" -value $_.Exception.Message
        }
}
 
[long]$ElementNr =0;
 
try {
    for(;;) {
        # read new line
        if ($line -eq $null) {
            $line = $reader.ReadLine()
            if ($line -eq $null) {
                # End of file
                break
            }
        }
        # process the line
        if($line.Contains("</$($element_name)>")){
            $pos = $line.IndexOf("</$($element_name)>") + "</$($element_name)>".Length
            #Write-Host "Line:$line"
            #Write-Host "Line:$($line.Length)"
            #write-Host "Position:$pos"
            if ($pos -eq $line.Length ){
                $StartOfLine = $line
                $line = $null
            }
            else {
                $StartOfLine = $line.Substring(0, $pos)
                $line = $line.Substring($pos)
            }
            try
                {
                  Add-Content "$($DestFileName)" "$($StartOfLine)" -Encoding UTF8
                }
                catch
                {
                   write-host "----------------------------------------------------------------------------------------------------------------"
                   Add-Content -path "$($source_file).Errors.log" -value $_.Exception
                   Add-Content -path "$($source_file).Errors.log" -value $_.Exception.Message
                }
            $ElementNr += 1;
            Write-Host "Element read:$($ElementNr)"
           
            if(($ElementNr % $records ) -eq 0 ){
                # Add end of file
                Get-Content "$($source_file).PostFix.xml" | %{
                    try
                        {
                          Add-Content $DestFileName $_  -Encoding UTF8
                        }
                        catch
                        {
                   write-host "----------------------------------------------------------------------------------------------------------------"
                           Add-Content -path "$($source_file).Errors.log" -value $_.Exception
                           Add-Content -path "$($source_file).Errors.log" -value $_.Exception.Message
                        }
                }
                $filenumber += 1;
                $DestFileName = "$($source_file).$("{0:D4}" -f $filenumber).xml" 
                if(Test-Path $DestFileName){
                    Remove-Item $DestFileName
                }
               
                # Add Prefix to first file
                Write-Host "Starting new output file $($DestFileName)"
                Get-Content "$($source_file).PreFix.xml" | %{
                    try
                        {
                          Add-Content $DestFileName $_  -Encoding UTF8
                        }
                        catch
                        {
                   write-host "----------------------------------------------------------------------------------------------------------------"
                           Add-Content -path "$($source_file).Errors.log" -value $_.Exception
                           Add-Content -path "$($source_file).Errors.log" -value $_.Exception.Message
                        }
                }
            }
        } else {
            try
                {
                  Add-Content "$($DestFileName)" "$($line)" -Encoding UTF8
                }
                catch
                {
                   write-host "----------------------------------------------------------------------------------------------------------------"
                   Add-Content -path "$($source_file).Errors.log" -value $_.Exception
                   Add-Content -path "$($source_file).Errors.log" -value $_.Exception.Message
                }
            $line =$null
        }
    }
}
finally {
#    $reader.Close()
}
 
$reader.Close()
