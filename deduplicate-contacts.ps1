Param(
    [Parameter(Mandatory=$True)]
    [string]$sourceFile,
    
    [Parameter(Mandatory=$True)]
    [string]$destinationFile,

    [Parameter(Mandatory=$False)]
    [string]$threads = 15
    )

Clear-Host
Write-Host "Parsing source csv file $($sourceFile)"
$contacts = Get-Content $sourceFile | ConvertFrom-CSV
Write-Host "Found $($contacts.Count) contacts"

$timeStart = Get-Date
$completedContacts = New-Object Collections.Generic.List[PSObject]
$deduppedContacts = New-Object Collections.Generic.List[PSObject]
$contacts = $contacts | Where-Object { $_ -notin $completedContacts }
$i = 0
$contacts | ForEach-Object -Parallel {
    $timeStart = Get-Date

    $i = $using:i
    $contacts = $using:contacts
    $completedContacts = $using:completedContacts
    $deduppedContacts = $using:deduppedContacts
    $contact = $_

    $i++
    if ($completedContacts -contains $contact) { continue }
    #Check for duplicates
    [Array]$dups = $contacts | Where-Object { $_.'First Name' -eq $contact.'First Name' -and $_.'Last Name' -eq $contact.'Last Name' -and $_.'Mobile Phone' -eq $contact.'Mobile Phone' -and $_.'Title' -eq $contact.'Title' -and $_.'E-mail Address' -eq $contact.'E-mail Address'  }
    if ($dups.Count -gt 1)
    {
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
        $dups | ForEach-Object {
            [void]$completedContacts.Add($_)
        }
    }
    else { [void]$completedContacts.Add($dups) }
    [void]$deduppedContacts.Add($dups[0])
    
    $timeEnd = Get-Date
    $timeElapsed = $timeEnd-$timeStart
    Write-Verbose "Needed $($timeElapsed.Seconds) seconds to analyze contact $($contact.'First Name') $($contact.'Last Name') (Title: $($contact.'Title')) with Mobile Phone $($contact.'Mobile Phone') and E-Mail $($contact.'E-mail Address')"
    Write-Host "Scanned $($i)/$($contacts.Count) contacts"
} -ThrottleLimit $threads

$timeEnd = Get-Date
$timeElapsed = $timeEnd-$timeStart
Write-Verbose "Needed $($timeElapsed.Seconds) seconds to analyze $($contacts.Count) contacts"

$deduppedContacts | ConvertTo-Csv | Out-File $destinationFile
Write-Host "Dedupped $($contacts.Count) contacts to $($deduppedContacts.Count) contacts"
