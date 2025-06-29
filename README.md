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

<br>

## Reverse Engineering
### Explanation of Execution Trace in x64dbg

This section provides a detailed analysis of each recorded event in the debug trace of a handcrafted Windows x64 assembly console application. Each line in the trace is explored as a discrete phase in system startup, bridging low-level loader behavior with practical debugging insights. Intended for systems programmers and reverse engineers, the breakdown clarifies exactly what Windows is doing under the hood when your EXE first breathes.

---

`INT3 breakpoint at <ntdll.LdrInitializeThunk>`

This marks the precise handoff from the Windows kernel to user-mode execution. After the OS invokes `NtCreateUserProcess`, it prepares an initial thread whose instruction pointer is aimed at `ntdll!LdrInitializeThunk`. When this breakpoint is hit, the process is paused on its very first instruction in user-space. The loader begins with infrastructure setup—accessing the PEB via `GS:[0x60]`, acquiring loader locks, initializing internal lists like `LdrpLoadedModuleList`, and preparing critical dispatch stubs like `LdrpInitializeProcess`. No application code has been touched yet. This entry point is responsible for loading DLLs, processing relocations, handling TLS (if applicable), and resolving imports. Hitting this breakpoint confirms the EXE loaded successfully and that the initial thread is now executing on user-mode stack and page tables. It’s ground zero for all Windows process-level code.

---

`DLL Loaded: C:\Windows\System32\kernel32.dll`

Once `LdrpInitializeProcess` inspects the Import Address Table of your binary, it discovers that kernel32.dll must be loaded. This DLL is foundational to every Win32 process, exporting APIs like `GetStdHandle`, `WriteConsole`, and `ExitProcess`—all of which your assembly program relies on. The loader maps the DLL into memory, aligns it according to section permissions and alignment hints, and checks for any base relocations. Once mapped, it fills in IAT entries in your EXE’s `.rdata` section with actual addresses of imported functions using kernel32's export table. It also builds an `LDR_DATA_TABLE_ENTRY` structure and inserts it into `PEB_LDR_DATA`’s module lists. The presence of this message in the log confirms that this critical dependency has been successfully mapped and prepped for initialization.

---

`DLL Loaded: C:\Windows\System32\KernelBase.dll`

Immediately following kernel32.dll, the loader brings in KernelBase.dll, a dependency of kernel32. Since Windows 7, kernel32 forwards much of its implementation to KernelBase, which houses the actual logic for most API calls. KernelBase is mapped with identical rigor—alignment, header validation, relocation, and dependency resolution. Its own PE structures are parsed and loaded into memory, and its exported symbols (like the real implementation of `WriteConsole`) become available. This stage is not just procedural—it’s necessary. Without KernelBase, kernel32’s import forwarding would leave unresolved references. When KernelBase successfully loads, your application’s API surface is effectively complete, primed for actual runtime calls from user code.

---

`DllMain (kernelbase.dll) at <kernelbase.OptionalHeader.AddressOfEntryPoint>`

At this stage, KernelBase’s `DllMain` function is called with the `DLL_PROCESS_ATTACH` parameter. This function resides at the address calculated by `ImageBase + AddressOfEntryPoint` in the PE Optional Header. This attach notification allows KernelBase to finalize its initialization. Internally, it may set up synchronization mechanisms, initialize internal memory managers, or register certain subsystems. The loader invokes this routine while holding the loader lock, which means KernelBase must avoid triggering recursive loading. If any TLS data or constructor logic exists, it may also be processed here. Reaching this point indicates that not only has the DLL been mapped, but it’s also run its bootstrap logic and is now stable and callable.

---

`-- Empty Console Window --`

Here, the operating system has now initialized the console subsystem. Because the PE header for your EXE specifies the `IMAGE_SUBSYSTEM_WINDOWS_CUI`, Windows spawns a user-mode console host (`conhost.exe`), which draws a window and binds the console session to the current process. At this point, standard handles (`stdin`, `stdout`, `stderr`) are created and accessible, typically with pseudo-handles like `-11` for STDOUT. These are returned via `GetStdHandle` and are required for any output to appear. Importantly, this happens before your program writes anything, and no user instructions have executed. The console is blank but initialized—primed to render output as soon as your code issues its first API call to write a string.

---

`INT3 breakpoint "DllMain (kernel32.dll)" at <kernel32.OptionalHeader.AddressOfEntryPoint>`

Now it’s kernel32.dll’s turn to execute its initialization routine. Like KernelBase, this occurs via a call to DllMain with `DLL_PROCESS_ATTACH`. Kernel32’s DllMain may perform dynamic library registrations, set up heap tracking, or establish global locks. It may also initialize legacy subsystems for backward compatibility. Because kernel32 is involved in virtually every user-mode API, its initialization marks the point where the process becomes fully equipped to invoke core OS services. This breakpoint often signifies the last phase of DLL setup before the loader transitions to user code.

---

`System breakpoint reached! jmp ntdll.7FFc53D0478C`

This log entry reflects an internal INT3 instruction issued by the loader stub, usually in `LdrpDispatchUserCallTarget`. Its purpose is purely diagnostic—it alerts any attached debugger that loader initialization is complete and that the next action will be a jump to your EXE’s entry point. This is the dividing line between system-controlled setup and application-directed execution. No state changes occur other than the placement of the INT3 breakpoint and its handler logic. If you wanted to attach a debugger and inspect the EXE just before it runs, this is your golden moment.

---

`INT3 breakpoint at ntdll.00007FFC63C15FD3! call <ntdll.NtContinue>`

This is where the magic happens. The call to `NtContinue` provides a fully prepared CONTEXT record—the same structure used by debuggers and exception handlers to store register state. This record includes your program’s starting instruction pointer (`RIP` = `mainCRTStartup`), stack pointer (`RSP`), and general-purpose registers. When this call is made, the OS resumes execution from this saved context as if your EXE had always been running. It marks the final detachment from loader scaffolding and the beginning of real code execution. From this point onward, the CPU executes only what you wrote.

---

`INT3 breakpoint "entry breakpoint" at <0x0000-asm-hello-world.mainCRTStartup>`

You’ve now arrived at your code. This is your declared entry point—`mainCRTStartup`. It’s the first instruction you control. In your assembly file, this begins with `sub rsp, 28h`, reserving shadow space and aligning the stack per Win64 calling conventions. From there, you invoke `GetStdHandle` to retrieve the console handle, and pass that along with your string to `WriteConsole`. This breakpoint is both symbolic and functional: it means your EXE loaded correctly, your imports resolved, your memory layout succeeded, and your process is now executing logic written entirely by you, unassisted by C runtimes or helper libraries.

---

`-- Console Window - Hello World --`

This means your call to `WriteConsoleA` completed successfully. The string stored in `.data`—"Hello World" followed by a newline and null terminator—was passed to the WinAPI, copied into the output buffer, and rendered to the active screen buffer managed by `conhost.exe`. Your parameters were correctly constructed (hConsole in RCX, buffer in RDX, length in R8, address of DWORD out-param in R9), and the stack was aligned, meaning that the underlying syscall completed without error. The console shows your output and the cursor rests on the next line. Congratulations—your assembly code spoke directly to the OS and the OS answered by painting pixels to glass.

---

`Process stopped with exit code 0x0 (0)`

This final log line means that the process exited normally. Your final `call ExitProcess` (with RCX = 0) passed control into kernel32, which issued a structured teardown: calling `DllMain(..., DLL_PROCESS_DETACH)` for each module in reverse load order, releasing memory heaps, invalidating handles, tearing down TLS slots, and deallocating any pending object references. Once all this was complete, `NtTerminateProcess` was called, signaling the kernel to cleanly remove the process object from the system. The exit code of `0x0` is a standard indicator of success. Your process began as a block of memory on disk and ended as a fully realized execution instance that loaded, ran, rendered, and died cleanly—all under your command.

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
