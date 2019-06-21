# Implement your module commands in this script.
function Sync-ADGroup {

    <#
.SYNOPSIS

Synchronizes two Active Directory groups.

.DESCRIPTION

Synchronizes two Active Directory groups by taking a reference group and duplicating it in a difference group

.PARAMETER referenceGroupName
Specifies the Active Directory Reference group. You can identify a group by its distinguished name (DN), GUID, security identifier (SID), Security Accounts Manager (SAM) account name, or canonical name.

.PARAMETER differenceGroupName
Specifies the Active Directory Difference group. You can identify a group by its distinguished name (DN), GUID, security identifier (SID), Security Accounts Manager (SAM) account name, or canonical name.

.INPUTS

None. You cannot pipe objects to Sync-ADGroup.
.OUTPUTS
Nothing
.EXAMPLE
PS> Sync-ADGroup -referenceGroupName rru.groupA -differenceGroupName rru.groupB
#>
    #Parameter names for the groups to be synced.
    param(
        [Parameter(Mandatory = $true)]
        [string]$referenceGroupName,
        [Parameter(Mandatory = $true)]
        [string]$differenceGroupName
    )

     #Get the AD groups needed for the sync
     Try {
        $referenceGroup = Get-ADGroup -Identity $referenceGroupName
        if (($referenceGroup | Measure-Object).Count -ne 1) { throw "Your reference group was not found" }
        $differenceGroup = Get-ADGroup -Identity $differenceGroupName
        if (($differenceGroup | Measure-Object).Count -ne 1) { throw "Your difference group was not found" }
    }
    Catch {
        Write-Output "Ran into an issue: $PSItem"
        Break
    }
    #Get the members of the two AD Groups
    $referenceGroupMembers = Get-ADGroupMember -Identity $referenceGroup
    $differenceGroupMemebers = Get-ADGroupMember -Identity $differenceGroup
    #Compare the two groups for differences
    $diffResult = Compare-Object -ReferenceObject $referenceGroupMembers -DifferenceObject $differenceGroupMemebers
    ForEach ($item IN $diffResult) {
        #Only in the Difference set. This User needs to be removed from the Difference set
        if ($item.SideIndicator -eq '=>') {
            "Remove " + $item.InputObject + " from Difference set"
            Remove-ADGroupMember -Identity $differenceGroup -members $item.InputObject
        }
        #Only in the Reference set. This user needs ot be added to the Difference set
        elseif ($item.SideIndicator -eq '<=') {
            "Add " + $item.InputObject + " to difference set"
            Add-ADGroupMember -Identity $differenceGroup -members $item.InputObject
        }
        #Technically I can't imagine how this could happen
        else {
            "Houston we have a problem."
        }
    }
}