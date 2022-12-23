Note:
The pattern described in the instructions can be found in the LEDpattern.PNG file

Assignment Instructions:

This project involves creating a circuit in Logisim that makes use of sequential logic. In
particular, the circuit we design will count in decimal, cycling from 0 to a maximum value that is
no greater than 9, and display the result using an array of six LED’s according to the pattern
provided above.

The overall circuit will consist of two major blocks in addition to the array of six LED’s. The first
block will be a counter circuit. The main input to the counter will be a free running clock which
will cause the count to increment by 1 every clock cycle. When the maximum value is reached,
the count will start over at 0.

The counter will have a secondary, 4 bit, input that can set the maximum value to any number
from 0 to 9. Since 4 bits can represent values up to 15, the circuit should automatically limit the
maximum to 9 – that is to say, if a value greater than 9 is input, the circuit should simply use 9
as the maximum value. This should also work “on the fly”, meaning that if a new maximum is
set to a value less than the current count, the next count value should reset to zero.
The second section is a decoder that takes the output of the counter and drives the individual
LED’s to display the numerical value in the LED’s.
