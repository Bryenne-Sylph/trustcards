# TRUST CARDS
## v1.0
### Written by Bryenne[Sylph]

This addon creates small graphical 'cards' when summoning Trusts.
Besides a nice cosmetic touch it also has two lines of information
to describe the trust as helpful hints, or not, in some cases.

These lines can be customized in the lua file to suit your own preferences!

## COMMANDS

Use //tc or //trustcards to give these COMMANDS

#### pos
Sets the location of the Trust Cards window (anchored on top-left corner), requires [x] and [y] coordinate			  
to change:
```xml			  
//tc pos x y 

For example:
//tc pos 1000 200 
```
This sets the window to 1000 pixels to the right and 200 pixels down
			  
#### bg
numeric 1-4, changes the background window of the Trust Card 
			  1 = Classic FFXI window
			  2 = A Red Gradient background
			  3 = A Green Gradient background
			  4 = "Heavy Metal Plate" background
			  
			  to change: //tc bg [1-4] 
			  
			  example: //tc bg 2 sets the window to the red gradient background
			  
alpha		: numeric 0-255, sets the alpha of the background window (and only the background, text and portraits are not affected)
			  by default this is set to 255 (solid)
			  
			  to change: //tc alpha [0-255]
			  
			  example: //tc alpha 128 sets the transparancy of the window to 50%
			  
checktrust	: [TODO] no parameters, just the command...this checks all your learned trusts against the internal database
			  then provides you with feedback on which trusts you are missing (ignores unity leaders)
			  
			  to use: //tc checktrust
			  
test		: string, shows card of a specific trust if a name is added, partial names work as well...this is mostly to test graphics or to check the traits
			  if you are looking for a specific trait.
			  
			  for example: 	//tc test ayame - will show the card for "Ayame"
							//tc test mihli - will show the card for "Mihli Aliapoh"
							
			  this is not super robust and if the string finds more than one possible hit it just doesn't do anything. 
			  ie: //tc test shantot - will not do anything, as there is Shantotto and Shantotto II
							
# CHANGELOG

## V1.0
Initial release with [x] different backgrounds and all portraits for trusts available at the start of 2025 (122 in total)