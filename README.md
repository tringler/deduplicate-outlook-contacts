## Purpose
A simple powershell script to deduplicate outlook contacts. You need to export the contacts to a CSV from outlook and pass it to the script.

## Usage
`deduplicate-contacts.ps1 -sourceFile .\contacts.csv -destinationFile .\deduppedContacts.csv`

## TBD
Currently there is no merging of contacts. If multiple versions of a contact is found the script print out a warning.
