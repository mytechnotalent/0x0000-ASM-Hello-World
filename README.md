<img src="https://github.com/mytechnotalent/0x0000-ASM-Hello-World/blob/master/0x0000-ASM-Hello-World.png?raw=true">

## FREE Reverse Engineering Self-Study Course [HERE](https://github.com/mytechnotalent/Reverse-Engineering-Tutorial)

<br>

# 0x0000-ASM-Hello-World
0x0000-ASM-Hello-World Windows Console App written in Assembler.

<br>

## Credit
### Windows Internals Crash Course by Duncan Ogilvie
#### [SLIDES](https://mrexodia.github.io/files/wicc-2023-slides.pdf)
#### [VIDEO](https://youtu.be/I_nJltUokE0?si=Q1yOfZuIF5jOa_2U)

## Reverse Engineering
```
CTRL-G ntdll.LdrInitializeThunk & cal <ntdll.NtContinue>

Restart
INT3 breaktpoint at <ntdll.LdrInitializeThunk>
DLL Loaded: kernel32.dll
DLL Loaded: KernelBase.dll
INT3 breakpoint "DllMain (kernelbase.dll" at <kernelbase.OptionalHeader.AddressOfEntryPoint>
-- Empty Console Window --
System breakpoint reached! jmp ntdll.XXXXXXXXXXXX
INT3 breakpoint at ntdll.XXXXXXXXXXXXXXXX call <ntdll.NtContinue>
INT3 breakpoint "entry breakpoint" at <0x0000-asm-hello-world.mainCRTStartup>
-- Console Window - Hello World --
Process stopped with exit code 0x1 (1)
```

<br>

## Code
```
;==============================================================================
; File:     main.asm
;
; Purpose:  0x0000-ASM-Hello-World Windows Console App written in Assembler.
;
; Platform: Windows x64
; Author:   Kevin Thomas
; Date:     2025-06-29
; Updated:  2025-06-29
;==============================================================================

extrn  GetStdHandle  :PROC
extrn  WriteConsoleA :PROC

.data
       msgText      db "Hello World", 0Ah, 0 
       writtenChars dq 0

.code

;------------------------------------------------------------------------------
; mainCRTStartup PROC main entry point
;------------------------------------------------------------------------------
mainCRTStartup PROC
  SUB    RSP, 28h                 ; reserve 32-byte shadow space, +8 16-b align 

  ; HANDLE WINAPI GetStdHandle(
  ;   _In_ DWORD nStdHandle
  ; );
  MOV    RCX, -11                 ; 1st param = nStdHandle - STD_OUTPUT_HANDLE
  CALL   GetStdHandle             ; call Win32 API

  ; BOOL WINAPI WriteConsole(
  ;   _In_             HANDLE  hConsoleOutput,
  ;   _In_       const VOID    *lpBuffer,
  ;   _In_             DWORD   nNumberOfCharsToWrite,
  ;   _Out_opt_        LPDWORD lpNumberOfCharsWritten,
  ;   _Reserved_       LPVOID  lpReserved
  ; );
  LEA    R9, writtenChars         ; 4th param = lpNumberOfCharsWritten
  MOV    R8, 12                   ; 3rd param = nNumberOfCharsToWrite
  LEA    RDX, msgText             ; 2nd param = *lpBuffer
  MOV    RCX, RAX                 ; 1st param = hConsoleOutput
  CALL   WriteConsoleA            ; call Win32 API

  ADD   RSP, 28h                  ; restore 32-byte shadow space, +8 16-b align
  ret                             ; return to caller
mainCRTStartup ENDP

END
```

<br>

## License
[MIT](https://github.com/mytechnotalent/0x0000-ASM-Hello-World/blob/master/LICENSE.txt)
