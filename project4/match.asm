; 
; Find matching characters in a string
;
; Written By: Julia Moran
; 

include Irvine32.inc

MAXCHARS = 101												; limits the strings to 100 user supplied characters, is 101 to account for the NULL terminator

.data
promptUserString BYTE "Enter string to search: ", 0			; prompt line for the string to search
promptMatchString BYTE "Enter characters to find: ",0		; prompt line for the characters to find
displayFoundString BYTE "Characters found: ", 0, 0Dh, 0Ah	; line to display the characters found
userString BYTE MAXCHARS DUP(0)								; string to search from the user
matchString BYTE MAXCHARS DUP(0)							; string to match characters from
foundString BYTE MAXCHARS DUP(0)							; string of found characters
		
.code
main PROC
	mov edx, OFFSET promptUserString						
	call WriteString										; print prompt line to get the user string

	mov edx, OFFSET userString					
	mov ecx, MAXCHARS										; limit the input for the user string to 100 characters
	call ReadString											; get string to compare against, the user string
		
	mov edx, OFFSET promptMatchString						
	call WriteString										; print prompt line to get the match string

	mov edx, OFFSET matchString
	mov ecx, MAXCHARS										; limit the input for the match string to 100 characters
	call ReadString											; get string to search from, the match string

	mov esi, OFFSET matchString								; inititalize string to search from, the match string
	mov edi, OFFSET foundString								; inititalize string of found characters, the found string
	
	buildString:											; loop through the user string to search for each character in the match string
		mov eax, OFFSET userString							; inititalize string to compare against from the user, the user string
		mov bl, [esi]										; get character from the match string to search from
		cmp bl, 0											; check if the end of the match string has been reached
		je endBuild											; end the loop if at the end of the match string
		call FindChar										; search for the current character
		cmp eax, 0											; check if the character was found
		je notFound											; continue through the match string if the character was not found
		mov [edi], al										; save the found character to the found string
		inc edi												; increment the pointer to the found string

		notFound:											; continue the loop through the user string if the character in the match string was not found
			inc esi											; increment the pointer to the user string
			loop buildString								; continue through loop

		endBuild:											; end the loop and print the results when the end of the match string has been reached
			mov edx, OFFSET displayFoundString				; store the line to display before the found string is printed
			call WriteString								; print the line to display before the found string is printed
			mov edx, OFFSET foundString						; store the string of found characters
			call WriteString								; print the found string, the string of characters from the match string found in the user
			call CrLf										; call the Irvine library function to write a carriage return and line feed sequence		
			call WaitMsg									; wait for user to hit enter
			invoke ExitProcess,0							; bye
main ENDP

;--------------------------------------------------------------------------------------------------
FindChar PROC USES esi ebx
;
; Searches the user string and returns current character in the match string if it is found in the
; user string.
; Receives: ESI - pointer to the user string
;			EBX - character in the match string to compare with each character in the user string
; Returns:	EAX - character in the match string that was found in the user string, 0 if not found
; Requires: nothing
;--------------------------------------------------------------------------------------------------
	mov esi, eax											; move the pointer to the user string to esi to use eax to store the return value

	search:													; search the user string for the character in match string
		mov al, [esi]										; get the character of user string
		cmp al, 0											; check if at the end of the user string
		je notEqual											; exit the loop if at the end of the user string
		cmp al, bl											; compare the current character in the user string to the character in the match string
		je Equal											; exit the procedure if a matching character has been found
		inc esi												; increment the pointer to the user string
		loopnz search										; loop through the search if the character was not found and not at the end of the user string

	notEqual:												; jump to if the character was not found in the user string
		mov eax, 0											; return a 0 if the character from match string was not found in the user string

	Equal:													; unconditional jump, jump to if the character in match string was found in user string

	ret														; return the character found or a 0 if the character was not found in eax
FindChar ENDP

END main