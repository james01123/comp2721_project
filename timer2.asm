; Authors: Darren Luck A00964037
;          Eric Hemming A01290673
;          Kiefer Thom  A01284069
; Timer 
; Compile with: nasm -f elf timer.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 timer.o -o timer
; Run with: ./timer

; iPrint function referenced from https://asmtutor.com/
 
;------------------------------------------
; void iprint(Integer number)
; Integer printing function (itoa)

; Moving any current values in registers to preserve data while they are in use.
iprint:
    push    eax             ; preserve eax on the stack to be restored after function runs
    push    ecx             ; preserve ecx on the stack to be restored after function runs
    push    edx             ; preserve edx on the stack to be restored after function runs
    push    esi             ; preserve esi on the stack to be restored after function runs
    mov     ecx, 0          ; counter of how many bytes we need to print in the end
 
; Pushes all ascii characters until we hit null.
divideLoop:
    inc     ecx             ; count each byte to print - number of characters
    mov     edx, 0          ; empty edx
    mov     esi, 10         ; mov 10 into esi, prepping registers
    idiv    esi             ; divide eax by esi,  the remainder will go to edx abd answer goes into eax
    add     edx, 48         ; convert edx to it's ascii representation - edx holds the remainder after a divide instruction
    push    edx             ; push edx (string representation of an intger) onto the stack
    cmp     eax, 0          ; can the integer be divided anymore?
    jnz     divideLoop      ; jump to the label divideLoop if flag in previous line is NOT 0
 
printLoop:
    dec     ecx             ; count down each byte that we put on the stack
    mov     eax, esp        ; mov the stack pointer into eax for printing
    call    sprint          ; call our string print function, prints 1 ascii character at a time
    pop     eax             ; remove last character from the stack to move esp forward
    cmp     ecx, 0          ; have we printed all bytes we pushed onto the stack? "check if count in ecx is 0"
    jnz     printLoop       ; jump to the label printLoop if flag in previous line in NOT 0.
 
    pop     esi             ; restore esi from the value we pushed onto the stack at the start
    pop     edx             ; restore edx from the value we pushed onto the stack at the start
    pop     ecx             ; restore ecx from the value we pushed onto the stack at the start
    pop     eax             ; restore eax from the value we pushed onto the stack at the start
    ret                     ; return to where iprint is called. (line 187)
 

;------------------------------------------
; int slen(String message)
; String length calculation function
slen:
    push    ebx                 ;saving value in ebx
    mov     ebx, eax            ; 
 
nextchar:
    cmp     byte [eax], 0       ; comparing byte value of eax until we reach null character '0' which denotes end of the string
    jz      finished            ; flag from previous line is 0 we have reached the end of the string
    inc     eax                 ; incrementing through string
    jmp     nextchar            ; loop to start of nextchar
 
finished:
    sub     eax, ebx            ; recovering values stored on stack into their registers.
    pop     ebx
    ret
 
 
;------------------------------------------
; void sprint(String message)
; String printing function


sprint:
    push    edx         ;Preserving values in registers by storing them on stack LIFO
    push    ecx
    push    ebx
    push    eax
    call    slen
 
    mov     edx, eax    ;edx is message length, 
    pop     eax         ; restore value for eax
 
    mov     ecx, eax    ; outs address where to start printing into ecx
    mov     ebx, 1      ; where to write to, 1 is standard output stdout
    mov     eax, 4      ;opcode for sys_write
    int     80h         ;return control to the kernal to execute
 
    pop     ebx     ;return original values stored on stack to their appropriate registers. LIFO
    pop     ecx
    pop     edx
    ret
 
 
SECTION .data                                           ; define constant variables
                                                        ; strings, magic numbers, terminating strings
msg1        db      '***Starting Stopwatch*** ', 10     ; message string printed at program start
msg1_l      equ     $ - msg1
msg2        db      ' Seconds ', 10                     ; message string of units to print
msg2_l      equ     $ - msg2
lapmsg      db      'Laptime: '                         ; message string for saying Laptime:
lapmsg_l    equ     $ - lapmsg                          ; & is the current address, subtract that from the lapmsg start.
totalmsg    db      10, 'Total time: '                  ; message string for stating "Total time"
totalmsg_l  equ     $ - totalmsg                        ; & is the current address, subtract that from the totalmsg start. 
eMsg        db      10, '***Closing Stopwatch***', 0h   ; What to print when exitting program
eMsg_l      equ     $ - eMsg                            ; Length of the exitting msg
fMsg        db      10, 'Fastest Lap was: '             ; Message for saying fastest lap
fMsg_l      equ     $ - fMsg                            ; length of the message
cMsg        db      "Total Laps were: "                 ; Message for total laps
cMsg_l      equ     $ - cMsg                            ; length of the message
oMsg        db      'Press l to finish lap and q to quit', 10   ; Open message to explain program
oMsg_l      equ     $ - oMsg                            ; length of openning message
 
SECTION .bss                                            ; reservering space in memory for future data
sinput2:    resb 1                                      ; For holding 1 character;
iTime:      resb 4                                      ; reserve 4 bytes for initial timestamp 
cTime:      resb 4                                      ; reserve 4 bytes for timestamp after 'enter' press by user
fastestLap  resb 4                                      ; reserve 4 bytes to hold time of fastest lap
lastTimestamp resb 4                                    ; reserver 4 bytes to hold the last timestamp
totalLaps   resb 4                                      ; reserve 4 bytes to hold total laps;

SECTION .text                                           ; always has _start if ld or main if gcc depending on compiler
                                                        ; rax 64bit register / eax 32bit register
                                                        ; registers: hardware implemented variables
global  _start
 
_start:

    mov     eax, 13                 ; invoke SYS_TIME (kernel opcode 13) (get timestamp) It is second since the start of time which is January 1st 1970
    int     80h                     ; call the kernel
    mov     [iTime], eax            ; move initial timestamp in eax to var1
    mov     [lastTimestamp], eax    ; Set the initial first lap time to starting time

    ; Print of that you are starting the stopwatch;
    mov	    edx, msg1_l         ;message length
    mov	    ecx, msg1           ;message to write
    mov	    ebx, 1              ;file descriptor (stdout)
    mov     eax, 4              ;system call number (sys_write)
    int	    0x80                ;call kernel
    
    ; Print out the instructions to use the stopwatch
    mov	    edx, oMsg_l         ;message length
    mov	    ecx, oMsg           ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov     eax,4               ;system call number (sys_write)
    int	    0x80                ;call kernel

    
    mov     [fastestLap], byte 255  ; setting fastest lap to a high number
    mov     eax, 0                  ; put 0 in eax
    mov     [totalLaps], eax        ; total laps



    loopName:                   ; loop for lap function

    ; ---User input delay---
    mov     edx, 1          ; number of bytes to read
    mov     ecx, sinput2    ; reserved space to store our input (known as a buffer)
    mov     ebx, 0          ; write to the STDIN file
    mov     eax, 3          ; invoke SYS_READ (kernel opcode 3)
    int     80h             ; command to kernal


    push    eax             ; save eax on the stack
    mov     al, [sinput2]   ; al is 8bits for comparing 1 character
    cmp     al, 'l'         ; l means a lap has passed
    jnz     exitLocation    ; jnz checks if the cmp result was 0, if they didn't input 'l' program quits
    pop     eax             ; retrieve eax on the stack
    


;   Get this next timestamp
    mov     eax, 13         ; invoke SYS_TIME (kernel opcode 13) (get timestamp)
    int     80h             ; call the kernel
    

    ; Print out "Total time: "
    push    eax                ; save eax current value on the stack
    mov	    edx, totalmsg_l     ;message length
    mov	    ecx, totalmsg       ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov	    eax,4               ;system call number (sys_write)
    int	    0x80                ;call kernel
    pop     eax                 ; return eax from the stack
    
    ; Print out the total time so far
    mov     [cTime], eax        ; move the timestamp after user presses enter to cTime
    mov     ebx, [iTime]        ; move iTime (initialy timestamp at program start) into ebx register
    sub     eax, ebx            ; subtraction function of ebx (initial timestamp) from eax (timestamp after 'enter' press)
    call    iprint              ; call integer print function to print out seconds difference
    
    ; Print out "seconds "
    mov	    edx, msg2_l         ;message length
    mov	    ecx, msg2           ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov	    eax,4               ;system call number (sys_write)
    int	    0x80                ;call kernel
    
    ; Print out "Laptime: "
    push    eax                ; save eax current value on the stack
    mov	    edx,lapmsg_l        ;message length
    mov	    ecx, lapmsg         ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov	    eax,4               ;system call number (sys_write)
    int	    0x80                ;call kernel
    pop     eax                 ; return eax from the stack

    
    ; Print out the time for that lap
    mov     eax, [cTime]         ; Put the current timestamp into eax register
    mov     ebx, [lastTimestamp]; Put the timestamp of end of last lap into ebx register
    sub     eax, ebx            ; get the difference between the two timp stamps
    
    cmp     eax, [fastestLap]   ; compares eax to fastestLap
    jl      newFastest          ; Checks the less flag if it was set go to newFastest
returnSpot:

    call iprint             ; call integer print function to print out seconds difference

    ; Print out "seconds "
    mov	    edx, msg2_l         ;message length
    mov	    ecx, msg2           ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov	    eax,4               ;system call number (sys_write)
    int	    0x80                ;call kernel


    ; Save the currentTimestamp into the lastTimestamp
    mov     eax, [cTime]         ; currentTime into eax register
    mov     [lastTimestamp], eax    ; currentTime stored into lastTimestamp
    
    ; Increase the lap count by one
    mov     eax, [totalLaps]    ; moves the total laps amount into eax
    inc     eax                 ; increase the amount in eax by one: add eax, 1 would do same thing
    mov     [totalLaps], eax    ; save the new lap amount
    
    jmp     loopName            ; Jump to the loop section
    
exitLocation:


        ; Print out "Total time: "
    push    eax                 ; save eax current value on the stack
    mov	    edx, totalmsg_l     ;message length
    mov	    ecx, totalmsg       ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov	    eax,4               ;system call number (sys_write)
    int	    0x80                ;call kernel
    pop     eax                 ; return eax from the stack
    
    ; Print out the total time so far
    mov     eax, [cTime]         ; move cTime (timestamp after enter press) into eax register
    mov     ebx, [iTime]         ; move iTime (initialy timestamp at program start) into ebx register
    sub     eax, ebx            ; subtraction function of ebx (initial timestamp) from eax (timestamp after 'enter' press)
    call    iprint              ; call integer print function to print out seconds difference
    
    ; Print out "seconds "
    mov 	edx, msg2_l         ;message length
    mov	    ecx, msg2           ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov 	eax,4               ;system call number (sys_write)
    int	    0x80                ;call kernel

    ; Print out "Total Laps "
    mov	    edx, cMsg_l         ;message length
    mov	    ecx, cMsg           ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov 	eax,4               ;system call number (sys_write)
    int 	0x80                ;call kernel
    
    ; Print out the totalLaps amount
    mov     eax, [totalLaps]    ; get the total lap amounts
    call    iprint              ; print them

    ; Print out "Fastest laptime "
    mov	    edx, fMsg_l         ;message length
    mov	    ecx, fMsg           ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov 	eax,4               ;system call number (sys_write)
    int 	0x80                ;call kernel
    
    ; Print out fastest lap amount
    mov     eax, [fastestLap]
    call    iprint
    
    ; Print out "seconds "
    mov	    edx, msg2_l         ;message length
    mov	    ecx, msg2           ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov	    eax,4               ;system call number (sys_write)
    int	    0x80                ;call kernel

    ; Print out "exit message "
    mov	    edx, eMsg_l         ;message length
    mov	    ecx, eMsg           ;message to write
    mov	    ebx,1               ;file descriptor (stdout)
    mov	    eax,4               ;system call number (sys_write)
    int	    0x80                ;call kernel

    ; Quit the program   
    mov     ebx, 0              ;exit code
    mov     eax, 1              ;system call number to quit
    int     80h                 ; give control to kernal
   
newFastest:
    mov     [fastestLap], eax;  ;move the current laptime into fastLap
    jmp     returnSpot          ;go back to where we left the code

