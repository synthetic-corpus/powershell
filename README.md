# powershell modules for Active Directory
This is a short sample of my work with Powershell. Purpose of these scripts is to manage user and laptop work stations in an active directory environment.

## What is "Ren"?

"Ren" is short for Renraku.com, the name of the domain these scripts are to be tested on. Powershell best practices
dictate that it's best to name custom cmdLETS in a way that indicates they're company specific. I.e. if you work for "New Haven University"
you might name a cmdLET "set-nhuLaptopOU" instead of simply "set-LaptopOU"

## What does this module do?

RENusers simplifies account creation for an hypothetical company that has three different locations with several unique departments within 
each location. Rather than entering e-mail address, a standardized password, moving a userobject to the correct OU etc manually (and then error checking!), this 
module simplifies the process into a single cmdLET.

### Exmaple:

  new-RENaccounts -path c:/users/admin/desktop/newUsers.xls -log
  
  This command will take in a properly formatted xls sheet. For each user the following will be done:
  1. New AD user object will be created.
  2. Generic password will be added with a hardcoded algorhthm.
  3. Password will require restart on first login.
  4. AD user object will be moved to an OU based on department and city columns of the .xls sheet
  5. Physical addresses for the user object will be updated.
  6. E-mail address will be added to the user object for record keeping, but will *not* create an actual e-mail account.

# Adapting for Use in professional environments.

First, The code assumes a certain structure in AD. In the test environment it looks like the image below.

Secondly, anything related to cities or physical worksites (e.g. certain switch parameters and mailing address variables) are also hardcoded. For instance, this code only has three different cities to choose from, and they all match with fake addresses. All of this would need to be changed before it could be deployed live.

Anything related to department can be handled dynamically and will not require changes in code, provided that the OU structure follows the same pattern in the example above.
