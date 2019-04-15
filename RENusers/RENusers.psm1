<# 

    **** Big Variable Section ****
    Varibles here will be used by various CMDlets and functions.
    Are entered here so that they can be easily adjusted.

#>

<# 
    LosAngeles is currently the only Location. 
    Other Departments will be added as the code improves.
#>
set-variable -name "losAngelesAddress" -value @{
    City = 'Los Angeles';
    Country = 'US';
    PostalCode = '90029';
    ST = 'CA';
    StreetAddress = '909 Upper Cienega Street';
} -option 'constant'

set-variable -name "seattleAddress" -value @{
    City = 'Seattle';
    Country = 'US';
    PostalCode = '80081';
    ST = 'WA';
    StreetAddress = '1100 Red Marcher Blvd';
} -option 'constant'

set-variable -name "chicagoAddress" -value @{
    City = 'chicago';
    Country = 'US';
    PostalCode = '60621';
    ST = 'IL';
    StreetAddress = '6051 Haddington st';
} -option 'constant'

<#
    **** Helper Function Section *****
    These are functions that should not be run directly by users,
    But will be used by CMDlets.

#>

function get-RENOUchildren {
    <#
        Helper Functions. Returns children OU, of whatever OU is put in.
        Turns them to Lowercase. Outputs them as an Array.
        
        Example: Running get-RENOUchildren -ouPath 'OU=Dublin,OU=Laptops,OU=Workstations,DC=renraku,DC=com'
        Returns all the OUs of the Dublin OU as an array of lowercase strings.
    #>
    # Parameter help description
    [cmdletBinding()]
    Param(
        [Parameter(mandatory=$true)]
        [string]$ouPath
    )

    $outPut = (Get-ADOrganizationalUnit -SearchBase $OUpath -SearchScope Subtree -Filter * ).name
    Write-verbose "Looking for OUs of $ouPath"
    Write-verbose "Returning $output"
    write-output $outPut.toLower()

}

function create-RENEmail {
    <#
        .DESCRIPTION
        HELPER FUNCTION do not run Directly.

        Makes a string a new e-mail from a First and Last username.
        Additional parameter is if the user is a temp.
        Creates a string output.
    #>
    [CMDletbinding()]
    Param(
        [Parameter(mandatory=$true)]
        [String] $first,
        [Parameter(mandatory=$true)]
        [String] $last
    )

    BEGIN{}

    PROCESS {
        Write-Verbose "Creating e-mail for $first $last."
        $base = -join($first,".",$last)
        Write-Verbose "Set up name to $base"
        Write-Verbose "Combinging into final string"
        $email = -join($base,"`@`renraku.com")
        Write-Verbose "Final e-mail is $email"
        Write-Output $email
    }

    END {}
}

function create-RENDefaultPassword {
    <#
        .DESCRIPTION
        HELPER FUNCTION do not run Directly.

        Makes the default user password as a String. Takes in the first and last name of a user.
        
        JGrenraku11
    #>
    [CMDletbinding()]
    Param(
        [Parameter(mandatory=$true)]
        [String] $first,
        [Parameter(mandatory=$true)]
        [String] $last
    )

    BEGIN {
        $suffix = 'renraku11'
    }

    PROCESS {
        Write-verbose "Creating Capital initials based on input"
        $firstInitial = $first.Substring(0,1).toUpper()
        $secondInitial = $last.Substring(0,1).toUpper()
        Write-verbose "Connecting Strings... Sending Output"
        $output = -join($firstInitial,$secondInitial,$suffix) | ConvertTo-SecureString -AsPlainText -Force
        Write-verbose "converted plain text string to secure string."
        Write-Output $output
    }
}

<#
    *** CMDLET Section ***
    This Section is where actual CMDlets will be written.
#>

function set-RENuserLocation {
    <#
        .SYNOPSIS
        Changes the Address of a user in a user object.
        Can be set by various switch parameters or manually with several other paramters.
        .DESCRIPTION
        This CMDlet takes in a user object, and then changes the physical address details 
        of that user object. Can only take in one user at time (no arrays inputs). By default, 
        it outputs the user object, whether or not it changed, for ease of piplining.
        .PARAMETER Identity
        Accepts a User object and can take a value from Pipline or anything that uniquely 
        identifies a user. One input only. No arrays allowed.
        .PARAMETER LosAngeles
        Sets the user Object to LosAngeles's phyiscal address.
        .EXAMPLE
        set-RENuserLocation -identity john.doe -LosAngeles
        Sets John Doe's address fields to the LosAngeles address.
        .EXAMPLE
        get-aduser "CN=ne.Jane Doe,OU=_Non Employees,OU=Employees,DC=renraku,DC=com" | set-RENuserlocation -LosAngeles
        Retreives a user that named ne.jane.doe and sets her to the LosAngeles Location.
        
    #>
    [CMDletbinding()]
    Param(
        [Parameter(mandatory=$true,position=0,valuefrompipeline=$true)]
        [Alias('user','employee','aduser')]
        [Microsoft.ActiveDirectory.Management.ADuser]$identity,
            [Parameter(mandatory=$true)]
            [validateset('los angeles','chicago','seattle')]
            [string]$location
    )

    BEGIN{
        try{
            $thisUser = get-aduser $identity -erroraction Stop
            Write-verbose "Retrieved User object succesfully."
        }catch{
            Write-verbose "Could not get a user with $identity. Is that input correct?"
        }
        
        Write-verbose 'Setting location for $location'
        switch($location){
            'los angeles'{
                $thisAddress = $losangelesAddress
            }
            'chicago'{
                $thisAddress = $dublinAddress
            }
            'seattle'{
                $thisAddress = $seattleAddress
            }
        }
    }

    PROCESS{
        Write-Verbose 'Updating user'
        try{
            <# Populates the ADuser's address frields based on the address of the particular location #>
            $output = set-aduser -identity $thisUser `
                       -StreetAddress $thisAddress.StreetAddress `
                       -city $thisAddress.city `
                       -state $thisAddress.ST `
                       -PostalCode $thisAddress.PostalCode `
                       -country $thisAddress.country `
                       -passthru `
                       -erroraction stop
            Write-Verbose 'User updated successfully. Passing objecting on through Pipline.'
            Write-output $output
        }catch{
            Write-warning 'There was an error in updating this user. Passing unchanged object to pipline'
            write-output $thisUser
        }
    }

    END{}
}

function set-RENuserOU {
    <#
        .SYNOPSIS
        Sets an AD user to a specific OU.
        .DESCRIPTION
        Takes in a user as a string. Moves to the relevent OU by a location switch parameter
        and a string department Parameter. The user to be moved can be any user within the REN domain.
        .PARAMETER PassThru
        This CMDLET will not normally return objects. Use PassThru if you plan to move the changed
        user object into a pipeline or if you wish to see the result displayed on screen.
        .PARAMETER Reset
        Use this to move the user into OU=Employees,DC=renraku,DC=com
        .PARAMETER Identity
        Enter anything here that can be used to uniquely Identify an ADuser object. This will be
        the ADuser to be moved.
        .PARAMETER LosAngeles
        Switch Parameter. Sets the user to one of the OU within the LosAngeles OU.
        .PARAMETER DEPARTMENT 
        String Parameter. Enter the *exact name* of the department OU with the OU set by the switch.
        E.G. if using -LosAngeles, enter any of the OUs within OU=LosAngeles,OU=Employees,DC=renraku,DC=com
        .EXAMPLE set-RENuserOU -identity john.doe -LosAngeles -department 'customer service'
        Takes John.doe from wherever OU he is in and moves him to the customer service OU.
        .EXAMPLE set-RENuserOU -employee john.doe -LosAngeles -department 'project' -passthu | out-file ./file.txt
        Moves john.doe to the porject manager OU and then writes it as a file for some reason.
        .EXAMPLE set-RENuserOU -identity 70d23f02-7d0c-4365-a9a0-3874ab15a181 -LosAngeles -d 'netops'
        Grabs the user whos GUID is listed above. This user is then moved to the netops OU.
    #>
    [CMDletbinding()]
    Param(
        [Parameter(mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [Alias('user','employee','aduser')]
        [Microsoft.ActiveDirectory.Management.ADuser[]]$identity,
        <# Passthru will output the changed user object to the Pipeline #>
        [switch]$passthru,
        <# LosAngeles Switch #>
            [Parameter(mandatory=$true,ParameterSetName='losangeles')]
            [Alias('los angeles','la','california')]
            [switch]$losangeles,
        <# Seattle/HQ Switch #>
            [Parameter(mandatory=$true,ParameterSetName='seattle')]
            [Alias('washington','hq')]
            [switch]$seattle,
        <# Seattle/HQ Switch #>
            [Parameter(mandatory=$true,ParameterSetName='chicago')]
            [Alias('midland')]
            [switch]$chicago,
        <# Department Parameter. Will validate based on what is currently in the Particular city's OU. #>
            [Parameter(mandatory=$true)]
            [ValidateScript(
                if($losangeles){
                    $validateME = get-RENOUchildren -ouPath 'OU=Los Angeles,OU=Staff,DC=Renraku,DC=com';
                }
                elseif($seattle){
                    $validateME = get-RENOUchildren -ouPath 'OU=Seattle,OU=Staff,DC=Renraku,DC=com';
                }
                elseif($chicago){
                    $validateME = get-RENOUchildren -ouPath 'OU=Chicago,OU=Staff,DC=Renraku,DC=com';
                }
                write-output $validateMe.contains($_.toLower())
            )]
            [Alias('d')]
            [string]$department
    )

    BEGIN {
        <# Sets up where the User should go. Eventually, other locations will be added. #>
        if($losAngeles){
            $destinationOU = -join('OU=',$department,',OU=Los Angeles,OU=Staff,DC=Renraku,DC=com')
        }
        elseif($seattle){
            $destinationOU = -join('OU=',$department,',OU=Seattle,OU=Staff,DC=Renraku,DC=com')
        }
        elseif($chicago){
            $destinationOU = -join('OU=',$department,',OU=Chicago,OU=Staff,DC=Renraku,DC=com')
        }
    }

    PROCESS {
        foreach($user in $identity){
            try{
                try{
                    Write-verbose "Retrieving user-ADobject"
                    $userObject = get-ADuser -identity $user -ErrorAction stop
                }catch{
                    write-warning "Not able to get computer object with $user. Is this a correct name? Is the user a temp?"
                }
                Write-verbose "Processing $user into new OU $destinationOU"
                Write-verbose "If this were to move, it would move $userObject to $destinationOU"
                Move-ADobject -Identity $userObject -targetpath $destinationOU -ErrorAction Stop
                
                if($passthru){
                    Write-output (get-Aduser -identity $user)
                }
            }catch{
                Write-warning "Error with $user! Object not moved!"
            }
        }
    }

    END {}
}

function new-RENuser {
    <#
        .SYNOPSIS
        Creates a user, creates and address, and sends them to the right OU.
        .DESCRIPTION
        This command takes in several required parameters and creates a new user from the 
        supplied information. The ultimate intention of of this command is to take 
        infromation from a pipeline. This can still only take one new user at a time.
        .Parameter name
        The new Employee's first name.
        .PARAMETER surname
        The new employee's last name.
        .PARAMETER title
        Takes in a string of what the person's job title. This string is not 
        validated in anyway so if you enter "-title 'Lord of all the Mushroom Pixies'" than 
        someone like "Jane Doe" will be offended that didn't get her gender right.
        .PARAMETER LosAngeles
        Applies the Los Angeles physical address and allows you to user the -Department 
        parameter for Los Angeles.
        .PARAMETER Seattle
        Applies the Seattle physical address and allows you to user the -Department 
        parameter for Seattle.
        .PARAMETER Chicago
        Applies the Los Angeles physical address and allows you to user the -Department 
        parameter for Los Angeles.
        .PARAMETER Department
        This will put the user in the relevent OU. The input is Validated based on 
        location. E.g. if you've used the "LosAngeles" switch this will only accept 
        the names of OUs within the Los Angeles OU.

    #>
    [CMDletbinding()]
    Param(
        [Parameter(mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [Alias('first','firstname')]
        [string]$name,
        [Parameter(mandatory=$true,Position=1,ValueFromPipeline=$true)]
        [Alias('last','lastname')]
        [string]$surname,
        [Parameter(mandatory=$true,Position=2,ValueFromPipeline=$true)]
        [alias('t','role')]
        [string]$title,
        <# LosAngeles Switch #>
            [Parameter(mandatory=$true,ParameterSetName='losangeles')]
            [Alias('los angeles','la','california')]
            [switch]$losangeles,
        <# Seattle/HQ Switch #>
            [Parameter(mandatory=$true,ParameterSetName='seattle')]
            [Alias('washington','hq')]
            [switch]$seattle,
        <# Seattle/HQ Switch #>
            [Parameter(mandatory=$true,ParameterSetName='chicago')]
            [Alias('midland')]
            [switch]$chicago,
        <# Department Parameter. Will validate based on what is currently in the Particular city's OU. #>
            [Parameter(mandatory=$true)]
            [ValidateScript(
                if($losangeles){
                    $validateME = get-RENOUchildren -ouPath 'OU=Los Angeles,OU=Staff,DC=Renraku,DC=com';
                }
                elseif($seattle){
                    $validateME = get-RENOUchildren -ouPath 'OU=Seattle,OU=Staff,DC=Renraku,DC=com';
                }
                elseif($chicago){
                    $validateME = get-RENOUchildren -ouPath 'OU=Chicago,OU=Staff,DC=Renraku,DC=com';
                }
                write-output $validateMe.contains($_.toLower())
            )]
            [Alias('d')]
            [string]$department
        
    )

    BEGIN {
        <# 
            Sets a user's Deftault password. Creates a String for E-mail.
            Does not actually create an e-mail account. String is
            for AD records only.
        #>
        $password = create-RENDefaultPassword -first $name -last $surname
        $email = create-RENDefaultPassword -first $name -last $surname 
        $adname = -join($name,'.',$surname)
    }

    PROCESS {
        <# Once more locations are added, a switch for each location will be added here too #>
        if($losangeles){
            <# Uses both CMDlets from the ActiveDirectory module and custom CMDLETs of this Module. #>
            new-adUser -AccountPassword $password -givenname $name -surname $surname -enabled `
                       -initials -join($name.substring(0,1),$surname.substring(0,1)) `
                       -EmailAddress $email -samaccountname $adname -changepasswordatlogin -PassThru| `
            set-RENuserOU -losangeles -department $department -passthru | `
            set-RENuserlocation -location 'los angeles'
        }
        elseif($seattle){
            <# Uses both CMDlets from the ActiveDirectory module and custom CMDLETs of this Module. #>
            new-adUser -AccountPassword $password -givenname $name -surname $surname -enabled `
                       -initials -join($name.substring(0,1),$surname.substring(0,1)) `
                       -EmailAddress $email -samaccountname $adname -changepasswordatlogin -PassThru| `
            set-RENuserOU -seattle -department $department -passthru | `
            set-RENuserlocation -location 'los angeles'
        }
        elseif($chicago){
            <# Uses both CMDlets from the ActiveDirectory module and custom CMDLETs of this Module. #>
            new-adUser -AccountPassword $password -givenname $name -surname $surname -enabled `
                       -initials -join($name.substring(0,1),$surname.substring(0,1)) `
                       -EmailAddress $email -samaccountname $adname -changepasswordatlogin -PassThru| `
            set-RENuserOU -chicago -department $department -passthru | `
            set-RENuserlocation -location 'los angeles'
        }
    }

    END {}
}