Param(
    [Parameter(Mandatory=$True)]
    [string]$sourceFile,
    
    [Parameter(Mandatory=$True)]
    [string]$destinationFile
)

Function Deduplicate {
    param(
        [Array]$dups,
        [System.Collections.ArrayList]$contacts,
        [System.Collections.ArrayList]$deduppedContacts       
    )
    if ($dups)
    {
        $timeStart = Get-Date

        $contact = $dups[0]
        #Check for same data on all duplicates
        $propSize = New-Object Collections.Generic.List[Int]
        $dups | ForEach-Object {
            $dup = $_
            $dup.PSObject.Properties | ForEach-Object {
                [void]$propSize.Add($_.Length)
            }
        }
        $propSizeDiff = $propSize | Where-Object { $_ -ne $propSize[0] }
        if ($propSizeDiff) {
            #TBD - Merging
            $dups | Out-File merge-me-$(Get-Random).json
            Write-Warning "Found mismatch on $($contact.'First Name') $($contact.'Last Name') (Title: $($contact.'Title')) with Mobile Phone $($contact.'Mobile Phone') and E-Mail $($contact.'E-mail Address')"
        }
        Write-Verbose "Found $($dups.Count) duplicates for $($contact.'First Name') $($contact.'Last Name') (title: $($contact.'Title')) with mobile phone $($contact.'Mobile Phone') and e-mail $($contact.'E-mail Address')"
    }
    $dups | ForEach-Object {
        [void]$contacts.Remove($_)
    }
    [void]$deduppedContacts.Add($contact)

    $timeEnd = Get-Date
    $timeElapsed = $timeEnd-$timeStart
    Write-Verbose "Needed $($timeElapsed.Seconds) seconds to analyze contact $($contact.'First Name') $($contact.'Last Name') (Title: $($contact.'Title')) with Mobile Phone $($contact.'Mobile Phone') and E-Mail $($contact.'E-mail Address')"
    Write-Host "Scanned $($i)/$($contacts.Count) contacts"

    return $contacts
}

Clear-Host
Write-Host "Parsing source csv file $($sourceFile)"
[System.Collections.ArrayList]$contacts = Get-Content $sourceFile | ConvertFrom-CSV
Write-Host "Found $($contacts.Count) contacts"

$timeStart = Get-Date
[System.Collections.ArrayList]$deduppedContacts = @()
$i=0
while ($contacts.count -gt 0)
{
        $contact = $contacts[$i]
        [Array]$dups = $contacts | Where-Object { $_.'First Name' -eq $contact.'First Name' -and $_.'Last Name' -eq $contact.'Last Name' -and $_.'Mobile Phone' -eq $contact.'Mobile Phone' -and $_.'Title' -eq $contact.'Title' -and $_.'E-mail Address' -eq $contact.'E-mail Address'  }

        $inputContactsCount = $contacts.Count
        $contacts = Deduplicate -dups $dups -contacts $contacts -deduppedContacts $deduppedContacts
	if ($inputContactsCount -eq $contacts.Count) { break }
        $i++
}

$timeEnd = Get-Date
$timeElapsed = $timeEnd-$timeStart
Write-Verbose "Needed $($timeElapsed.Seconds) seconds to analyze $($contacts.Count) contacts"

$deduppedContacts | ConvertTo-Csv | Out-File $destinationFile
Write-Host "Dedupped $($contacts.Count) contacts to $($deduppedContacts.Count) contacts"
