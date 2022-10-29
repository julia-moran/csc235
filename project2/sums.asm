;
; ------------------------------------------------------------------------------
; Calculate cumulative sum for integers up to 20, store in memory
; Compute squares of integers, subtract stored cumulative sum - display output
; ------------------------------------------------------------------------------
;
; Written By: 
; Julia Moran

include Irvine32.inc

.data
NUMINTS = 20						; set the number of integers to be operated on
list DWORD NUMINTS DUP(?)			; define an array to store the cumulative sums

.code
main PROC
	mov esi, OFFSET list			; set the pointer to the list
	mov ebx, 0						; set a counter at zero to count up the number of times the outer loop loops
	mov ecx, NUMINTS				; set the number of times for the first outer loop to loop

CUMULATE1:							; outer loop for the cumulative sums
	inc ebx							; increment the counter starting at zero
	mov eax, 0						; reset the sum
	mov edx, ecx					; save the outer loop count
	mov ecx, ebx					; set inner loop counter

CUMULATE2:							; inner loop for the cumulative sums
	add eax, ecx					; add the loop counter to an overall sum
	loop CUMULATE2					; loop until the loop counter hits zero to add up the cumulative sum

	mov ecx,edx						; restore the outer loop counter
	mov [esi], eax					; store the cumulative sum in an array 
	add esi, 4						; increment the array by four since it is an array of dwords
	loop CUMULATE1					; loop the outer loop  

	mov ebx, 0						; set a counter at zero to count up the number of times the second outer loop loops
	mov ecx, NUMINTS				; set the number of times for the second outer loop to loop
	sub esi, NUMINTS * 4			; set the pointer to the array to the beginning of the array to traverse it again after the squares are calulated

SQUARE1:							; outer loop for the squared values
	inc ebx							; increment the counter
	mov eax, 0						; reset the sum
	mov edx, ecx					; save the outer loop count
	mov ecx, ebx					; set inner loop counter

SQUARE2:							; inner loop for the squared values
	add eax, ebx					; add the outer loop's counter to the overall sum
	loop SQUARE2					; loop through the inner loop to calculate the square of each integer
	
	mov ecx, edx					; restore the outer loop counter
	sub eax, [esi]					; calculate the difference between the cumulative sum and the square
	call WriteDec					; output the difference
	call Crlf						; write one difference per line
	add esi, 4						; increment the pointer to the array 
	loop SQUARE1					; loop the outer loop  

	call WaitMsg					; wait for user to hit enter
	invoke ExitProcess,0			; 'bye

main ENDP
END main