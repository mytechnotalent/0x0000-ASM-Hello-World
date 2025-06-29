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
extrn  ExitProcess   :PROC

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

  ; void ExitProcess(
  ;   [in] UINT uExitCode
  ; );
  MOV    RCX, 0                   ; 1st param = uExitCode
  CALL   ExitProcess              ; call Win32 API

mainCRTStartup ENDP

END
