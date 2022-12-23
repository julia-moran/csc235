; 
; Load a list of musicians into an array of structs created via heap allocation.
; Print out musician information, calculating the musician's age
; 
; Written by:
; Julia Moran

include Irvine32.inc

; define some constants
FSIZE = 100							; max file name size
LINESIZE = 100						; max input line size
CR = 0Dh							; c/r
LF = 0Ah							; line feed
ASTERISK = 2Ah						; asterisk for new entry
NULL = 00h							; null character
SPACE = 20h							; space character
MSTRSIZE = 32						; string sizes in struct

musician STRUCT
	artist BYTE MSTRSIZE DUP('n')		; 32 bytes	
	instrument BYTE MSTRSIZE DUP('i')	; 32
	born DWORD 0						; year born (4)
	died DWORD 0						; year died	(4)
musician ENDS							; 72 total

.data
filename BYTE FSIZE DUP(?)			; array to hold the file name
lbuffer BYTE LINESIZE DUP(?)		; line buffer array
fileptr DWORD 0						; the file pointer
prompt1 BYTE "Enter the number of musicians: ",0	; prompt for number of musicians
prompt2 BYTE "Enter a filename: ",0	; prompt for file name
ferror BYTE "Invalid input...",0	; error message


maxnum DWORD 0						; max number of musicians to load
mlistptr DWORD 0					; pointer to musician list 
									; (i.e. array of musician structs)
numread	DWORD 0						; number of musicians loaded

; for output listing (these can be used as globals)
outname  BYTE "Artist: ",0
outinstr BYTE "Instrument: ",0
outage   BYTE "Age: ",0


.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main PROC
	; prompt for the number of musicians 
    mov edx,OFFSET prompt1			; output the prompt
	call WriteString				; uses edx 
	call ReadInt					; get the maximium number of musicians
	mov maxnum,eax					; save it

	;;;;;;;;;;;;;;;;;;
	; access the heap and allocate memory for musician struct array
	;;;;;;;;;;;;;;;;;;
	push maxnum						; set the number of bytes to allocate for the heap
	call allocMusicians				; allocate the heap
	mov mlistptr, eax				; return the pointer to the allocated heap
	jc DONE							; end the program if an error occured

	; prompt for the file name 
    mov edx,OFFSET prompt2			; output the prompt
	call WriteString				; uses edx 

	; read the file name
	mov edx,OFFSET filename			; point to the start of the file name string
	mov ecx,FSIZE				    ; max size for file name
	call ReadString					; load the file name (string pointer in edx, max size in ecx)
	
	;;;;;;;;;;;;;;;;;;
	; open the file, get the file pointer
	;;;;;;;;;;;;;;;;;;
	call OpenInputFile				; open the file to read
	mov fileptr, eax				; save the pointer to the file
	cmp eax, INVALID_HANDLE_VALUE	; check if the file name is valid
	je INVALID						; exit if the file is invalid

	;;;;;;;;;;;;;;;;;;
	; load the musician information
	;;;;;;;;;;;;;;;;;;
	push mlistptr					; pointer to the array of structs
	push fileptr					; pointer to the file
	push maxnum						; max number of musicians to read
	call loadAllMusicians			; load the information from the file to an array of structs
	
	;;;;;;;;;;;;;;;;;;
	; output the musician information
	;;;;;;;;;;;;;;;;;;
	push ebx						; pointer to the array of structs
	push eax						; max number of musicians to read
	call outputAllMusicians			; print the musician information


	;;;;;;;;;;;;;;;;;;
	; be sure to:
	;     close the file
	;     handle any errors encountered
	;;;;;;;;;;;;;;;;;;
	mov eax, fileptr				; pointer to the file
    call CloseFile					; close the file

DONE:
	call WaitMsg					; wait for user to hit enter
	invoke ExitProcess,0			; bye

INVALID:
	mov edx, OFFSET ferror			; get the error message
	call WriteString				; print the error message
	call Crlf						; skip a line
	call WaitMsg					; wait for user to hit enter
	invoke ExitProcess,0			; bye
main ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read a character from a file
; receives:
;	[ebp+8]  = file pointer
; returns:
;	eax = character read, or system error code if carry flag is set
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readFileChar PROC
	push ebp						; save the base pointer
	mov ebp,esp						; base of the stack frame
	sub esp,4						; create a local variable for the return value
	push edx						; save the registers
	push ecx

	mov eax,[ebp+8]					; file pointer
	lea edx,[ebp-4]					; pointer to value read
	mov ecx,1						; number of chars to read
	call ReadFromFile				; gets file handle from eax (loaded above)
	jc DONE							; if CF is set, leave the error code in eax
	mov eax,[ebp-4]					; otherwise, copy the char read from local variable

DONE:
	pop ecx							; restore the registers
	pop edx
	mov esp,ebp						; remove local var from stack 
	pop ebp
	ret 4
readFileChar ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; allocate the heap
; receives:
;	[ebp+8]  = number of structs in the array
; returns:
;	eax = pointer to the allocated heap
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
allocMusicians PROC
	LOCAL structHeap:HANDLE

	call GetProcessHeap				; get the program's heap handle
	cmp eax, 0						; check if there was an error in getting the heap handle 
	je HeapError					; stop allocating the heap if there is an error
	mov structHeap, eax				; save the heap handle if there is not an error
	
	mov ebx, [ebp + 8]				; number of musician structs to store in the array
	mov eax, 72d					; number of bytes in one musician struct
	mul ebx							; multiply the max num of musicians by the size of the musician struct
	
	push eax						; number of bytes to allocate
	push HEAP_ZERO_MEMORY			; initialize to all zeros
	push structHeap					; heap handle
	call HeapAlloc					; allocate from the current heap
	cmp eax, 0						; check for an error in allocating the heap
	je HeapError					; set the carry flag if there was an error in allocating the heap
	jmp EndHeap						; else end the procedure as normal			

	HeapError:
		stc							; set the carry flag on an error
	EndHeap:
		ret 4						; remove the parameter from the stack
allocMusicians ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read one line of the file
; receives:
;	[ebp + 16] = max size of the string to read
;	[ebp + 12] = pointer to the file
;	[ebp + 8]  = pointer to the string buffer to read to
; returns:
;	eax = number of characters read and stored in the string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readFileLine PROC
	push ebp						; save the base pointer
	mov ebp, esp					; base of the stack frame

	mov ecx, [ebp + 16]				; max size of the string to read
	mov esi, [ebp + 12]				; pointer to the file
	mov edi, [ebp + 8]				; buffer to read to

	push ebx						; save the ebx register
	mov ebx, 0						; start the counter of number of bytes read at zero

	buildString:
		push esi					; pointer to the file
		call readFileChar			; read one character to the buffer line
		jc endRead					; stop reading the line if an error occurs while reading the character
		cmp al, LF					; check if the line feed was reached
		je endOfLine				; finish reading the line at the line feed
		cmp al, CR					; check if the carriage return was reached
		je nextChar					; skip adding a character to the buffer if the carriage return was reached
		cmp al, NULL
		je errorFound
		
		mov [edi], al				; add the character to the line buffer
		inc edi						; increment the pointer to the buffer

	nextChar:
		inc ebx						; increment the number of characters read
		cmp ebx, ecx				; check if the max number of bytes was reached
		jne buildString				; read the next character if the max has not been reached

	endOfLine:
		mov al, NULL
		mov [edi], al				; add a NULL character to the end of the string
		inc edi						; increment the pointer to the buffer
		mov eax, ebx				; return the number of characters read
		jmp endRead					; end the read

	errorFound:
		stc							; set the carry flag if an error was found
	
	endRead:
		pop ebx						; restore the ebx register
		pop ebp						; restore the base pointer
		ret 12						; remove the parameters from the stack
readFileLine ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load one musician into a struct
; receives:
;	[ebp + 12] = pointer to the beginning of a struct object
;	[ebp + 8]  = pointer to the file
; returns:
;	eax = updated file pointer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
loadMusician PROC USES ecx edx
	LOCAL localBuffer[LINESIZE]:BYTE

	mov edx, [ebp + 12]					; pointer to the struct object
	mov esi, [ebp + 8]					; pointer to the file
	lea edi, localBuffer				; buffer to read to
	mov ecx, LINESIZE					; get the maximum number of bytes to read to the buffer
	sub ecx, 1							; subtract from the max number of bytes to account for the NULL terminator

	push ecx							; maximum number of bytes to read to the buffer
	push esi							; pointer to the file
	push edi							; pointer to the buffer to read to
	call readFileLine					; read the next line in the file, which should be the asterisk
	jc failure							; stop loading the musician if an error occured in reading the line
	dec edi								; go to the first character read to the buffer
	dec edi								; go to the first character read to the buffer
	mov al, [edi]						; get the first character read to the buffer
	cmp al, ASTERISK					; check if the asterisk, which proceeds musician information, was read
	jne failure							; stop loading the musician if the asterisk did not proceed the musician information

	lea edi, localBuffer				; set the buffer's pointer to the beginning of the buffer line
	push ecx							; maximum number of bytes to read to the buffer
	push esi							; pointer to the file
	push edi							; pointer to the buffer to read to
	call readFileLine					; read the next line in the file, which should be the musician's name
	jc failure							; stop loading the musician if an error occured in reading the line

	lea edi, localBuffer				; set the buffer's pointer to the beginning of the buffer line
	mov edx, [ebp+12]					; reset the struct pointer to the beginning of the struct	 
	add edx, OFFSET musician.artist		; increment struct pointer to the musician name
	push edx							; target for string copy, the pointer to the musician name
	push edi							; source for string copy, the pointer to the last line read
	call Str_copy						; load the last line read to the name

	lea edi, localBuffer				; set the buffer's pointer to the beginning of the buffer line
	push ecx							; maximum number of bytes to read to the buffer
	push esi							; pointer to the file
	push edi							; pointer to the buffer to read to
	call readFileLine					; read the next line in the file, which should be the musician's instrument
	jc failure							; stop loading the musician if an error occured in reading the line

	lea edi, localBuffer				; reset the buffer's pointer to the beginning of the buffer line
	mov edx, [ebp+12]					; reset the struct pointer to the beginning of the struct
	add edx, OFFSET musician.instrument	; increment struct pointer to the musician instrument
	push edx							; target for string copy, the pointer to the musician instrument
	push edi							; source for string copy, the pointer to the last line read
	call Str_copy						; load the last line read to the instrument

	lea edi, localBuffer				; set the buffer's pointer to the beginning of the buffer line
	push ecx							; maximum number of bytes to read to the buffer
	push esi							; pointer to the file
	push edi							; pointer to the buffer to read to
	call readFileLine					; read the next line in the file, which should be the year the musician was born
	jc failure							; stop loading the musician if an error occured in reading the line

	lea edi, localBuffer				; set the buffer's pointer to the beginning of the buffer line
	mov edx, edi						; array that holds year data
	push ecx							; save the ecx register
	mov ecx, eax						; number of characters read in the year array
	call ParseInteger32					; convert the year string to a DWORD
	pop ecx								; restore the ecx register

	mov edx, [ebp+12]					; reset the struct pointer to the beginning of the struct
	add edx, OFFSET musician.born		; increment struct pointer to the musician birth year
	mov [edx], eax						; load the converted year read to the struct

	lea edi, localBuffer				; set the buffer's pointer to the beginning of the buffer line
	push ecx							; maximum number of bytes to read to the buffer
	push esi							; pointer to the file
	push edi							; pointer to the buffer to read to
	call readFileLine					; read the next line in the file, which should be the year the musician died
	jc failure							; stop loading the musician if an error occured in reading the line

	lea edi, localBuffer				; set the buffer's pointer to the beginning of the buffer line
	mov edx, edi						; array that holds year data
	push ecx							; save the ecx register
	mov ecx, eax						; number of characters read in the year array
	call ParseInteger32					; convert the year string to a DWORD
	pop ecx								; restore the ecx register

	mov edx, [ebp+12]					; reset the struct pointer to the beginning of the struct
	add edx, OFFSET musician.died		; increment struct pointer to the musician death year
	mov [edx], eax						; load the converted year read to the struct

	mov edx, [ebp + 12]					; reset the struct pointer to the beginning of the struct
	mov eax, esi						; return the file pointer
	jmp success							; end the load without the carry flag set

	failure:
		stc								; set the carry flag on an error

	success:
		ret 8							; remove the parameters from the stack
loadMusician ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load all the musician structs into an array
; receives:
;	[ebp + 16] = pointer to the beginning of the struct array
;	[ebp + 12] = pointer to the file
;	[ebp + 8]  = maximum number of musicians to read
; returns:
;	eax = number of musicians read
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
loadAllMusicians PROC
	push ebp							; save the base pointer
	mov ebp, esp						; base of the stack frame

	mov ebx, [ebp + 16]					; get the pointer to the struct array
	mov esi, [ebp + 12]					; get the pointer to the file
	mov ecx, [ebp + 8]					; maximum number of musicians to read
	mov edx, 0							; start the number of musicians read at zero

	cmp ecx, 0							; check if the number of musicians to read is zero
	je endLoad							; end the load if the number of musicians to read is zero

	getMusicians:
		push ebx						; pointer to the beginning of the struct to add to the array		
		push esi						; pointer to the file
		call loadMusician				; load one musician to the struct
		mov esi, eax					; get the file pointer from the loadMusican procedure
		jc endLoad						; stop loading the structs to the array if an error occured
		inc edx							; increment the number of musicians read to the array
		add ebx, TYPE musician			; increment the pointer to the array of structs to add another musician
		loop getMusicians				; get the next musician

	endLoad:
		mov ebx, [ebp + 16]				; reset the pointer to the array of structs to the beginning of the array
		mov eax, edx					; return the number of musicians read

		pop ebp							; restore the base pointer
		ret 12							; remove the parameters from the stack
loadAllMusicians ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; print the content of one musician
; receives:
;	[ebp + 8]  = pointer to the beginning of the struct
; returns:
;	N/A
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
outputMusician PROC
	push ebp							; save the base pointer
	mov ebp, esp						; base of the stack frame

	mov edx, OFFSET outname				; get the "Artist: " string
	call WriteString					; print "Artist: " before the musician name

	mov edx, [ebp + 8]					; set the pointer to the beginning of the struct
	add edx, OFFSET musician.artist		; increment the struct pointer to the musician name
	call WriteString					; print the musician's name

	call Crlf							; skip a line

	mov edx, OFFSET outinstr			; get the "Instrument: " string
	call WriteString					; print "Instrument: " before the musician instrument

	mov edx, [ebp + 8]					; reset the pointer to the beginning of the struct
	add edx, OFFSET musician.instrument	; increment the struct pointer to the musician instrument
	call WriteString					; print the musician's instrument

	call Crlf							; skip a line

	mov edx, OFFSET outage				; get the "Age: " string
	call WriteString					; print "Age: " before the musician age

	mov edx, [ebp + 8]					; reset the pointer to the beginning of the struct
	add edx, OFFSET musician.born		; increment the struct pointer to the musician birth year
	mov ebx, [edx]						; get the year the musician was born

	mov edx, [ebp + 8]					; reset the pointer to the beginning of the struct
	add edx, OFFSET musician.died		; increment the struct pointer to the musician death year
	mov eax, [edx]						; get the year the musician was born
	sub eax, ebx						; subtract the birth year from the death year
	
	call WriteDec						; print the age the musician was when they died

	pop ebp								; restore the base pointer
	ret 4								; remove the parameters from the stack
outputMusician ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; print all of the musicians in the array
; receives:
;	[ebp + 12] = pointer to the beginning of the array
;	[ebp + 8]  = maximum number of musicians to read
; returns:
;	N/A
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
outputAllMusicians PROC
	push ebp							; save the base pointer
	mov ebp, esp						; base of the stack frame

	mov edi, [ebp + 12]					; set the pointer to the beginning of the struct array
	mov ecx, [ebp + 8]					; set the maximum number of musicians to read

	cmp ecx, 0							; check if the number of musicians to read is zero
	je endPrint							; do not print anything if the number of musicians to read is zero

	call Crlf							; skip a line

	printMusicians:
		push edi						; pointer to the beginning of the struct array
		call outputMusician				; print one musician
		cmp ecx, 1						; check if 
		je endPrint						; stop printing at the last struct in the array

		add edi, TYPE musician			; increment the pointer to the struct array
		call Crlf						; skip a line
		call Crlf						; skip a line
		loop printMusicians				; print each musician in the array

	endPrint:
		call Crlf						; skip a line
		pop ebp							; restore the base pointer
		ret 8							; remove the parameters from the stack
outputAllMusicians ENDP

END main