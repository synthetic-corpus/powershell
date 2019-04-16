# powershell modules for Active Directory
This is a short sample of my work with Powershell. Purpose of these scripts is to manage user and laptop work stations in an active directory environment.

# What is "Ren"?

"Ren" is short for Renraku.com, the name of the domain these scripts are to be tested on. Powershell best practices
dictate that it's best to name custom cmdLETS in a way that indicates they're company specific. I.e. if you work for "New Haven University"
you might name a cmdLET "set-nhuLaptopOU" instead of simply "set-LaptopOU"

# What does this module do?

RENusers simplifies account creation for an hypothetical company that has three different locations with several unique departments within 
each loaction. Rather than entering e-mail address, a standardized password, moving a userobject to the correct OU etc etc, this 
module simplifies the process into a single cmdLET.
