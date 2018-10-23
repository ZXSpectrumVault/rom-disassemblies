; **********************************************
; *** SPANISH SPECTRUM 128 ROM 0 DISASSEMBLY ***
; **********************************************

; The Spectrum ROMs are copyright Amstrad, who have kindly given permission
; to reverse engineer and publish Spectrum ROM disassemblies.

; =====
; NOTES
; =====

; ------------
; Release Date
; ------------
; 23rd January 2017

; ------------------------
; Disassembly Contributors
; ------------------------
; Paul Farrow (www.fruitcake.plus.com)

; -------
; Markers
; -------
; The following markers appear throughout the disassembly:
;
; [...] = Indicates a comment about the code.
; ????  = Information to be determined.
;
; For bugs, the following marker format is used:
;
; [*BUG* - xxxx. Credit: yyyy]  = Indicates a confirmed bug, with a description 'xxxx' of it and the discoverer 'yyyy'.
; [*BUG*? - xxxx. Credit: yyyy] = Indicates a suspected bug, with a description 'xxxx' of it and the discoverer 'yyyy'.
;
; Since many of the Spanish 128 ROM routines were re-used in the UK Spectrum 128, Spectrum +2 and +3, where a bug was originally identified
; in the Spectrum +2 or +3 the discoverer is acknowledged along with who located the corresponding bug in the Spectrum 128.
;
; For every bug identified, an example fix is provided and the author acknowledged. Some of these fixes can be made directly within the routines
; affected since they do not increase the length of those routines. Others require the insertion of extra instructions and hence these cannot be
; completely fitted within the routines affected. Instead a jump must be made to a patch routine located within a spare area of the ROM.


; =================
; ASSEMBLER DEFINES
; =================

;TASM directives:

#DEFINE DEFB .BYTE
#DEFINE DEFW .WORD
#DEFINE DEFM .TEXT
#DEFINE DEFS .BLOCK
#DEFINE END  .END
#DEFINE EQU  .EQU
#DEFINE ORG  .ORG

#define BUG_FIXES      ; Specify to patch with fixes for all known bugs within ROM 0

; All bugs have been fixed apart from four. There is not enough free space within the ROM to make the fix for the bugs at $1ADF and $22E4.
; Fixing the bug at $152E would break compatibility with 48K mode and so has not been changed. The bug at $02C0 does not yet have a solution.


; ==============================
; REFERENCE INFORMATION - PART 1
; ==============================

; ==================
; Timing Information
; ==================
; Clock Speed   = 3.54690 MHz (48K Spectrum clock speed was 3.50000 MHz)
; Scan line     = 228 T-states (48K Spectrum was 224 T-states).
; TV scan lines = 311 total, 63 above picture (48K Spectrum had 312 total, 64 above picture).


; ===========
; I/O Details
; ===========

; -------------
; Memory Paging
; -------------
; Memory paging is controlled by I/O port:
; $7FFD (Out) - Bits 0-2: RAM bank (0-7) to page into memory map at $C000.
;               Bit 3   : 0=SCREEN 0 (normal display file in bank 5), 1=SCREEN 1 (shadow display file in bank 7).
;               Bit 4   : 0=ROM 0 (128K Editor), 1=ROM 1 (48K BASIC).
;               Bit 5   : 1=Disable further output to this port until a hard reset occurs.
;               Bit 6-7 : Not used (always write 0).
;
; The Editor ROM (ROM 0) always places a copy of the last value written to port $7FFD
; into new system variable BANK_M ($5B5C).
;
; ----------
; Memory Map
; ----------
; ROM 0 or 1 resides at $0000-$3FFF.
; RAM bank 5 resides at $4000-$7FFF always.
; RAM bank 2 resides at $8000-$BFFF always.
; Any RAM bank may reside at $C000-$FFFF.
;
; -------------------
; Shadow Display File
; -------------------
; The shadow screen may be active even when not paged into the memory map.
;
; -----------------
; Logical RAM Banks
; -----------------
; Throughout ROM 0, memory banks are accessed using a logical numbering scheme, which
; maps to physical RAM banks as follows:
;
; Logical Bank   Physical Bank
; ------------   -------------
;     $00             $01
;     $01             $03
;     $02             $04
;     $03             $06
;     $04             $07
;     $05             $00
;
; This scheme makes the RAM disk code simpler than having to deal directly with physical RAM bank numbers.

; -------------------------
; AY-3-8912 Sound Generator
; -------------------------
; The AY-3-8912 sound generator is controlled by two I/O ports:
; $FFFD (Out)    - Select a register 0-14.
; $FFFD (In)     - Read from the selected register.
; $BFFD (In/Out) - Write to the selected register. The status of the register can also be read back.
;
; The AY-3-8912 I/O port A is used to drive the RS232 and Keypad sockets.
;
; Register       Function                        Range
; --------       --------                        -----
; 0              Channel A fine pitch            8-bit (0-255)
; 1              Channel A course pitch          4-bit (0-15)
; 2              Channel B fine pitch            8-bit (0-255)
; 3              Channel B course pitch          4-bit (0-15)
; 4              Channel C fine pitch            8-bit (0-255)
; 5              Channel C course pitch          4-bit (0-15)
; 6              Noise pitch                     5-bit (0-31)
; 7              Mixer                           8-bit (see end of file for description)
; 8              Channel A volume                4-bit (0-15, see end of file for description)
; 9              Channel B volume                4-bit (0-15, see end of file for description)
; 10             Channel C volume                4-bit (0-15, see end of file for description)
; 11             Envelope fine duration          8-bit (0-255)
; 12             Envelope course duration        8-bit (0-255)
; 13             Envelope shape                  4-bit (0-15)
; 14             I/O port A                      8-bit (0-255)
;
; See the end of this document for description on the sound generator registers.
;
; ----------------------------------
; I/O Port A (AY-3-8912 Register 14)
; ----------------------------------
; This controls the RS232 and Keypad sockets.
; Select the port via a write to port $FFFD with 14, then read via port $FFFD and write via port $BFFD.
;
; Bit 0: KEYPAD CTS (out) - 0=Spectrum ready to receive, 1=Busy
; Bit 1: KEYPAD RXD (out) - 0=Transmit high bit,         1=Transmit low bit
; Bit 2: RS232  CTS (out) - 0=Spectrum ready to receive, 1=Busy
; Bit 3: RS232  RXD (out) - 0=Transmit high bit,         1=Transmit low bit
; Bit 4: KEYPAD DTR (in)  - 0=Keypad ready for data,     1=Busy
; Bit 5: KEYPAD TXD (in)  - 0=Receive high bit,          1=Receive low bit
; Bit 6: RS232  DTR (in)  - 0=Device ready for data,     1=Busy
; Bit 7: RS232  TXD (in)  - 0=Receive high bit,          1=Receive low bit
;
; See the end of this document for the pinouts for the RS232 and KEYPAD sockets.

; ------------------
; Standard I/O Ports
; ------------------
; See the end of this document for descriptions of the standard Spectrum I/O ports.


; ==================
; Error Report Codes
; ==================

; ---------------------------
; Standard Error Report Codes
; ---------------------------
; See the end of this document for descriptions of the standard error report codes.

; ----------------------
; New Error Report Codes
; ----------------------
; a - MERGE error                      MERGE! would not execute for some reason - either size or file type wrong.
; b - Wrong file type                  A file of an inappropriate type was specified during RAM disk operation, for instance a CODE file in LOAD!"name".
; c - CODE error                       The size of the file would lead to an overrun of the top of memory.
; d - Too many brackets                Too many brackets around a repeated phrase in one of the arguments.
; e - File already exists              The file name specified has already been used.
; f - Invalid name                     The file name specified is empty or above 10 characters in length.
; g - File does not exist              [Never used by the ROM].
; h - File does not exist              The specified file could not be found.
; i - Invalid device                   The device name following the FORMAT command does not exist or correspond to a physical device.
; j - Invalid baud rate                The baud rate for the RS232 was set to 0.
; k - Invalid note name                PLAY came across a note or command it didn't recognise, or a command which was in lower case.
; l - Number too big                   A parameter for a command is an order of magnitude too big.
; m - Note out of range                A series of sharps or flats has taken a note beyond the range of the sound chip.
; n - Out of range                     A parameter for a command is too big or too small. If the error is very large, error L results.
; o - Too many tied notes              An attempt was made to tie too many notes together.
; p - Parameter error                  This error is given when too many PLAY channel strings are specified. Up to 8 PLAY channel strings are supported
;                                      by MIDI devices such as synthesisers, drum machines or sequencers. Note that a PLAY command with more than 8 strings
;                                      cannot be entered directly from the Editor. The error is also supposed produced with certain invalid parameters to the
;                                      Editor commands EDIT, DELETE, RENUMBER and WIDTH.


; ================
; System Variables
; ================

; --------------------
; New System Variables
; --------------------
; These are held in the old ZX Printer buffer at $5B00-$5BFF. Many of the new system variables made their way into the
; UK Spectrum 128 and so their names have been used here (note that some of the names conflict with the system variables
; used by the ZX Interface 1). For those whether there is not an equivalent in the UK Spectrum 128 suitable names have
; been allocated (marked with a ^). Many of the system variables are used for multiple purposes and so to reduce confusion
; when reading the disassembly, several names are used for these system variables. The variables have been grouped by
; function so that their structure is clearer to see, but this means it is not always possible to list them in address order.

SWAP        EQU $5B00  ;  20   Swap paging subroutine.
YOUNGER     EQU $5B14  ;   9   Return paging subroutine.
ONERR       EQU $5B1D  ;  18   Error handler paging subroutine.
PIN         EQU $5B2F  ;   5   RS232 input pre-routine.
POUT        EQU $5B34  ;  22   RS232 token output pre-routine. This can be patched to bypass the control code filter.
POUT2       EQU $5B4A  ;  14   RS232 character output pre-routine.
TARGET      EQU $5B58  ;   2   Address of subroutine to call in ROM 1.
RETADDR     EQU $5B5A  ;   2   Return address in ROM 0.
BANK_M      EQU $5B5C  ;   2   Copy of last byte output to I/O port $7FFD.
RAMRST      EQU $5B5D  ;   1   Stores instruction RST $08 and used to produce a standard ROM error. Changing this instruction allows 128 BASIC to be extended (see end of this document for details).
RAMERR      EQU $5B5E  ;   1   Error number for use by RST $08 held in RAMRST.
BAUD        EQU $5B5F  ;   2   Baud rate timing constant for RS232 socket. Default value of 11. [Name clash with ZX Interface 1 system variable at $5CC3]
SERFL       EQU $5B61  ;   2   Second character received flag:
                       ;         Bit 0   : 1=Character in buffer.
                       ;         Bits 1-7: Not used (always hold 0).
              ; $5B62  ;       Received Character.
COL         EQU $5B63  ;   1   Current column from 1 to WIDTH.
WIDTH       EQU $5B64  ;   1   Paper column width. Default value of 80. [Name clash with ZX Interface 1 Edition 2 system variable at $5CB1]
TVPARS      EQU $5B65  ;   1   Number of inline parameters expected by RS232 (e.g. 2 for AT).
FLAGS3      EQU $5B66  ;   1   Flags: [Name clashes with the ZX Interface 1 system variable at $5CB6]
                       ;         Bit 0: 1=BASIC/Calculator mode, 0=Editor mode.
                       ;         Bit 1: 1=???? 1=Auto-run loaded BASIC program, 0=Do not auto-run loaded BASIC program / 1=BASIC/Calculator mode, 0=Editor mode / 1=Delete operation, 0=Cursor move operation. ???? might be 1=line changed (Enter, cursor down, delete), 0=unchanged
                       ;         Bit 2: 1=Editing RAM disk catalogue.
                       ;         Bit 3: 1=Using RAM disk commands, 0=Using cassette commands.
                       ;         Bit 4: 1=Indicate LOAD.
                       ;         Bit 5: 1=Indicate SAVE.
                       ;         Bit 6; 1=Indicate MERGE.
                       ;         Bit 7: 1=Indicate VERIFY.
N_STR1      EQU $5B67  ;  10   Used by RAM disk to store a filename. [Name clash with ZX Interface 1 system variable at $5CDA]

ED_LINE     EQU $5B67  ;^  2   Used by the Editor to store the line number of the BASIC line that contains the cursor.
ED_ATTA     EQU $5B69  ;^  2   Used by the Editor to store the address of the cursor position within the attributes file when awaiting a key press.
ED_COL      EQU $5B6B  ;^  1   Used by the Editor to store the cursor column number.
ED_ROW      EQU $5B6C  ;^  1   Used by the Editor to store the cursor row number.
ED_IDNT     EQU $5B6D  ;^  1   Used by the Editor to store the indentation column when editing a string variable. ???? and BASIC?
ED_XXXX     EQU $5B6E  ;^  1   ???? Used by the Editor to store the row number of ????

EB_FLGS     EQU $5B72  ;^  1   Used by the Editor to store various flags used when ???? BASIC :
                       ;         Bit 0   : ????
                       ;         Bit 1   : 1=On first row of the BASIC line.
                       ;         Bit 2   : 1=Not within a quoted string.
                       ;         Bit 3   : 1=Start of a new statement within the BASIC line.
                       ;         Bit 4   : ????
                       ;         Bit 5   : ???? reset when deleting to right. 1=shift rows up?
                       ;         Bit 6   : ????
                       ;         Bit 7   : ???? reset with cursor up/left, set with cursor down/right

EV_XXXX     EQU $5B70  ;^  2   ???? Used by the String Variable Editor to ????
EV_ADDR     EQU $5B72  ;^  2   Used by the String Variable Editor to store the address of the variable's content.
EV_LEN      EQU $5B74  ;^  2   Used by the String Variable Editor to store the length of the variable.
EV_FLGS     EQU $5B76  ;^  1   Used by the String Variable Editor to store various flags:
                       ;         Bits 0-1: Mode: $00=Overtype, $01=Insert, $10=Indent.
                       ;         Bit 2   : 1=Word Wrap mode.
                       ;         Bit 3   : 1=Indicates within a word. ????
                       ;         Bit 4   : ????
                       ;         Bit 5   : ????
                       ;         Bit 6   : 1=Do not update display file during edit operation.
                       ;         Bit 7   : ????
ED_ATTP     EQU $5B77  ;^  1   Used by the Editor to store the attribute value at the cursor position when awaiting a key press.

ED_POS      EQU $5B92  ;^  2   Used by the Editor to store the cursor position, i.e. offset character position within the screen until the cursor.
ED_EDIT     EQU $5B94  ;^  2   Used by the Editor to store the line number to edit ???? or with the cursor?.

RNNEXT      EQU $5B6B  ;^  2   Used by the renumber routine to store the address of the next BASIC line.
RNFIRST     EQU $5B6D  ;   2   Used by the renumber routine to store the starting line number. Default value of 10.
RNSTEP      EQU $5B6F  ;   2   Used by the renumber routine to store the step size. Default value of 10.
RNLEN       EQU $5B71  ;^  2   Used by the renumber routine to store the number of digits in a pre-renumbered line number reference. [Name clash with ZX Interface 1 system variable at $5CE7]
RNBUF       EQU $5B73  ;^  4   Used by the renumber routine to store the generated ASCII representation of a new line number.
RNEND       EQU $5B77  ;^  2   Used by the renumber routine to store the address of a referenced BASIC line.
RNPOS       EQU $5B79  ;^  2   Used by the renumber routine to store existing VARS address/current address within a line.
RNLINE      EQU $5B94  ;   2   Used by the renumber routine to store the address of the length bytes in the line currently being renumbered.

KPARAM1     EQU $5B6D  ;^  2   Used by the command parser to store the value of the first keyword parameter.
KPARAM2     EQU $5B6F  ;^  2   Used by the command parser to store the value of the second keyword parameter.
KINDEX      EQU $5B71  ;^  1   Used by the command parser to store the index number of the editor keyword found.
KPARAMS     EQU $5B72  ;^  2   Used by the command parser to store the number of parameters for a new editor command.

F_TBAUD     EQU $5B71  ;^  1   Used by the FORMAT command to temporarily store the specified baud rate.

CP_COL      EQU $5B71  ;^  1   Used by the COPY command to store the column pixel counter.
CP_HROW     EQU $5B72  ;^  1   Used by the COPY command to store the half row counter.

HD_00       EQU $5B71  ;   1   Used by the RAM disk to store file header information (see RAM disk Catalogue section below for details). [Name clash with ZX Interface 1 system variable at $5CE6]
HD_0B       EQU $5B72  ;   2   Used by the RAM disk to store file header information (see RAM disk Catalogue section below for details). [Name clash with ZX Interface 1 system variable at $5CE7]
HD_0D       EQU $5B74  ;   2   Used by the RAM disk to store file header information (see RAM disk Catalogue section below for details). [Name clash with ZX Interface 1 system variable at $5CE9]
HD_0F       EQU $5B76  ;   2   Used by the RAM disk to store file header information (see RAM disk Catalogue section below for details). [Name clash with ZX Interface 1 system variable at $5CEB]
HD_11       EQU $5B78  ;   2   Used by the RAM disk to store file header information (see RAM disk Catalogue section below for details). [Name clash with ZX Interface 1 system variable at $5CED]
SC_00       EQU $5B7A  ;   1   Used by the RAM disk to store secondary file header information (see RAM disk Catalogue section below for details).
SC_0B       EQU $5B7B  ;   2   Used by the RAM disk to store secondary file header information (see RAM disk Catalogue section below for details).
SC_0D       EQU $5B7D  ;   2   Used by the RAM disk to store secondary file header information (see RAM disk Catalogue section below for details).
SC_0F       EQU $5B7F  ;   2   Used by the RAM disk to store secondary file header information (see RAM disk Catalogue section below for details).
OLDSP       EQU $5B81  ;   2   Stores old stack pointer when TSTACK is in use.
SFNEXT      EQU $5B83  ;   2   Used by the RAM disk to store the 'end of catalogue marker'. Pointer to first empty catalogue entry.
SFSPACE     EQU $5B85  ;   3   Used by the RAM disk to store the number of bytes free (3 bytes, 17 bit, LSB first).
ROW01       EQU $5B88  ;   1   Used by the Keypad routines to store key press data for row 3, and communication flags:
                       ;         Bit 0   : 1=Key '+' pressed.
                       ;         Bit 1   : 1=Key '6' pressed.
                       ;         Bit 2   : 1=Key '5' pressed.
                       ;         Bit 3   : 1=Key '4' pressed.
                       ;         Bits 4-5: Always 0.
                       ;         Bit 6   : 1=Indicates successful communications to the keypad.
                       ;         Bit 7   : 1=Indicates communications to the keypad has been established.
ROW23       EQU $5B89  ;   1   Used by the Keypad routines to store key press data for rows 1 and 2:
                       ;         Bit 0: 1=Key ')' pressed.
                       ;         Bit 1: 1=Key '(' pressed.
                       ;         Bit 2: 1=Key '*' pressed.
                       ;         Bit 3: 1=Key '/' pressed.
                       ;         Bit 4: 1=Key '-' pressed.
                       ;         Bit 5: 1=Key '9' pressed.
                       ;         Bit 6: 1=Key '8' pressed.
                       ;         Bit 7: 1=Key '7' pressed.
ROW45       EQU $5B8A  ;   1   Used by the Keypad routines to stores key press data for rows 4 and 5:
                       ;         Bit 0: Always 0.
                       ;         Bit 1: 1=Key '.' pressed.
                       ;         Bit 2: Always 0.
                       ;         Bit 3: 1=Key '0' pressed.
                       ;         Bit 4: 1=Key 'ENTER' pressed.
                       ;         Bit 5: 1=Key '3' pressed.
                       ;         Bit 6: 1=Key '2' pressed.
                       ;         Bit 7: 1=Key '1' pressed.
SYNRET      EQU $5B8B  ;   2   Return address for ONERR routine.
LASTV       EQU $5B8D  ;   5   Last value printed by calculator.
DISKBUF     EQU $5B96  ;^ 32   Used by the RAM disk as a transfer buffer.
                       ;       ...
TSTACK      EQU $5BFE  ;   n   Temporary stack (grows downwards).
ED_FLGS     EQU $5BFF  ;^  1   Editor flags (often accessed via IY-$3B):
                       ;         Bit 0: 1=Invert attribute values, 0=Do not invert attribute values.
                       ;         Bit 1: ????
                       ;         Bit 2: ????
                       ;         Bit 3: 1=Lower edit screen area, 0=Main edit screen area.
                       ;         Bit 4: 1=Variable editing mode, 0=BASIC editing mode.
                       ;         Bit 5: 1=Update changes in the Screen Buffer to the display file. ???? Sometimes seems inverted
                       ;         Bit 6: 1=Editor keyword parameter out of range.
                       ;         Bit 7: ????

; -------------------------
; Standard System Variables
; -------------------------
; These occupy addresses $5C00-$5CB5.
; See the end of this document for descriptions of the standard system variables.

; ------------------
; RAM Disk Catalogue
; ------------------
; The catalogue can occupy addresses $C000-$EBFF in physical RAM bank 7, starting at $EBFF and growing downwards.
;
; Each entry contains 20 bytes:
;   Bytes $00-$09: Filename
;   Bytes $0A-$0C: Start address of file in RAM disk area.
;   Bytes $0D-$0F: Length of file in RAM disk area.
;   Bytes $10-$12: End address of file in RAM disk area (used as current position indicator when loading/saving).
;   Byte  $13    : Flags:
;                     Bit 0   : 1=Entry requires updating.
;                     Bits 1-7: Not used (always hold 0).
;
; The catalogue can store up to 562 entries, and hence the RAM disk can never hold more than 562 files no matter
; how small the files themselves are. Note that filenames are case sensitive.
;
; The shadow screen (SCREEN 1) also resides in physical RAM bank 7 and so if more than 217 catalogue
; entries are created then SCREEN 1 will become corrupted [Credit: Toni Baker, ZX Computing Monthly].
; However, since screen 1 cannot be used from BASIC, it may have been a design decision to allow the
; RAM disk to overwrite it.
;
; The actual files are stored in physical RAM banks 1, 3, 4, 6 and 7 (logical banks 0, 1, 2, 3 and 4),
; starting from $C000 in physical RAM bank 1 and growing upwards until $EBFF in RAM bank 7. Note that
; the use of RAM bank 7 could cause a clash with the catalogue since this is also stored here. Therefore,
; care must be taken when the RAM disk holds more than 64K of data. It was probably a design decision to
; allow this sharing so as to allow the available space to be efficently used whether a lot of small files
; or a few large files.
;
; A file consists of a 9 byte header followed by the data for the file. The header bytes
; have the following meaning:
;   Byte  $00    : File type - $00=Program, $01=Numeric array, $02=Character array, $03=Code/Screen$.
;   Bytes $01-$02: Length of program/code block/screen$/array ($1B00 for screen$).
;   Bytes $03-$04: Start of code block/screen$ ($4000 for screen$).
;   Bytes $05-$06: Offset to the variables (i.e. length of program) if a program. For an array, $05 holds the variable name.
;   Bytes $07-$08: Auto-run line number for a program ($80 in high byte if no auto-run).

; --------------------------
; Editor Workspace Variables
; --------------------------
; These occupy addresses $EC00-$FFFF in physical RAM bank 7, and form a workspace used by 128 BASIC Editor.
;
;???? [There may be similarities to the Spectrum 128 workspace variables]

; $EC00 4736   The Screen Buffer. ???? consists of 148 rows of 32 characters.
; $FE80   64   Banner Display Buffer - 2 rows used for the Editor banner.
; $FEC0    1   ????

; $FEC2    1   ???? number of available (unused) visible rows in the screen buffer?


;THE FOLLOWING ARE RESET TO $00 AS A BLOCK

; $FEC4    2   ???? holds address of previous BASIC line
; $FEC6        Line Number Mapping List, consisting of 22 entries. Each entry holds the Screen Buffer address
;              corresponding to a BASIC line within the program. A line number value of $0000 denotes the end of the list.
;              The first entry is initialised with Screen Buffer address $EC00 and no line number, i.e. $0000.
;              Each entry consists of 4 bytes:
;                Bytes 0-1: Address within Screen Buffer.
;                Bytes 2-3: BASIC line number.
;              The last entry is at $FF1A.
; $FF1E    2   ???? Next Line Screen Buffer Mapping.
;                   Address of next available screen buffer address.
; $FF20    2   ???? line number? ????

;END OF BLOCK


; $FF22    2   ???? holds the next available address within the Screen Buffer when displaying a program.
; $FF24    2   Address of the Screen Buffer. This usually points to $EC00 (the true start of the Screen Buffer) but is temporarily changed by some routines
;              when searching for the BASIC line that contains the cursor.
;              ???? might need to rephrase comments to state 'address within the Screen Buffer'

;  or is this a pointer to the next available location within the Screen Buffer?


; $FF62     2   ???? Start address of a BASIC line in the Screen Buffer, used when copying a BASIC Line from Screen Buffer into the Editing Workspace.


; The lower screen area of the Screen Buffer is followed by a byte $FF.

; ========================
; Called ROM 1 Subroutines
; ========================

ERROR_1     EQU $0008
PRINT_A_1   EQU $0010
GET_CHAR    EQU $0018
NEXT_CHAR   EQU $0020
BC_SPACES   EQU $0030
TOKENS      EQU $0095
BEEPER      EQU $03B5
BEEP        EQU $03F8
SA_ALL      EQU $075A
ME_CONTRL   EQU $08B6
SA_CONTROL  EQU $0970
PRINT_OUT   EQU $09F4
PO_T_UDG    EQU $0B52
PO_MSG      EQU $0C0A
TEMPS       EQU $0D4D
CLS         EQU $0D6B
CLS_LOWER   EQU $0D6E
CL_ALL      EQU $0DAF
CL_ATTR     EQU $0E88
CL_ADDR     EQU $0E9B
ADD_CHAR    EQU $0F81
ED_ERROR    EQU $107F
CLEAR_SP    EQU $1097
KEY_INPUT   EQU $10A8
REMOVE_FP   EQU $11A7
KEY_M_CL    EQU $10DB
MAIN_4      EQU $1303
ERROR_MSGS  EQU $1391
MESSAGES    EQU $1537
REPORT_J    EQU $15C4
OUT_CODE    EQU $15EF
CHAN_OPEN   EQU $1601
CHAN_FLAG   EQU $1615
POINTERS    EQU $1664
CLOSE       EQU $16E5
MAKE_ROOM   EQU $1655
LINE_NO     EQU $1695
SET_MIN     EQU $16B0
SET_WORK    EQU $16BF
SET_STK     EQU $16C5
OPEN        EQU $1736
LIST_5      EQU $1822
NUMBER      EQU $18B6
LINE_ADDR   EQU $196E
EACH_STMT   EQU $198B
NEXT_ONE    EQU $19B8
RECLAIM     EQU $19E5
RECLAIM_2   EQU $19E8
E_LINE_NO   EQU $19FB
OUT_NUM_1   EQU $1A1B
CLASS_01    EQU $1C1F
VAL_FET_1   EQU $1C56
CLASS_04    EQU $1C6C
EXPT_2NUM   EQU $1C7A
EXPT_1NUM   EQU $1C82
EXPT_EXP    EQU $1C8C
CLASS_09    EQU $1CBE
FETCH_NUM   EQU $1CDE
USE_ZERO    EQU $1CE6
STOP        EQU $1CEE
F_REORDER   EQU $1D16
LOOK_PROG   EQU $1D86
NEXT        EQU $1DAB
PASS_BY     EQU $1E39
RESTORE     EQU $1E42
REST_RUN    EQU $1E45
RANDOMIZE   EQU $1E4F
CONTINUE    EQU $1E5F
GO_TO       EQU $1E67
COUT        EQU $1E7A     ; Should be OUT but renamed since some assemblers detect this as an instruction.
POKE        EQU $1E80
FIND_INT2   EQU $1E99
TEST_ROOM   EQU $1F05
PAUSE       EQU $1F3A
PRINT_2     EQU $1FDF
PR_ST_END   EQU $2048
STR_ALTER   EQU $2070
INPUT_1     EQU $2096
IN_ITEM_1   EQU $20C1
CO_TEMP_4   EQU $21FC
BORDER      EQU $2294
PIXEL_ADDR  EQU $22AA
PLOT        EQU $22DC
PLOT_SUB    EQU $22E5
CIRCLE      EQU $2320
DR_3_PRMS   EQU $238D
LINE_DRAW   EQU $2477
SCANNING    EQU $24FB
SYNTAX_Z    EQU $2530
LOOK_VARS   EQU $28B2
STK_VAR     EQU $2996
STK_FETCH   EQU $2BF1
D_RUN       EQU $2C15
DEC_TO_FP   EQU $2C9B
ALPHA       EQU $2C8D
NUMERIC     EQU $2D1B
STACK_BC    EQU $2D2B
FP_TO_BC    EQU $2DA2
PRINT_FP    EQU $2DE3
HL_MULT_DE  EQU $30A9
STACK_NUM   EQU $33B4
TEST_ZERO   EQU $34E9
KP_SCAN     EQU $3C01
TEST_SCREEN EQU $3C04
CHAR_SET    EQU $3D00


;**************************************************

; =========================
; RESTART ROUTINES - PART 1
; =========================
; RST $10, $18 and $20 call the equivalent subroutines in ROM 1, via RST $28.
;
; RST $00 - Reset the machine.
; RST $08 - Not used. Would have invoked the ZX Interface 1 if fitted.
; RST $10 - Print a character      (equivalent to RST $10 ROM 1).
; RST $18 - Collect a character    (equivalent to RST $18 ROM 1).
; RST $20 - Collect next character (equivalent to RST $20 ROM 1).
; RST $28 - Call routine in ROM 1.
; RST $30 - Not used.
; RST $38 - Not used.

; -----------------------
; RST $00 - Reset Machine
; -----------------------

        ORG $0000

L0000:  DI                ; Ensure interrupts are disabled.
        JP   L00C7        ; Jump ahead to continue.

; ---------------------
; Programmers' Initials
; ---------------------

L0004:  DEFM "MB KM AT "  ; MB=Martin Brennan. KM=Kevin Males. AT=????.

L000D:  DEFB $00, $00     ; [Spare bytes]
        DEFB $00          ;

; ---------------------------
; RST $10 - Print A Character
; ---------------------------

L0010:  RST  28H          ; Call corresponding routine in ROM 1.
        DEFW PRINT_A_1    ; $0010.
        RET               ;

L0014:

;--------------
; CLEAR Bug Fix
;--------------

#ifdef BUG_FIXES
BUG_FIX5:                 ;@ [*BUG_FIX*]
        CALL L0566        ;@ [*BUG_FIX*] Produce error report.
        DEFB $15          ;@ [*BUG_FIX*] "M Ramtop no good"
#else
        DEFB $00, $00     ; [Spare bytes]
        DEFB $00, $00     ;
#endif

; -----------------------------
; RST $18 - Collect A Character
; -----------------------------

L0018:  RST  28H          ; Call corresponding routine in ROM 1.
        DEFW GET_CHAR     ; $0018.
        RET               ;

L001C:  DEFB $00, $00     ; [Spare bytes]
        DEFB $00, $00     ;

; --------------------------------
; RST $20 - Collect Next Character
; --------------------------------

L0020:  RST  28H          ; Call corresponding routine in ROM 1.
        DEFW NEXT_CHAR    ; $0020.
        RET               ;

L0024:  DEFB $00, $00     ; [Spare bytes]
        DEFB $00, $00     ;

; -------------------------------
; RST $28 - Call Routine in ROM 1
; -------------------------------
; RST 28 calls a routine in ROM 1 (or alternatively a routine in RAM while
; ROM 1 is paged in). Call as follows: RST 28 / DEFW address.

L0028:  EX   (SP),HL      ; Get the address after the RST $28 into HL,
                          ; saving HL on the stack.
        PUSH AF           ; Save the AF registers.
        LD   A,(HL)       ; Fetch the first address byte.
        INC  HL           ; Point HL to the byte after
        INC  HL           ; the required address.
        LD   (RETADDR),HL ; $5B5A. Store this in RETADDR.
        DEC  HL           ; (There is no RST $30)
        LD   H,(HL)       ; Fetch the second address byte.
        LD   L,A          ; HL=Subroutine to call.
        POP  AF           ; Restore AF.
        JP   L005C        ; Jump ahead to continue.

L0037:  DEFB $00          ; [Spare byte]


; ==========================
; Maskable Interrupt Routine
; ==========================
; This routine preserves the HL register pair. It then performs the following:
; - Execute the ROM switching code held in RAM to switch to ROM 1.
; - Execute the maskable interrupt routine in ROM 1.
; - Execute the ROM switching code held in RAM to return to ROM 0.
; - Return to address $0048 (ROM 0).

L0038:  PUSH HL           ; Save HL register pair.
        LD   HL,L0048     ; Return address of $0048 (ROM 0).
        PUSH HL           ;
        LD   HL,SWAP      ; $5B00. Address of swap ROM routine held in RAM at $5B00.
        PUSH HL           ;
        LD   HL,L0038     ; Maskable interrupt routine address $0038 (ROM 0).
        PUSH HL           ;
        JP   SWAP         ; $5B00. Switch to other ROM (ROM 1) via routine held in RAM at $5B00.

L0048:  POP  HL           ; Restore the HL register pair.
        RET               ; End of interrupt routine.


; ===============================
; ERROR HANDLER ROUTINES - PART 1
; ===============================

; ------------------
; 128K Error Routine
; ------------------

L004A:  LD   BC,$7FFD     ;
        XOR  A            ; ROM 0, Bank 0, Screen 0, 128K mode.
        DI                ; Ensure interrupts are disabled whilst paging.
        OUT  (C),A        ;
        LD   (BANK_M),A   ; $5B5C. Note the new paging status.
        EI                ; Re-enable interrupts.
        DEC  A            ; A=$FF.
        LD   (IY+$00),A   ; Set ERR_NR to no error ($FF).
        JP   L02C0        ; Jump ahead to continue.


; =========================
; RESTART ROUTINES - PART 2
; =========================

; -----------------------------------------
; Call ROM 1 Routine (RST $28 Continuation)
; -----------------------------------------
; Continuation from routine at $0028 (ROM 0).

L005C:  LD   (TARGET),HL  ; $5B58. Save the address in ROM 0 to call.
        LD   HL,YOUNGER   ; $5B14. HL='Return to ROM 0' routine held in RAM.
        EX   (SP),HL      ; Stack HL.
        PUSH HL           ; Save previous stack address.
        LD   HL,(TARGET)  ; $5B58. HL=Retrieve address to call. [There is no NMI code. Credit: Andrew Owen].
        EX   (SP),HL      ; Stack HL.
        JP   SWAP         ; $5B00. Switch to other ROM (ROM 1) and return to address to call.


; ============
; RAM ROUTINES
; ============
; The following code will be copied to locations $5B00 to $5B57, within the old ZX Printer buffer.

; -----------------
; Swap to Other ROM (copied to $5B00)
; -----------------
; Switch to the other ROM from that currently paged in.

; [The switching between the two ROMs invariably enables interrupts, which may not always be desired.
; To overcome this issue would require a rewrite of the SWAP routine as follows, but this it larger than
; the existing routine and so cannot simply be used in direct replacement of it. A work-around solution
; is to poke a JP instruction at the start of the SWAP routine in the ZX Printer buffer and direct control
; to the replacement routine held somewhere else in RAM. Credit: Toni Baker, ZX Computing Monthly]
;
; SWAP:
;       PUSH AF           ; Stack AF.
;       PUSH BC           ; Stack BC.
;
;       LD   A,R          ; P/V flag=Interrupt status.
;       PUSH AF           ; Stack interrupt status.
;
;       LD   BC,$7FFD     ; BC=Port number required for paging.
;       LD   A,(BANK_M)   ; A=Current paging configuration.
;       XOR  $10          ; Complement 'ROM' bit.
;       DI                ; Disable interrupts (in case an interrupt occurs between the next two instructions).
;       LD   (BANK_M),A   ; Store revised paging configuration.
;       OUT  (C),A        ; Page ROM.
;
;       POP  AF           ; P/V flag=Former interrupt status.
;       JP   PO,SWAP_EXIT ; Jump if interrupts were previously disabled.
;
;       EI                ; Re-enable interrupts.
;
; SWAP_EXIT:
;       POP BC            ; Restore BC.
;       POP AF            ; Restore AF.
;       RET               ;

;SWAP
L006B:  PUSH AF           ; Save AF and BC.
        PUSH BC           ;
        LD   BC,$7FFD     ;
        LD   A,(BANK_M)   ; $5B5C.
        XOR  $10          ; Select other ROM.
        DI                ; Disable interrupts whilst switching ROMs.
        LD   (BANK_M),A   ; $5B5C.
        OUT  (C),A        ; Switch to the other ROM.
        EI                ;
        POP  BC           ; Restore BC and AF.
        POP  AF           ;
        RET               ;

; ---------------------------
; Return to Other ROM Routine (copied to $5B14)
; ---------------------------
; Switch to the other ROM from that currently paged in
; and then return to the address held in RETADDR.

;YOUNGER
L007F:  CALL SWAP         ; $5B00. Toggle to the other ROM.
        PUSH HL           ;
        LD   HL,(RETADDR) ; $5B5A.
        EX   (SP),HL      ;
        RET               ; Return to the address held in RETADDR.

; ---------------------
; Error Handler Routine (copied to $5B1D)
; ---------------------
; This error handler routine switches back to ROM 0 and then
; executes the routine pointed to by system variable TARGET.

;ONERR
L0088:  DI                ; Ensure interrupts are disabled whilst paging.
        LD   A,(BANK_M)   ; $5B5C. Fetch current paging configuration.
        AND  $EF          ; Select ROM 0.
        LD   (BANK_M),A   ; $5B5C. Save the new configuration
        LD   BC,$7FFD     ;
        OUT  (C),A        ; Switch to ROM 0.
        EI                ;
        JP   L00C3        ; Jump to $00C3 (ROM 0) to continue.

; -------------------------
; 'P' Channel Input Routine (copied to $5B2F)
; -------------------------
; Called when data is read from channel 'P'.
; It causes ROM 0 to be paged in so that the new RS232 routines
; can be accessed.

;PIN
L009A:  LD   HL,L0692     ; RS232 input routine within ROM 0.
        JR   L00A2        ;

; --------------------------
; 'P' Channel Output Routine (copied to $5B34)
; --------------------------
; Called when data is written to channel 'P'.
; It causes ROM 0 to be paged in so that the new RS232 routines
; can be accessed.
; Entry: A=Byte to send.

;POUT
L009F:  LD   HL,L0784     ; RS232 output routine within ROM 0.

L00A2:  EX   AF,AF'       ; Save AF registers.
        LD   BC,$7FFD     ;
        LD   A,(BANK_M)   ; $5B5C. Fetch the current paging configuration
        PUSH AF           ; and save it.
        AND  $EF          ; Select ROM 0.
        DI                ; Ensure interrupts are disabled whilst paging.
        LD   (BANK_M),A   ; $5B5C. Store the new paging configuration.
        OUT  (C),A        ; Switch to ROM 0.
        JP   L05A0        ; Jump to the RS232 channel input/output handler routine.

; ------------------------
; 'P' Channel Exit Routine (copied to $5B4A)
; ------------------------
; Used when returning from a channel 'P' read or write operation.
; It causes the original ROM to be paged back in and returns back to
; the calling routine.

;POUT2
L00B5:  EX   AF,AF'       ; Save AF registers. For a read, A holds the byte read and the flags the success status.
        POP  AF           ; Retrieve original paging configuration.
        LD   BC,$7FFD     ;
        DI                ; Ensure interrupts are disabled whilst paging.
        LD   (BANK_M),A   ; $5B5C. Store original paging configuration.
        OUT  (C),A        ; Switch back to original paging configuration.
        EI                ;
        EX   AF,AF'       ; Restore AF registers. For a read, A holds the byte read and the flags the success status.
        RET               ; <<< End of RAM Routines >>>


; ===============================
; ERROR HANDLER ROUTINES - PART 2
; ===============================

; ---------------
; Call Subroutine
; ---------------
; Called from ONERR ($5B1D) to execute the routine pointed
; to by system variable SYNRET.

L00C3:  LD   HL,(SYNRET)  ; $5B8B. Fetch the address to call.
        JP   (HL)         ; and execute it.


; ================================
; INITIALISATION ROUTINES - PART 1
; ================================

; --------------------------------------------
; Reset Routine (RST $00 Continuation, Part 1)
; --------------------------------------------
; Continuation from routine at $0000 (ROM 0). It performs a test on all RAM banks.
; This test is crude and can fail to detect a variety of RAM errors.

L00C7:  LD   B,$08        ; Loop through all RAM banks.

L00C9:  LD   A,B          ;
        EXX               ; Save B register.
        DEC  A            ; RAM bank number 0 to 7. 128K mode, ROM 0, Screen 0.
        LD   BC,$7FFD     ;
        OUT  (C),A        ; Switch RAM bank.

        LD   HL,$C000     ; Start of the current RAM bank.
        LD   DE,$C001     ;
        LD   BC,$3FFF     ; All 16K of RAM bank.
        LD   A,$FF        ;
        LD   (HL),A       ; Store $FF into RAM location.
        CP   (HL)         ; Check RAM integrity.
        JR   NZ,L0131     ; Jump if RAM error found.

        XOR  A            ;
        LD   (HL),A       ; Store $00 into RAM location.
        CP   (HL)         ; Check RAM integrity.
        JR   NZ,L0131     ; Jump if difference found.

        LDIR              ; Clear the whole page
        EXX               ; Restore B registers.
        DJNZ L00C9        ; Repeat for other RAM banks.

        LD   (ROW01),A    ; $5B88. Signal no communications in progress to the keypad.

        LD   C,$FD        ;
        LD   D,$FF        ;
        LD   E,$BF        ;
        LD   B,D          ; BC=$FFFD, DE=$FFBF.
        LD   A,$0E        ;
        OUT  (C),A        ; Select AY register 14.
        LD   B,E          ; BC=$BFFD.
        LD   A,$FF        ;
        OUT  (C),A        ; Set AY register 14 to $FF. This will force a communications reset to the keypad if present.
        JR   L0137        ; Jump ahead to continue.

L00FF:  DEFB $00          ; [Spare byte]


; ====================
; ROUTINE VECTOR TABLE
; ====================

L0100:  JP   L179D        ; BASIC interpreter parser.
L0103:  JP   L1826        ; 'Line Run' entry point.
L0106:  JP   L1E5E        ; Transfer bytes to logical RAM bank 4 (physical bank 7).
L0109:  JP   L1E93        ; Transfer bytes from logical RAM bank 4 (physical bank 7).
L010C:  JP   L004A        ; 128K error routine.
L010F:  JP   L0341        ; Error routine.               Called from patch at $3B3B in ROM 1.
L0112:  JP   L1818        ; 'Statement Return' routine.  Called from patch at $3B4D in ROM 1.
L0115:  JP   L1896        ; 'Statement Next' routine.    Called from patch at $3B5D in ROM 1.
L0118:  JP   L012D        ; Scan the keypad.
L011B:  JP   L09BF        ; Play music strings.
L011E:  JP   L117F        ; MIDI byte output routine.
L0121:  JP   L0692        ; RS232 byte input routine.
L0124:  JP   L0784        ; RS232 text output routine.
L0127:  JP   L085D        ; RS232 byte output routine.
L012A:  JP   L08AA        ; COPY (screen dump) routine.
L012D:  RST  28H          ; Call keypad scan routine in ROM 1.
#ifndef BUG_FIXES
        DEFW KP_SCAN-$0100 ; $3B01. [*BUG* - The address jumps into the middle of the keypad decode routine in ROM 1. It
#else
        DEFW KP_SCAN      ;
#endif
        RET               ;                  looks like it is supposed to deal with the keypad and so the most likely
                          ;                  addresses are $3A42 (read keypad) or $39A0 (scan keypad). At $3C01 in
                          ;                  ROM 1 is a vector jump command to $39A0 to scan the keypad and this is
                          ;                  similar enough to the $3B01 to imply a simple error in one of the bytes. Credit: Paul Farrow].


; ================================
; INITIALISATION ROUTINES - PART 2
; ================================

; ---------------
; Fatal RAM Error
; ---------------
; Set the border colour to indicate which RAM bank was found faulty:
; RAM bank 7 - Black.
; RAM bank 6 - White.
; RAM bank 5 - Yellow.
; RAM bank 4 - Cyan.
; RAM bank 3 - Green.
; RAM bank 2 - Magenta.
; RAM bank 1 - Red.
; RAM bank 0 - Blue.

L0131:  EXX               ; Retrieve RAM bank number + 1 in B.
        LD   A,B          ; Indicate which RAM bank failed by
        OUT  ($FE),A      ; setting the border colour.

L0135:  JR   L0135        ; Infinite loop.

; --------------------------------------------
; Reset Routine (RST $00 Continuation, Part 2)
; --------------------------------------------
; Continuation from routine at $00C7 (ROM 0).

L0137:  LD   B,D          ; Complete setting up the sound chip registers.
        LD   A,$07        ;
        OUT  (C),A        ; Select AY register 7.
        LD   B,E          ;
        LD   A,$FF        ; Disable AY-3-8912 sound channels.
        OUT  (C),A        ;

        LD   DE,SWAP      ; $5B00. Copy the various paging routines to the old printer buffer.
        LD   HL,L006B     ; The source is in this ROM.
        LD   BC,$0058     ; There are eighty eight bytes to copy.
        LDIR              ; Copy the block of bytes.

        LD   A,$CF        ; Load A with the code for the Z80 instruction 'RST $08'.
        LD   (RAMRST),A   ; $5B5D. Insert into new System Variable RAMRST.
        LD   SP,TSTACK+1  ; $5BFF. Set the stack pointer to last location of old buffer.

        LD   A,$04        ;
        CALL L1BF3        ; Page in logical RAM bank 4 (physical RAM bank 7).

        LD   IX,$EBEC     ; First free entry in RAM disk.
        LD   (SFNEXT),IX  ; $5B83.
        LD   (IX+$0A),$00 ;
        LD   (IX+$0B),$C0 ;
        LD   (IX+$0C),$00 ;
        LD   HL,$2BEC     ;
        LD   A,$01        ; AHL=Free space in RAM disk.
        LD   (SFSPACE),HL ; $5B85. Current address.
        LD   (SFSPACE+2),A ; $5B87. Current RAM bank.

        LD   A,$05        ;
        CALL L1BF3        ; Page in logical RAM bank 5 (physical RAM bank 0).

        LD   HL,$FFFF     ; Load HL with known last working byte - 65535.
        LD   ($5CB4),HL   ; P_RAMT. Set physical RAM top to 65535.

        LD   DE,CHAR_SET+$01AF ; $3EAF. Set DE to address of the last bitmap of 'U' in ROM 1.
        LD   BC,$00A8     ; There are 21 User Defined Graphics to copy.
        EX   DE,HL        ; Swap so destination is $FFFF.
        RST  28H          ;
        DEFW MAKE_ROOM+$000C ; Calling this address (LDDR/RET) in the main ROM
                          ; cleverly copies the 21 characters to the end of RAM.

        EX   DE,HL        ; Transfer DE to HL.
        INC  HL           ; Increment to address first byte of UDG 'A'.
        LD   ($5C7B),HL   ; UDG. Update standard System Variable UDG.

        DEC  HL           ;
        LD   BC,$0040     ; Set values 0 for PIP and 64 for RASP.
        LD   ($5C38),BC   ; RASP. Update standard System Variables RASP and PIP.
        LD   ($5CB2),HL   ; RAMTOP. Update standard System Variable RAMTOP - the last
                          ; byte of the BASIC system area. Any machine code and
                          ; graphics above this address are protected from NEW.

; Entry point for NEW with interrupts disabled and physical RAM bank 0 occupying
; the upper RAM region $C000 - $FFFF, i.e. the normal BASIC memory configuration.

L019D:  LD   HL,CHAR_SET-$0100 ; $3C00. Set HL to where, in theory character zero would be.
        LD   ($5C36),HL   ; CHARS. Update standard System Variable CHARS.

        LD   HL,($5CB2)   ; RAMTOP. Load HL with value of System Variable RAMTOP.
        INC  HL           ; Address next location.
        LD   SP,HL        ; Set the Stack Pointer.
        IM   1            ; Select Interrupt Mode 1.
        LD   IY,$5C3A     ; Set the IY register to address the standard System
                          ; Variables and many of the new System Variables and
                          ; even those of ZX Interface 1 in some cases.
        SET  4,(IY+$01)   ; FLAGS. Signal 128K mode.
                          ; [This bit was unused and therefore never set by 48K BASIC]

        EI                ; With a stack and the IY register set, interrupts can
                          ; be enabled.

        LD   HL,$000B     ; Set HL to eleven, timing constant for 9600 baud.
        LD   (BAUD),HL    ; $5B5F. Select default RS232 baud rate of 9600 baud.

        XOR  A            ; Clear accumulator.
        LD   (SERFL),A    ; $5B61. Indicate no byte waiting in RS232 receive buffer.
        LD   (COL),A      ; $5B63. Set RS232 output column position to 0.
        LD   (TVPARS),A   ; $5B65. Indicate no control code parameters expected.
        SET   3,(IY+$30)  ; FLAGS2. Set CAPS LOCK on.

#ifndef BUG_FIXES
        LD   HL,$EC00     ; Store the address of the Screen Buffer. [*BUG* - Should write to RAM bank 7. Main RAM has
        LD   ($FF24),HL   ; now been corrupted. Credit: Geoff Wearmouth]
                          ; In fact this workspace variable will be set again at $23D5 and hence there is no need to
                          ; set the value here.
#else
        DEFB $00, $00, $00
        DEFB $00, $00, $00
#endif

; [The 1985 Sinclair Research ESPAGNOL source code says that this instruction will write to the (previously cleared)
; main BASIC RAM during initialization but that a different page of RAM will be present during NEW.
; Stuff and Nonsense! Assemblers and other utilities present above RAMTOP will be corrupted by the BASIC NEW command
; since $FF24 will be written to even if it is above RAMTOP.]

        LD   A,$50        ; Set printer width to a default of 80.
        LD   (WIDTH),A    ; $5B64. Set RS232 printer output width to 80 columns.

        LD   HL,$5CB6     ; Load HL with the address following the System Variables.
        LD   ($5C4F),HL   ; CHANS. Set standard System Variable CHANS.

        LD   DE,L0543     ; Point to Initial Channel Information in this ROM.
                          ; This is similar to that in main ROM but
                          ; channel 'P' has input and output addresses in the
                          ; new $5Bxx region.
        LD   BC,$0015     ; There are 21 bytes to copy.
        EX   DE,HL        ; Switch pointer so destination is CHANS.
        LDIR              ; Copy the block of bytes.

        EX   DE,HL        ; Transfer DE to HL.
        DEC  HL           ; Decrement to point to $80 end-marker.
        LD   ($5C57),HL   ; DATADD. Update standard System Variable DATADD to this
                          ; resting address.
        INC  HL           ; Bump address.
        LD   ($5C53),HL   ; PROG. Set standard System Variable PROG.
        LD   ($5C4B),HL   ; VARS. Set standard System Variable VARS.
        LD   (HL),$80     ; Insert the Variables end-marker.
        INC  HL           ; Increment the address.
        LD   ($5C59),HL   ; E_LINE.Set standard System Variable E_LINE.
        LD   (HL),$0D     ; Insert a carriage return.
        INC  HL           ; Increment address.
        LD   (HL),$80     ; Insert the $80 end-marker.
        INC  HL           ; increment address.
        LD   ($5C61),HL   ; WORKSP. Set the standard System Variable WORKSP.
        LD   ($5C63),HL   ; STKBOT.Set the standard System Variable STKBOT.
        LD   ($5C65),HL   ; STKEND. Set the standard System Variable STKEND.

        LD   A,$38        ; Set colour attribute to black ink on white paper.
        LD   ($5C8D),A    ; ATTR_P. Set the standard System Variable ATTR_P.
        LD   ($5C8F),A    ; MASK_P. Set the standard System Variable MASK_P.
        LD   ($5C48),A    ; BORDCR. Set the standard System Variable BORDCR.
        LD   A,$07        ; Load the accumulator with colour for white.
        OUT  ($FE),A      ; Output to port $FE changing border to white.

        LD   HL,$0523     ; The values five and thirty five.
        LD   ($5C09),HL   ; REPDEL. Set the standard System Variables REPDEL and REPPER.

        DEC  (IY-$3A)     ; Set KSTATE+0 to $FF.
        DEC  (IY-$36)     ; Set KSTATE+4 to $FF.

        LD   HL,L0558     ; Set source to Initial Stream Data in this ROM (which is identical to that in main ROM).
        LD   DE,$5C10     ; Set destination to standard System Variable STRMS-FD
        LD   BC,$000E     ; There are fourteen bytes to copy.
        LDIR              ; Block copy the bytes.

        RES  1,(IY+$01)   ; Update FLAGS - signal printer not is use.
        LD   (IY+$00),$FF ; Set standard System Variable ERR_NR to $FF (OK-1).
        LD   (IY+$31),$02 ; Set standard System Variable DF_SZ to two lines.

        RST  28H          ;
        DEFW CLS          ; $0D6B. Clear screen.
        LD   DE,L0506     ; Sinclair copyright message.
        CALL L0537        ; Print a message terminated by having bit 7 set.

        SET  5,(IY+$02)   ; TV_FLAG. Signal lower screen will require clearing.
        JP   L23C6        ; Jump to run the Editor.


; ===================================
; COMMAND EXECUTION ROUTINES - PART 1
; ===================================

; --------------------
; Execute Command Line
; --------------------
; A typed in command resides in the editing workspace. Execute it.
; The command could either be a new line to insert, or a line number to delete, or a numerical expression to evaluate.

L0244:  LD   HL,FLAGS3    ; $5B66.
        SET  0,(HL)       ; Select BASIC/Calculator mode.

        LD   (IY+$00),$FF ; ERR_NR. Set to '0 OK' status.
        LD   (IY+$31),$02 ; DF_SZ. Reset the number of rows in the lower screen.

        LD   HL,ONERR     ; $5B1D. Return address should an error occur.
        PUSH HL           ; Stack it.

        LD   ($5C3D),SP   ; Save the stack pointer in ERR_SP.

        LD   HL,L027C     ; Return address in ROM 0 after syntax checking.
        LD   (SYNRET),HL  ; $5B8B. Store it in SYNRET.

        CALL L1636        ; Point to start of typed in BASIC command.
        CALL L163F        ; Is the first character an operator token, i.e. the start of a numerical expression?
        JP   Z,L15E1      ; Jump if so to evaluate it.

        CALL L165F        ; Is the first character a function token, i.e. the start of a numerical expression?
        JP   Z,L158F      ; Jump if so to evaluate it.

        CP   '('          ; $28. Is the first character the start of an expression?
        JP   Z,L158F      ; Jump if so to evaluate it.

        CALL L1674        ; Is it numeric or function expression?
        JP   Z,L158F      ; Jump if so to evaluate it.

        JP   L179D        ; Jump to parse and execute the BASIC command line, returning to $027C (ROM 0).

; -----------------------------------
; Return from BASIC Line Syntax Check
; -----------------------------------
; This routine is returned to when a BASIC line has been syntax checked.

L027C:  BIT  7,(IY+$00)   ; Test ERR_NR.
        JR   NZ,L0283     ; Jump ahead if no error.

        RET               ; Simply return if an error.

;The syntax check was successful, so now proceed to parse the line for insertion or execution

L0283:  LD   HL,($5C59)   ; ELINE. Point to start of editing area.
        LD   ($5C5D),HL   ; Store in CH_ADD.
        RST  28H          ;
        DEFW E_LINE_NO    ; $19FB. Call E_LINE_NO in ROM 1 to read the line number into editing area.
        LD   A,B          ;
        OR   C            ;
        JP   NZ,L0396     ; Jump ahead if there was a line number.

; --------------------------------------
; Parse a BASIC Line with No Line Number
; --------------------------------------

        RST  18H          ; Get character.
        CP   $0D          ; End of the line reached, i.e. no BASIC statement?
        RET  Z            ; Return if so.

        CALL L1586        ; Clear screen if it requires it.

        RST  28H          ;
        DEFW CLS_LOWER    ; $0D6E. Clear the lower screen.

        LD   A,$19        ; 25.
        SUB  (IY+$4F)     ; S_POSN+1. Subtract the current print row position.
        LD   ($5C8C),A    ; SCR_CT. Set the number of scrolls.

        SET  7,(IY+$01)   ; FLAGS. Not syntax checking.

        LD   (IY+$0A),$01 ; NSPPC. Set line to be jumped to as line 1.

; [*BUG* - Whenever a typed in command is executed directly from the editing workspace, a new GO SUB marker is set up on the
;          stack. Any existing GO SUB calls that were on the stack are lost and as a result attempting to continue the program
;          (without the use of CLEAR or RUN) will likely lead to a "7 RETURN without GOSUB" error report message being displayed.
;          However, the stack marker will already have been lost due to the error handler routine at $02C0. The first action it
;          does is to reset the stack pointer to point to the location of RAMTOP, i.e. after the GO SUB marker. This is why it is
;          necessary for a new GO SUB marker needs to be set up. Credit: Michal Skrzypek]

        LD   HL,$3E00     ; The end of GO SUB stack marker.
        PUSH HL           ; Place it on the stack.

        LD   HL,ONERR     ; $5B1D. The return address should an error occur.
        PUSH HL           ; Place it on the stack.

        LD   ($5C3D),SP   ; ERR_SP. Store error routine address.

        LD   HL,L02C0     ; Address of error handler routine in ROM 0.
        LD   (SYNRET),HL  ; $5B8B. Store it in SYNRET.

        JP   L1826        ; Jump ahead to the main parser routine to execute the line.


; ===============================
; ERROR HANDLER ROUTINES - PART 3
; ===============================

; ---------------------
; Error Handler Routine
; ---------------------

; [*BUG* - Upon terminating a BASIC program, either via reaching the end of the program or due to an error occurring,
;          execution is passed to this routine. The first action it does is to reset the stack pointer to point to the
;          location of RAMTOP, i.e. after the GO SUB marker. However, this means that any existing GO SUB calls that
;          were on the stack are lost and so attempting to continue the program (without the use of CLEAR or RUN) will
;          likely lead to a "7 RETURN without GOSUB" error report message being displayed. When a new typed in command
;          is executed, the code at $02AC sets up a new GO SUB marker on the stack. Credit: Michal Skrzypek]

L02C0:  LD   SP,($5CB2)   ; RAMTOP.
        INC  SP           ; Reset SP to top of memory map.
        LD   HL,TSTACK+1  ; $5BFF.
        LD   (OLDSP),HL   ; $5B81.

        HALT              ; Trap error conditions where interrupts are disabled.

        RES  5,(IY+$01)   ; FLAGS. Signal ready for a new key press.
        LD   HL,FLAGS3    ; $5B66.
        BIT  2,(HL)       ; Editing RAM disk catalogue?
        JR   Z,L02E9      ; Jump if not.

        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        LD   IX,(SFNEXT)  ; $5B83.
        LD   BC,$0014     ; Catalogue entry size.
        ADD  IX,BC        ; Remove last entry.
        CALL L1CE5        ; Update catalogue entry (leaves logical RAM bank 4 paged in)

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).

;Print error code held in ERR_NR

L02E9:  LD   A,($5C3A)    ; Fetch error code from ERR_NR.
        INC  A            ; Increment error code.

L02ED:  PUSH AF           ; Save the error code.

        LD   HL,$0000     ;
        LD   (IY+$37),H   ; Clear ATTR_T.
        LD   (IY+$26),H   ; Clear STRLEN.
        LD   ($5C0B),HL   ; Clear DEFADD.

        LD   HL,$0001     ;
        LD   ($5C16),HL   ; STRMS+$0006. Restore channel 'K' stream data.

        RST  28H          ;
        DEFW SET_MIN      ; $16B0. Clears editing area and areas after it.
        RES  5,(IY+$37)   ; FLAGX. Signal not INPUT mode.

        RST  28H          ;
        DEFW CLS_LOWER    ; $0D6E. Clear lower editing screen.
        SET  5,(IY+$02)   ; TVFLAG. Indicate lower screen does not require clearing.

        POP  AF           ; Retrieve error code.
        LD   B,A          ; Store error code in B.
        CP   $0A          ; Is it a numeric error code (1-9)?
        JR   C,L031E      ; If so jump ahead to print it.

        CP   $1D          ; Is it one of the standard errors (A-R)?
        JR   C,L031C      ; If so jump ahead to add 7 and print.

        ADD  A,$14        ; Otherwise add 20 to create code for lower case letters.
        JR   L031E        ; and jump ahead to print.
                          ; [Could have saved 2 bytes by using ADD A,$0C instead
                          ; of these two instructions]

L031C:  ADD  A,$07        ; Increase code to point to upper case letters.

L031E:  RST  28H          ;
        DEFW OUT_CODE     ; $15EF. Print the character held in the A register.

        LD   A,$20        ; Print a space.
        RST  10H          ;
        LD   A,B          ; Retrieve the error code.
        CP   $1D          ; Is it one of the standard errors (A-R)?
        JR   C,L033B      ; Jump if an standard error message (A-R).

;Print a new error message

;[Note that there is no test to range check the error code value and therefore whether a message exists for it. Poking
;directly to system variable ERR_NR with an invalid code (43 or above) will more than likely cause a crash]

        SUB  $1D          ; A=Code $00 - $0E.
        LD   B,$00        ;
        LD   C,A          ; Pass code to BC.
        LD   HL,L03E6     ; Error message vector table.
        ADD  HL,BC        ;
        ADD  HL,BC        ; Find address in error message vector table.

        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; DE=Address of message to print.

        CALL L0537        ; Print error message.
        JR   L0341        ; Jump ahead.

;Print a standard error message.

L033B:  LD   DE,ERROR_MSGS ; $1391. Position of the error messages in ROM 1.
        RST  28H          ; A holds the error code.
        DEFW PO_MSG       ; $0C0A. Call message printing routine.

;Continue to print the line and statement number

L0341:  XOR  A            ; Select the first message ", " (a 'comma' and a 'space').
        LD   DE,MESSAGES-1 ; $1536. Message base address in ROM 1.
        RST  28H          ;
        DEFW PO_MSG       ; Print a comma followed by a space.

        LD   BC,($5C45)   ; PPC. Fetch current line number.
        RST  28H          ;
        DEFW OUT_NUM_1    ; $1A1B. Print the line number.

        LD   A,$3A        ; Print ':'.
        RST  10H          ;

        LD   C,(IY+$0D)   ; SUBPPC. Fetch current statement number.
        LD   B,$00        ;
        RST  28H          ;
        DEFW OUT_NUM_1    ; $1A1B. Print the statement number.

        RST  28H          ;
        DEFW CLEAR_SP     ; $1097. Clear editing and workspace areas.

        LD   A,($5C3A)    ; ERR_NR. Fetch the error code.
        INC  A
        JR   Z,L037E      ; Jump ahead for "0 OK".

        CP   $09          ;
        JR   Z,L036B      ; Jump for "A Invalid argument", thereby advancing to the next statement.

        CP   $15          ;
        JR   NZ,L036E     ; Jump unless "M Ramtop no good".

L036B:  INC  (IY+$0D)     ; SUBPPC. Advance to the next statement.

L036E:  LD   BC,$0003     ;
        LD   DE,$5C70     ; OSPPC. Continue statement number.
        LD   HL,$5C44     ; NSPPC. Next statement number.
        BIT  7,(HL)       ; Is there a statement number?
        JR   Z,L037C      ; Jump if so.

        ADD  HL,BC        ; HL=SUBPPC. The current statement number.

L037C:  LDDR              ; Copy SUBPPC and PPC to OSPPC and OLDPPC, for use by CONTINUE.

L037E:  LD   (IY+$0A),$FF ; NSPPC. Signal no current statement number.
        RES  3,(IY+$01)   ; FLAGS. Select K-Mode.
        LD   HL,FLAGS3    ; $5B66.
        RES  0,(HL)       ; Select 128 Editor mode.
        JP   L23C6        ; Jump ahead to return control to the Editor.

; ---------------------------------------------
; Error Handler Routine When Parsing BASIC Line
; ---------------------------------------------

L038E:  LD   A,$10        ; Error code 'G - No room for line'.
        LD   BC,$0000     ;
        JP   L02ED        ; Jump to print the error code.


; ===================================
; COMMAND EXECUTION ROUTINES - PART 2
; ===================================

; -------------------------------------
; Parse a BASIC Line with a Line Number
; -------------------------------------
; This routine handles executing a BASIC line with a line number specified, or just a line number
; specified on its own, i.e. delete the line.

L0396:  LD   ($5C49),BC   ; E_PPC. Current edit line number.

        LD   HL,($5C5D)   ; CH_ADD. Point to the next character in the BASIC line.
        EX   DE,HL        ;

        LD   HL,L038E     ; Address of error handler routine should there be no room for the line.
        PUSH HL           ; Stack it.

        LD   HL,($5C61)   ; WORKSP.
        SCF               ;
        SBC  HL,DE        ; HL=Length of BASIC line.
        PUSH HL           ; Stack it.

        LD   H,B          ;
        LD   L,C          ; Transfer edit line number to HL.
        RST  28H          ;
        DEFW LINE_ADDR    ; $196E. Returns address of the line in HL.
        JR   NZ,L03B6     ; Jump if the line does not exist.

;The line already exists so delete it

        RST  28H          ;
        DEFW NEXT_ONE     ; $19B8. Find the address of the next line.
        RST  28H          ;
        DEFW RECLAIM_2    ; $19E8. Delete the line.

L03B6:  POP  BC           ; BC=Length of the BASIC line.
        LD   A,C          ;
        DEC  A            ; Is it 1, i.e. just an 'Enter' character, and hence only
        OR   B            ; a line number was entered?
        JR   Z,L03E4      ; Jump ahead if so to make a return.

        PUSH BC           ; BC=Length of the BASIC line. Stack it.

        INC  BC           ;
        INC  BC           ;
        INC  BC           ;
        INC  BC           ; BC=BC+4. Allow for line number and length bytes.

        DEC  HL           ; Point to before the current line, i.e. the location to insert bytes at.

        LD   DE,($5C53)   ; PROG. Get start address of the BASIC program.
        PUSH DE           ; Stack it.

        RST  28H          ;
        DEFW MAKE_ROOM    ; $1655. Insert BC spaces at address HL.

        POP HL            ; HL=Start address of BASIC program.
        LD   ($5C53),HL   ; PROG. Save start address of BASIC program.

        POP  BC           ; BC=Length of the BASIC line.
        PUSH BC           ;

        INC  DE           ; Point to the first location of the newly created space.
        LD   HL,($5C61)   ; WORKSP. Address of end of the BASIC line in the workspace.
        DEC  HL           ;
        DEC  HL           ; Skip over the newline and terminator bytes.
        LDDR              ; Copy the BASIC line from the workspace into the program area.
        LD   HL,($5C49)   ; E_PPC. Current edit line number.
        EX   DE,HL        ;

        POP  BC           ; BC=Length of BASIC line.
        LD   (HL),B       ; Store the line length.
        DEC  HL           ;
        LD   (HL),C       ;
        DEC  HL           ;
        LD   (HL),E       ; DE=line number.
        DEC  HL           ;
        LD   (HL),D       ; Store the line number.

L03E4:  POP  AF           ; Drop item (address of error handler routine).
        RET               ; Exit with HL=Address of the line.


; ===============================
; ERROR HANDLER ROUTINES - PART 4
; ===============================

; ------------------------------
; New Error Message Vector Table
; ------------------------------
; Pointers into the new error message table.

L03E6:  DEFW L0406        ; Error report 'a'.
        DEFW L0414        ; Error report 'b'.
        DEFW L0428        ; Error report 'c'.
        DEFW L0434        ; Error report 'd'.
        DEFW L0449        ; Error report 'e'.
        DEFW L045D        ; Error report 'f'.
        DEFW L046C        ; Error report 'g'.
        DEFW L046C        ; Error report 'h'.
        DEFW L047F        ; Error report 'i'.
        DEFW L0492        ; Error report 'j'.
        DEFW L049F        ; Error report 'k'.
        DEFW L04B1        ; Error report 'l'
        DEFW L04C0        ; Error report 'm'.
        DEFW L04D3        ; Error report 'n'.
        DEFW L04E1        ; Error report 'o'.
        DEFW L04F9        ; Error report 'p'.

; -----------------------
; New Error Message Table
; -----------------------

L0406:  DEFM "MEZCLA ERRONE"               ; Report 'a'.
        DEFB 'A'+$80
L0414:  DEFM "TIPO FICHERO ERRONE"         ; Report 'b'.
        DEFB 'O'+$80
L0428:  DEFM "ERROR CODIG"                 ; Report 'c'.
        DEFB 'O'+$80
L0434:  DEFM "DEMASIADAS PARENTESI"        ; Report 'd'.
        DEFB 'S'+$80
L0449:  DEFM "FICHERO YA EXISTENT"         ; Report 'e'.
        DEFB 'E'+$80
L045D:  DEFM "NOMBRE INVALID"              ; Report 'f'.
        DEFB 'O'+$80
L046C:  DEFM "FICHERO INEXISTENT"          ; Report 'g' & 'h'.
        DEFB 'E'+$80
L047F:  DEFM "DISPOSITIVO ERRONE"          ; Report 'i'.
        DEFB 'O'+$80
L0492:  DEFM "BAUD RATE MA"                ; Report 'j'.
        DEFB 'L'+$80
L049F:  DEFM "MAL NOMBRE DE NOT"           ; Report 'k'.
        DEFB 'A'+$80
L04B1:  DEFM "NUMERO MUY ALT"              ; Report 'l'.
        DEFB 'O'+$80
L04C0:  DEFM "NOTA FUERA DE RANG"          ; Report 'm'.
        DEFB 'O'+$80
L04D3:  DEFM "FUERA DE RANG"               ; Report 'n'.
        DEFB 'O'+$80
L04E1:  DEFM "DEMASIADAS NOTAS LIGADA"     ; Report 'o'.
        DEFB 'S'+$80
L04F9:  DEFM "PARAMETRO MA"                ; Report 'p'.
        DEFB 'L'+$80
L0506:  DEFB $7F                           ; '(c)'
        DEFM " 1985 Sinclair Research Ltd              ESPA" ; Copyright.
        DEFB $5C                           ; '\' which on the Spanish 128 is displayed as an 'N' with a bar above it.
        DEFB 'O'
        DEFB 'L'+$80

; -------------
; Print Message
; -------------
; Print a message which is terminated by having bit 7 set, pointed at by DE.

L0537:  LD   A,(DE)       ; Fetch next byte.
        AND  $7F          ; Mask off top bit.
        PUSH DE           ; Save address of current message byte.
        RST  10H          ; Print character.
        POP  DE           ; Restore message byte pointer.
        LD   A,(DE)       ;
        INC  DE           ;
        ADD  A,A          ; Carry flag will be set if byte is $FF.
        JR   NC,L0537     ; Else print next character.

        RET               ;

; ================================
; INITIALISATION ROUTINES - PART 3
; ================================

; ---------------------------------
; The 'Initial Channel Information'
; ---------------------------------
; Initially there are four channels ('K', 'S', 'R', & 'P') for communicating with the 'keyboard', 'screen', 'work space' and 'printer'.
; For each channel the output routine address comes before the input routine address and the channel's code.
; This table is almost identical to that in ROM 1 at $15AF but with changes to the channel P routines to use the RS232 port
; instead of the ZX Printer.
; Used at $01D8 (ROM 0).

L0543:  DEFW PRINT_OUT    ; $09F4 - K channel output routine.
        DEFW KEY_INPUT    ; $10A8 - K channel input routine.
        DEFB 'K'          ; $4B   - Channel identifier 'K'.
        DEFW PRINT_OUT    ; $09F4 - S channel output routine.
        DEFW REPORT_J     ; $15C4 - S channel input routine.
        DEFB 'S'          ; $53   - Channel identifier 'S'.
        DEFW ADD_CHAR     ; $0F81 - R channel output routine.
        DEFW REPORT_J     ; $15C4 - R channel input routine.
        DEFB 'R'          ; $52   - Channel identifier 'R'.
        DEFW $5B34        ; POUT  - P Channel output routine.
        DEFW $5B2F        ; PIN   - P Channel input routine.
        DEFB 'P'          ; $50   - Channel identifier 'P'.
        DEFB $80          ; End marker.

; -------------------------
; The 'Initial Stream Data'
; -------------------------
; Initially there are seven streams - $FD to $03.
; This table is identical to that in ROM 1 at $15C6.
; Used at $021D (ROM 0).

L0558:  DEFB $01, $00     ; Stream $FD leads to channel 'K'.
        DEFB $06, $00     ; Stream $FE leads to channel 'S'.
        DEFB $0B, $00     ; Stream $FF leads to channel 'R'.
        DEFB $01, $00     ; Stream $00 leads to channel 'K'.
        DEFB $01, $00     ; Stream $01 leads to channel 'K'.
        DEFB $06, $00     ; Stream $02 leads to channel 'S'.
        DEFB $10, $00     ; Stream $03 leads to channel 'P'.


; ===============================
; ERROR HANDLER ROUTINES - PART 5
; ===============================

; --------------------
; Produce Error Report
; --------------------

L0566:  POP  HL           ; Point to the error byte.
        LD   BC,$7FFD     ;
        XOR  A            ; ROM 0, Screen 0, Bank 0, 128 mode.
        DI                ; Ensure interrupts disable whilst paging.
        LD   (BANK_M),A   ; $5B5C. Store new state in BANK_M.
        OUT  (C),A        ; Switch to ROM 0.
        EI                ;

        LD   SP,($5C3D)   ; Restore SP from ERR_SP.
        LD   A,(HL)       ; Fetch the error number.
        LD   (RAMERR),A   ; $5B5E. Store the error number.
        INC  A            ;
#ifndef BUG_FIXES
        CP   $1E          ; [*BUG* - This should be $1D. As such, error code 'a' will be delegated to ROM 1 for handling. Credit: Paul Farrow]
#else
        CP   $1D          ;
#endif
        JR   NC,L0582     ; Jump if not a standard error code.

;Handle a standard error code

        RST  28H          ;
        DEFW RAMRST       ; $5B5D. Call the error handler routine in ROM 1.

;Handle a new error code

L0582:  DEC  A            ;
        LD   (IY+$00),A   ; Store in ERR_NR.
        LD   HL,($5C5D)   ; CH_ADD.
        LD   ($5C5F),HL   ; X_PTR. Set up the address of the character after the '?' marker.

        RST  28H          ;
        DEFW SET_STK      ; $16C5. Set the calculator stack.
        RET               ; Return to the error routine.

; ----------------------------
; Check for BREAK into Program
; ----------------------------

L0590:  LD   A,$7F        ; Read keyboard row B - SPACE.
        IN   A,($FE)      ;
        RRA               ; Extract the SPACE key.
        RET  C            ; Return if SPACE not pressed.

        LD   A,$FE        ; Read keyboard row CAPS SHIFT - V.
        IN   A,($FE)      ;
        RRA               ; Extract the CAPS SHIFT key.
        RET  C            ; Return if CAPS SHIFT not pressed.

        CALL L0566        ; Produce an error.
        DEFB $14          ; "L Break into program"


; ======================
; RS232 PRINTER ROUTINES
; ======================

; ------------------------------
; RS232 Channel Handler Routines
; ------------------------------
; This routine handles input and output RS232 requested. It is similar to the
; routine in the ZX Interface 1 ROM at $0D5A, but in that ROM the routine is only used
; for input.

L05A0:  EI                ; Enabled interrupts.
        EX   AF,AF'       ; Save AF registers.
        LD   DE,POUT2     ; $5B4A. Address of the RS232 exit routine held in RAM.
        PUSH DE           ; Stack it.

        RES  3,(IY+$02)   ; TVFLAG. Indicate not automatic listing.
        PUSH HL           ; Save the input/output routine address.

        LD   HL,($5C3D)   ; Fetch location of error handler routine from ERR_SP.
        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; DE=Address of error handler routine.
        AND  A            ;
        LD   HL,ED_ERROR  ; $107F in ROM 1.
        SBC  HL,DE        ;
        JR   NZ,L05F1     ; Jump if error handler address is different, i.e. due to INKEY$# or PRINT#.

; Handle INPUT#
; -------------

        POP  HL           ; Retrieve the input/output routine address.
        LD   SP,($5C3D)   ; ERR_SP.
        POP  DE           ; Discard the error handler routine address.
        POP  DE           ; Fetch the original address of ERR_SP (this was stacked at the beginning of the INPUT routine in ROM 1).
        LD   ($5C3D),DE   ; ERR_SP.

L05C4:  PUSH HL           ; Save the input/output routine address.
        LD   DE,L05CA     ; Address to return to.
        PUSH DE           ; Stack the address.
        JP   (HL)         ; Jump to the RS232 input/output routine.

;Return here from the input/output routine

L05CA:  JR   C,L05D5      ; Jump if a character was received.
        JR   Z,L05D2      ; Jump if a character was not received.

L05CE:  CALL L0566        ; Produce an error "8 End of file".
        DEFB $07          ;

;A character was not received

L05D2:  POP  HL           ; Retrieve the input routine address.
        JR   L05C4        ; Jump back to await another character.

;A character was received

L05D5:  CP   $0D          ; Is it a carriage return?
        JR   Z,L05E7      ; Jump ahead if so.

        LD   HL,(RETADDR) ; $5B5A. Fetch the return address.
        PUSH HL           ;

        RST  28H          ;
        DEFW ADD_CHAR+4   ; $0F85. Insert the character into the INPUT line.

        POP  HL           ;
        LD   (RETADDR),HL ; $5B5A. Restore the return address.

        POP  HL           ; Retrieve the input routine address.
        JR   L05C4        ; Jump back to await another character.

;Enter was received so end reading the stream

L05E7:  POP  HL           ; Discard the input routine address.
        LD   A,(BANK_M)   ; $5B5C. Fetch current paging configuration.
        OR   $10          ; Select ROM 1.
        PUSH AF           ; Stack the required paging configuration.
        JP   POUT2        ; $5B4A. Exit.

; Handle INKEY$# and PRINT#
; -------------------------

L05F1:  POP  HL           ; Retrieve the input/output routine address.
        LD   DE,L05F7     ;
        PUSH DE           ; Stack the return address.
        JP   (HL)         ; Jump to input or output routine.

;Return here from the input/output routine. When returning from the output routine, either the carry or zero flags should always
;be set to avoid the false generation of error report "8 End of file" [though this is not always the case - see bugs starting at $0826 (ROM 0)].

L05F7:  RET  C            ; Return if a character was received.
        RET  Z            ; Return if a character was not received or was written.

        JR   L05CE        ; Produce error report "8 End of file".

; --------------
; FORMAT Routine
; --------------
; The format command sets the RS232 baud rate, e.g. FORMAT "P"; 9600.
; It attempts to match against one of the supported baud rates, or uses the next
; higher baud rate if a non-standard value is requested. The maximum baud rate supported
; is 9600, and this is used for any rates specified that are higher than this.

L05FB:  RST  28H          ; [Could just do RST $18]
        DEFW GET_CHAR     ; $0018.
        RST  28H          ; Get an expression.
        DEFW EXPT_EXP     ; $1C8C.
        BIT  7,(IY+$01)   ; FLAGS.
        JR   Z,L061B      ; Jump ahead if syntax checking.

        RST  28H          ;
        DEFW STK_FETCH    ; $2BF1. Fetch the expression.
        LD   A,C          ;
        DEC  A            ;
        OR   B            ;
        JR   Z,L0613      ; Jump ahead if string is 1 character long.

        CALL L0566        ; Produce error report.
        DEFB $24          ; "i Invalid device".

L0613:  LD   A,(DE)       ; Get character.
        AND  $DF          ; Convert to upper case.
        CP   'P'          ; $50. Is it channel 'P'?
        JP   NZ,L1900     ; Jump if not to produce error report "C Nonsense in BASIC".

L061B:  LD   HL,($5C5D)   ; CH_ADD. Next character to be interpreted.
        LD   A,(HL)       ;
        CP   $3B          ; Next character must be ';'.
        JP   NZ,L1900     ; Jump if not to produce error report "C Nonsense in BASIC".

        RST  28H          ; Skip past the ';' character.
        DEFW NEXT_CHAR    ; $0020. [Could just do RST $20]
        RST  28H          ; Get a numeric expression from the line.
        DEFW EXPT_1NUM    ; $1C82.
        BIT  7,(IY+$01)   ; FLAGS. Checking syntax mode?
        JR   Z,L0637      ; Jump ahead if so.

        RST  28H          ; Get the result as an integer.
        DEFW FIND_INT2    ; $1E99.
        LD   (F_TBAUD),BC ; $5B71. Store the result temporarily for use later.

L0637:  RST  28H          ; [Could just do RST $18]
        DEFW GET_CHAR     ; $0018. Get the next character in the BASIC line.
        CP   $0D          ; It should be ENTER.
        JR   Z,L0643      ; Jump ahead if it is.

        CP   ':'          ; $3A. Or the character is allowed to be ':'.
        JP   NZ,L1900     ; Jump if not to produce error report "C Nonsense in BASIC".

L0643:  CALL L188F        ; Check for end of line.
        LD   BC,(F_TBAUD) ; $5B71. Get the baud rate saved earlier.
        LD   A,B          ; Is it zero?
        OR   C            ;
        JR   NZ,L0652     ; Jump if not, i.e. a numeric value was specified.

        CALL L0566        ; Produce error report.
        DEFB $25          ; "j invalid baud rate"

;Lookup the timing constant to use for the specified baud rate

L0652:  LD   HL,L0672     ; Table of supported baud rates.

L0655:  LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ;
        INC  HL           ;
        EX   DE,HL        ; HL=Supported baud rate value.
        LD   A,H          ;
        CP   $25          ; Reached the last baud rate value in the table?
        JR   NC,L0669     ; Jump is so to use a default baud rate of 9600.

        AND  A            ;
        SBC  HL,BC        ; Table entry matches or is higher than requested baud rate?
        JR   NC,L0669     ; Jump ahead if so to use this baud rate.

        EX   DE,HL        ;
        INC  HL           ; Skip past the timing constant value
        INC  HL           ; for this baud rate entry.
        JR   L0655        ;

;The baud rate has been matched

L0669:  EX   DE,HL        ; HL points to timing value for the baud rate.
        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; DE=Timing value for the baud rate.
        LD   (BAUD),DE    ; $5B5F. Store new value in system variable BAUD.
        RET               ;

; ---------------
; Baud Rate Table
; ---------------
; Consists of entries of baud rate value followed by timing constant to use in the RS232 routines.

L0672:  DEFW $0032, $0AA5  ; Baud=50.
        DEFW $006E, $04D4  ; Baud=110.
        DEFW $012C, $01C3  ; Baud=300.
        DEFW $0258, $00E0  ; Baud=600.
        DEFW $04B0, $006E  ; Baud=1200.
        DEFW $0960, $0036  ; Baud=2400.
        DEFW $12C0, $0019  ; Baud=4800.
        DEFW $2580, $000B  ; Baud=9600.

; -------------------
; RS232 Input Routine
; -------------------
; Exit: Carry flag set if a byte was read with the byte in A. Carry flag reset upon error.

L0692:  LD   HL,SERFL     ; $5B61. SERFL holds second char that can be received
        LD   A,(HL)       ; Is the second-character received flag set?
        AND  A            ; i.e. have we already received data?
        JR   Z,L069F      ; Jump ahead if not.

        LD   (HL),$00     ; Otherwise clear the flag
        INC  HL           ;
        LD   A,(HL)       ; and return the data which we received earlier.
        SCF               ; Set carry flag to indicate success
        RET               ;

; -------------------------
; Read Byte from RS232 Port
; -------------------------
; The timing of the routine is achieved using the timing constant held in system variable BAUD.
; Exit: Carry flag set if a byte was read, or reset upon error.
;       A=Byte read in.

L069F:  CALL L0590        ; Check the BREAK key, and produce error message if it is being pressed.

        DI                ; Ensure interrupts are disabled to achieve accurate timing.

        EXX               ;

        LD   DE,(BAUD)    ; $5B5F. Fetch the baud rate timing constant.
        LD   HL,(BAUD)    ; $5B5F.
        SRL  H            ;
        RR   L            ; HL=BAUD/2. So that will sync to half way point in each bit.

        OR   A            ; [Redundant byte]

        LD   B,$FA        ; Waiting time for start bit.
        EXX               ; Save B.
        LD   C,$FD        ;
        LD   D,$FF        ;
        LD   E,$BF        ;
        LD   B,D          ;
        LD   A,$0E        ;
        OUT  (C),A        ; Selects register 14, port I/O of AY-3-8912.

        IN   A,(C)        ; Read the current state of the I/O lines.
        OR   $F0          ; %11110000. Default all input lines to 1.
        AND  $FB          ; %11111011. Force CTS line to 0.
        LD   B,E          ; B=$BF.
        OUT  (C),A        ; Make CTS (Clear To Send) low to indicate ready to receive.

        LD   H,A          ; Store status of other I/O lines.

;Look for the start bit

L06C8:  LD   B,D          ;
        IN   A,(C)        ; Read the input line.
        AND  $80          ; %10000000. Test TXD (input) line.
        JR   Z,L06D8      ; Jump if START BIT found.

L06CF:  EXX               ; Fetch timeout counter
        DEC  B            ; and decrement it.
        EXX               ; Store it.
        JR   NZ,L06C8     ; Continue to wait for start bit if not timed out.

        XOR  A            ; Reset carry flag to indicate no byte read.
        PUSH AF           ; Save the failure flag.
        JR   L0711        ; Timed out waiting for START BIT.

L06D8:  IN   A,(C)        ; Second test of START BIT - it should still be 0.
        AND  $80          ; Test TXD (input) line.
        JR   NZ,L06CF     ; Jump back if it is no longer 0.

        IN   A,(C)        ; Third test of START BIT - it should still be 0.
        AND  $80          ; Test TXD (input) line.
        JR   NZ,L06CF     ; Jump back if it is no longer 0.

;A start bit has been found, so the 8 data bits are now read in.
;As each bit is read in, it is shifted into the msb of A. Bit 7 of A is preloaded with a 1
;to represent the start bit and when this is shifted into the carry flag it signifies that 8
;data bits have been read in.

        EXX               ;
        LD   BC,$FFFD     ;
        LD   A,$80        ; Preload A with the START BIT. It forms a shift counter used to count
        EX   AF,AF'       ; the number of bits to read in.

L06EB:  ADD  HL,DE        ; HL=1.5*(BAUD).

        NOP               ; (4) Fine tune the following delay.
        NOP               ;
        NOP               ;
        NOP               ;

;BD-DELAY
L06F0:  DEC  HL           ; (6) Delay for 26*BAUD.
        LD   A,H          ; (4)
        OR   L            ; (4)
        JR   NZ,L06F0     ; (12) Jump back to until delay completed.

        IN   A,(C)        ; Read a bit.
        AND  $80          ; Test TXD (input) line.
        JP   Z,L0705      ; Jump if a 0 received.

;Received one 1

        EX   AF,AF'       ; Fetch the bit counter.
        SCF               ; Set carry flag to indicate received a 1.
        RRA               ; Shift received bit into the byte (C->76543210->C).
        JR   C,L070E      ; Jump if START BIT has been shifted out indicating all data bits have been received.

        EX   AF,AF'       ; Save the bit counter.
        JP   L06EB        ; Jump back to read the next bit.

;Received one 0

L0705:  EX   AF,AF'       ; Fetch the bit counter.
        OR   A            ; Clear carry flag to indicate received a 0.
        RRA               ; Shift received bit into the byte (C->76543210->C).
        JR   C,L070E      ; Jump if START BIT has been shifted out indicating all data bits have been received.

        EX   AF,AF'       ; Save the bit counter.
        JP   L06EB        ; Jump back to read next bit.

;After looping 8 times to read the 8 data bits, the start bit in the bit counter will be shifted out
;and hence A will contain a received byte.

L070E:  SCF               ; Signal success.
        PUSH AF           ; Push success flag.
        EXX

;The success and failure paths converge here

L0711:  LD   A,H          ;
        OR   $04          ; A=%1111x1xx. Force CTS line to 1.

        LD   B,E          ; B=$BF.
        OUT  (C),A        ; Make CTS (Clear To Send) high to indicate not ready to receive.
        EXX

        LD   H,D          ;
        LD   L,E          ; HL=(BAUD).
        LD   BC,$0007     ;
        OR   A            ;
        SBC  HL,BC        ; HL=(BAUD)-7.

L0720:  DEC  HL           ; Delay for the stop bit.
        LD   A,H          ;
        OR   L            ;
        JR   NZ,L0720     ; Jump back until delay completed.

        LD   BC,$FFFD     ; HL will be $0000.
        ADD  HL,DE        ; DE=(BAUD).
        ADD  HL,DE        ;
        ADD  HL,DE        ; HL=3*(BAUD). This is how long to wait for the next start bit.

;The device at the other end of the cable may send a second byte even though
;CTS is low. So repeat the procedure to read another byte.

L072B:  IN   A,(C)        ; Read the input line.
        AND  $80          ; %10000000. Test TXD (input) line.
        JR   Z,L0739      ; Jump if START BIT found.

        DEC  HL           ; Decrement timeout counter.
        LD   A,H          ;
        OR   L            ;
        JR   NZ,L072B     ; Jump back looping for a start bit until a timeout occurs.

;No second byte incoming so return status of the first byte read attempt

        POP  AF           ; Return status of first byte read attempt - carry flag reset for no byte received or
        EI                ; carry flag set and A holds the received byte.
        RET

L0739:  IN   A,(C)        ; Second test of START BIT - it should still be 0.
        AND  $80          ; Test TXD (input) line.
        JR   NZ,L072B     ; Jump back if it is no longer 0.

        IN   A,(C)        ; Third test of START BIT - it should still be 0.
        AND  $80          ; Test TXD (input) line.
        JR   NZ,L072B     ; Jump back if it is no longer 0.

;A second byte is on its way and is received exactly as before

        LD   H,D          ;
        LD   L,E          ; HL=(BAUD).
        LD   BC,$0002     ;
        SRL  H            ;
        RR   L            ; HL=(BAUD)/2.
        OR   A            ;
        SBC  HL,BC        ; HL=(BAUD)/2 - 2.

        LD   BC,$FFFD     ;
        LD   A,$80        ; Preload A with the START BIT. It forms a shift counter used to count
        EX   AF,AF'       ; the number of bits to read in.

L0757:  NOP               ; Fine tune the following delay.
        NOP               ;
        NOP               ;
        NOP               ;

        ADD  HL,DE        ; HL=1.5*(BAUD).

L075C:  DEC  HL           ; Delay for 26*(BAUD).
        LD   A,H          ;
        OR   L            ;
        JR   NZ,L075C     ; Jump back to until delay completed.

        IN   A,(C)        ; Read a bit.
        AND  $80          ; Test TXD (input) line.
        JP   Z,L0771      ; Jump if a 0 received.

;Received one 1

        EX   AF,AF'       ; Fetch the bit counter.
        SCF               ; Set carry flag to indicate received a 1.
        RRA               ; Shift received bit into the byte (C->76543210->C).
        JR   C,L077A      ; Jump if START BIT has been shifted out indicating all data bits have been received.

        EX   AF,AF'       ; Save the bit counter.
        JP   L0757        ; Jump back to read the next bit.

;Received one 0

L0771:  EX   AF,AF'       ; Fetch the bit counter.
        OR   A            ; Clear carry flag to indicate received a 0.
        RRA               ; Shift received bit into the byte (C->76543210->C).
        JR   C,L077A      ; Jump if START BIT has been shifted out indicating all data bits have been received.

        EX   AF,AF'       ; Save the bit counter.
        JP   L0757        ; Jump back to read next bit.

;Exit with the byte that was read in

L077A:  LD   HL,SERFL     ; $5B61.
        LD   (HL),$01     ; Set the flag indicating a second byte is in the buffer.
        INC  HL           ;
        LD   (HL),A       ; Store the second byte read in the buffer.
        POP  AF           ; Return the first byte.

        EI                ; Re-enable interrupts.
        RET

; --------------------
; RS232 Output Routine
; --------------------
; This routine handles control codes, token expansion, graphics and UDGs. It therefore cannot send binary data and hence cannot support
; EPSON format ESC control codes [Credit: Andrew Owen].
; The routine suffers from a number of bugs as described in the comments below. It also suffers from a minor flaw in the design, which prevents
; interlacing screen and printer control codes and their parameters. For example, the following will not work correctly:
;
; 10 LPRINT CHR$ 16;
; 20 PRINT AT 0,0;
; 30 LPRINT CHR$ 0;"ABC"
;
; The control byte 16 gets stored in TVDATA so that the system knows how to interpret its parameter byte. However, the AT control code 22
; in line 20 will overwrite it. When line 30 is executed, TVDATA still holds the control code for 'AT' and so this line is interpreted as
; PRINT AT instead of PRINT INK. [Credit: Ian Collier (+3)]
;
; Entry: A=character to output.
; Exit : Carry flag reset indicates success.

L0784:  PUSH AF           ; Save the character to print.
        LD   A,(TVPARS)   ; $5B65. Number of parameters expected.
        OR   A            ;
        JR   Z,L079A      ; Jump if no parameters.

        DEC  A            ; Ignore the parameter.
        LD   (TVPARS),A   ; $5B65.
        JR   NZ,L0795     ; Jump ahead if we have not processed all parameters.

;All parameters processed

        POP  AF           ; Retrieve character to print.
        JP   L082C        ; Jump ahead to continue.

L0795:  POP  AF           ; Retrieve character to print.
        LD   ($5C0F),A    ; TVDATA+1. Store it for use later.
        RET               ;

L079A:  POP  AF           ; Retrieve character to print.
        CP   $A3          ; Test against code for 'SPECTRUM'.
        JR   C,L07AC      ; Jump ahead if not a token.

;Process tokens

        LD   HL,(RETADDR) ; $5B5A. Save RETADDR temporarily.
        PUSH HL           ;
        RST  28H          ;
        DEFW PO_T_UDG     ; $0B52. Print tokens via call to ROM 1 routine PO-T&UDG.
        POP  HL           ;
        LD   (RETADDR),HL ; $5B5A. Restore the original contents of RETADDR.
        SCF               ;
        RET               ;

L07AC:  LD   HL,$5C3B     ; FLAGS.
        RES  0,(HL)       ; Suppress printing a leading space.
        CP   ' '          ; $20. Is character to output a space?
        JR   NZ,L07B7     ; Jump ahead if not a space.

        SET  0,(HL)       ; Signal leading space required.

L07B7:  CP   $7F          ; Compare against copyright symbol.
        JR   C,L07BD      ; Jump ahead if not a graphic or UDG character.

        LD   A,'?'        ; $3F. Print a '?' for all graphic and UDG characters.

L07BD:  CP   $20          ; Is it a control character?
        JR   C,L07D8      ; Jump ahead if so.

;Printable character

L07C1:  PUSH AF           ; Save the character to print.
        LD   HL,COL       ; $5B63. Point to the column number.
        INC  (HL)         ; Increment the column number.
        LD   A,(WIDTH)    ; $5B64. Fetch the number of columns.
        CP   (HL)         ;
        JR   NC,L07D4     ; Jump if end of row not reached.

        CALL L07DC        ; Print a carriage return and line feed.

        LD   A,$01        ;
        LD   (COL),A      ; $5B63. Set the print position to column 1.

L07D4:  POP  AF           ; Retrieve character to print.
        JP   L085D        ; Jump ahead to print the character.

;Process control codes

L07D8:  CP   $0D          ; Is it a carriage return?
        JR   NZ,L07EA     ; Jump ahead if not.

;Handle a carriage return

L07DC:  XOR  A            ;
        LD   (COL),A      ; $5B63. Set the print position back to column 0.

        LD   A,$0D        ;
        CALL L085D        ; Print a carriage return.

        LD   A,$0A        ;
        JP   L085D        ; Print a line feed.

L07EA:  CP   $06          ; Is it a comma?
        JR   NZ,L080D     ; Jump ahead if not.

;Handle a comma

        LD   BC,(COL)     ; $5B63. Fetch the column position.
        LD   E,$00        ; Will count number of columns to move across to reach next comma position.

L07F4:  INC  E            ; Increment column counter.
        INC  C            ; Increment column position.
        LD   A,C          ;
        CP   B            ; End of row reached?
        JR   Z,L0802      ; Jump if so.

L07FA:  SUB  $08          ;
        JR   Z,L0802      ; Jump if column 8, 16 or 32 reached.

        JR   NC,L07FA     ; Column position greater so subtract another 8.

        JR   L07F4        ; Jump back and increment column position again.

;Column 8, 16 or 32 reached. Output multiple spaces until the desired column position is reached.

L0802:  PUSH DE           ; Save column counter in E.
        LD   A,$20        ;
        CALL L0784        ; Output a space via a recursive call.
        POP  DE           ; Retrieve column counter to E.
        DEC  E            ; More spaces to output?
        RET  Z            ; Return if no more to output.

        JR   L0802        ; Repeat for the next space to output.

L080D:  CP   $16          ; Is it AT?
        JR   Z,L081A      ; Jump ahead to handle AT.

        CP   $17          ; Is it TAB?
        JR   Z,L081A      ; Jump ahead to handle TAB.

        CP   $10          ; Check for INK, PAPER, FLASH, BRIGHT, INVERSE, OVER.
        RET  C            ; Ignore if not one of these.

        JR   L0823        ; Jump ahead to handle INK, PAPER, FLASH, BRIGHT, INVERSE, OVER.

;Handle AT and TAB

L081A:  LD   ($5C0E),A    ; TV_DATA. Store the control code for use later, $16 (AT) or $17 (TAB).
        LD   A,$02        ; Two parameters expected (even for TAB).

BF1_CONT:                 ;@ [*BUG_FIX*]
        LD   (TVPARS),A   ; $5B65.
        RET               ; Return with zero flag set.

;Handle INK, PAPER, FLASH, BRIGHT, INVERSE, OVER

L0823:  LD   ($5C0E),A    ; TV_DATA. Store the control code for use later.

#ifndef BUG_FIXES
        LD   A,$02        ; Two parameters expected. [*BUG* - Should be 1 parameter. 'LPRINT INK 4' will produce error report 'C Nonsense in BASIC'. Credit: Toni Baker, ZX Computing Monthly].
        LD   (TVPARS),A   ; $5B65.
        RET               ; [*BUG* - Should return with the carry flag reset and the zero flag set. It causes a statement such as 'LPRINT INK 1;' to produce error report '8 End of file'.
                          ; It is due to the main RS232 processing loop using the state of the flags to determine the success/failure response of the RS232 output routine. Credit: Ian Collier (+3), Andrew Owen (128)]
                          ; [The bug can be fixed by inserting a XOR A instruction before the RET instruction. Credit: Paul Farrow]
#else
        XOR  A            ;@ [*BUG FIX*]
        LD   A,$01        ;@ [*BUG_FIX*]
        JR   BF1_CONT     ;@ [*BUG_FIX*] All lines until next bug fix moved up by 1 byte.
#endif

;All parameters processed

L082C:  LD   D,A          ; D=Character to print.
        LD   A,($5C0E)    ; TV_DATA. Fetch the control code.
        CP   $16          ; Is it AT?
        JR   Z,L083C      ; Jump ahead to handle AT parameter.

        CP   $17          ; Is it TAB?
#ifndef BUG_FIXES
        CCF               ; [*BUG* - Should return with the carry flag reset and the zero flag set. It causes a statement such as 'LPRINT INK 1;' to produce error report '8 End of file'.
                          ; It is due to the main RS232 processing loop using the state of the flags to determine the success/failure response of the RS232 output routine. Credit: Toni Baker, ZX Computing Monthly]
        RET  NZ           ; Ignore if not TAB.
#else
;[The bug can be fixed by replacing the instructions CCF and RET NZ with the following. Credit: Paul Farrow]
;
;       JR   Z,NOT_TAB
;
;       XOR  A
;       RET
;
;NOT_TAB:

        JP NZ,BUG_FIX2    ;@ [*BUG_FIX*] Jump to XOR A / RET.
#endif

;Handle TAB parameter

        LD   A,($5C0F)    ; TV_DATA+1. Fetch the saved parameter.
        LD   D,A          ; Fetch parameter to D.

;Process AT and TAB

L083C:  LD   A,(WIDTH)    ; $5B64.
        CP   D            ; Reached end of row?
        JR   Z,L0844      ; Jump ahead if so.

        JR   NC,L084A     ; Jump ahead if before end of row.

;Column position equal or greater than length of row requested

L0844:  LD   B,A          ; (WIDTH).
        LD   A,D          ; TAB/AT column position.
        SUB  B            ; TAB/AT position - WIDTH.
        LD   D,A          ; The new required column position.
        JR   L083C        ; Handle the new TAB/AT position.

L084A:  LD   A,D          ; Fetch the desired column number.
        OR   A            ;
        JP   Z,L07DC      ; Jump to output a carriage return if column 0 required.

L084F:  LD   A,(COL)      ; $5B63. Fetch the current column position.
        CP   D            ; Compare against desired column position.
        RET  Z            ; Done if reached requested column.

        PUSH DE           ; Save the number of spaces to output.
        LD   A,$20        ;
        CALL L0784        ; Output a space via a recursive call.
        POP  DE           ; Retrieve number of spaces to output.
        JR   L084F        ; Keep outputting spaces until desired column reached.

; ------------------------
; Write Byte to RS232 Port
; ------------------------
; The timing of the routine is achieved using the timing constant held in system variable BAUD.
; Entry: A holds character to send.
; Exit:  Carry and zero flags reset.

L085D:  PUSH AF           ; Save the byte to send.

        LD   C,$FD        ;
        LD   D,$FF        ;

        LD   E,$BF        ;
        LD   B,D          ;
        LD   A,$0E        ;
        OUT  (C),A        ; Select AY register 14 to control the RS232 port.

L0869:  CALL L0590        ; Check the BREAK key, and produce error message if it is being pressed.

        IN   A,(C)        ; Read status of data register.
        AND  $40          ; %01000000. Test the DTR line.
        JR   NZ,L0869     ; Jump back until device is ready for data.

        LD   HL,(BAUD)    ; $5B5F. HL=Baud rate timing constant.
        LD   DE,$0002     ;
        OR   A            ;
        SBC  HL,DE        ;
        EX   DE,HL        ; DE=(BAUD)-2.

        POP  AF           ; Retrieve the byte to send.
        CPL               ; Invert the bits of the byte (RS232 logic is inverted).
        SCF               ; Carry is used to send START BIT.
        LD   B,$0B        ; B=Number of bits to send (1 start + 8 data + 2 stop).

        DI                ; Disable interrupts to ensure accurate timing.

;Transmit each bit

L0882:  PUSH BC           ; Save the number of bits to send.
        PUSH AF           ; Save the data bits.

        LD   A,$FE        ;
        LD   H,D          ;
        LD   L,E          ; HL=(BAUD)-2.
        LD   BC,$BFFD     ; AY-3-8912 data register.

        JP   NC,L0894     ; Branch to transmit a 1 or a 0 (initially sending a 0 for the start bit).

;Transmit a 0

        AND  $F7          ; Clear the RXD (out) line.
        OUT  (C),A        ; Send out a 0 (high level).
        JR   L089A        ; Jump ahead to continue with next bit.

;Transmit a 1

L0894:  OR   $08          ; Set the RXD (out) line.
        OUT  (C),A        ; Send out a 1 (low level).
        JR   L089A        ; Jump ahead to continue with next bit.

;Delay the length of a bit

L089A:  DEC  HL           ; (6) Delay 26*BAUD cycles.
        LD   A,H          ; (4)
        OR   L            ; (4)
        JR   NZ,L089A     ; (12) Jump back until delay is completed.

        NOP               ; (4) Fine tune the timing.
        NOP               ; (4)
        NOP               ; (4)

        POP  AF           ; Retrieve the data bits to send.
        POP  BC           ; Retrieve the number of bits left to send.
        OR   A            ; Clear carry flag.
        RRA               ; Shift the next bit to send into the carry flag.
        DJNZ L0882        ; Jump back to send next bit until all bits sent.

        EI                ; Re-enable interrupts.
        RET               ; Return with carry and zero flags reset.

; --------------------
; COPY Command Routine
; --------------------
; This routine copies 22 rows of the screen, outputting them to the printer a
; half row at a time. It is designed for EPSON compatible printers supporting
; double density bit graphics and 7/72 inch line spacing.
; Only the pixel information is processed; the attributes are ignored.

L08AA:  LD   HL,HD_0B     ; Half row counter.
        LD   (HL),$2B     ; Set the half row counter to 43 half rows (will output 44 half rows in total).

L08AF:  LD   HL,L0933     ; Point to printer configuration data (7/72 inch line spacing, double density bit graphics).
        CALL L0919        ; Send the configuration data to printer.

        CALL L08CF        ; Output a half row, at double height.

        LD   HL,L093A     ; Table holds a line feed only.
        CALL L0919        ; Send a line feed to printer.

        LD   HL,HD_0B     ; $5B72. The half row counter is tested to see if it is zero
        XOR  A            ; and if so then the line spacing is reset to its
        CP   (HL)         ; original value.
        JR   Z,L08C8      ; Jump if done, resetting printer line spacing.

        DEC  (HL)         ; Decrement half row counter.
        JR   L08AF        ; Repeat for the next half row.

;Copy done so reset printer line spacing before exiting

L08C8:  LD   HL,L093C     ; Point to printer configuration data (1/6 inch line spacing).
        CALL L0919        ; Send the configuration data to printer.
        RET               ; [Could have saved 1 byte by using JP $0919 (ROM 0)]

; ---------------
; Output Half Row
; ---------------

L08CF:  LD   HL,CP_COL    ; $5B71. Pixel column counter.
        LD   (HL),$FF     ; Set pixel column counter to 255 pixels.

L08D4:  CALL L08E0        ; Output a column of pixels, at double height.

        LD   HL,CP_COL    ; $5B71. Pixel column counter.
        XOR  A            ;
        CP   (HL)         ; Check if all pixels in this row have been output.
        RET  Z            ; Return if so.

        DEC  (HL)         ; Decrement pixel column counter.
        JR   L08D4        ; Repeat for all pixels in this row.

;Output a column of pixels (at double height)

L08E0:  LD   DE,$C000     ; D=%11000000. Used to hold the double height pixel.
        LD   BC,(CP_COL)  ; $5B71. C=Pixel column counter, B=Half row counter.
        SCF               ;
        RL   B            ; B=2xB+1
        SCF               ;
        RL   B            ; B=4xB+3. The pixel row coordinate.

        LD   A,C          ; Pixel column counter.
        CPL               ;
        LD   C,A          ; C=255-C. The pixel column coordinate.

        XOR  A            ; Clear A. Used to generate double height nibble of pixels to output.
        PUSH AF           ;

        PUSH DE           ;
        PUSH BC           ; Save registers.

L08F4:  CALL L0927        ; Test whether pixel (B,C) is set

        POP  BC           ;
        POP  DE           ; Restore registers.

        LD   E,$00        ; Set double height pixel = 0.
        JR   Z,L08FE      ; Jump if pixel is reset.

        LD   E,D          ; The double height pixel to output (%11000000, %00110000, %00001100 or %00000011).

L08FE:  POP  AF           ;
        OR   E            ; Add the double height pixel value to the byte to output.
        PUSH AF           ;

        DEC  B            ; Decrement half row coordinate.
        SRL  D            ;
        SRL  D            ; Create next double height pixel value (%00110000, %00001100 or %00000011).

        PUSH DE           ;
        PUSH BC           ;
        JR   NC,L08F4     ; Repeat for all four pixels in the half row.

        POP  BC           ;
        POP  DE           ; Unload the stack.

        POP  AF           ;
        LD   B,$03        ; Send double height nibble of pixels output 3 times.

; -----------------------
; Output Nibble of Pixels
; -----------------------
; Send each nibble of pixels (i.e. column of 4 pixels) output 3 times so that
; the width of a pixel is the same size as its height.

L090F:  PUSH BC           ;
        PUSH AF           ;
        CALL L085D        ; Send byte to RS232 port.
        POP  AF           ;
        POP  BC           ;
        DJNZ L090F        ;

        RET               ;

; ----------------------------
; Output Characters from Table
; ----------------------------
; This routine is used to send a sequence of EPSON printer control codes out to the RS232 port.
; It sends (HL) characters starting from HL+1.

L0919:  LD   B,(HL)       ; Get number of bytes to send.
        INC  HL           ; Point to the data to send.

L091B:  LD   A,(HL)       ; Retrieve value.
        PUSH HL           ;
        PUSH BC           ;
        CALL L085D        ; Send byte to RS232 port.
        POP  BC           ;
        POP  HL           ;
        INC  HL           ; Point to next data byte to send.
        DJNZ L091B        ; Repeat for all bytes.

        RET               ;

; -------------------------------
; Test Whether Pixel (B,C) is Set
; -------------------------------
; Entry: B=Pixel line
;        C=Pixel column.
; Exit : A=$00 if pixel is reset
;        A>$00 if pixel is set (actually the value of the bit corresponding to the pixel within the byte).

L0927:  RST  28H          ; Get address of (B,C) pixel into HL and pixel position within byte into A.
        DEFW PIXEL_ADDR   ; $22AA.
        LD   B,A          ; B=Pixel position within byte (0-7).
        INC  B            ;

        XOR  A            ; Pixel mask.
        SCF               ; Carry flag holds bit to be rotated into the mask.

L092E:  RRA               ; Shift the mask bit into the required bit position.
        DJNZ L092E        ;

        AND  (HL)         ; Isolate this pixel from A.
        RET               ;

; ---------------------------------
; EPSON Printer Control Code Tables
; ---------------------------------

L0933:  DEFB $06                 ; 6 characters follow.
        DEFB $1B, $31            ; ESC '1'     - 7/72 inch line spacing.
        DEFB $1B, $4C, $00, $03  ; ESC 'L' 0 3 - Double density (768 bytes per row).

L093A:  DEFB $01                 ; 1 character follows.
        DEFB $0A                 ; Line feed.

L093C:  DEFB $02                 ; 2 characters follow.
        DEFB $1B, $32            ; ESC '2' - 1/6 inch line spacing.


; =====================
; PLAY COMMAND ROUTINES
; =====================
; Up to 3 channels of music/noise are supported by the AY-3-8912 sound generator.
; Up to 8 channels of music can be sent to support synthesisers, drum machines or sequencers via the MIDI interface,
; with the first 3 channels also played by the AY-3-8912 sound generator. For each channel of music, a MIDI channel
; can be assigned to it using the 'Y' command.
;
; The PLAY command reserves and initialises space for the PLAY command. This comprises a block of $003C bytes
; used to manage the PLAY command (IY points to this command data block) and a block of $0037 bytes for each
; channel string (IX is used to point to the channel data block for the current channel). [Note that the command
; data block is $04 bytes larger than it needs to be, and each channel data block is $11 bytes larger than it
; needs to be]
;
; Entry: B=The number of strings in the PLAY command (1..8).

; -------------------------
; Command Data Block Format
; -------------------------
; IY+$00 / IY+$01 = Channel 0 data block pointer. Points to the data for channel 0 (string 1).
; IY+$02 / IY+$03 = Channel 1 data block pointer. Points to the data for channel 1 (string 2).
; IY+$04 / IY+$05 = Channel 2 data block pointer. Points to the data for channel 2 (string 3).
; IY+$06 / IY+$07 = Channel 3 data block pointer. Points to the data for channel 3 (string 4).
; IY+$08 / IY+$09 = Channel 4 data block pointer. Points to the data for channel 4 (string 5).
; IY+$0A / IY+$0B = Channel 5 data block pointer. Points to the data for channel 5 (string 6).
; IY+$0C / IY+$0D = Channel 6 data block pointer. Points to the data for channel 6 (string 7).
; IY+$0E / IY+$0F = Channel 7 data block pointer. Points to the data for channel 7 (string 8).
; IY+$10          = Channel bitmap. Initialised to $FF and a 0 rotated in to the left for each string parameters
;                   of the PLAY command, thereby indicating the channels in use.
; IY+$11 / IY+$12 = Channel data block duration pointer. Points to duration length store in channel 0 data block (string 1).
; IY+$13 / IY+$14 = Channel data block duration pointer. Points to duration length store in channel 1 data block (string 2).
; IY+$15 / IY+$16 = Channel data block duration pointer. Points to duration length store in channel 2 data block (string 3).
; IY+$17 / IY+$18 = Channel data block duration pointer. Points to duration length store in channel 3 data block (string 4).
; IY+$19 / IY+$1A = Channel data block duration pointer. Points to duration length store in channel 4 data block (string 5).
; IY+$1B / IY+$1C = Channel data block duration pointer. Points to duration length store in channel 5 data block (string 6).
; IY+$1D / IY+$1E = Channel data block duration pointer. Points to duration length store in channel 6 data block (string 7).
; IY+$1F / IY+$20 = Channel data block duration pointer. Points to duration length store in channel 7 data block (string 8).
; IY+$21          = Channel selector. It is used as a shift register with bit 0 initially set and then shift to the left
;                   until a carry occurs, thereby indicating all 8 possible channels have been processed.
; IY+$22          = Temporary channel bitmap, used to hold a working copy of the channel bitmap at IY+$10.
; IY+$23 / IY+$24 = Address of the channel data block pointers, or address of the channel data block duration pointers
;                   (allows the routine at $0A28 (ROM 0) to be used with both set of pointers).
; IY+$25 / IY+$26 = Stores the smallest duration length of all currently playing channel notes.
; IY+$27 / IY+$28 = The current tempo timing value (derived from the tempo parameter 60..240 beats per second).
; IY+$29          = The current effect waveform value.
; IY+$2A          = Temporary string counter selector.
; IY+$2B..IY+$37  = Holds a floating point calculator routine.
; IY+$38..IY+$3B  = Not used.

; -------------------------
; Channel Data Block Format
; -------------------------
; IX+$00          = The note number being played on this channel (equivalent to index offset into the note table).
; IX+$01          = MIDI channel assigned to this string (range 0 to 15).
; IX+$02          = Channel number (range 0 to 7), i.e. index position of the string within the PLAY command.
; IX+$03          = 12*Octave number (0, 12, 24, 36, 48, 60, 72, 84 or 96).
; IX+$04          = Current volume (range 0 to 15, or if bit 4 set then using envelope).
; IX+$05          = Last note duration value as specified in the string (range 1 to 9).
; IX+$06 / IX+$07 = Address of current position in the string.
; IX+$08 / IX+$09 = Address of byte after the end of the string.
; IX+$0A          = Flags:
;                     Bit 0   : 1=Single closing bracket found (repeat string indefinitely).
;                     Bits 1-7: Not used (always 0).
; IX+$0B          = Open bracket nesting level (range $00 to $04).
; IX+$0C / IX+$0D = Return address for opening bracket nesting level 0 (points to character after the bracket).
; IX+$0E / IX+$0F = Return address for opening bracket nesting level 1 (points to character after the bracket).
; IX+$10 / IX+$11 = Return address for opening bracket nesting level 2 (points to character after the bracket).
; IX+$12 / IX+$13 = Return address for opening bracket nesting level 3 (points to character after the bracket).
; IX+$14 / IX+$15 = Return address for opening bracket nesting level 4 (points to character after the bracket).
; IX+$16          = Closing bracket nesting level (range $FF to $04).
; IX+$17...IX+$18 = Return address for closing bracket nesting level 0 (points to character after the bracket).
; IX+$19...IX+$1A = Return address for closing bracket nesting level 1 (points to character after the bracket).
; IX+$1B...IX+$1C = Return address for closing bracket nesting level 2 (points to character after the bracket).
; IX+$1D...IX+$1E = Return address for closing bracket nesting level 3 (points to character after the bracket).
; IX+$1F...IX+$20 = Return address for closing bracket nesting level 4 (points to character after the bracket).
; IX+$21          = Tied notes counter (for a single note the value is 1).
; IX+$22 / IX+$23 = Duration length, specified in 96ths of a note.
; IX+$24...IX+$25 = Subsequent note duration length (used only with triplets), specified in 96ths of a note.
; IX+$26...IX+$36 = Not used.

L093F:  DI                ; Disable interrupts to ensure accurate timing.

;Create a workspace for the play channel command strings

        PUSH BC           ; B=Number of channel string (range 1 to 8). Also used as string index number in the following loop.

        LD   DE,$0037     ;
        LD   HL,$003C     ;

L0947:  ADD  HL,DE        ; Calculate HL=$003C + ($0037 * B).
        DJNZ L0947        ;

        LD   C,L          ;
        LD   B,H          ; BC=Space required (maximum = $01F4).
        RST  28H          ;
        DEFW BC_SPACES    ; $0030. Make BC bytes of space in the workspace.

        DI                ; Interrupts get re-enabled by the call mechanism to ROM 1 so disable them again.

        PUSH DE           ;
        POP  IY           ; IY=Points at first new byte - the command data block.

        PUSH HL           ;
        POP  IX           ; IX=Points at last new byte - byte after all channel information blocks.

        LD   (IY+$10),$FF ; Initial channel bitmap with value meaning 'zero strings'

;Loop over each string to be played

L095A:  LD   BC,$FFC9     ; $-37 ($37 bytes is the size of a play channel string information block).
        ADD  IX,BC        ; IX points to start of space for the last channel.
        LD   (IX+$03),$3C ; Default octave is 5.
        LD   (IX+$01),$FF ; No MIDI channel assigned.
        LD   (IX+$04),$0F ; Default volume is 15.
        LD   (IX+$05),$05 ; Default note duration.
        LD   (IX+$21),$00 ; Count of the number of tied notes.
        LD   (IX+$0A),$00 ; Signal not to repeat the string indefinitely.
        LD   (IX+$0B),$00 ; No opening bracket nesting level.
        LD   (IX+$16),$FF ; No closing bracket nesting level.
        LD   (IX+$17),$00 ; Return address for closing bracket nesting level 0.
        LD   (IX+$18),$00 ; [No need to initialise this since it is written to before it is ever tested]

; [*BUG* - At this point interrupts are disabled and IY is now being used as a pointer to the master
;          PLAY information block. Unfortunately, interrupts are enabled during the STK_FETCH call and
;          IY is left containing the wrong value. This means that if an interrupt were to occur during
;          execution of the subroutine then there would be a one in 65536 chance that (IY+$40) will be
;          corrupted - this corresponds to the volume setting for music channel A.
;          Rewriting the SWAP routine to only re-enable interrupts if they were originally enabled
;          would cure this bug (see end of file for description of her suggested fix). Credit: Toni Baker, ZX Computing Monthly]

;[An alternative and simpler solution to the fix Toni Baker describes would be to stack IY, set IY to point
;to the system variables at $5C3A, call STK_FETCH, disable interrupts, then pop the stacked value back to IY. Credit: Paul Farrow]

#ifndef BUG_FIXES
        RST  28H          ; Get the details of the string from the stack.
        DEFW STK_FETCH    ; $2BF1.
#else
        CALL BUG_FIX3     ;@ [*BUG_FIX*]
#endif
        DI                ; Interrupts get re-enabled by the call mechanism to ROM 1 so disable them again.

        LD   (IX+$06),E   ; Store the current position within in the string, i.e. the beginning of it.
        LD   (IX+$07),D   ;
        LD   (IX+$0C),E   ; Store the return position within the string for a closing bracket,
        LD   (IX+$0D),D   ; which is initially the start of the string in case a single closing bracket is found.

        EX   DE,HL        ; HL=Points to start of string. BC=Length of string.
        ADD  HL,BC        ; HL=Points to address of byte after the string.
        LD   (IX+$08),L   ; Store the address of the character just
        LD   (IX+$09),H   ; after the string.

        POP  BC           ; B=String index number (range 1 to 8).
        PUSH BC           ; Save it on the stack again.
        DEC  B            ; Reduce the index so it ranges from 0 to 7.

        LD   C,B          ;
        LD   B,$00        ;
        SLA  C            ; BC=String index*2.

        PUSH IY           ;
        POP  HL           ; HL=Address of the command data block.
        ADD  HL,BC        ; Skip 8 channel data pointer words.

        PUSH IX           ;
        POP  BC           ; BC=Address of current channel information block.

        LD   (HL),C       ; Store the pointer to the channel information block.
        INC  HL           ;
        LD   (HL),B       ;

        OR   A            ; Clear the carry flag.
        RL   (IY+$10)     ; Rotate one zero-bit into the least significant bit of the channel bitmap.
                          ; This initially holds $FF but once this loop is over, this byte has
                          ; a zero bit for each string parameter of the PLAY command.

        POP  BC           ; B=Current string index.
        DEC  B            ; Decrement string index so it ranges from 0 to 7.
        PUSH BC           ; Save it for future use on the next iteration.
        LD   (IX+$02),B   ; Store the channel number.

        JR   NZ,L095A     ; Jump back while more channel strings to process.

        POP  BC           ; Drop item left on the stack.

;Entry point here from the vector table at $011B

L09BF:  LD   (IY+$27),$1A ; Set the initial tempo timing value.
        LD   (IY+$28),$0B ; Corresponds to a 'T' command value of 120, and gives two crotchets per second.

        PUSH IY           ;
        POP  HL           ; HL=Points to the command data block.

        LD   BC,$002B     ;
        ADD  HL,BC        ;
        EX   DE,HL        ; DE=Address to store RAM routine.
        LD   HL,L09EB     ; HL=Address of the RAM routine bytes.
        LD   BC,$000D     ;
        LDIR              ; Copy the calculator routine to RAM.

        LD   D,$07        ; Register 7 - Mixer.
        LD   E,$F8        ; I/O ports are inputs, noise output off, tone output on.
        CALL L0E2E        ; Write to sound generator register.

        LD   D,$0B        ; Register 11 - Envelope Period (Fine).
        LD   E,$FF        ; Set period to maximum.
        CALL L0E2E        ; Write to sound generator register.

        INC  D            ; Register 12 - Envelope Period (Coarse).
        CALL L0E2E        ; Write to sound generator register.

        JR   L0A37        ; Jump ahead to continue.
                          ; [Could have saved these 2 bytes by having the code at $0A37 (ROM 0) immediately follow]

; -------------------------------------------------
; Calculate Timing Loop Counter <<< RAM Routine >>>
; -------------------------------------------------
; This routine is copied into the command data block (offset $2B..$37) by
; the routine at $09BF (ROM 0).
; It uses the floating point calculator found in ROM 1, which is usually
; invoked via a RST $28 instruction. Since ROM 0 uses RST $28 to call a
; routine in ROM 1, it is unable to invoke the floating point calculator
; this way. It therefore copies the following routine to RAM and calls it
; with ROM 1 paged in.
;
; The routine calculates (10/x)/7.33e-6, where x is the tempo 'T' parameter value
; multiplied by 4. The result is used an inner loop counter in the wait routine at $0F28 (ROM 0).
; Each iteration of this loop takes 26 T-states. The time taken by 26 T-states
; is 7.33e-6 seconds. So the total time for the loop to execute is 2.5/TEMPO seconds.
;
; Entry: The value 4*TEMPO exists on the calculator stack (where TEMPO is in the range 60..240).
; Exit : The calculator stack holds the result.

L09EB:  RST 28H           ; Invoke the floating point calculator.
        DEFB $A4          ; stk-ten.   = x, 10
        DEFB $01          ; exchange.  = 10, x
        DEFB $05          ; division.  = 10/x
        DEFB $34          ; stk-data.  = 10/x, 7.33e-6
        DEFB $DF          ; - exponent $6F (floating point number 7.33e-6).
        DEFB $75          ; - mantissa byte 1
        DEFB $F4          ; - mantissa byte 2
        DEFB $38          ; - mantissa byte 3
        DEFB $75          ; - mantissa byte 4
        DEFB $05          ; division.  = (10/x)/7.33e-6
        DEFB $38          ; end-calc.
        RET               ;

; --------------
; Test BREAK Key
; --------------
; Test for BREAK being pressed.
; Exit: Carry flag reset if BREAK is being pressed.

L09F8:  LD   A,$7F        ;
        IN   A,($FE)      ;
        RRA               ;
        RET  C            ; Return with carry flag set if SPACE not pressed.

        LD   A,$FE        ;
        IN   A,($FE)      ;
        RRA               ;
        RET               ; Return with carry flag set if CAPS not pressed.

; -------------------------------------------
; Select Channel Data Block Duration Pointers
; -------------------------------------------
; Point to the start of the channel data block duration pointers within the command data block.
; Entry: IY=Address of the command data block.
; Exit : HL=Address of current channel pointer.

L0A04:  LD   BC,$0011     ; Offset to the channel data block duration pointers table.
        JR   L0A0C        ; Jump ahead to continue.

; ----------------------------------
; Select Channel Data Block Pointers
; ----------------------------------
; Point to the start of the channel data block pointers within the command data block.
; Entry: IY=Address of the command data block.
; Exit : HL=Address of current channel pointer.

L0A09:  LD   BC,$0000     ; Offset to the channel data block pointers table.

L0A0C:  PUSH IY           ;
        POP  HL           ; HL=Point to the command data block.

        ADD  HL,BC        ; Point to the desired channel pointers table.

        LD   (IY+$23),L   ;
        LD   (IY+$24),H   ; Store the start address of channels pointer table.

        LD   A,(IY+$10)   ; Fetch the channel bitmap.
        LD   (IY+$22),A   ; Initialise the working copy.

        LD   (IY+$21),$01 ; Channel selector. Set the shift register to indicate the first channel.
        RET               ;

; -------------------------------------------------
; Get Channel Data Block Address for Current String
; -------------------------------------------------
; Entry: HL=Address of channel data block pointer.
; Exit : IX=Address of current channel data block.

L0A21:  LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; Fetch the address of the current channel data block.

        PUSH DE           ;
        POP  IX           ; Return it in IX.
        RET               ;

; -------------------------
; Next Channel Data Pointer
; -------------------------

L0A28:  LD   L,(IY+$23)   ; The address of current channel data pointer.
        LD   H,(IY+$24)   ;
        INC  HL           ;
        INC  HL           ; Advance to the next channel data pointer.
        LD   (IY+$23),L   ;
        LD   (IY+$24),H   ; The address of new channel data pointer.
        RET               ;

; ---------------------------
; PLAY Command (Continuation)
; ---------------------------
; This section is responsible for processing the PLAY command and is a continuation of the routine
; at $093F (ROM 0). It begins by determining the first note to play on each channel and then enters
; a loop to play these notes, fetching the subsequent notes to play at the appropriate times.

L0A37:  CALL L0A09        ; Select channel data block pointers.

L0A3A:  RR   (IY+$22)     ; Working copy of channel bitmap. Test if next string present.
        JR   C,L0A46      ; Jump ahead if there is no string for this channel.

;HL=Address of channel data pointer.

        CALL L0A21        ; Get address of channel data block for the current string into IX.
        CALL L0B16        ; Find the first note to play for this channel from its play string.

L0A46:  SLA  (IY+$21)     ; Have all channels been processed?
        JR   C,L0A51      ; Jump ahead if so.

        CALL L0A28        ; Advance to the next channel data block pointer.
        JR   L0A3A        ; Jump back to process the next channel.

;The first notes to play for each channel have now been determined. A loop is entered that coordinates playing
;the notes and fetching subsequent notes when required. Notes across channels may be of different lengths and
;so the shortest one is determined, the tones for all channels set and then a waiting delay entered for the shortest
;note delay. This delay length is then subtracted from all channel note lengths to leave the remaining lengths that
;each note needs to be played for. For the channel with the smallest note length, this will now have completely played
;and so a new note is fetched for it. The smallest length of the current notes is then determined again and the process
;described above repeated. A test is made on each iteration to see if all channels have run out of data to play, and if
;so this ends the PLAY command.

L0A51:  CALL L0F43        ; Find smallest duration length of the current notes across all channels.

        PUSH DE           ; Save the smallest duration length.
        CALL L0EF4        ; Play a note on each channel.
        POP  DE           ; DE=The smallest duration length.

L0A59:  LD   A,(IY+$10)   ; Channel bitmap.
        CP   $FF          ; Is there anything to play?
        JR   NZ,L0A65     ; Jump if there is.

        CALL L0E45        ; Turn off all sound and restore IY.
        EI                ; Re-enable interrupts.
        RET               ; End of play command.

L0A65:  DEC  DE           ; DE=Smallest channel duration length, i.e. duration until the next channel state change.
        CALL L0F28        ; Perform a wait.
        CALL L0F73        ; Play a note on each channel and update the channel duration lengths.

        CALL L0F43        ; Find smallest duration length of the current notes across all channels.
        JR   L0A59        ; Jump back to see if there is more to process.

; ----------------------------
; PLAY Command Character Table
; ----------------------------
; Recognised characters in PLAY commands.

L0A71:  DEFM "HZYXWUVMT)(NO!"

; ------------------
; Get Play Character
; ------------------
; Get the current character from the PLAY string and then increment the
; character pointer within the string.
; Exit: Carry flag set if string has been fully processed.
;       Carry flag reset if character is available.
;       A=Character available.

L0A7F:  CALL L0E95        ; Get the current character from the play string for this channel.
        RET  C            ; Return if no more characters.

        INC  (IX+$06)     ; Increment the low byte of the string pointer.
        RET  NZ           ; Return if it has not overflowed.

        INC  (IX+$07)     ; Else increment the high byte of the string pointer.
        RET               ; Returns with carry flag reset.

; --------------------------
; Get Next Note in Semitones
; --------------------------
; Finds the number of semitones above C for the next note in the string,
; Entry: IX=Address of the channel data block.
; Exit : A=Number of semitones above C, or $80 for a rest.

L0A8B:  PUSH HL           ; Save HL.

        LD   C,$00        ; Default is for a 'natural' note, i.e. no adjustment.

L0A8E:  CALL L0A7F        ; Get the current character from the PLAY string, and advance the position pointer.
        JR   C,L0A9B      ; Jump if at the end of the string.

        CP   '&'          ; $26. Is it a rest?
        JR   NZ,L0AA6     ; Jump ahead if not.

        LD   A,$80        ; Signal that it is a rest.

L0A99:  POP  HL           ; Restore HL.
        RET               ;

L0A9B:  LD   A,(IY+$21)   ; Fetch the channel selector.
        OR   (IY+$10)     ; Clear the channel flag for this string.
        LD   (IY+$10),A   ; Store the new channel bitmap.
        JR   L0A99        ; Jump back to return.

L0AA6:  CP   '#'          ; $23. Is it a sharpen?
        JR   NZ,L0AAD     ; Jump ahead if not.

        INC  C            ; Increment by a semitone.
        JR   L0A8E        ; Jump back to get the next character.

L0AAD:  CP   '$'          ; $24. Is it a flatten?
        JR   NZ,L0AB4     ; Jump ahead if not.

        DEC  C            ; Decrement by a semitone.
        JR   L0A8E        ; Jump back to get the next character.

L0AB4:  BIT  5,A          ; Is it a lower case letter?
        JR   NZ,L0ABE     ; Jump ahead if lower case.

        PUSH AF           ; It is an upper case letter so
        LD   A,$0C        ; increase an octave
        ADD  A,C          ; by adding 12 semitones.
        LD   C,A          ;
        POP  AF           ;

L0ABE:  AND  $DF          ; Convert to upper case.
        SUB  $41          ; Reduce to range 'A'->0 .. 'G'->6.
        JP   C,L0ED4      ; Jump if below 'A' to produce error report "k Invalid note name".

        CP   $07          ; Is it 7 or above?
        JP   NC,L0ED4     ; Jump if so to produce error report "k Invalid note name".

        PUSH BC           ; C=Number of semitones.

        LD   B,$00        ;
        LD   C,A          ; BC holds 0..6 for 'a'..'g'.
        LD   HL,L0DB6     ; Look up the number of semitones above note C for the note.
        ADD  HL,BC        ;
        LD   A,(HL)       ; A=Number of semitones above note C.

        POP  BC           ; C=Number of semitones due to sharpen/flatten characters.
        ADD  A,C          ; Adjust number of semitones above note C for the sharpen/flatten characters.

        POP  HL           ; Restore HL.
        RET               ;

; ----------------------------------
; Get Numeric Value from Play String
; ----------------------------------
; Get a numeric value from a PLAY string, returning 0 if no numeric value present.
; Entry: IX=Address of the channel data block.
; Exit : BC=Numeric value, or 0 if no numeric value found.

L0AD7:  PUSH HL           ; Save registers.
        PUSH DE           ;

        LD   L,(IX+$06)   ; Get the pointer into the PLAY string.
        LD   H,(IX+$07)   ;

        LD   DE,$0000     ; Initialise result to 0.

L0AE2:  LD   A,(HL)       ;
        CP   '0'          ; $30. Is character numeric?
        JR   C,L0AFF      ; Jump ahead if not.

        CP   ':'          ; $3A. Is character numeric?
        JR   NC,L0AFF     ; Jump ahead if not.

        INC  HL           ; Advance to the next character.
        PUSH HL           ; Save the pointer into the string.

        CALL L0B0A        ; Multiply result so far by 10.
        SUB  '0'          ; $30. Convert ASCII digit to numeric value.
        LD   H,$00        ;
        LD   L,A          ; HL=Numeric digit value.
        ADD  HL,DE        ; Add the numeric value to the result so far.
        JR   C,L0AFC      ; Jump ahead if an overflow to produce error report "l number too big".

        EX   DE,HL        ; Transfer the result into DE.

        POP  HL           ; Retrieve the pointer into the string.
        JR   L0AE2        ; Loop back to handle any further numeric digits.

L0AFC:  JP   L0ECC        ; Jump to produce error report "l number too big".
                          ; [Could have saved 1 byte by directly using JP C,$0ECC (ROM 0) instead of using this JP and
                          ; the two JR C,$0AFC (ROM 0) instructions that come here]

;The end of the numeric value was reached

L0AFF:  LD   (IX+$06),L   ; Store the new pointer position into the string.
        LD   (IX+$07),H   ;

        PUSH DE           ;
        POP  BC           ; Return the result in BC.

        POP  DE           ; Restore registers.
        POP  HL           ;
        RET               ;

; -----------------
; Multiply DE by 10
; -----------------
; Entry: DE=Value to multiple by 10.
; Exit : DE=Value*10.

L0B0A:  LD   HL,$0000     ;
        LD   B,$0A        ; Add DE to HL ten times.

L0B0F:  ADD  HL,DE        ;
        JR   C,L0AFC      ; Jump ahead if an overflow to produce error report "l number too big".

        DJNZ L0B0F        ;

        EX   DE,HL        ; Transfer the result into DE.
        RET               ;

; ----------------------------------
; Find Next Note from Channel String
; ----------------------------------
; Entry: IX=Address of channel data block.

L0B16:  CALL L09F8        ; Test for BREAK being pressed.
        JR   C,L0B23      ; Jump ahead if not pressed.

        CALL L0E45        ; Turn off all sound and restore IY.
        EI                ; Re-enable interrupts.

        CALL L0566        ; Produce error report. [Could have saved 1 byte by using JP $0590 (ROM 0)]
        DEFB $14          ; "L Break into program"

L0B23:  CALL L0A7F        ; Get the current character from the PLAY string, and advance the position pointer.
        JP   C,L0D5F      ; Jump if at the end of the string.

        CALL L0DAD        ; Find the handler routine for the PLAY command character.

        LD   B,$00        ;
        SLA  C            ; Generate the offset into the
        LD   HL,L0D87     ; command vector table.
        ADD  HL,BC        ; HL points to handler routine for this command character.

        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; Fetch the handler routine address.

        EX   DE,HL        ; HL=Handler routine address for this command character.
        CALL L0B3E        ; Make an indirect call to the handler routine.
        JR   L0B16        ; Jump back to handle the next character in the string.

;Comes here after processing a non-numeric digit that does not have a specific command routine handler
;Hence the next note to play has been determined and so a return is made to process the other channels.

L0B3D:  RET               ; Just make a return.

L0B3E:  JP   (HL)         ; Jump to the command handler routine.

; --------------------------
; Play Command '!' (Comment)
; --------------------------
; A comment is enclosed within exclamation marks, e.g. "! A comment !".
; Entry: IX=Address of the channel data block.

L0B3F:  CALL L0A7F        ; Get the current character from the PLAY string, and advance the position pointer.
        JP   C,L0D5E      ; Jump if at the end of the string.

        CP   '!'          ; $21. Is it the end-of-comment character?
        RET  Z            ; Return if it is.

        JR   L0B3F        ; Jump back to test the next character.

; -------------------------
; Play Command 'O' (Octave)
; -------------------------
; The 'O' command is followed by a numeric value within the range 0 to 8,
; although due to loose range checking the value MOD 256 only needs to be
; within 0 to 8. Hence O256 operates the same as O0.
; Entry: IX=Address of the channel data block.

L0B4A:  CALL L0AD7        ; Get following numeric value from the string into BC.

        LD   A,C          ; Is it between 0 and 8?
        CP   $09          ;
        JP   NC,L0EC4     ; Jump if above 8 to produce error report "n Out of range".

        SLA  A            ; Multiply A by 12.
        SLA  A            ;
        LD   B,A          ;
        SLA  A            ;
        ADD  A,B          ;

        LD   (IX+$03),A   ; Store the octave value.
        RET               ;

; ----------------------------
; Play Command 'N' (Separator)
; ----------------------------
; The 'N' command is simply a separator marker and so is ignored.
; Entry: IX=Address of the channel data block.

L0B5F:  RET               ; Nothing to do so make an immediate return.

; ----------------------------------
; Play Command '(' (Start of Repeat)
; ----------------------------------
; A phrase can be enclosed within brackets causing it to be repeated, i.e. played twice.
; Entry: IX=Address of the channel data block.

L0B60:  LD   A,(IX+$0B)   ; A=Current level of open bracket nesting.
        INC  A            ; Increment the count.
        CP   $05          ; Only 4 levels supported.
        JP   Z,L0EDC      ; Jump if this is the fifth to produce error report "d Too many brackets".

        LD   (IX+$0B),A   ; Store the new open bracket nesting level.

        LD   DE,$000C     ; Offset to the bracket level return position stores.
        CALL L0BE1        ; HL=Address of the pointer in which to store the return location of the bracket.

        LD   A,(IX+$06)   ; Store the current string position as the return address of the open bracket.
        LD   (HL),A       ;
        INC  HL           ;
        LD   A,(IX+$07)   ;
        LD   (HL),A       ;
        RET               ;

; --------------------------------
; Play Command ')' (End of Repeat)
; --------------------------------
; A phrase can be enclosed within brackets causing it to be repeated, i.e. played twice.
; Brackets can also be nested within each other, to 4 levels deep.
; If a closing bracket if used without a matching opening bracket then the whole string up
; until that point is repeated indefinitely.
; Entry: IX=Address of the channel data block.

L0B7C:  LD   A,(IX+$16)   ; Fetch the nesting level of closing brackets.
        LD   DE,$0017     ; Offset to the closing bracket return address store.
        OR   A            ; Is there any bracket nesting so far?
        JP   M,L0BAA      ; Jump if none. [Could have been faster by jumping to $0BAD (ROM 0)]

;Has the bracket level been repeated, i.e. re-reached the same position in the string as the closing bracket return address?

        CALL L0BE1        ; HL=Address of the pointer to the corresponding closing bracket return address store.
        LD   A,(IX+$06)   ; Fetch the low byte of the current address.
        CP   (HL)         ; Re-reached the closing bracket?
        JR   NZ,L0BAA     ; Jump ahead if not.

        INC  HL           ; Point to the high byte.
        LD   A,(IX+$07)   ; Fetch the high byte address of the current address.
        CP   (HL)         ; Re-reached the closing bracket?
        JR   NZ,L0BAA     ; Jump ahead if not.

;The bracket level has been repeated. Now check whether this was the outer bracket level.

        DEC  (IX+$16)     ; Decrement the closing bracket nesting level since this level has been repeated.
        LD   A,(IX+$16)   ; [There is no need for the LD A,(IX+$16) and OR A instructions since the DEC (IX+$16) already set the flags]
        OR   A            ; Reached the outer bracket nesting level?
        RET  P            ; Return if not the outer bracket nesting level such that the character
                          ; after the closing bracket is processed next.

;The outer bracket level has been repeated

        BIT  0,(IX+$0A)   ; Was this a single closing bracket?
        RET  Z            ; Return if it was not.

;The repeat was caused by a single closing bracket so re-initialise the repeat

        LD   (IX+$16),$00 ; Restore one level of closing bracket nesting.
        XOR  A            ; Select closing bracket nesting level 0.
        JR   L0BC5        ; Jump ahead to continue.

;A new level of closing bracket nesting

L0BAA:  LD   A,(IX+$16)   ; Fetch the nesting level of closing brackets.
        INC  A            ; Increment the count.
        CP   $05          ; Only 5 levels supported (4 to match up with opening brackets and a 5th to repeat indefinitely).
        JP   Z,L0EDC      ; Jump if this is the fifth to produce error report "d Too many brackets".

        LD   (IX+$16),A   ; Store the new closing bracket nesting level.

        CALL L0BE1        ; HL=Address of the pointer to the appropriate closing bracket return address store.

        LD   A,(IX+$06)   ; Store the current string position as the return address for the closing bracket.
        LD   (HL),A       ;
        INC  HL           ;
        LD   A,(IX+$07)   ;
        LD   (HL),A       ;

        LD   A,(IX+$0B)   ; Fetch the nesting level of opening brackets.

L0BC5:  LD   DE,$000C     ;
        CALL L0BE1        ; HL=Address of the pointer to the opening bracket nesting level return address store.

        LD   A,(HL)       ; Set the return address of the nesting level's opening bracket
        LD   (IX+$06),A   ; as new current position within the string.
        INC  HL           ;
        LD   A,(HL)       ; For a single closing bracket only, this will be the start address of the string.
        LD   (IX+$07),A   ;

        DEC  (IX+$0B)     ; Decrement level of open bracket nesting.
        RET  P            ; Return if the closing bracket matched an open bracket.

;There is one more closing bracket then opening brackets, i.e. repeat string indefinitely

        LD   (IX+$0B),$00 ; Set the opening brackets nesting level to 0.
        SET  0,(IX+$0A)   ; Signal a single closing bracket only, i.e. to repeat the string indefinitely.
        RET               ;

; ------------------------------------
; Get Address of Bracket Pointer Store
; ------------------------------------
; Entry: IX=Address of the channel data block.
;        DE=Offset to the bracket pointer stores.
;        A=Index into the bracket pointer stores.
; Exit : HL=Address of the specified pointer store.

L0BE1:  PUSH IX           ;
        POP  HL           ; HL=IX.

        ADD  HL,DE        ; HL=IX+DE.
        LD   B,$00        ;
        LD   C,A          ;
        SLA  C            ;
        ADD  HL,BC        ; HL=IX+DE+2*A.
        RET               ;

; ------------------------
; Play Command 'T' (Tempo)
; ------------------------
; A temp command must be specified in the first play string and is followed by a numeric
; value in the range 60 to 240 representing the number of beats (crotchets) per minute.
; Entry: IX=Address of the channel data block.

L0BEC:  CALL L0AD7        ; Get following numeric value from the string into BC.
        LD   A,B          ;
        OR   A            ;
        JP   NZ,L0EC4     ; Jump if 256 or above to produce error report "n Out of range".

        LD   A,C          ;
        CP   $3C          ;
        JP   C,L0EC4      ; Jump if 59 or below to produce error report "n Out of range".

        CP   $F1          ;
        JP   NC,L0EC4     ; Jump if 241 or above to produce error report "n Out of range".

;A holds a value in the range 60 to 240

        LD   A,(IX+$02)   ; Fetch the channel number.
        OR   A            ; Tempo 'T' commands have to be specified in the first string.
        RET  NZ           ; If it is in a later string then ignore it.

        LD   B,$00        ; [Redundant instruction - B is already zero]
        PUSH BC           ; C=Tempo value.
        POP  HL           ;
        ADD  HL,HL        ;
        ADD  HL,HL        ; HL=Tempo*4.

        PUSH HL           ;
        POP  BC           ; BC=Tempo*4. [Would have been quicker to use the combination LD B,H and LD C,L]

        PUSH IY           ; Save the pointer to the play command data block.
        RST  28H          ;
        DEFW STACK_BC     ; $2D2B. Place the contents of BC onto the stack. The call restores IY to $5C3A.
        DI                ; Interrupts get re-enabled by the call mechanism to ROM 1 so disable them again.
        POP  IY           ; Restore IY to point at the play command data block.

        PUSH IY           ; Save the pointer to the play command data block.

        PUSH IY           ;
        POP  HL           ; HL=pointer to the play command data block.

        LD   BC,$002B     ;
        ADD  HL,BC        ; HL =IY+$002B.
        LD   IY,$5C3A     ; Reset IY to $5C3A since this is required by the floating point calculator.
        PUSH HL           ; HL=Points to the calculator RAM routine.

        LD   HL,L0C30     ;
        LD   (RETADDR),HL ; $5B5A. Set up the return address.

        LD   HL,YOUNGER   ;
        EX   (SP),HL      ; Stack the address of the swap routine used when returning to this ROM.
        PUSH HL           ; Re-stack the address of the calculator RAM routine.

        JP   SWAP         ; $5B00. Toggle to other ROM and make a return to the calculator RAM routine.

; --------------------
; Tempo Command Return
; --------------------
; The calculator stack now holds the value (10/(Tempo*4))/7.33e-6 and this is stored as the tempo value.
; The result is used an inner loop counter in the wait routine at $0F28 (ROM 0). Each iteration of this loop
; takes 26 T-states. The time taken by 26 T-states is 7.33e-6 seconds. So the total time for the loop
; to execute is 2.5/TEMPO seconds.

L0C30:  DI                ; Interrupts get re-enabled by the call mechanism to ROM 1 so disable them again.

        RST  28H          ;
        DEFW FP_TO_BC     ; $2DA2. Fetch the value on the top of the calculator stack.

        DI                ; Interrupts get re-enabled by the call mechanism to ROM 1 so disable them again.

        POP  IY           ; Restore IY to point at the play command data block.

        LD   (IY+$27),C   ; Store tempo timing value.
        LD   (IY+$28),B   ;
        RET               ;

; ------------------------
; Play Command 'M' (Mixer)
; ------------------------
; This command is used to select whether to use tone and/or noise on each of the 3 channels.
; It is followed by a numeric value in the range 1 to 63, although due to loose range checking the
; value MOD 256 only needs to be within 0 to 63. Hence M256 operates the same as M0.
; Entry: IX=Address of the channel data block.

L0C3E:  CALL L0AD7        ; Get following numeric value from the string into BC.
        LD   A,C          ; A=Mixer value.
        CP   $40          ; Is it 64 or above?
        JP   NC,L0EC4     ; Jump if so to produce error report "n Out of range".

;Bit 0: 1=Enable channel A tone.
;Bit 1: 1=Enable channel B tone.
;Bit 2: 1=Enable channel C tone.
;Bit 3: 1=Enable channel A noise.
;Bit 4: 1=Enable channel B noise.
;Bit 5: 1=Enable channel C noise.

        CPL               ; Invert the bits since the sound generator's mixer register uses active low enable.
                          ; This also sets bit 6 1, which selects the I/O port as an output.
        LD   E,A          ; E=Mixer value.
        LD   D,$07        ; D=Register 7 - Mixer.
        CALL L0E2E        ; Write to sound generator register to set the mixer.
        RET               ; [Could have saved 1 byte by using JP $0E2E (ROM 0)]

; -------------------------
; Play Command 'V' (Volume)
; -------------------------
; This sets the volume of a channel and is followed by a numeric value in the range
; 0 (minimum) to 15 (maximum), although due to loose range checking the value MOD 256
; only needs to be within 0 to 15. Hence V256 operates the same as V0.
; Entry: IX=Address of the channel data block.

L0C4F:  CALL L0AD7        ; Get following numeric value from the string into BC.

        LD   A,C          ;
        CP   $10          ; Is it 16 or above?
        JP   NC,L0EC4     ; Jump if so to produce error report "n Out of range".

#ifndef BUG_FIXES
        LD   (IX+$04),A   ; Store the volume level.

; [*BUG* - An attempt to set the volume for a sound chip channel is now made. However, this routine fails to take into account
;          that it is also called to set the volume for a MIDI only channel, i.e. play strings 4 to 8. As a result, corruption
;          occurs to various sound generator registers, causing spurious sound output. There is in fact no need for this routine
;          to set the volume for any channels since this is done every time a new note is played - see routine at $0A51 (ROM 0).
;          the bug fix is to simply to make a return at this point. This routine therefore contains 11 surplus bytes. Credit: Ian Collier (+3), Paul Farrow (128)]

        LD   E,(IX+$02)   ; E=Channel number.
        LD   A,$08        ; Offset by 8.
        ADD  A,E          ; A=8+index.
        LD   D,A          ; D=Sound generator register number for the channel.

        LD   E,C          ; E=Volume level.
        CALL L0E2E        ; Write to sound generator register to set the volume for the channel.
        RET               ; [Could have saved 1 byte by using JP $0E2E (ROM 0)]

#else
        JR   BF4_CONT     ;@ [*BUG_FIX*]

; ------------------------
; BUG FIX 3 - PLAY COMMAND
; ------------------------

BUG_FIX3:                 ;@ [*BUG_FIX*]
        PUSH IY           ;@ [*BUG_FIX*]
        LD   IY,$5C3A     ;@ [*BUG_FIX*]
        RST  28H          ;@ [*BUG_FIX*] Get the details of the string from the stack.
        DEFW STK_FETCH    ;@ [*BUG_FIX*] $2bf1.
        DI                ;@ [*BUG_FIX*]
        POP  IY           ;@ [*BUG_FIX*]
        RET               ;@ [*BUG_FIX*]
#endif

; ------------------------------------
; Play Command 'U' (Use Volume Effect)
; ------------------------------------
; This command turns on envelope waveform effects for a particular sound chip channel. The volume level is now controlled by
; the selected envelope waveform for the channel, as defined by the 'W' command. MIDI channels do not support envelope waveforms
; and so the routine has the effect of setting the volume of a MIDI channel to maximum, i.e. 15. It might seem odd that the volume
; for MIDI channels is set to 15 rather than just filtered out. However, the three sound chip channels can also drive three MIDI
; channels and so it would be inconsistent for these MIDI channels to have their volume set to 15 but have the other MIDI channels
; behave differently. However, it could be argued that all MIDI channels should be unaffected by the 'U' command.
; There are no parameters to this command.
; Entry: IX=Address of the channel data block.

L0C67:  LD   E,(IX+$02)   ; Get the channel number.
        LD   A,$08        ; Offset by 8.
        ADD  A,E          ; A=8+index.
        LD   D,A          ; D=Sound generator register number for the channel. [This is not used and so there is no need to generate it. It was probably a left
                          ; over from copying and modifying the 'V' command routine. Deleting it would save 7 bytes. Credit: Ian Collier (+3), Paul Farrow (128)]

        LD   E,$1F        ; E=Select envelope defined by register 13, and reset volume bits to maximum (though these are not used with the envelope).
BF4_CONT:                 ;@ [*BUG_FIX*]
        LD   (IX+$04),E   ; Store that the envelope is being used (along with the reset volume level).
#ifndef BUG_FIXES
        CALL L0E2E        ; [*BUG* - As per the 'V' Command. The bug fix is to omit this instruction, as was done in the UK Spectrum 128. Credit: Paul Farrow]
        RET               ;
#else
	RET

;---------------------
; RS232 Output Bug Fix
;---------------------

BUG_FIX2:                 ;@ [*BUG_FIX*]
        XOR  A            ;@ [*BUG_FIX*]
        RET               ;@ [*BUG_FIX*]

        DEFB $00          ;@ [*BUG_FIX*]
#endif

; ------------------------------------------
; Play command 'W' (Volume Effect Specifier)
; ------------------------------------------
; This command selects the envelope waveform to use and is followed by a numeric value in the range
; 0 to 7, although due to loose range checking the value MOD 256 only needs to be within 0 to 7.
; Hence W256 operates the same as W0.
; Entry: IX=Address of the channel data block.

L0C77:  CALL L0AD7        ; Get following numeric value from the string into BC.

        LD   A,C          ;
        CP   $08          ; Is it 8 or above?
        JP   NC,L0EC4     ; Jump if so to produce error report "n Out of range".

        LD   B,$00        ;
        LD   HL,L0DA5     ; Envelope waveform lookup table.
        ADD  HL,BC        ; HL points to the corresponding value in the table.
        LD   A,(HL)       ;
        LD   (IY+$29),A   ; Store new effect waveform value.
        RET               ;

; -----------------------------------------
; Play Command 'X' (Volume Effect Duration)
; -----------------------------------------
; This command allows the duration of a waveform effect to be specified, and is followed by a numeric
; value in the range 0 to 65535. A value of 1 corresponds to the minimum duration, increasing up to 65535
; and then maximum duration for a value of 0. If no numeric value is specified then the maximum duration is used.
; Entry: IX=Address of the channel data block.

L0C8B:  CALL L0AD7        ; Get following numeric value from the string into BC.

        LD   D,$0B        ; Register 11 - Envelope Period Fine.
        LD   E,C          ;
        CALL L0E2E        ; Write to sound generator register to set the envelope period (low byte).

        INC  D            ; Register 12 - Envelope Period Coarse.
        LD   E,B          ;
        CALL L0E2E        ; Write to sound generator register to set the envelope period (high byte).
        RET               ; [Could have saved 1 byte by using JP $0E2E (ROM 0)]

; -------------------------------
; Play Command 'Y' (MIDI Channel)
; -------------------------------
; This command sets the MIDI channel number that the string is assigned to and is followed by a numeric
; value in the range 1 to 16, although due to loose range checking the value MOD 256 only needs to be within 1 to 16.
; Hence Y257 operates the same as Y1.
; Entry: IX=Address of the channel data block.

L0C9A:  CALL L0AD7        ; Get following numeric value from the string into BC.

        LD   A,C          ;
        DEC  A            ; Is it 0?
        JP   M,L0EC4      ; Jump if so to produce error report "n Out of range".

        CP   $10          ; Is it 10 or above?
        JP   NC,L0EC4     ; Jump if so to produce error report "n Out of range".

        LD   (IX+$01),A   ; Store MIDI channel number that this string is assigned to.
        RET               ;

; ----------------------------------------
; Play Command 'Z' (MIDI Programming Code)
; ----------------------------------------
; This command is used to send a programming code to the MIDI port. It is followed by a numeric
; value in the range 0 to 255, although due to loose range checking the value MOD 256 only needs
; to be within 0 to 255. Hence Z256 operates the same as Z0.
; Entry: IX=Address of the channel data block.

L0CAB:  CALL L0AD7        ; Get following numeric value from the string into BC.

        LD   A,C          ; A=(low byte of) the value.
        CALL L117F        ; Write byte to MIDI device.
        RET               ; [Could have saved 1 byte by using JP $0E2E (ROM 0)]

; -----------------------
; Play Command 'H' (Stop)
; -----------------------
; This command stops further processing of a play command. It has no parameters.
; Entry: IX=Address of the channel data block.

L0CB3:  LD   (IY+$10),$FF ; Indicate no channels to play, thereby causing
        RET               ; the play command to terminate.

; --------------------------------------------------------
; Play Commands 'a'..'g', 'A'..'G', '1'.."12", '&' and '_'
; --------------------------------------------------------
; This handler routine processes commands 'a'..'g', 'A'..'G', '1'.."12", '&' and '_',
; and determines the length of the next note to play. It provides the handling of triplet and tied notes.
; It stores the note duration in the channel data block's duration length entry, and sets a pointer in the command
; data block's duration lengths pointer table to point at it. A single note letter is deemed to be a tied
; note count of 1. Triplets are deemed a tied note count of at least 2.
; Entry: IX=Address of the channel data block.
;        A=Current character from play string.

L0CB8:  CALL L0DD6        ; Is the current character a number?
        JP   C,L0D3E      ; Jump if not number digit.

;The character is a number digit

        CALL L0D69        ; HL=Address of the duration length within the channel data block.
        CALL L0D71        ; Store address of duration length in command data block's channel duration length pointer table.

        XOR  A            ;
        LD   (IX+$21),A   ; Set no tied notes.

        CALL L0E7A        ; Get the previous character in the string, the note duration.
        CALL L0AD7        ; Get following numeric value from the string into BC.
        LD   A,C          ;
        OR   A            ; Is the value 0?
        JP   Z,L0EC4      ; Jump if so to produce error report "n Out of range".

        CP   $0D          ; Is it 13 or above?
        JP   NC,L0EC4     ; Jump if so to produce error report "n Out of range".

        CP   $0A          ; Is it below 10?
        JR   C,L0CEF      ; Jump if so.

;It is a triplet semi-quaver (10), triplet quaver (11) or triplet crotchet (12)

        CALL L0DBD        ; DE=Note duration length for the duration value.
        CALL L0D31        ; Increment the tied notes counter.
        LD   (HL),E       ; HL=Address of the duration length within the channel data block.
        INC  HL           ;
        LD   (HL),D       ; Store the duration length.

L0CE5:  CALL L0D31        ; Increment the counter of tied notes.

        INC  HL           ;
        LD   (HL),E       ;
        INC  HL           ; Store the subsequent note duration length in the channel data block.
        LD   (HL),D       ;
        INC  HL           ;
        JR   L0CF5        ; Jump ahead to continue.

;The note duration was in the range 1 to 9

L0CEF:  LD   (IX+$05),C   ; C=Note duration value (1..9).
        CALL L0DBD        ; DE=Duration length for this duration value.

L0CF5:  CALL L0D31        ; Increment the tied notes counter.

L0CF8:  CALL L0E95        ; Get the current character from the play string for this channel.

        CP   '_'          ; $5F. Is it a tied note?
        JR   NZ,L0D2B     ; Jump ahead if not.

        CALL L0A7F        ; Get the current character from the PLAY string, and advance the position pointer.
        CALL L0AD7        ; Get following numeric value from the string into BC.
        LD   A,C          ; Place the value into A.
        CP   $0A          ; Is it below 10?
        JR   C,L0D1C      ; Jump ahead for 1 to 9 (semiquaver ... semibreve).

;A triplet note was found as part of a tied note

        PUSH HL           ; HL=Address of the duration length within the channel data block.
        PUSH DE           ; DE=First tied note duration length.
        CALL L0DBD        ; DE=Note duration length for this new duration value.
        POP  HL           ; HL=Current tied note duration length.
        ADD  HL,DE        ; HL=Current+new tied note duration lengths.
        LD   C,E          ;
        LD   B,D          ; BC=Note duration length for the duration value.
        EX   DE,HL        ; DE=Current+new tied note duration lengths.
        POP  HL           ; HL=Address of the duration length within the channel data block.

        LD   (HL),E       ;
        INC  HL           ;
        LD   (HL),D       ; Store the combined note duration length in the channel data block.

        LD   E,C          ;
        LD   D,B          ; DE=Note duration length for the second duration value.
        JR   L0CE5        ; Jump back.

;A non-triplet tied note

L0D1C:  LD   (IX+$05),C   ; Store the note duration value.

        PUSH HL           ; HL=Address of the duration length within the channel data block.
        PUSH DE           ; DE=First tied note duration length.
        CALL L0DBD        ; DE=Note duration length for this new duration value.
        POP  HL           ; HL=Current tied note duration length.
        ADD  HL,DE        ; HL=Current+new tied not duration lengths.
        EX   DE,HL        ; DE=Current+new tied not duration lengths.
        POP  HL           ; HL=Address of the duration length within the channel data block.

        JP   L0CF8        ; Jump back to process the next character in case it is also part of a tied note.

;The number found was not part of a tied note, so store the duration value

L0D2B:  LD   (HL),E       ; HL=Address of the duration length within the channel data block.
        INC  HL           ; (For triplet notes this could be the address of the subsequent note duration length)
        LD   (HL),D       ; Store the duration length.
        JP   L0D59        ; Jump forward to make a return.

; This subroutine is called to increment the tied notes counter

L0D31:  LD   A,(IX+$21)   ; Increment counter of tied notes.
        INC  A            ;
        CP   $0B          ; Has it reached 11?
        JP   Z,L0EEC      ; Jump if so to produce to error report "o too many tied notes".

        LD   (IX+$21),A   ; Store the new tied notes counter.
        RET               ;

;The character is not a number digit so is 'A'..'G', '&' or '_'

L0D3E:  CALL L0E7A        ; Get the previous character from the string.

        LD   (IX+$21),$01 ; Set the number of tied notes to 1.

;Store a pointer to the channel data block's duration length into the command data block

        CALL L0D69        ; HL=Address of the duration length within the channel data block.
        CALL L0D71        ; Store address of duration length in command data block's channel duration length pointer table.

        LD   C,(IX+$05)   ; C=The duration value of the note (1 to 9).
        PUSH HL           ; [Not necessary]
        CALL L0DBD        ; Find the duration length for the note duration value.
        POP  HL           ; [Not necessary]

        LD   (HL),E       ; Store it in the channel data block.
        INC  HL           ;
        LD   (HL),D       ;
        JP   L0D59        ; Jump to the instruction below. [Redundant instruction]

L0D59:  POP  HL           ;
        INC  HL           ;
        INC  HL           ; Modify the return address to point to the RET instruction at $0B3D (ROM 0).
        PUSH HL           ;
        RET               ; [Over elaborate when a simple POP followed by RET would have sufficed, saving 3 bytes]

; -------------------
; End of String Found
; -------------------
;This routine is called when the end of string is found within a comment. It marks the
;string as having been processed and then returns to the main loop to process the next string.

L0D5E:  POP  HL           ; Drop the return address of the call to the comment command.

;Enter here if the end of the string is found whilst processing a string.

L0D5F:  LD   A,(IY+$21)   ; Fetch the channel selector.
        OR   (IY+$10)     ; Clear the channel flag for this string.
        LD   (IY+$10),A   ; Store the new channel bitmap.
        RET               ;

; --------------------------------------------------
; Point to Duration Length within Channel Data Block
; --------------------------------------------------
; Entry: IX=Address of the channel data block.
; Exit : HL=Address of the duration length within the channel data block.

L0D69:  PUSH IX           ;
        POP  HL           ; HL=Address of the channel data block.
        LD   BC,$0022     ;
        ADD  HL,BC        ; HL=Address of the store for the duration length.
        RET               ;

; -------------------------------------------------------------------------
; Store Entry in Command Data Block's Channel Duration Length Pointer Table
; -------------------------------------------------------------------------
; Entry: IY=Address of the command data block.
;        IX=Address of the channel data block for the current string.
;        HL=Address of the duration length store within the channel data block.
; Exit : HL=Address of the duration length store within the channel data block.
;        DE=Channel duration.

L0D71:  PUSH HL           ; Save the address of the duration length within the channel data block.

        PUSH IY           ;
        POP  HL           ; HL=Address of the command data block.

        LD   BC,$0011     ;
        ADD  HL,BC        ; HL=Address within the command data block of the channel duration length pointer table.

        LD   B,$00        ;
        LD   C,(IX+$02)   ; BC=Channel number.

        SLA  C            ; BC=2*Index number.
        ADD  HL,BC        ; HL=Address within the command data block of the pointer to the current channel's data block duration length.

        POP  DE           ; DE=Address of the duration length within the channel data block.

        LD   (HL),E       ; Store the pointer to the channel duration length in the command data block's channel duration pointer table.
        INC  HL           ;
        LD   (HL),D       ;
        EX   DE,HL        ;
        RET               ;

; -----------------------
; PLAY Command Jump Table
; -----------------------
; Handler routine jump table for all PLAY commands.

L0D87:  DEFW L0CB8        ; Command handler routine for all other characters.
        DEFW L0B3F        ; '!' command handler routine.
        DEFW L0B4A        ; 'O' command handler routine.
        DEFW L0B5F        ; 'N' command handler routine.
        DEFW L0B60        ; '(' command handler routine.
        DEFW L0B7C        ; ')' command handler routine.
        DEFW L0BEC        ; 'T' command handler routine.
        DEFW L0C3E        ; 'M' command handler routine.
        DEFW L0C4F        ; 'V' command handler routine.
        DEFW L0C67        ; 'U' command handler routine.
        DEFW L0C77        ; 'W' command handler routine.
        DEFW L0C8B        ; 'X' command handler routine.
        DEFW L0C9A        ; 'Y' command handler routine.
        DEFW L0CAB        ; 'Z' command handler routine.
        DEFW L0CB3        ; 'H' command handler routine.

; ------------------------------
; Envelope Waveform Lookup Table
; ------------------------------
; Table used by the play 'W' command to find the corresponding envelope value
; to write to the sound generator envelope shape register (register 13). This
; filters out the two duplicate waveforms possible from the sound generator and
; allows the order of the waveforms to be arranged in a more logical fashion.

L0DA5:  DEFB $00          ; W0 - Single decay then off.   (Continue off, attack off, alternate off, hold off)
        DEFB $04          ; W1 - Single attack then off.  (Continue off, attack on,  alternate off, hold off)
        DEFB $0B          ; W2 - Single decay then hold.  (Continue on,  attack off, alternate on,  hold on)
        DEFB $0D          ; W3 - Single attack then hold. (Continue on,  attack on,  alternate off, hold on)
        DEFB $08          ; W4 - Repeated decay.          (Continue on,  attack off, alternate off, hold off)
        DEFB $0C          ; W5 - Repeated attack.         (Continue on,  attack on,  alternate off, hold off)
        DEFB $0E          ; W6 - Repeated attack-decay.   (Continue on,  attack on,  alternate on,  hold off)
        DEFB $0A          ; W7 - Repeated decay-attack.   (Continue on,  attack off, alternate on,  hold off)

; --------------------------
; Identify Command Character
; --------------------------
; This routines attempts to match the command character to those in a table.
; The index position of the match indicates which command handler routine is required
; to process the character. Note that commands are case sensitive.
; Entry: A=Command character.
; Exit : Zero flag set if a match was found.
;        BC=Indentifying the character matched, 1 to 15 for match and 0 for no match.

L0DAD:  LD   BC,$000F     ; Number of characters + 1 in command table.
        LD   HL,L0A71     ; Start of command table.
        CPIR              ; Search for a match.
        RET               ;

; ---------------
; Semitones Table
; ---------------
; This table contains an entry for each note of the scale, A to G,
; and is the number of semitones above the note C.

L0DB6:  DEFB $09          ; 'A'
        DEFB $0B          ; 'B'
        DEFB $00          ; 'C'
        DEFB $02          ; 'D'
        DEFB $04          ; 'E'
        DEFB $05          ; 'F'
        DEFB $07          ; 'G'

; -------------------------
; Find Note Duration Length
; -------------------------
; Entry: C=Duration value (0 to 12, although a value of 0 is never used).
; Exit : DE=Note duration length.

L0DBD:  PUSH HL           ; Save HL.

        LD   B,$00        ;
        LD   HL,L0DC9     ; Note duration table.
        ADD  HL,BC        ; Index into the table.
        LD   D,$00        ;
        LD   E,(HL)       ; Fetch the length from the table.

        POP  HL           ; Restore HL.
        RET               ;

; -------------------
; Note Duration Table
; -------------------
; A whole note is given by a value of 96d and other notes defined in relation to this.
; The value of 96d is the lowest common denominator from which all note durations
; can be defined.

L0DC9:  DEFB $80          ; Rest                 [Not used since table is always indexed into with a value of 1 or more]
        DEFB $06          ; Semi-quaver          (sixteenth note).
        DEFB $09          ; Dotted semi-quaver   (3/32th note).
        DEFB $0C          ; Quaver               (eighth note).
        DEFB $12          ; Dotted quaver        (3/16th note).
        DEFB $18          ; Crotchet             (quarter note).
        DEFB $24          ; Dotted crotchet      (3/8th note).
        DEFB $30          ; Minim                (half note).
        DEFB $48          ; Dotted minim         (3/4th note).
        DEFB $60          ; Semi-breve           (whole note).
        DEFB $04          ; Triplet semi-quaver  (1/24th note).
        DEFB $08          ; Triplet quaver       (1/12th note).
        DEFB $10          ; Triplet crochet      (1/6th note).

; -----------------
; Is Numeric Digit?
; -----------------
; Tests whether a character is a number digit.
; Entry: A=Character.
; Exit : Carry flag reset if a number digit.

L0DD6:  CP   '0'          ; $30. Is it '0' or less?
        RET  C            ; Return with carry flag set if so.

        CP   ':'          ; $3A. Is it more than '9'?
        CCF               ;
        RET               ; Return with carry flag set if so.

; -----------------------------------
; Play a Note On a Sound Chip Channel
; -----------------------------------
; This routine plays the note at the current octave and current volume on a sound chip channel. For play strings 4 to 8,
; it simply stores the note number and this is subsequently played later.
; Entry: IX=Address of the channel data block.
;        A=Note value as number of semitones above C (0..11).

L0DDD:  LD   C,A          ; C=The note value.
        LD   A,(IX+$03)   ; Octave number * 12.
        ADD  A,C          ; Add the octave number and the note value to form the note number.
        CP   $80          ; Is note within range?
        JP   NC,L0EE4     ; Jump if not to produce error report "m Note out of range".

        LD   C,A          ; C=Note number.
        LD   A,(IX+$02)   ; Get the channel number.
        OR   A            ; Is it the first channel?
        JR   NZ,L0DF1     ; Jump ahead if not.

;Only set the noise generator frequency on the first channel

        LD   A,C          ; A=Note number (0..107), in ascending audio frequency.
        CPL               ; Invert since noise register value is in descending audio frequency.
        AND  $7F          ; Mask off bit 7.
        SRL  A            ;
        SRL  A            ; Divide by 4 to reduce range to 0..31.
        LD   D,$06        ; Register 6 - Noise pitch.
        LD   E,A          ;
        CALL L0E2E        ; Write to sound generator register.

L0DF1:  LD   (IX+$00),C   ; Store the note number.
        LD   A,(IX+$02)   ; Get the channel number.
        CP   $03          ; Is it channel 0, 1 or 2, i.e. a sound chip channel?
        RET  NC           ; Do not output anything for play strings 4 to 8.

;Channel 0, 1 or 2

        LD   HL,L1048     ; Start of note lookup table.
        LD   B,$00        ; BC=Note number.
        SLA  C            ; Generate offset into the table.
        ADD  HL,BC        ; Point to the entry in the table.
        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; DE=Word to write to the sound chip registers to produce this note.

L0E10:  EX   DE,HL        ; HL=Register word value to produce the note.

        LD   D,(IX+$02)   ; Get the channel number.
        SLA  D            ; D=2*Channel number, to give the tone channel register (fine control) number 0, 2, or 4.
        LD   E,L          ; E=The low value byte.
        CALL L0E2E        ; Write to sound generator register.

        INC  D            ; D=Tone channel register (coarse control) number 1, 3, or 5.
        LD   E,H          ; E=The high value byte.
        CALL L0E2E        ; Write to sound generator register.

        BIT  4,(IX+$04)   ; Is the envelope waveform being used?
        RET  Z            ; Return if it is not.

        LD   D,$0D        ; Register 13 - Envelope Shape.
        LD   A,(IY+$29)   ; Get the effect waveform value.
        LD   E,A          ;
        CALL L0E2E        ; Write to sound generator register.
        RET               ; [Could have saved 4 bytes by dropping down into the routine below.]

; ----------------------------
; Set Sound Generator Register
; ----------------------------
; Entry: D=Register to write.
;        E=Value to set register to.

L0E2E:  PUSH BC           ;

        LD   BC,$FFFD     ;
        OUT  (C),D        ; Select the register.
        LD   BC,$BFFD     ;
        OUT  (C),E        ; Write out the value.

        POP  BC           ;
        RET               ;

; -----------------------------
; Read Sound Generator Register
; -----------------------------
; Entry: A=Register to read.
; Exit : A=Value of currently selected sound generator register.

L0E3B:  PUSH BC           ;

        LD   BC,$FFFD     ;
        OUT  (C),A        ; Select the register.
        IN   A,(C)        ; Read the register's value.

        POP  BC           ;
        RET               ;

; ------------------
; Turn Off All Sound
; ------------------

L0E45:  LD   D,$07        ; Register 7 - Mixer.
        LD   E,$FF        ; I/O ports are inputs, noise output off, tone output off.
        CALL L0E2E        ; Write to sound generator register.

;Turn off the sound from the AY-3-8912

        LD   D,$08        ; Register 8 - Channel A volume.
        LD   E,$00        ; Volume of 0.
        CALL L0E2E        ; Write to sound generator register to set the volume to 0.

        INC  D            ; Register 9 - Channel B volume.
        CALL L0E2E        ; Write to sound generator register to set the volume to 0.

        INC  D            ; Register 10 - Channel C volume.
        CALL L0E2E        ; Write to sound generator register to set the volume to 0.

        CALL L0A09        ; Select channel data block pointers.

;Now reset all MIDI channels in use

L0E5E:  RR   (IY+$22)     ; Working copy of channel bitmap. Test if next string present.
        JR   C,L0E6A      ; Jump ahead if there is no string for this channel.

        CALL L0A21        ; Get address of channel data block for the current string into IX.
        CALL L1169        ; Turn off the MIDI channel sound assigned to this play string.

L0E6A:  SLA  (IY+$21)     ; Have all channels been processed?
        JR   C,L0E75      ; Jump ahead if so.

        CALL L0A28        ; Advance to the next channel data block pointer.
        JR   L0E5E        ; Jump back to process the next channel.

L0E75:  LD   IY,$5C3A     ; Restore IY.
        RET               ;

; ---------------------------------------
; Get Previous Character from Play String
; ---------------------------------------
; Get the previous character from the PLAY string, skipping over spaces and 'Enter' characters.
; Entry: IX=Address of the channel data block.

L0E7A:  PUSH HL           ; Save registers.
        PUSH DE           ;

        LD   L,(IX+$06)   ; Get the current pointer into the PLAY string.
        LD   H,(IX+$07)   ;

L0E82:  DEC  HL           ; Point to previous character.
        LD   A,(HL)       ; Fetch the character.
        CP   ' '          ; $20. Is it a space?
        JR   Z,L0E82      ; Jump back if a space.

        CP   $0D          ; Is it an 'Enter'?
        JR   Z,L0E82      ; Jump back if an 'Enter'.

        LD   (IX+$06),L   ; Store this as the new current pointer into the PLAY string.
        LD   (IX+$07),H   ;

        POP  DE           ; Restore registers.
        POP  HL           ;
        RET               ;

; --------------------------------------
; Get Current Character from Play String
; --------------------------------------
; Get the current character from the PLAY string, skipping over spaces and 'Enter' characters.
; Exit: Carry flag set if string has been fully processed.
;       Carry flag reset if character is available.
;       A=Character available.

L0E95:  PUSH HL           ; Save registers.
        PUSH DE           ;
        PUSH BC           ;

        LD   L,(IX+$06)   ; HL=Pointer to next character to process within the PLAY string.
        LD   H,(IX+$07)   ;

L0E9E:  LD   A,H          ;
        CP   (IX+$09)     ; Reached end-of-string address high byte?
        JR   NZ,L0EAD     ; Jump forward if not.

        LD   A,L          ;
        CP   (IX+$08)     ; Reached end-of-string address low byte?
        JR   NZ,L0EAD     ; Jump forward if not.

        SCF               ; Indicate string all processed.
        JR   L0EB7        ; Jump forward to return.

L0EAD:  LD   A,(HL)       ; Get the next play character.
        CP   ' '          ; $20. Is it a space?
        JR   Z,L0EBB      ; Ignore the space by jumping ahead to process the next character.

        CP   $0D          ; Is it 'Enter'?
        JR   Z,L0EBB      ; Ignore the 'Enter' by jumping ahead to process the next character.

        OR   A            ; Clear the carry flag to indicate a new character has been returned.

L0EB7:  POP  BC           ; Restore registers.
        POP  DE           ;
        POP  HL           ;
        RET               ;

L0EBB:  INC  HL           ; Point to the next character.
        LD   (IX+$06),L   ;
        LD   (IX+$07),H   ; Update the pointer to the next character to process with the PLAY string.
        JR   L0E9E        ; Jump back to get the next character.

; --------------------------
; Produce Play Error Reports
; --------------------------

L0EC4:  CALL L0E45        ; Turn off all sound and restore IY.
        EI                ;
        CALL L0566        ; Produce error report.
        DEFB $29          ; "n Out of range"

L0ECC:  CALL L0E45        ; Turn off all sound and restore IY.
        EI                ;
        CALL L0566        ; Produce error report.
        DEFB $27          ; "l Number too big"

L0ED4:  CALL L0E45        ; Turn off all sound and restore IY.
        EI                ;
        CALL L0566        ; Produce error report.
        DEFB $26          ; "k Invalid note name"

L0EDC:  CALL L0E45        ; Turn off all sound and restore IY.
        EI                ;
        CALL L0566        ; Produce error report.
        DEFB $1F          ; "d Too many brackets"

L0EE4:  CALL L0E45        ; Turn off all sound and restore IY.
        EI                ;
        CALL L0566        ; Produce error report.
        DEFB $28          ; "m Note out of range"

L0EEC:  CALL L0E45        ; Turn off all sound and restore IY.
        EI                ;
        CALL L0566        ; Produce error report.
        DEFB $2A          ; "o Too many tied notes"

; -------------------------
; Play Note on Each Channel
; -------------------------
; Play a note and set the volume on each channel for which a play string exists.

L0EF4:  CALL L0A09        ; Select channel data block pointers.

L0EF7:  RR   (IY+$22)     ; Working copy of channel bitmap. Test if next string present.
        JR   C,L0F1E      ; Jump ahead if there is no string for this channel.

        CALL L0A21        ; Get address of channel data block for the current string into IX.

        CALL L0A8B        ; Get the next note in the string as number of semitones above note C.
        CP   $80          ; Is it a rest?
        JR   Z,L0F1E      ; Jump ahead if so and do nothing to the channel.

        CALL L0DDD        ; Play the note if a sound chip channel.

        LD   A,(IX+$02)   ; Get channel number.
        CP   $03          ; Is it channel 0, 1 or 2, i.e. a sound chip channel?
        JR   NC,L0F1B     ; Jump if not to skip setting the volume.

;One of the 3 sound chip generator channels so set the channel's volume for the new note

        LD   D,$08        ;
        ADD  A,D          ; A=0 to 2.
        LD   D,A          ; D=Register (8 + string index), i.e. channel A, B or C volume register.
        LD   E,(IX+$04)   ; E=Volume for the current channel.
        CALL L0E2E        ; Write to sound generator register to set the output volume.

L0F1B:  CALL L114A        ; Play a note and set the volume on the assigned MIDI channel.

L0F1E:  SLA  (IY+$21)     ; Have all channels been processed?
        RET  C            ; Return if so.

        CALL L0A28        ; Advance to the next channel data block pointer.
        JR   L0EF7        ; Jump back to process the next channel.

; ------------------
; Wait Note Duration
; ------------------
; This routine is the main timing control of the PLAY command.
; It waits for the specified length of time, which will be the
; lowest note duration of all active channels.
; The actual duration of the wait is dictated by the current tempo.
; Entry: DE=Note duration, where 96d represents a whole note.

;Enter a loop waiting for (135+ ((26*(tempo-100))-5) )*DE+5 T-states

L0F28:  PUSH HL           ; (11) Save HL.

        LD   L,(IY+$27)   ; (19) Get the tempo timing value.
        LD   H,(IY+$28)   ; (19)

        LD   BC,$0064     ; (10) BC=100
        OR   A            ; (4)
        SBC  HL,BC        ; (15) HL=tempo timing value - 100.

        PUSH HL           ; (11)
        POP  BC           ; (10) BC=tempo timing value - 100.

        POP  HL           ; (10) Restore HL.

;Tempo timing value = (10/(TEMPO*4))/7.33e-6, where 7.33e-6 is the time for 26 T-states.
;The loop below takes 26 T-states per iteration, where the number of iterations is given by the tempo timing value.
;So the time for the loop to execute is 2.5/TEMPO seconds.
;
;For a TEMPO of 60 beats (crotchets) per second, the time per crotchet is 1/24 second.
;The duration of a crotchet is defined as 24 from the table at $0E0C, therefore the loop will get executed 24 times
;and hence the total time taken will be 1 second.
;
;The tempo timing value above has 100 subtracted from it, presumably to approximately compensate for the overhead time
;previously taken to prepare the notes for playing. This reduces the total time by 2600 T-states, or 733us.

L0F38:  DEC  BC           ; (6)  Wait for tempo-100 loops.
        LD   A,B          ; (4)
        OR   C            ; (4)
        JR   NZ,L0F38     ; (12/7)

        DEC  DE           ; (6) Repeat DE times
        LD   A,D          ; (4)
        OR   E            ; (4)
        JR   NZ,L0F28     ; (12/7)

        RET               ; (10)

; -----------------------------
; Find Smallest Duration Length
; -----------------------------
; This routine finds the smallest duration length for all current notes
; being played across all channels.
; Exit: DE=Smallest duration length.

L0F43:  LD   DE,$FFFF     ; Set smallest duration length to 'maximum'.

        CALL L0A04        ; Select channel data block duration pointers.

L0F49:  RR   (IY+$22)     ; Working copy of channel bitmap. Test if next string present.
        JR   C,L0F61      ; Jump ahead if there is no string for this channel.

;HL=Address of channel data pointer. DE holds the smallest duration length found so far.

        PUSH DE           ; Save the smallest duration length.

        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ;
        EX   DE,HL        ; DE=Channel data block duration length.

        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; DE=Channel duration length.

        PUSH DE           ;
        POP  HL           ; HL=Channel duration length.

        POP  BC           ; Last channel duration length.
        OR   A            ;
        SBC  HL,BC        ; Is current channel's duration length smaller than the smallest so far?
        JR   C,L0F61      ; Jump ahead if so, with the new smallest value in DE.

;The current channel's duration was not smaller so restore the last smallest into DE.

        PUSH BC           ;
        POP  DE           ; DE=Smallest duration length.

L0F61:  SLA  (IY+$21)     ; Have all channel strings been processed?
        JR   C,L0F6C      ; Jump ahead if so.

        CALL L0A28        ; Advance to the next channel data block duration pointer.
        JR   L0F49        ; Jump back to process the next channel.

L0F6C:  LD   (IY+$25),E   ;
        LD   (IY+$26),D   ; Store the smallest channel duration length.
        RET               ;

; ---------------------------------------------------------------
; Play a Note on Each Channel and Update Channel Duration Lengths
; ---------------------------------------------------------------
; This routine is used to play a note and set the volume on all channels.
; It subtracts an amount of time from the duration lengths of all currently
; playing channel note durations. The amount subtracted is equivalent to the
; smallest note duration length currently being played, and as determined earlier.
; Hence one channel's duration will go to 0 on each call of this routine, and the
; others will show the remaining lengths of their corresponding notes.
; Entry: IY=Address of the command data block.

L0F73:  XOR  A            ;
        LD   (IY+$2A),A   ; Holds a temporary channel bitmap.

        CALL L0A09        ; Select channel data block pointers.

L0F7A:  RR   (IY+$22)     ; Working copy of channel bitmap. Test if next string present.
        JP   C,L100C      ; Jump ahead if there is no string for this channel.

        CALL L0A21        ; Get address of channel data block for the current string into IX.

        PUSH IY           ;
        POP  HL           ; HL=Address of the command data block.

        LD   BC,$0011     ;
        ADD  HL,BC        ; HL=Address of channel data block duration pointers.

        LD   B,$00        ;
        LD   C,(IX+$02)   ; BC=Channel number.
        SLA  C            ; BC=2*Channel number.
        ADD  HL,BC        ; HL=Address of channel data block duration pointer for this channel.

        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; DE=Address of duration length within the channel data block.

        EX   DE,HL        ; HL=Address of duration length within the channel data block.
        PUSH HL           ; Save it.

        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; DE=Duration length for this channel.

        EX   DE,HL        ; HL=Duration length for this channel.

        LD   E,(IY+$25)   ;
        LD   D,(IY+$26)   ; DE=Smallest duration length of all current channel notes.

        OR   A            ;
        SBC  HL,DE        ; HL=Duration length - smallest duration length.
        EX   DE,HL        ; DE=Duration length - smallest duration length.

        POP  HL           ; HL=Address of duration length within the channel data block.
        JR   Z,L0FAE      ; Jump if this channel uses the smallest found duration length.

        LD   (HL),E       ;
        INC  HL           ; Update the duration length for this channel with the remaining length.
        LD   (HL),D       ;

        JR   L100C        ; Jump ahead to update the next channel.

;The current channel uses the smallest found duration length

;[A note has been completed and so the channel volume is set to 0 prior to the next note being played.
;This occurs on both sound chip channels and MIDI channels. When a MIDI channel is assigned to more than
;one play string and a rest is used in one of those strings. As soon as the end of the rest period is
;encountered, the channel's volume is set to off even though one of the other play strings controlling
;the MIDI channel may still be playing. This can be seen using the command PLAY "Y1a&", "Y1N9a". Here,
;string 1 starts playing 'a' for the period of a crotchet (1/4 of a note), where as string 2 starts playing
;'a' for nine periods of a crotchet (9/4 of a note). When string 1 completes its crotchet, it requests
;to play a period of silence via the rest '&'. This turns the volume of the MIDI channel off even though
;string 2 is still timing its way through its nine crotchets. The play command will therefore continue for
;a further seven crotchets but in silence. This is because the volume for note is set only at its start
;and no coordination occurs between strings to turn the volume back on for the second string. It is arguably
;what the correct behaviour should be in such a circumstance where the strings are providing conflicting instructions,
;but having the latest command or note take precedence seems a logical approach. Credit: Ian Collier (+3), Paul Farrow (128)]

L0FAE:  LD   A,(IX+$02)   ; Get the channel number.
        CP   $03          ; Is it channel 0, 1 or 2, i.e. a sound chip channel?
        JR   NC,L0FBE     ; Jump ahead if not a sound generator channel.

        LD   D,$08        ;
        ADD  A,D          ;
        LD   D,A          ; D=Register (8+channel number) - Channel volume.
        LD   E,$00        ; E=Volume level of 0.
        CALL L0E2E        ; Write to sound generator register to turn the volume off.

L0FBE:  CALL L1169        ; Turn off the assigned MIDI channel sound.

        PUSH IX           ;
        POP  HL           ; HL=Address of channel data block.

        LD   BC,$0021     ;
        ADD  HL,BC        ; HL=Points to the tied notes counter.

        DEC  (HL)         ; Decrement the tied notes counter. [This contains a value of 1 for a single note]
        JR   NZ,L0FD8     ; Jump ahead if there are more tied notes.

        CALL L0B16        ; Find the next note to play for this channel from its play string.

        LD   A,(IY+$21)   ; Fetch the channel selector.
        AND  (IY+$10)     ; Test whether this channel has further data in its play string.
        JR   NZ,L100C     ; Jump to process the next channel if this channel does not have a play string.

        JR   L0FEF        ; The channel has more data in its play string so jump ahead.

;The channel has more tied notes

L0FD8:  PUSH IY           ;
        POP  HL           ; HL=Address of the command data block.

        LD   BC,$0011     ;
        ADD  HL,BC        ; HL=Address of channel data block duration pointers.

        LD   B,$00        ;
        LD   C,(IX+$02)   ; BC=Channel number.
        SLA  C            ; BC=2*Channel number.
        ADD  HL,BC        ; HL=Address of channel data block duration pointer for this channel.

        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; DE=Address of duration length within the channel data block.

        INC  DE           ;
        INC  DE           ; Point to the subsequent note duration length.

        LD   (HL),D       ;
        DEC  HL           ;
        LD   (HL),E       ; Store the new duration length.

L0FEF:  CALL L0A8B        ; Get next note in the string as number of semitones above note C.
        LD   C,A          ; C=Number of semitones.

        LD   A,(IY+$21)   ; Fetch the channel selector.
        AND  (IY+$10)     ; Test whether this channel has a play string.
        JR   NZ,L100C     ; Jump to process the next channel if this channel does not have a play string.

        LD   A,C          ; A=Number of semitones.
        CP   $80          ; Is it a rest?
        JR   Z,L100C      ; Jump to process the next channel if it is.

        CALL L0DDD        ; Play the new note on this channel at the current volume if a sound chip channel, or simply store the note for play strings 4 to 8.

        LD   A,(IY+$21)   ; Fetch the channel selector.
        OR   (IY+$2A)     ; Insert a bit in the temporary channel bitmap to indicate this channel has more to play.
        LD   (IY+$2A),A   ; Store it.

;Check whether another channel needs its duration length updated

L100C:  SLA  (IY+$21)     ; Have all channel strings been processed?
        JR   C,L1018      ; Jump ahead if so.

        CALL L0A28        ; Advance to the next channel data pointer.
        JP   L0F7A        ; Jump back to update the duration length for the next channel.

; [*BUG* - By this point, the volume for both sound chip and MIDI channels has been set to 0, i.e. off. So although the new notes have been
;          set playing on the sound chip channels, no sound is audible. For MIDI channels, no new notes have yet been output and hence these
;          are also silent. If the time from turning the volume off for the current note to the time to turn the volume on for the next note
;          is short enough, then it will not be noticeable. However, the code at $1018 (ROM 0) introduces a 1/96th of a note delay and as a result a
;          1/96th of a note period of silence between notes. The bug can be resolved by simply deleting the two instructions below that introduce
;          the delay. A positive side effect of the bug in the 'V' volume command at $0C4F (ROM 0) is that it can be used to overcome the gaps of silence
;          between notes for sound chip channels. By interspersing volume commands between notes, a new volume level is immediately set before
;          the 1/96th of a note delay is introduced for the new note. Therefore, the delay occurs when the new note is audible instead of when it
;          is silent. For example, PLAY "cV15cV15c" instead of PLAY "ccc". The note durations are still 1/96th of a note longer than they should
;          be though. This technique will only work on the sound chip channels and not for any MIDI channels. Credit: Ian Collier (+3), Paul Farrow (128)]

L1018:
#ifndef BUG_FIXES
        LD   DE,$0001     ; Delay for 1/96th of a note.
        CALL L0F28        ;
#else
        JR BF_DELAY       ;@ [*BUG_FIX*]

        DEFB $00, $00     ;@ [*BUG_FIX*]
        DEFB $00, $00     ;@ [*BUG_FIX*]

BF_DELAY:                 ;@ [*BUG_FIX*]
#endif
        CALL L0A09        ; Select channel data block pointers.

;All channel durations have been updated. Update the volume on each sound chip channel, and the volume and note on each MIDI channel

L1021:  RR   (IY+$2A)     ; Temporary channel bitmap. Test if next string present.
        JR   NC,L103E     ; Jump ahead if there is no string for this channel.

        CALL L0A21        ; Get address of channel data block for the current string into IX.

        LD   A,(IX+$02)   ; Get the channel number.
        CP   $03          ; Is it channel 0, 1 or 2, i.e. a sound chip channel?
        JR   NC,L103B     ; Jump ahead if so to process the next channel.

        LD   D,$08        ;
        ADD  A,D          ;
        LD   D,A          ; D=Register (8+channel number) - Channel volume.
        LD   E,(IX+$04)   ; Get the current volume.
        CALL L0E2E        ; Write to sound generator register to set the volume of the channel.

L103B:  CALL L114A        ; Play a note and set the volume on the assigned MIDI channel.

L103E:  SLA  (IY+$21)     ; Have all channels been processed?
        RET  C            ; Return if so.

        CALL L0A28        ; Advance to the next channel data pointer.
        JR   L1021        ; Jump back to process the next channel.

; -----------------
; Note Lookup Table
; -----------------
; Each word gives the value of the sound generator tone registers for a given note.
; There are 10 octaves, containing a total of 128 notes. Notes 0 to 20 cannot be
; reproduced correctly on the sound chip and so only notes 21 to 128 should be used.
; However, they will be sent to a MIDI device if one is assigned to a channel.
; [Note that both the sound chip and the MIDI port can not play note 128 and so
; its inclusion in the table is a waste of 2 bytes]. The PLAY command does not allow
; octaves higher than 8 to be selected directly. Using PLAY "O8G" will select note 115. To
; select higher notes, sharps must be included, e.g. PLAY "O8#G" for note 116, PLAY "O8##G"
; for note 117, etc, up to PLAY "O8############G" for note 127. Attempting to access note
; 128 using PLAY "O8#############G" will lead to error report "m Note out of range".

L1048:  DEFW $34F5        ; Octave  0, Note   0 - C  ( 8.18Hz, Ideal= 8.18Hz, Error=-0.00%) C-1
        DEFW $31FC        ; Octave  0, Note   1 - C# ( 8.66Hz, Ideal= 8.66Hz, Error=-0.00%)
        DEFW $2F2E        ; Octave  0, Note   2 - D  ( 9.18Hz, Ideal= 9.18Hz, Error=+0.00%)
        DEFW $2C88        ; Octave  0, Note   3 - D# ( 9.72Hz, Ideal= 9.72Hz, Error=+0.01%)
        DEFW $2A08        ; Octave  0, Note   4 - E  (10.30Hz, Ideal=10.30Hz, Error=+0.00%)
        DEFW $27AC        ; Octave  0, Note   5 - F  (10.91Hz, Ideal=10.91Hz, Error=+0.00%)
        DEFW $2572        ; Octave  0, Note   6 - F# (11.56Hz, Ideal=11.56Hz, Error=+0.00%)
        DEFW $2358        ; Octave  0, Note   7 - G  (12.25Hz, Ideal=12.25Hz, Error=+0.00%)
        DEFW $215D        ; Octave  0, Note   8 - G# (12.98Hz, Ideal=12.98Hz, Error=-0.00%)
        DEFW $1F7D        ; Octave  0, Note   9 - A  (13.75Hz, Ideal=13.75Hz, Error=+0.00%)
        DEFW $1DB9        ; Octave  0, Note  10 - A# (14.57Hz, Ideal=14.58Hz, Error=-0.10%)
        DEFW $1C0E        ; Octave  0, Note  11 - B  (15.43Hz, Ideal=15.43Hz, Error=-0.00%)

        DEFW $1A7A        ; Octave  1, Note  12 - C  (16.35Hz, Ideal=16.35Hz, Error=+0.01%) C0
        DEFW $18FE        ; Octave  1, Note  13 - C# (17.32Hz, Ideal=17.33Hz, Error=-0.00%)
        DEFW $1797        ; Octave  1, Note  14 - D  (18.35Hz, Ideal=18.35Hz, Error=+0.00%)
        DEFW $1644        ; Octave  1, Note  15 - D# (19.45Hz, Ideal=19.44Hz, Error=+0.01%)
        DEFW $1504        ; Octave  1, Note  16 - E  (20.60Hz, Ideal=20.60Hz, Error=+0.00%)
        DEFW $13D6        ; Octave  1, Note  17 - F  (21.83Hz, Ideal=21.83Hz, Error=+0.00%)
        DEFW $12B9        ; Octave  1, Note  18 - F# (23.13Hz, Ideal=23.13Hz, Error=+0.00%)
        DEFW $11AC        ; Octave  1, Note  19 - G  (24.50Hz, Ideal=24.50Hz, Error=+0.00%)
        DEFW $10AE        ; Octave  1, Note  20 - G# (25.96Hz, Ideal=25.96Hz, Error=+0.01%)
        DEFW $0FBF        ; Octave  1, Note  21 - A  (27.50Hz, Ideal=27.50Hz, Error=-0.01%)
        DEFW $0EDC        ; Octave  1, Note  22 - A# (29.14Hz, Ideal=29.16Hz, Error=-0.08%)
        DEFW $0E07        ; Octave  1, Note  23 - B  (30.87Hz, Ideal=30.87Hz, Error=-0.00%)

        DEFW $0D3D        ; Octave  2, Note  24 - C  (32.71Hz, Ideal=32.70Hz, Error=+0.01%) C1
        DEFW $0C7F        ; Octave  2, Note  25 - C# (34.65Hz, Ideal=34.65Hz, Error=-0.00%)
        DEFW $0BCC        ; Octave  2, Note  26 - D  (36.70Hz, Ideal=36.71Hz, Error=-0.01%)
        DEFW $0B22        ; Octave  2, Note  27 - D# (38.89Hz, Ideal=38.89Hz, Error=+0.01%)
        DEFW $0A82        ; Octave  2, Note  28 - E  (41.20Hz, Ideal=41.20Hz, Error=+0.00%)
        DEFW $09EB        ; Octave  2, Note  29 - F  (43.66Hz, Ideal=43.65Hz, Error=+0.00%)
        DEFW $095D        ; Octave  2, Note  30 - F# (46.24Hz, Ideal=46.25Hz, Error=-0.02%)
        DEFW $08D6        ; Octave  2, Note  31 - G  (49.00Hz, Ideal=49.00Hz, Error=+0.00%)
        DEFW $0857        ; Octave  2, Note  32 - G# (51.92Hz, Ideal=51.91Hz, Error=+0.01%)
        DEFW $07DF        ; Octave  2, Note  33 - A  (55.01Hz, Ideal=55.00Hz, Error=+0.01%)
        DEFW $076E        ; Octave  2, Note  34 - A# (58.28Hz, Ideal=58.33Hz, Error=-0.08%)
        DEFW $0703        ; Octave  2, Note  35 - B  (61.75Hz, Ideal=61.74Hz, Error=+0.02%)

        DEFW $069F        ; Octave  3, Note  36 - C  ( 65.39Hz, Ideal= 65.41Hz, Error=-0.02%) C2
        DEFW $0640        ; Octave  3, Note  37 - C# ( 69.28Hz, Ideal= 69.30Hz, Error=-0.04%)
        DEFW $05E6        ; Octave  3, Note  38 - D  ( 73.40Hz, Ideal= 73.42Hz, Error=-0.01%)
        DEFW $0591        ; Octave  3, Note  39 - D# ( 77.78Hz, Ideal= 77.78Hz, Error=+0.01%)
        DEFW $0541        ; Octave  3, Note  40 - E  ( 82.41Hz, Ideal= 82.41Hz, Error=+0.00%)
        DEFW $04F6        ; Octave  3, Note  41 - F  ( 87.28Hz, Ideal= 87.31Hz, Error=-0.04%)
        DEFW $04AE        ; Octave  3, Note  42 - F# ( 92.52Hz, Ideal= 92.50Hz, Error=+0.02%)
        DEFW $046B        ; Octave  3, Note  43 - G  ( 98.00Hz, Ideal= 98.00Hz, Error=+0.00%)
        DEFW $042C        ; Octave  3, Note  44 - G# (103.78Hz, Ideal=103.83Hz, Error=-0.04%)
        DEFW $03F0        ; Octave  3, Note  45 - A  (109.96Hz, Ideal=110.00Hz, Error=-0.04%)
        DEFW $03B7        ; Octave  3, Note  46 - A# (116.55Hz, Ideal=116.65Hz, Error=-0.08%)
        DEFW $0382        ; Octave  3, Note  47 - B  (123.43Hz, Ideal=123.47Hz, Error=-0.03%)

        DEFW $034F        ; Octave  4, Note  48 - C  (130.86Hz, Ideal=130.82Hz, Error=+0.04%) C3
        DEFW $0320        ; Octave  4, Note  49 - C# (138.55Hz, Ideal=138.60Hz, Error=-0.04%)
        DEFW $02F3        ; Octave  4, Note  50 - D  (146.81Hz, Ideal=146.83Hz, Error=-0.01%)
        DEFW $02C8        ; Octave  4, Note  51 - D# (155.68Hz, Ideal=155.55Hz, Error=+0.08%)
        DEFW $02A1        ; Octave  4, Note  52 - E  (164.70Hz, Ideal=164.82Hz, Error=-0.07%)
        DEFW $027B        ; Octave  4, Note  53 - F  (174.55Hz, Ideal=174.62Hz, Error=-0.04%)
        DEFW $0257        ; Octave  4, Note  54 - F# (185.04Hz, Ideal=185.00Hz, Error=+0.02%)
        DEFW $0236        ; Octave  4, Note  55 - G  (195.83Hz, Ideal=196.00Hz, Error=-0.09%)
        DEFW $0216        ; Octave  4, Note  56 - G# (207.57Hz, Ideal=207.65Hz, Error=-0.04%)
        DEFW $01F8        ; Octave  4, Note  57 - A  (219.92Hz, Ideal=220.00Hz, Error=-0.04%)
        DEFW $01DC        ; Octave  4, Note  58 - A# (232.86Hz, Ideal=233.30Hz, Error=-0.19%)
        DEFW $01C1        ; Octave  4, Note  59 - B  (246.86Hz, Ideal=246.94Hz, Error=-0.03%)

        DEFW $01A8        ; Octave  5, Note  60 - C  (261.42Hz, Ideal=261.63Hz, Error=-0.08%) C4 Middle C
        DEFW $0190        ; Octave  5, Note  61 - C# (277.10Hz, Ideal=277.20Hz, Error=-0.04%)
        DEFW $0179        ; Octave  5, Note  62 - D  (294.01Hz, Ideal=293.66Hz, Error=+0.12%)
        DEFW $0164        ; Octave  5, Note  63 - D# (311.35Hz, Ideal=311.10Hz, Error=+0.08%)
        DEFW $0150        ; Octave  5, Note  64 - E  (329.88Hz, Ideal=329.63Hz, Error=+0.08%)
        DEFW $013D        ; Octave  5, Note  65 - F  (349.65Hz, Ideal=349.23Hz, Error=+0.12%)
        DEFW $012C        ; Octave  5, Note  66 - F# (369.47Hz, Ideal=370.00Hz, Error=-0.14%)
        DEFW $011B        ; Octave  5, Note  67 - G  (391.66Hz, Ideal=392.00Hz, Error=-0.09%)
        DEFW $010B        ; Octave  5, Note  68 - G# (415.13Hz, Ideal=415.30Hz, Error=-0.04%)
        DEFW $00FC        ; Octave  5, Note  69 - A  (439.84Hz, Ideal=440.00Hz, Error=-0.04%)
        DEFW $00EE        ; Octave  5, Note  70 - A# (465.72Hz, Ideal=466.60Hz, Error=-0.19%)
        DEFW $00E0        ; Octave  5, Note  71 - B  (494.82Hz, Ideal=493.88Hz, Error=+0.19%)

        DEFW $00D4        ; Octave  6, Note  72 - C  (522.83Hz, Ideal=523.26Hz, Error=-0.08%) C5
        DEFW $00C8        ; Octave  6, Note  73 - C# (554.20Hz, Ideal=554.40Hz, Error=-0.04%)
        DEFW $00BD        ; Octave  6, Note  74 - D  (586.46Hz, Ideal=587.32Hz, Error=-0.15%)
        DEFW $00B2        ; Octave  6, Note  75 - D# (622.70Hz, Ideal=622.20Hz, Error=+0.08%)
        DEFW $00A8        ; Octave  6, Note  76 - E  (659.77Hz, Ideal=659.26Hz, Error=+0.08%)
        DEFW $009F        ; Octave  6, Note  77 - F  (697.11Hz, Ideal=698.46Hz, Error=-0.19%)
        DEFW $0096        ; Octave  6, Note  78 - F# (738.94Hz, Ideal=740.00Hz, Error=-0.14%)
        DEFW $008D        ; Octave  6, Note  79 - G  (786.10Hz, Ideal=784.00Hz, Error=+0.27%)
        DEFW $0085        ; Octave  6, Note  80 - G# (833.39Hz, Ideal=830.60Hz, Error=+0.34%)
        DEFW $007E        ; Octave  6, Note  81 - A  (879.69Hz, Ideal=880.00Hz, Error=-0.04%)
        DEFW $0077        ; Octave  6, Note  82 - A# (931.43Hz, Ideal=933.20Hz, Error=-0.19%)
        DEFW $0070        ; Octave  6, Note  83 - B  (989.65Hz, Ideal=987.76Hz, Error=+0.19%)

        DEFW $006A        ; Octave  7, Note  84 - C  (1045.67Hz, Ideal=1046.52Hz, Error=-0.08%) C6
        DEFW $0064        ; Octave  7, Note  85 - C# (1108.41Hz, Ideal=1108.80Hz, Error=-0.04%)
        DEFW $005E        ; Octave  7, Note  86 - D  (1179.16Hz, Ideal=1174.64Hz, Error=+0.38%)
        DEFW $0059        ; Octave  7, Note  87 - D# (1245.40Hz, Ideal=1244.40Hz, Error=+0.08%)
        DEFW $0054        ; Octave  7, Note  88 - E  (1319.53Hz, Ideal=1318.52Hz, Error=+0.08%)
        DEFW $004F        ; Octave  7, Note  89 - F  (1403.05Hz, Ideal=1396.92Hz, Error=+0.44%)
        DEFW $004B        ; Octave  7, Note  90 - F# (1477.88Hz, Ideal=1480.00Hz, Error=-0.14%)
        DEFW $0047        ; Octave  7, Note  91 - G  (1561.14Hz, Ideal=1568.00Hz, Error=-0.44%)
        DEFW $0043        ; Octave  7, Note  92 - G# (1654.34Hz, Ideal=1661.20Hz, Error=-0.41%)
        DEFW $003F        ; Octave  7, Note  93 - A  (1759.38Hz, Ideal=1760.00Hz, Error=-0.04%)
        DEFW $003B        ; Octave  7, Note  94 - A# (1878.65Hz, Ideal=1866.40Hz, Error=+0.66%)
        DEFW $0038        ; Octave  7, Note  95 - B  (1979.30Hz, Ideal=1975.52Hz, Error=+0.19%)

        DEFW $0035        ; Octave  8, Note  96 - C  (2091.33Hz, Ideal=2093.04Hz, Error=-0.08%) C7
        DEFW $0032        ; Octave  8, Note  97 - C# (2216.81Hz, Ideal=2217.60Hz, Error=-0.04%)
        DEFW $002F        ; Octave  8, Note  98 - D  (2358.31Hz, Ideal=2349.28Hz, Error=+0.38%)
        DEFW $002D        ; Octave  8, Note  99 - D# (2463.13Hz, Ideal=2488.80Hz, Error=-1.03%)
        DEFW $002A        ; Octave  8, Note 100 - E  (2639.06Hz, Ideal=2637.04Hz, Error=+0.08%)
        DEFW $0028        ; Octave  8, Note 101 - F  (2771.02Hz, Ideal=2793.84Hz, Error=-0.82%)
        DEFW $0025        ; Octave  8, Note 102 - F# (2995.69Hz, Ideal=2960.00Hz, Error=+1.21%)
        DEFW $0023        ; Octave  8, Note 103 - G  (3166.88Hz, Ideal=3136.00Hz, Error=+0.98%)
        DEFW $0021        ; Octave  8, Note 104 - G# (3358.81Hz, Ideal=3322.40Hz, Error=+1.10%)
        DEFW $001F        ; Octave  8, Note 105 - A  (3575.50Hz, Ideal=3520.00Hz, Error=+1.58%)
        DEFW $001E        ; Octave  8, Note 106 - A# (3694.69Hz, Ideal=3732.80Hz, Error=-1.02%)
        DEFW $001C        ; Octave  8, Note 107 - B  (3958.59Hz, Ideal=3951.04Hz, Error=+0.19%)

        DEFW $001A        ; Octave  9, Note 108 - C  (4263.10Hz, Ideal=4186.08Hz, Error=+1.84%) C8
        DEFW $0019        ; Octave  9, Note 109 - C# (4433.63Hz, Ideal=4435.20Hz, Error=-0.04%)
        DEFW $0018        ; Octave  9, Note 110 - D  (4618.36Hz, Ideal=4698.56Hz, Error=-1.71%)
        DEFW $0016        ; Octave  9, Note 111 - D# (5038.21Hz, Ideal=4977.60Hz, Error=+1.22%)
        DEFW $0015        ; Octave  9, Note 112 - E  (5278.13Hz, Ideal=5274.08Hz, Error=+0.08%)
        DEFW $0014        ; Octave  9, Note 113 - F  (5542.03Hz, Ideal=5587.68Hz, Error=-0.82%)
        DEFW $0013        ; Octave  9, Note 114 - F# (5833.72Hz, Ideal=5920.00Hz, Error=-1.46%)
        DEFW $0012        ; Octave  9, Note 115 - G  (6157.81Hz, Ideal=6272.00Hz, Error=-1.82%)
        DEFW $0011        ; Octave  9, Note 116 - G# (6520.04Hz, Ideal=6644.80Hz, Error=-1.88%)
        DEFW $0010        ; Octave  9, Note 117 - A  (6927.54Hz, Ideal=7040.00Hz, Error=-1.60%)
        DEFW $000F        ; Octave  9, Note 118 - A# (7389.38Hz, Ideal=7465.60Hz, Error=-1.02%)
        DEFW $000E        ; Octave  9, Note 119 - B  (7917.19Hz, Ideal=7902.08Hz, Error=+0.19%)

        DEFW $000D        ; Octave 10, Note 120 - C  ( 8526.20Hz, Ideal= 8372.16Hz, Error=+1.84%) C9
        DEFW $000C        ; Octave 10, Note 121 - C# ( 9236.72Hz, Ideal= 8870.40Hz, Error=+4.13%)
        DEFW $000C        ; Octave 10, Note 122 - D  ( 9236.72Hz, Ideal= 9397.12Hz, Error=-1.71%)
        DEFW $000B        ; Octave 10, Note 123 - D# (10076.42Hz, Ideal= 9955.20Hz, Error=+1.22%)
        DEFW $000B        ; Octave 10, Note 124 - E  (10076.42Hz, Ideal=10548.16Hz, Error=-4.47%)
        DEFW $000A        ; Octave 10, Note 125 - F  (11084.06Hz, Ideal=11175.36Hz, Error=-0.82%)
        DEFW $0009        ; Octave 10, Note 126 - F# (12315.63Hz, Ideal=11840.00Hz, Error=+4.02%)
        DEFW $0009        ; Octave 10, Note 127 - G  (12315.63Hz, Ideal=12544.00Hz, Error=-1.82%)
        DEFW $0008        ; Octave 10, Note 128 - G# (13855.08Hz, Ideal=13289.60Hz, Error=+4.26%)

; -------------------------
; Play Note on MIDI Channel
; -------------------------
; This routine turns on a note on the MIDI channel and sets its volume, if MIDI channel is assigned to the current string.
; Three bytes are sent, and have the following meaning:
;   Byte 1: Channel number $00..$0F, with bits 4 and 7 set.
;   Byte 2: Note number $00..$7F.
;   Byte 3: Note velocity $00..$7F.
; Entry: IX=Address of the channel data block.

L114A:  LD   A,(IX+$01)   ; Is a MIDI channel assigned to this string?
        OR   A            ;
        RET  M            ; Return if not.

;A holds the assigned channel number ($00..$0F)

        OR   $90          ; Set bits 4 and 7 of the channel number. A=$90..$9F.
        CALL L117F        ; Write byte to MIDI device.

        LD   A,(IX+$00)   ; The note number.
        CALL L117F        ; Write byte to MIDI device.

        LD   A,(IX+$04)   ; Fetch the channel's volume.
        RES  4,A          ; Ensure the 'using envelope' bit is reset so
        SLA  A            ; that A holds a value between $00 and $0F.
        SLA  A            ; Multiply by 8 to increase the range to $00..$78.
        SLA  A            ; A=Note velocity.
        CALL L117F        ; Write byte to MIDI device.
        RET               ; [Could have saved 1 byte by using JP $117F (ROM 0)]

; ---------------------
; Turn MIDI Channel Off
; ---------------------
; This routine turns off a note on the MIDI channel, if a MIDI channel is assigned to the current string.
; Three bytes are sent, and have the following meaning:
;   Byte 1: Channel number $00..$0F, with bit 7 set.
;   Byte 2: Note number $00..$7F.
;   Byte 3: Note velocity $00..$7F.
; Entry: IX=Address of the channel data block.

L1169:  LD   A,(IX+$01)   ; Is a MIDI channel assigned to this string?
        OR   A            ;
        RET  M            ; Return if not.

;A holds the assigned channel number ($00..$0F)

        OR   $80          ; Set bit 7 of the channel number. A=$80..$8F.
        CALL L117F        ; Write byte to MIDI device.

        LD   A,(IX+$00)   ; The note number.
        CALL L117F        ; Write byte to MIDI device.

        LD   A,$40        ; The note velocity.
        CALL L117F        ; Write byte to MIDI device.
        RET               ; [Could have saved 1 byte by using JP $117F (ROM 0)]

; ------------------------
; Send Byte to MIDI Device
; ------------------------
; This routine sends a byte to the MIDI port. MIDI devices communicate at 31250 baud,
; although this routine actually generates a baud rate of 31388, which is within the 1%
; tolerance supported by MIDI devices.
; Entry: A=Byte to send.

L117F:  LD   L,A          ; Store the byte to send.

        LD   BC,$FFFD     ;
        LD   A,$0E        ;
        OUT  (C),A        ; Select register 14 - I/O port.

        LD   BC,$BFFD     ;
        LD   A,$FA        ; Set RS232 'RXD' transmit line to 0. (Keep KEYPAD 'CTS' output line low to prevent the keypad resetting)
        OUT  (C),A        ; Send out the START bit.

        LD   E,$03        ; (7) Introduce delays such that the next bit is output 113 T-states from now.

L1190:  DEC  E            ; (4)
        JR   NZ,L1190     ; (12/7)

        NOP               ; (4)
        NOP               ; (4)
        NOP               ; (4)
        NOP               ; (4)

        LD   A,L          ; (4) Retrieve the byte to send.

        LD   D,$08        ; (7) There are 8 bits to send.

L119A:  RRA               ; (4) Rotate the next bit to send into the carry.
        LD   L,A          ; (4) Store the remaining bits.
        JP   NC,L11A5     ; (10) Jump if it is a 0 bit.

        LD   A,$FE        ; (7) Set RS232 'RXD' transmit line to 1. (Keep KEYPAD 'CTS' output line low to prevent the keypad resetting)
        OUT  (C),A        ; (11)
        JR   L11AB        ; (12) Jump forward to process the next bit.

L11A5:  LD   A,$FA        ; (7) Set RS232 'RXD' transmit line to 0. (Keep KEYPAD 'CTS' output line low to prevent the keypad resetting)
        OUT  (C),A        ; (11)
        JR   L11AB        ; (12) Jump forward to process the next bit.

L11AB:  LD   E,$02        ; (7) Introduce delays such that the next data bit is output 113 T-states from now.

L11AD:  DEC  E            ; (4)
        JR   NZ,L11AD     ; (12/7)

        NOP               ; (4)
        ADD  A,$00        ; (7)

        LD   A,L          ; (4) Retrieve the remaining bits to send.
        DEC  D            ; (4) Decrement the bit counter.
        JR   NZ,L119A     ; (12/7) Jump back if there are further bits to send.

        NOP               ; (4) Introduce delays such that the stop bit is output 113 T-states from now.
        NOP               ; (4)
        ADD  A,$00        ; (7)
        NOP               ; (4)
        NOP               ; (4)

        LD   A,$FE        ; (7) Set RS232 'RXD' transmit line to 0. (Keep KEYPAD 'CTS' output line low to prevent the keypad resetting)
        OUT  (C),A        ; (11) Send out the STOP bit.

        LD   E,$06        ; (7) Delay for 101 T-states (28.5us).

L11C3:  DEC  E            ; (4)
        JR   NZ,L11C3     ; (12/7)

        RET               ; (10)


; ===============================================
; CASSETTE AND RAM DISK COMMAND ROUTINES - PART 1
; ===============================================

; ------------
; SAVE Routine
; ------------

L11C7:  LD   HL,FLAGS3    ; $5B66.
        SET  5,(HL)       ; Indicate SAVE.
        JR   L11E1

; ------------
; LOAD Routine
; ------------

L11CE:  LD   HL,FLAGS3    ; $5B66.
        SET  4,(HL)       ; Indicate LOAD.
        JR   L11E1

; --------------
; VERIFY Routine
; --------------

L11D5:  LD   HL,FLAGS3    ; $5B66.
        SET  7,(HL)       ; Indicate VERIFY.
        JR   L11E1

; -------------
; MERGE Routine
; -------------

L11DC:  LD   HL,FLAGS3    ; $5B66.
        SET  6,(HL)       ; Indicate MERGE.

L11E1:  LD   HL,FLAGS3    ; $5B66.
        RES  3,(HL)       ; Indicate using cassette.
        RST  18H          ; Get current character.
        CP   '!'          ; $21. '!'
        JP   NZ,L139A     ; Jump ahead to handle cassette command.

;RAM disk operation

        LD   HL,FLAGS3    ; $5B66.
        SET  3,(HL)       ; Indicate using RAM disk.
        RST  20H          ; Move on to next character.
        JP   L139A        ; Jump ahead to handle RAM disk command.

; ----------------------------------
; Error Report C - Nonsense in BASIC
; ----------------------------------

L11F5:  CALL L0566        ; Produce error report.
        DEFB $0B          ; "C Nonsense in BASIC"

; -------------------------
; RAM Disk Command Handling
; -------------------------
; The information relating to the file is copied into memory in $5B66 (FLAGS3)
; to ensure that it is available once other RAM banks are switched in.
; This code is very similar to that in the ZX Interface 1 ROM at $08F6.
; Entry: HL=Start address.
;        IX=File header descriptor.

L11F9:  LD   (HD_0D),HL   ; $5B74. Save start address.

        LD   A,(IX+$00)   ; Transfer header file information
        LD   (HD_00),A    ; $5B71.  from IX to HD_00 onwards.
        LD   L,(IX+$0B)   ;
        LD   H,(IX+$0C)   ;
        LD   (HD_0B),HL   ; $5B72.
        LD   L,(IX+$0D)   ;
        LD   H,(IX+$0E)   ;
        LD   (HD_11),HL   ; $5B78.
        LD   L,(IX+$0F)   ;
        LD   H,(IX+$10)   ;
        LD   (HD_0F),HL   ; $5B76.

;A copy of the header information has now been copied from IX+$00 onwards to HD_00 onwards

        OR   A            ; Test file type.
        JR   Z,L122A      ; Jump ahead for a program file.

        CP   $03          ;
        JR   Z,L122A      ; Jump ahead for a CODE/SCREEN$ file.

;An array type

        LD   A,(IX+$0E)   ;
        LD   (HD_0F),A    ; $5B76. Store array name.

L122A:  PUSH IX           ; IX points to file header.
        POP  HL           ; Retrieve into HL.

        INC  HL           ; HL points to filename.
        LD   DE,N_STR1    ; $5B67.
        LD   BC,$000A     ;
        LDIR              ; Copy the filename.

        LD   HL,FLAGS3    ; $5B66.
        BIT  5,(HL)       ; SAVE operation?
        JP   NZ,L1B3C     ; Jump ahead if SAVE.

; Load / Verify or Merge
; ----------------------

        LD   HL,HD_00     ; $5B71.
        LD   DE,SC_00     ; $5B7A.
        LD   BC,$0007     ;
        LDIR              ; Transfer requested details from HD_00 onwards into SC_00 onwards.

        CALL L1BBD        ; Find and load requested file header into HD_00 ($5B71).

;The file exists else the call above would have produced an error "h file does not exist"

        LD   A,(SC_00)    ; $5B7A. Requested file type.
        LD   B,A          ;
        LD   A,(HD_00)    ; $5B71. Loaded file type.
        CP   B            ;
        JR   NZ,L125C     ; Error 'b' if file types do not match.

        CP   $03          ; Is it a CODE file type?
        JR   Z,L126C      ; Jump ahead to avoid MERGE program/array check.

        JR   C,L1260      ; Only file types 0, 1 and 2 are OK.

L125C:  CALL L0566        ; Produce error report.
        DEFB $1D          ; "b Wrong file type"

L1260:  LD   A,(FLAGS3)   ; $5B66.
        BIT  6,A          ; Is it a MERGE program/array operation?
        JR   NZ,L12A1     ; Jump ahead if so.

        BIT  7,A          ; Is it a VERIFY program/array operation?
        JP   Z,L12B7      ; Jump ahead if LOAD.

;Either a verify program/array or a load/verify CODE/SCREEN$ type file

L126C:  LD   A,(FLAGS3)   ; $5B66.
        BIT  6,A          ; MERGE operation?
        JR   Z,L1277      ; Jump ahead if VERIFY.

;Cannot merge CODE/SCREEN$

        CALL L0566        ; Produce error report.
        DEFB $1C          ; "a MERGE error"

; ------------------------
; RAM Disk VERIFY! Routine
; ------------------------

L1277:  LD   HL,(SC_0B)   ; $5B7B. Length requested.
        LD   DE,(HD_0B)   ; $5B72. File length.
        LD   A,H          ;
        OR   L            ;
        JR   Z,L128A      ; Jump ahead if requested length is 0, i.e. not specified.

        SBC  HL,DE        ; Is file length <= requested length?
        JR   NC,L128A     ; Jump ahead if so; requested length is OK.

;File was smaller than requested

        CALL L0566        ; Produce error report.
        DEFB $1E          ; "c CODE error"

L128A:  LD   HL,(SC_0D)   ; $5B7D. Fetch start address.
        LD   A,H          ;
        OR   L            ; Is length 0, i.e. not provided?
        JR   NZ,L1294     ; Jump ahead if start address was provided.

        LD   HL,(HD_0D)   ; $5B74. Not provided so use file's start address.

L1294:  LD   A,(HD_00)    ; $5B71. File type.
        AND  A            ; Is it a program?
        JR   NZ,L129D     ; Jump ahead if not.

        LD   HL,($5C53)   ; PROG. Set start address as start of program area.

L129D:  CALL L135A        ; Load DE bytes at address pointed to by HL.
                          ; [The Spectrum 128 manual states that the VERIFY keyword is not used with the RAM disk yet it clearly is,
                          ; although verifying a RAM disk file simply loads it in just as LOAD would do. To support verifying, the routine
                          ; at $1DC6 (ROM 0) which loads blocks of data would need to be able to load or verify a block. The success status would
                          ; then need to be propagated back to here via routines at $135A (ROM 0), $1BDA (ROM 0) and $1DC6 (ROM 0)]
        RET               ; [Could have saved 1 byte by using JP $135A (ROM 0), although could have saved a lot more by not supporting the
                          ; VERIFY keyword at all]

; -----------------------
; RAM Disk MERGE! Routine
; -----------------------

L12A1:  LD   BC,(HD_0B)   ; $5B72. File length.
        PUSH BC           ; Save the length.
        INC  BC           ; Increment for terminator $80 (added later).
        RST  28H          ;
        DEFW BC_SPACES    ; $0030. Create room in the workspace for the file.
        LD   (HL),$80     ; Insert terminator.

        EX   DE,HL        ; HL=Start address.
        POP  DE           ; DE=File length.
        PUSH HL           ; Save start address.
        CALL L135A        ; Load DE bytes to address pointed to by HL.
        POP  HL           ; Retrieve start address.

        RST  28H          ;
        DEFW ME_CONTRL+$0018 ;$08CE. Delegate actual merge handling to ROM 1.
        RET               ;

; ----------------------
; RAM Disk LOAD! Routine
; ----------------------

L12B7:  LD   DE,(HD_0B)   ; $5B72. File length.
        LD   HL,(SC_0D)   ; $5B7D. Requested start address.
        PUSH HL           ; Save requested start address.
        LD   A,H          ;
        OR   L            ; Was start address specified? (0 if not).
        JR   NZ,L12C9     ; Jump ahead if start address specified.

;Start address was not specified

        INC  DE           ; Allow for variable overhead.
        INC  DE           ;
        INC  DE           ;
        EX   DE,HL        ; HL=File Length+3.
        JR   L12D2        ; Jump ahead to test if there is room.

;A start address was specified

L12C9:  LD   HL,(SC_0B)   ; $5B7B. Requested length.
        EX   DE,HL        ; DE=Requested length. HL=File length.
        SCF               ;
        SBC  HL,DE        ; File length-Requested Length-1
        JR   C,L12DB      ; Jump if file is smaller than requested.

;Test if there is room since file is bigger than requested

L12D2:  LD   DE,$0005     ;
        ADD  HL,DE        ;
        LD   B,H          ;
        LD   C,L          ; Space required in BC.
        RST  28H          ;
        DEFW TEST_ROOM    ; $1F05. Will automatically produce error '4' if out of memory.

;Test file type

L12DB:  POP  HL           ; Requested start address.
        LD   A,(HD_00)    ; $5B71. Get requested file type.

L12DF:  AND  A            ; Test file type.
        JR   Z,L1311      ; Jump if program file type.

; Array type
; ----------

        LD   A,H          ;
        OR   L            ; Was start address of existing array specified?
        JR   Z,L12F1      ; Jump ahead if not.

;Start address of existing array was specified

        DEC  HL           ;
        LD   B,(HL)       ;
        DEC  HL           ;
        LD   C,(HL)       ; Fetch array length.
        DEC  HL           ;
        INC  BC           ;
        INC  BC           ;
        INC  BC           ; Allow for variable header.
        RST  28H          ;
        DEFW RECLAIM_2    ; $19E8. Delete old array.

;Insert new array entry into variables area

L12F1:  LD   HL,($5C59)   ; E_LINE.
        DEC  HL           ; Point to end
        LD   BC,(HD_0B)   ; $5B72. Array length.
        PUSH BC           ; Save array length.
        INC  BC           ; Allow for variable header.
        INC  BC           ;
        INC  BC           ;
        LD   A,(SC_0F)    ; $5B7F. Get array name.
        PUSH AF           ; Save array name.
        RST  28H          ;
        DEFW MAKE_ROOM    ; $1655. Create room for new array.
        INC HL
        POP  AF           ;
        LD   (HL),A       ; Store array name.
        POP  DE           ;
        INC  HL           ;
        LD   (HL),E       ;
        INC  HL           ;
        LD   (HL),D       ; Store array length.
        INC  HL           ;

L130D:  CALL L135A        ; Load DE bytes to address pointed to by HL.
        RET               ; [Could have saved 1 byte by using JP $135A (ROM 0)]

; Program type
; ------------

L1311:  LD   HL,FLAGS3    ; $5B66.
        RES  1,(HL)       ; Signal do not auto-run BASIC program.

        LD   DE,($5C53)   ; PROG. Address of start of BASIC program.
        LD   HL,($5C59)   ; E_LINE. Address of end of program area.
        DEC  HL           ; Point before terminator.
        RST  28H          ;
        DEFW RECLAIM      ; $19E5. Delete current BASIC program.

        LD   BC,(HD_0B)   ; $5B72. Fetch file length.
        LD   HL,($5C53)   ; PROG. Address of start of BASIC program.
        RST  28H          ;
        DEFW MAKE_ROOM    ; $1655. Create room for the file.
        INC HL            ; Allow for terminator.

        LD   BC,(HD_0F)   ; $5B76. Length of variables.
        ADD  HL,BC        ; Determine new address of variables.
        LD   ($5C4B),HL   ; VARS.

        LD   A,(HD_11+1)  ; $5B79. Fetch high byte of auto-run line number.
        LD   H,A          ;
        AND  $C0          ;
        JR   NZ,L134C     ; If holds $80 then no auto-run line number specified.

        LD   A,(HD_11)    ; $5B78. Low byte of auto-run line number.
        LD   L,A          ;
        LD   ($5C42),HL   ; NEWPPC. Set line number to run.
        LD   (IY+$0A),$00 ; NSPPC. Statement 0.

        LD   HL,FLAGS3    ; $5B66.
        SET  1,(HL)       ; Signal auto-run BASIC program.

L134C:  LD   HL,($5C53)   ; PROG. Address of start of BASIC program.
        LD   DE,(HD_0B)   ; $5B72. Program length.
        DEC  HL           ;
        LD   ($5C57),HL   ; NXTLIN. Set the address of next line to the end of the program.
        INC  HL           ;
        JR   L130D        ; Jump back to load program bytes.

; -------------------
; RAM Disk Load Bytes
; -------------------
; Make a check that the requested length is not zero before proceeding to perform
; the LOAD, MERGE or VERIFY. Note that VERIFY simply performs a LOAD.
; Entry: HL=Destination address.
;        DE=Length.
;        IX=Address of catalogue entry.
;        HD_00-HD_11 holds file header information.

L135A:  LD   A,D          ;
        OR   E            ;
        RET  Z            ; Return if length is zero.

        CALL L1BDA        ; Load bytes
        RET               ; [Could have used JP $1BDA (ROM 0) to save 1 byte]

; ------------------------------
; Get Expression from BASIC Line
; ------------------------------
; Returns in BC.

L1361:  RST  28H          ; Expect an expression on the BASIC line.
        DEFW EXPT_EXP     ; $1C8C.
        BIT  7,(IY+$01)   ; Return early if syntax checking.
        RET  Z            ;

        PUSH AF           ; Get the item off the calculator stack
        RST  28H          ;
        DEFW STK_FETCH    ; $2BF1.
        POP  AF           ;
        RET               ;

; -----------------------
; Check Filename and Copy
; -----------------------
; Called to check a filename for validity and to copy it into N_STR1 ($5B67).

L136F:  RST  20H          ; Advance the pointer into the BASIC line.
        CALL L1361        ; Get expression from BASIC line.
        RET  Z            ; Return if syntax checking.

        PUSH AF           ; [No need to save AF - see comment below]

        LD   A,C          ; Check for zero length.
        OR   B            ;
        JR   Z,L1396      ; Jump if so to produce error report "f Invalid name".

        LD   HL,$000A     ; Check for length greater than 10.
        SBC  HL,BC        ;
        JR   C,L1396      ; Jump if so to produce error report "f Invalid name".

        PUSH DE           ; Save the filename start address.
        PUSH BC           ; Save the filename length.

        LD   HL,N_STR1    ; $5B67. HL points to filename buffer.
        LD   B,$0A        ;
        LD   A,$20        ;

L1389:  LD   (HL),A       ; Fill it with 10 spaces.
        INC  HL           ;
        DJNZ L1389        ;

        POP  BC           ; Restore filename length.
        POP  HL           ; Restore filename start address.

        LD   DE,N_STR1    ; $5B67. DE points to where to store the filename.
        LDIR              ; Perform the copy.

        POP  AF           ; [No need to have saved AF as not subsequently used]
        RET               ;

L1396:  CALL L0566        ; Produce error report.
        DEFB $21          ; "f Invalid name"

; ------------------------------------
; Cassette / RAM Disk Command Handling
; ------------------------------------
; Handle SAVE, LOAD, MERGE, VERIFY commands.
; Bit 3 of FLAGS3 indicates whether a cassette or RAM disk command.
; This code is very similar to that in ROM 1 at $0605.

L139A:  RST 28H
        DEFW EXPT_EXP     ; $1C8C. Pass the parameters of the 'name' to the calculator stack.

        BIT  7,(IY+$01)   ;
        JR   Z,L13E3      ; Jump ahead if checking syntax.

        LD   BC,$0011     ; Size of save header, 17 bytes.
        LD   A,($5C74)    ; T_ADDR. Indicates which BASIC command.
        AND  A            ; Is it SAVE?
        JR   Z,L13AE      ; Jump ahead if so.

        LD   C,$22        ; Otherwise need 34d bytes for LOAD, MERGE and VERIFY commands.
                          ; 17 bytes for the header of the requested file, and 17 bytes for the files tested from tape.

L13AE:  RST  28H          ;
        DEFW BC_SPACES    ; $0030. Create space in workspace.

        PUSH DE           ; Get start of the created space into IX.
        POP  IX           ;

        LD   B,$0B        ; Clear the filename.
        LD   A,$20        ;

L13B8:  LD   (DE),A       ; Set all characters to spaces.
        INC  DE           ;
        DJNZ L13B8        ;

        LD   (IX+$01),$FF ; Indicate a null name.
        RST  28H          ; The parameters of the name are fetched.
        DEFW STK_FETCH    ; $2BF1.

        LD   HL,$FFF6     ; = -10.
        DEC  BC           ;
        ADD  HL,BC        ;
        INC  BC           ;
        JR   NC,L13DC     ; Jump ahead if filename length within 10 characters.

        LD   A,($5C74)    ; T_ADDR. Indicates which BASIC command.
        AND  A            ; Is it SAVE?
        JR   NZ,L13D5     ; Jump ahead if not since LOAD, MERGE and VERIFY can have null filenames.

        CALL L0566        ; Produce error report.
        DEFB $0E          ; "F Invalid file name"

;Continue to handle the name of the program.

L13D5:  LD   A,B
        OR   C            ;
        JR   Z,L13E3      ; Jump forward if the name has a null length.

        LD   BC,$000A     ; Truncate longer filenames.

;The name is now transferred to the work space (second location onwards)

L13DC:  PUSH IX           ;
        POP  HL           ; Transfer address of the workspace to HL.
        INC  HL           ; Step to the second location.
        EX   DE,HL        ;
        LDIR              ; Copy the filename.

;The many different parameters, if any, that follow the command are now considered.
;Start by handling 'xxx "name" DATA'.

L13E3:  RST  18H          ; Get character from BASIC line.
        CP   $E4          ; Is it 'DATA'?
        JR   NZ,L143B     ; Jump if not DATA.

; 'xxx "name" DATA'
; -----------------

        LD   A,($5C74)    ; T_ADDR. Check the BASIC command.
        CP   $03          ; Is it MERGE?
        JP   Z,L11F5      ; "C Nonsense in BASIC" if so.

        RST  20H          ; Get next character from BASIC line.
        RST  28H          ;
        DEFW LOOK_VARS    ; $28B2. Look in the variables area for the array.
        JR NC,L140B       ; Jump if handling an existing array.

        LD   HL,$0000     ; Signal 'using a new array'.
        BIT  6,(IY+$01)   ; FLAGS. Is it a string Variable?
        JR   Z,L1401      ; Jump forward if so.

        SET  7,C          ; Set bit 7 of the array's name.

L1401:  LD   A,($5C74)    ; T_ADDR.
        DEC  A            ; Give an error if trying to
        JR   Z,L1420      ; SAVE or VERIFY a new array.

        CALL L0566        ; Produce error report.
        DEFB $01          ; "2 Variable not found"

;Continue with the handling of an existing array

L140B:  JP   NZ,L11F5     ; Jump if not an array to produce "C Nonsense in BASIC".

        BIT  7,(IY+$01)   ; FLAGS.
        JR   Z,L142D      ; Jump forward if checking syntax.

        LD   C,(HL)       ;
        INC  HL           ; Point to the 'low length' of the variable.
        LD   A,(HL)       ; The low length byte goes into
        LD   (IX+$0B),A   ; the work space.
        INC  HL           ;
        LD   A,(HL)       ; The high length byte goes into
        LD   (IX+$0C),A   ; the work space.
        INC  HL           ; Step past the length bytes.

;The next part is common to both 'old' and 'new' arrays

L1420:  LD   (IX+$0E),C   ; Copy the array's name.
        LD   A,$01        ; Assume an array of numbers - Code $01.
        BIT  6,C          ;
        JR   Z,L142A      ; Jump if it is so.

        INC  A            ; Indicate it is an array of characters - Code $02.

L142A:  LD   (IX+$00),A   ; Save the 'type' in the first location of the header area.

;The last part of the statement is examined before joining the other pathways

L142D:  EX   DE,HL        ; Save the pointer in DE.
        RST  20H          ;
        CP   ')'          ; $29. Is the next character a ')'?
        JR   NZ,L140B     ; Give report C if it is not.

        RST  20H          ; Advance to next character.
        CALL L188F        ; Move on to the next statement if checking syntax.
        EX   DE,HL        ; Return the pointer to the HL.
                          ; (The pointer indicates the start of an existing array's contents).
        JP   L14F5        ; Jump forward.

; Now Consider 'SCREEN$'

L143B:  CP   $AA          ; Is the present code the token 'SCREEN$'?
        JR   NZ,L145E     ; Jump ahead if not.

; 'xxx "name" SCREEN$'
; --------------------

        LD   A,($5C74)    ; T_ADDR_lo. Check the BASIC command.
        CP   $03          ; Is it MERGE?
        JP   Z,L11F5      ; Jump to "C Nonsense in BASIC" if so since it is not possible to have 'MERGE name SCREEN$'.

        RST  20H          ; Advance pointer into BASIC line.
        CALL L188F        ; Move on to the next statement if checking syntax.

        LD   (IX+$0B),$00 ; Length of the block.
        LD   (IX+$0C),$1B ; The display area and the attribute area occupy $1800 locations.

        LD   HL,$4000     ; Start of the block, beginning of the display file $4000.
        LD   (IX+$0D),L   ;
        LD   (IX+$0E),H   ; Store in the workspace.
        JR   L14AB        ; Jump forward.

; Now consider 'CODE'

L145E:  CP   $AF          ; Is the present code the token 'CODE'?
        JR   NZ,L14B1     ; Jump ahead if not.

; 'xxx "name" CODE'
; -----------------

        LD   A,($5C74)    ; T_ADDR_lo. Check the BASIC command.
        CP   $03          ; Is it MERGE?
        JP   Z,L11F5      ; Jump to "C Nonsense in BASIC" if so since it is not possible to have 'MERGE name CODE'.

        RST  20H          ; Advance pointer into BASIC line.
        RST  28H          ;
        DEFW PR_ST_END    ; $2048.
        JR   NZ,L147C     ; Jump forward if the statement has not finished

        LD   A,($5C74)    ; T_ADDR_lo.
        AND  A            ; It is not possible to have 'SAVE name CODE' by itself.
        JP   Z,L11F5      ; Jump if so to produce "C Nonsense in BASIC".

        RST  28H          ;
        DEFW USE_ZERO     ; $1CE6. Put a zero on the calculator stack - for the 'start'.
        JR   L148B        ; Jump forward.

;Look for a 'starting address'

L147C:  RST  28H          ;
        DEFW EXPT_1NUM    ; $1C82. Fetch the first number.
        RST  18H          ;
        CP   ','          ; $2C. Is the present character a ','?
        JR   Z,L1490      ; Jump if it is - the number was a 'starting address'

        LD   A,($5C74)    ; T_ADDR_lo.
        AND  A            ; Refuse 'SAVE name CODE' that does not have a 'start' and a 'length'.
        JP   Z,L11F5      ; Jump if so to produce "C Nonsense in BASIC".

L148B:  RST  28H          ;
        DEFW USE_ZERO     ; $1CE6. Put a zero on the calculator stack - for the 'length'.
        JR   L1494        ; Jump forward.

;Fetch the 'length' as it was specified

L1490:  RST  20H          ; Advance to next character.
        RST  28H          ;
        DEFW EXPT_1NUM    ; $1C82. Fetch the 'length'.

;The parameters are now stored in the header area of the work space

L1494:  CALL L188F        ; But move on to the next statement now if checking syntax.
        RST  28H          ;
        DEFW FIND_INT2    ; $1E99. Compress the 'length' into BC.
        LD   (IX+$0B),C   ; Store the length of the CODE block.
        LD   (IX+$0C),B   ;
        RST  28H          ;
        DEFW FIND_INT2    ; $1E99. Compress the 'starting address' into BC.
        LD   (IX+$0D),C   ; Store the start address of the CODE block.
        LD   (IX+$0E),B   ;
        LD   H,B          ; Transfer start address pointer to HL.
        LD   L,C          ;

;'SCREEN$' and 'CODE' are both of type 3

L14AB:  LD   (IX+$00),$03 ; Store file type = $03 (CODE).
        JR   L14F5        ; Rejoin the other pathways.

; 'xxx "name"' / 'SAVE "name" LINE'
; ---------------------------------

;Now consider 'LINE' and 'no further parameters'

L14B1:  CP   $CA          ; Is the present code the token 'LINE'?
        JR   Z,L14BE      ; Jump ahead if so.

        CALL L188F        ; Move on to the next statement if checking syntax.
        LD   (IX+$0E),$80 ; Indicate no LINE number.
        JR   L14D5        ; Jump forward.

;Fetch the 'line number' that must follow 'LINE'

L14BE:  LD   A,($5C74)    ; T_ADDR_lo. Only allow 'SAVE name LINE number'.
        AND  A            ; Is it SAVE?
        JP   NZ,L11F5     ; Produce "C Nonsense in BASIC" if not.

        RST  20H          ; Advance pointer into BASIC line.
        RST  28H          ; Get LINE number onto calculator stack
        DEFW EXPT_1NUM    ; $1C82. Pass the number to the calculator stack.
        CALL L188F        ; Move on to the next statement if checking syntax.
        RST  28H          ; Retrieve LINE number from calculator stack
        DEFW FIND_INT2    ; $1E99. Compress the 'line number' into BC.
        LD   (IX+$0D),C   ; Store the LINE number.
        LD   (IX+$0E),B   ;

;'LINE' and 'no further parameters' are both of type 0

L14D5:  LD   (IX+$00),$00 ; Store file type = $00 (program).
        LD   HL,($5C59)   ; E_LINE. The pointer to the end of the variables area.
        LD   DE,($5C53)   ; PROG. The pointer to the start of the BASIC program.
        SCF               ;
        SBC  HL,DE        ; Perform the subtraction to find the length of the 'program + variables'.
        LD   (IX+$0B),L   ;
        LD   (IX+$0C),H   ; Store the length.

        LD   HL,($5C4B)   ; VARS. Repeat the operation but this
        SBC  HL,DE        ; time storing the length of the
        LD   (IX+$0F),L   ; 'program' only.
        LD   (IX+$10),H   ;
        EX   DE,HL        ; Transfer pointer to HL.

;In all cases the header information has now been prepared:
;- The location 'IX+00' holds the type number.
;- Locations 'IX+01 to IX+0A' holds the name ($FF in 'IX+01' if null).
;- Locations 'IX+0B & IX+0C' hold the number of bytes that are to be found in the 'data block'.
;- Locations 'IX+0D to IX+10' hold a variety of parameters whose exact interpretation depends on the 'type'.

;The routine continues with the first task being to separate SAVE from LOAD, VERIFY and MERGE.

L14F5:  LD   A,(FLAGS3)   ; $5B66.
        BIT  3,A          ; Using RAM disk?
        JP   NZ,L11F9     ; Jump if the operation is on the RAM disk.

        LD   A,($5C74)    ; T_ADDR_lo. Get the BASIC command.
        AND  A            ; Is it SAVE?
        JR   NZ,L1507     ; Jump ahead if not.

        RST  28H          ;
        DEFW SA_CONTROL   ; $0970. Run the save routine in ROM 1.
        RET               ;

;In the case of a LOAD, VERIFY or MERGE command the first seventeen bytes of the 'header area'
;in the work space hold the prepared information, as detailed above;
;and it is now time to fetch a 'header' from the tape.

L1507:  RST  28H          ;
        DEFW SA_ALL+$0007 ; $0761. Run the load/merge/verify routine in ROM 1.
        RET               ;


; ==============================================
; BASIC LINE AND COMMAND INTERPRETATION ROUTINES
; ==============================================

; --------------
; LPRINT Routine
; --------------

L150B:  LD   A,$03        ; Printer channel.
        JR   L1511        ; Jump ahead.

; --------------
; PRINT Routine
; --------------

L150F:  LD   A,$02        ; Main screen channel.

L1511:  RST  28H          ;
        DEFW SYNTAX_Z     ; $2530.
        JR   Z,L1519      ; Jump forward if syntax is being checked.

        RST  28H          ;
        DEFW CHAN_OPEN    ; $1601.

L1519:  RST  28H          ;
        DEFW TEMPS        ; $0D4D.
        RST  28H          ;
        DEFW PRINT_2      ; $1FDF. Delegate handling to ROM 1.
        CALL L188F        ; "C Nonsense in BASIC" during syntax checking if not
                          ; at end of line or statement.
        RET               ;

; -------------
; INPUT Routine
; -------------
; This routine allows for values entered from the keyboard to be assigned
; to variables. It is also possible to have print items embedded in the
; INPUT statement and these items are printed in the lower part of the display.

L1523:  RST  28H          ;
        DEFW SYNTAX_Z     ; $2530.
        JR   Z,L1530      ; Jump forward if syntax is being checked.

        LD   A,$01        ; Open channel 'K'.
        RST  28H          ;
        DEFW CHAN_OPEN    ; $1601.
        RST  28H          ; Clear the lower part of the display.
        DEFW CLS_LOWER    ; $0D6E. [*BUG* - This call will re-select channel 'S' and so should have been called prior to opening
                          ; channel 'K'. It is a direct copy of the code that appears in the standard Spectrum ROM (and ROM 1). It is
                          ; debatable whether it is better to reproduce the bug so as to ensure that the INPUT routine operates the same
                          ; in 128K mode as it does in 48K mode. Credit: Geoff Wearmouth]

L1530:  LD   (IY+$02),$01 ; TV_FLAG. Signal that the lower screen is being handled. [Not a bug as has been reported elsewhere. The confusion seems to have
                          ; arisen due to the incorrect system variable being originally mentioned in the Spectrum ROM Disassembly by Logan and O'Hara]
        RST  28H          ;
        DEFW IN_ITEM_1    ; $20C1. Call the subroutine to deal with the INPUT items.
        CALL L188F        ; Move on to the next statement if checking syntax.
        RST  28H          ;
        DEFW INPUT_1+$000A ; $20A0. Delegate handling to ROM 1.
        RET               ;

; ------------
; COPY Routine
; ------------

L153E:  JP   L08AA        ; Jump to new COPY routine.

; -----------
; NEW Routine
; -----------

L1541:  DI                ;
        JP   L019D        ; Re-initialise the machine.

; --------------
; CIRCLE Routine
; --------------
; This routine draws an approximation to the circle with centre co-ordinates
; X and Y and radius Z. These numbers are rounded to the nearest integer before use.
; Thus Z must be less than 87.5, even when (X,Y) is in the centre of the screen.
; The method used is to draw a series of arcs approximated by straight lines.

L1545:  RST  18H          ; Get character from BASIC line.
        CP   ','          ; $2C. Check for second parameter.
        JR   NZ,L1582     ; Jump ahead (for error C) if not.

        RST  20H          ; Advance pointer into BASIC line.
        RST  28H          ; Get parameter.
        DEFW EXPT_1NUM    ; $1C82. Radius to calculator stack.
        CALL L188F        ; Move to consider next statement if checking syntax.
        RST  28H          ;
        DEFW CIRCLE+$000D ; $232D. Delegate handling to ROM 1.
        RET               ;

; ------------
; DRAW Routine
; ------------
; This routine is entered with the co-ordinates of a point X0, Y0, say, in
; COORDS. If only two parameters X, Y are given with the DRAW command, it
; draws an approximation to a straight line from the point X0, Y0 to X0+X, Y0+Y.
; If a third parameter G is given, it draws an approximation to a circular arc
; from X0, Y0 to X0+X, Y0+Y turning anti-clockwise through an angle G radians.

L1555:  RST  18H          ; Get current character.
        CP   ','          ; $2C.
        JR   Z,L1561      ; Jump if there is a third parameter.

        CALL L188F        ; Error C during syntax checking if not at end of line/statement.
        RST  28H          ;
        DEFW LINE_DRAW    ; $2477. Delegate handling to ROM 1.
        RET               ;

L1561:  RST  20H          ; Get the next character.
        RST  28H          ;
        DEFW EXPT_1NUM    ; $1C82. Angle to calculator stack.
        CALL L188F        ; Error C during syntax checking if not at end of line/statement.
        RST  28H          ;
        DEFW DR_3_PRMS+$0007 ; $2394. Delegate handling to ROM 1.
        RET               ;

; -----------
; DIM Routine
; -----------
; This routine establishes new arrays in the variables area. The routine starts
; by searching the existing variables area to determine whether there is an existing
; array with the same name. If such an array is found then it is 'reclaimed' before
; the new array is established. A new array will have all its elements set to zero
; if it is a numeric array, or to 'spaces' if it is an array of strings.

L156C:  RST  28H          ; Search to see if the array already exists.
        DEFW LOOK_VARS    ; $28B2.
        JR   NZ,L1582     ; Jump if array variable not found.

        RST  28H
        DEFW SYNTAX_Z     ; $2530.
        JR   NZ,L157E     ; Jump ahead during syntax checking.

        RES  6,C          ; Test the syntax for string arrays as if they were numeric.
        RST  28H          ;
        DEFW STK_VAR      ; $2996. Check the syntax of the parenthesised expression.
        CALL L188F        ; Error when checking syntax unless at end of line/statement.

;An 'existing array' is reclaimed.

L157E:  RST  28H          ;
        DEFW D_RUN        ; $2C15. Delegate handling to ROM 1.
        RET               ;

; ----------------------------------
; Error Report C - Nonsense in BASIC
; ----------------------------------
; This is a duplication of the code at $11F5 (ROM 0).

L1582:  CALL L0566        ; Produce error report.
        DEFB $0B          ; "C Nonsense in BASIC"

; --------------------
; Clear Screen Routine
; --------------------
; Clear screen if it is not already clear.

L1586:  BIT  0,(IY+$30)   ; FLAGS2. Is the screen clear?
        RET  Z            ; Return if it is.

        RST  28H          ;
        DEFW CL_ALL       ; $0DAF. Otherwise clear the whole display.
        RET               ;

; ---------------------------
; Evaluate Numeric Expression
; ---------------------------
; This routine is called when a numerical expression is typed directly into the editor or calculator.
; A numeric expression is any that begins with a numeric digit, '(' or is one of the function keywords, e.g. ABS, SIN, etc,
; or is the name of a numeric variable.

L158F:  LD   HL,$FFFE     ; A line in the editing area is considered as line '-2'.
        LD   ($5C45),HL   ; PPC. Signal no current line number.

;Check the syntax of the BASIC line

        RES  7,(IY+$01)   ; Indicate 'syntax checking' mode.
        CALL L1636        ; Point to start of the BASIC command line.

        RST  28H          ;
        DEFW SCANNING     ; $24FB. Evaluate the command line.
        BIT  6,(IY+$01)   ; Is it a numeric value?
        JR   Z,L15DD      ; Jump to produce an error if a string result.

        SET  7,(IY+$01)   ; If so, indicate 'execution' mode.
        CALL L1636        ; Point to start of the BASIC command line.

        CALL L1586        ;
        LD   HL,L02C0     ; Set up the error handler routine address.
        LD   (SYNRET),HL  ; $5B8B.

        RST  28H          ;
        DEFW SCANNING     ; $24FB. Evaluate the command line.

;The 'Evaluate Operator Expression' routine joins here

L15B8:  BIT  6,(IY+$01)   ; FLAGS. Is it a numeric value?
        JR   Z,L15DD      ; Jump to produce an error if a string result.

        LD   DE,LASTV     ; $5B8D. DE points to last calculator value.
        LD   HL,($5C65)   ; STKEND.
        LD   BC,$0005     ; The length of the floating point value.
        OR   A            ;
        SBC  HL,BC        ; HL points to value on top of calculator stack.
        LDIR              ; Copy the value in the workspace to the top of the calculator stack.

        LD   A,$02        ; Main screen channel.
        RST  28H          ;
        DEFW CHAN_OPEN    ; $1601. Open the channel.

        RST  28H          ;
        DEFW PRINT_FP     ; $2DE3. Print the floating point number.

        LD   A,$0D        ; Print a newline character.
        RST  28H          ;
        DEFW PRINT_A_1    ; $0010.

L15D9:  POP  HL           ;
        JP   L02C0        ; Jump to the error handler routine.

L15DD:  CALL L0566        ; Produce error report.
        DEFB $19          ; "Q Parameter error"

; ----------------------------
; Evaluate Operator Expression
; ----------------------------
; This routine is called when a numerical expression is typed directly into the editor or calculator,
; beginning with: +, -, *, /, ^, =, >, <, <=, >=, <>, OR or AND.

L15E1:  LD   HL,$FFFE     ; A line in the editing area is considered as line '-2'.
        LD   ($5C45),HL   ; PPC. Signal no current line number.

;First the syntax of the operation is checked

        RES  7,(IY+$01)   ; FLAGS. Syntax checking.
        CALL L1636        ; Find start of the BASIC command.

        SET  6,(IY+$01)   ; FLAGS. Signal a numeric variable.

        LD   HL,L1604     ; Set the return address for the call to the evaluation routine within ROM 1.
        PUSH HL           ;
        LD   HL,SWAP      ; $5B00.
        PUSH HL           ;
        LD   B,$00        ; Set the lowest priority level for a dummy 'last' operation to force an immediate evaluation.
        PUSH BC           ;
        LD   HL,$2723     ; Stack the address of routine S_OPERTR in ROM 1.
        PUSH HL           ;
        JP   SWAP         ; $5B00. Page in ROM 1, returning to the stacked address.

;The return from the evaluation routine within ROM 1 to check syntax comes here
;so now perform the real evaluation

L1604:  SET  7,(IY+$01)   ; FLAGS. Not syntax checking.
        CALL L1636        ; Find start of the BASIC command.

        CALL L1586        ; Clear screen if it is not already clear.

        LD   HL,L02C0     ; Set up the error handler routine address.
        LD   (SYNRET),HL  ; $5B8B.

        LD   HL,L15B8     ; Set the return address for the call to the evaluation routine within ROM 1.
        PUSH HL           ;
        LD   HL,SWAP      ; $5B00.
        PUSH HL           ;
        LD   B,$00        ; Set the lowest priority level for a dummy 'last' operation to force an immediate evaluation.
        PUSH BC           ;

        LD   DE,($5C65)   ; STKEND.
        LD   HL,LASTV     ; $5B8D. HL points to last calculator value.
        LD   BC,$0005     ; The length of the floating point value.
        LDIR              ;
        LD   ($5C65),DE   ; STKEND.

        LD   HL,$2723     ; Stack the address of routine S_OPERTR in ROM 1.
        PUSH HL           ;
        JP   SWAP         ; $5B00.

; ---------------------------
; Find Start of BASIC Command
; ---------------------------
; Point to the start of a typed in BASIC command
; and return first character in A.

L1636:  LD   HL,($5C59)   ; E_LINE. Get the address of command being typed in.
        DEC  HL           ;
        LD   ($5C5D),HL   ; CH_ADD. Store it as the address of next character to be interpreted.
        RST  20H          ; Get the next character.
        RET               ;

; ----------------------
; Is Operator Character?
; ----------------------
; Exit: Zero flag set if character is an operator.

L163F:  LD   B,A          ; Save B.
        LD   HL,L1651     ; Start of operator token table.

L1643:  LD   A,(HL)       ; Fetch character from the table.
        INC  HL           ; Advance to next entry.
        OR   A            ; End of table?
        JR   Z,L164D      ; Jump if end of table reached.

        CP   B            ; Found required character?
        JR   NZ,L1643     ; Jump if not to try next character in table.

;Found

        LD   A,B          ; Restore character to A.
        RET               ; Return with zero flag set to indicate an operator.

;Not found

L164D:  OR   $FF          ; Reset zero flag to indicate not an operator.
        LD   A,B          ; Restore character to A.
        RET               ;

; ---------------------
; Operator Tokens Table
; ---------------------

L1651:  DEFB $2B, $2D, $2A  ; '+',  '-',  '*'
        DEFB $2F, $5E, $3D  ; '/',  '^',  '='
        DEFB $3E, $3C, $C7  ; '>',  '<',  '<='
        DEFB $C8, $C9, $C5  ; '>=', '<>', 'OR'
        DEFB $C6            ; 'AND'
        DEFB $00            ; End marker.

; ----------------------
; Is Function Character?
; ----------------------
; Exit: Zero set if a function token.

L165F:  CP   $A5          ; 'RND'. (first 48K token)
        JR   C,L1671      ; Jump ahead if not a token with zero flag reset.

        CP   $C4          ; 'BIN'.
        JR   NC,L1671     ; Jump ahead if not a function token.

        CP   $AC          ; 'AT'.
        JR   Z,L1671      ; Jump ahead if not a function token.

        CP   $AD          ; 'TAB'.
        JR   Z,L1671      ; Jump ahead if not a function token.

        CP   A            ; Return zero flag set if a function token.
        RET               ;

L1671:  CP   $A5          ; Return zero flag set if a function token.
        RET               ;

; ----------------------------------
; Is Numeric or Function Expression?
; ----------------------------------
; Exit: Zero flag set if a numeric or function expression.

L1674:  LD   B,A          ; Fetch character code.
        OR   $20          ; Make lowercase.
        CP   'a'          ; $61. Is it 'a' or above?
        JR   C,L1681      ; Jump ahead if not a letter.

#ifndef BUG_FIXES
        CP   $7A          ; [*BUG* - Should be $7B, as corrected in the UK Spectrum 128. Credit: Paul Farrow]
#else
        CP   $7B          ;@ [*BUG_FIX*]
#endif
L167D:  JR   NC,L1681     ; Jump ahead if not.

        CP   A            ; Character is a letter so return
        RET               ; with zero flag set.

L1681:  LD   A,B          ; Fetch character code.
        CP   '.'          ; $2E. Is it '.'?
        RET  Z            ; Return zero flag set indicating numeric.

        CALL L169E        ; Is character a number?
        JR   NZ,L169B     ; Jump ahead if not a number.

L168A:  RST  20H          ; Get next character.
        CALL L169E        ; Is character a number?
        JR   Z,L168A      ; Repeat for next character if numeric.

        CP   '.'          ; $2E. Is it '.'?
        RET  Z            ; Return zero flag set indicating numeric.

        CP   'E'          ; $45. Is it 'E'?
        RET  Z            ; Return zero flag set indicating  numeric.

        CP   'e'          ; $65. Is it 'e'?
        RET  Z            ; Return zero flag set indicating  numeric.

        JR   L163F        ; Jump to test for operator tokens.

L169B:  OR   $FF          ; Reset the zero flag to indicate non-alphanumeric.
        RET               ;

; ---------------------
; Is Numeric Character?
; ---------------------
; Exit: Zero flag set if numeric character.

L169E:  CP   '0'          ; $30. Is it below '0'?
        JR   C,L16A8      ; Jump below '0'.

        CP   ':'          ; $3A. Is it below ':'?
        JR   NC,L16A8     ; Jump above '9'

        CP   A            ;
        RET               ; Set zero flag if numeric.

L16A8:  CP   '0'          ; $30. This will cause zero flag to be reset.
        RET               ;

; ------------
; PLAY Routine
; ------------

L16AB:  LD   B,$00        ; String index.
        RST  18H          ;

L16AE:  PUSH BC           ;
        RST  28H          ; Get string expression.
        DEFW EXPT_EXP
        POP  BC           ;
        INC  B            ;
        CP   ','          ; $2C. A ',' indicates another string.
        JR   NZ,L16BB     ; Jump ahead if no more.

        RST  20H          ; Advance to the next character.
        JR   L16AE        ; Loop back.

L16BB:  LD   A,B          ; Check the index.
        CP   $09          ; Maximum of 8 strings (to support synthesisers, drum machines or sequencers).
        JR   C,L16C4      ;

        CALL L0566        ; Produce error report.
        DEFB $2B          ; "p Parameter Error"


L16C4:  CALL L188F        ; Ensure end-of-statement or end-of-line.
        JP   L093F        ; Continue with PLAY code.

; -----------------------
; The Syntax Offset Table
; -----------------------
; Similar in construction to the table in ROM 1 at $1A48.

L16CA:  DEFB $B1          ; DEF FN    -> $177B (ROM 0)
        DEFB $C9          ; CAT       -> $1794 (ROM 0)
        DEFB $BC          ; FORMAT    -> $1788 (ROM 0)
        DEFB $BE          ; MOVE      -> $178B (ROM 0)
        DEFB $C3          ; ERASE     -> $1791 (ROM 0)
        DEFB $AF          ; OPEN #    -> $177E (ROM 0)
        DEFB $B4          ; CLOSE #   -> $1784 (ROM 0)
        DEFB $93          ; MERGE     -> $1764 (ROM 0)
        DEFB $91          ; VERIFY    -> $1763 (ROM 0)
        DEFB $92          ; BEEP      -> $1765 (ROM 0)
        DEFB $95          ; CIRCLE    -> $1769 (ROM 0)
        DEFB $98          ; INK       -> $176D (ROM 0)
        DEFB $98          ; PAPER     -> $176E (ROM 0)
        DEFB $98          ; FLASH     -> $176F (ROM 0)
        DEFB $98          ; BRIGHT    -> $1770 (ROM 0)
        DEFB $98          ; INVERSE   -> $1771 (ROM 0)
        DEFB $98          ; OVER      -> $1772 (ROM 0)
        DEFB $98          ; OUT       -> $1773 (ROM 0)
        DEFB $7F          ; LPRINT    -> $175B (ROM 0)
        DEFB $81          ; LLIST     -> $175E (ROM 0)
        DEFB $2E          ; STOP      -> $170C (ROM 0)
        DEFB $6C          ; READ      -> $174B (ROM 0)
        DEFB $6E          ; DATA      -> $174E (ROM 0)
        DEFB $70          ; RESTORE   -> $1751 (ROM 0)
        DEFB $48          ; NEW       -> $172A (ROM 0)
        DEFB $94          ; BORDER    -> $1777 (ROM 0)
        DEFB $56          ; CONTINUE  -> $173A (ROM 0)
        DEFB $3F          ; DIM       -> $1724 (ROM 0)
        DEFB $41          ; REM       -> $1727 (ROM 0)
        DEFB $2B          ; FOR       -> $1712 (ROM 0)
        DEFB $17          ; GO TO     -> $16FF (ROM 0)
        DEFB $1F          ; GO SUB    -> $1708 (ROM 0)
        DEFB $37          ; INPUT     -> $1721 (ROM 0)
        DEFB $77          ; LOAD      -> $1762 (ROM 0)
        DEFB $44          ; LIST      -> $1730 (ROM 0)
        DEFB $0F          ; LET       -> $16FC (ROM 0)
        DEFB $59          ; PAUSE     -> $1747 (ROM 0)
        DEFB $2B          ; NEXT      -> $171A (ROM 0)
        DEFB $43          ; POKE      -> $1733 (ROM 0)
        DEFB $2D          ; PRINT     -> $171E (ROM 0)
        DEFB $51          ; PLOT      -> $1743 (ROM 0)
        DEFB $3A          ; RUN       -> $172D (ROM 0)
        DEFB $6D          ; SAVE      -> $1761 (ROM 0)
        DEFB $42          ; RANDOMIZE -> $1737 (ROM 0)
        DEFB $0D          ; IF        -> $1703 (ROM 0)  [No instruction fetch at $1708 hence ZX Interface 1 will not be paged in by this ROM. Credit: Paul Farrow].
        DEFB $49          ; CLS       -> $1740 (ROM 0)
        DEFB $5C          ; DRAW      -> $1754 (ROM 0)
        DEFB $44          ; CLEAR     -> $173D (ROM 0)
        DEFB $15          ; RETURN    -> $170F (ROM 0)
        DEFB $5D          ; COPY      -> $1758 (ROM 0)

; --------------------------
; The Syntax Parameter Table
; --------------------------
; Similar to the parameter table in ROM 1 at $1A7A.

L16FC:  DEFB $01          ; CLASS-01    LET
        DEFB '='          ; $3D. '='
        DEFB $02          ; CLASS-02

L16FF:  DEFB $06          ; CLASS-06    GO TO
        DEFB $00          ; CLASS-00
        DEFW GO_TO        ; $1E67. GO TO routine in ROM 1.

L1703:  DEFB $06          ; CLASS-06    IF
        DEFB $CB          ; 'THEN'
        DEFB $0E          ; CLASS-0E
        DEFW L1955        ; New IF routine in ROM 0.

L1708:  DEFB $06          ; CLASS-06    GO SUB
        DEFB $0C          ; CLASS-0C
        DEFW L1A41        ; New GO SUB routine in ROM 0.

L170C:  DEFB $00          ; CLASS-00    STOP
        DEFW STOP         ; $1CEE. STOP routine in ROM 1.

L170F:  DEFB $0C          ; CLASS-0C    RETURN
        DEFW L1A5D        ; New RETURN routine in ROM 0.

L1712:  DEFB $04          ; CLASS-04    FOR
        DEFB '='          ; $3D. '='
        DEFB $06          ; CLASS-06
        DEFB $CC          ; 'TO'
        DEFB $06          ; CLASS-06
        DEFB $0E          ; CLASS-0E
        DEFW L196F        ; New FOR routine in ROM 0.

L171A:  DEFB $04          ; CLASS-04    NEXT
        DEFB $00          ; CLASS-00
        DEFW NEXT         ; $1DAB. NEXT routine in ROM 1.

L171E:  DEFB $0E          ; CLASS-0E    PRINT
        DEFW L150F        ; New PRINT routine in ROM 0.

L1721:  DEFB $0E          ; CLASS-0E    INPUT
        DEFW L1523        ; New INPUT routine in ROM 0.

L1724:  DEFB $0E          ; CLASS-0E    DIM
        DEFW L156C        ; New DIM routine in ROM 0.

L1727:  DEFB $0E          ; CLASS-0E    REM
        DEFW L1850        ; New REM routine in ROM 0.

L172A:  DEFB $0C          ; CLASS-0C    NEW
        DEFW L1541        ; New NEW routine in ROM 0.

L172D:  DEFB $0D          ; CLASS-0D    RUN
        DEFW L19F0        ; New RUN routine in ROM 0.

L1730:  DEFB $0E          ; CLASS-0E    LIST
        DEFW L1B04        ; New LIST routine in ROM 0.

L1733:  DEFB $08          ; CLASS-08    POKE
        DEFB $00          ; CLASS-00
        DEFW POKE         ; $1E80. POKE routine in ROM 1.

L1737:  DEFB $03          ; CLASS-03    RANDOMIZE
        DEFW RANDOMIZE    ; $1E4F. RANDOMIZE routine in ROM 1.

L173A:  DEFB $00          ; CLASS-00    CONTINUE
        DEFW CONTINUE     ; $1E5F. CONTINUE routine in ROM 1.

L173D:  DEFB $0D          ; CLASS-0D    CLEAR
        DEFW L19FB        ; New CLEAR routine in ROM 0.

L1740:  DEFB $00          ; CLASS-00    CLS
        DEFW CLS          ; $0D6B. CLS routine in ROM 1.

L1743:  DEFB $09          ; CLASS-09    PLOT
        DEFB $00          ; CLASS-00
        DEFW PLOT         ; $22DC. PLOT routine in ROM 1

L1747:  DEFB $06          ; CLASS-06    PAUSE
        DEFB $00          ; CLASS-00
        DEFW PAUSE        ; $1F3A. PAUSE routine in ROM 1.

L174B:  DEFB $0E          ; CLASS-0E    READ
        DEFW L1999        ; New READ routine in ROM 0.

L174E:  DEFB $0E          ; CLASS-0E    DATA
        DEFW L19D9        ; New DATA routine in ROM 0.

L1751:  DEFB $03          ; CLASS-03    RESTORE
        DEFW RESTORE      ; $1E42. RESTORE routine in ROM 1.

L1754:  DEFB $09          ; CLASS-09    DRAW
        DEFB $0E          ; CLASS-0E
        DEFW L1555        ; New DRAW routine in ROM 0.

L1758:  DEFB $0C          ; CLASS-0C    COPY
        DEFW L153E        ; New COPY routine in ROM 0.

L175B:  DEFB $0E          ; CLASS-0E    LPRINT
        DEFW L150B        ; New LPRINT routine in ROM 0.

L175E:  DEFB $0E          ; CLASS-0E    LLIST
        DEFW L1B00        ; New LLIST routine in ROM 0.

L1761:  DEFB $0B          ; CLASS-0B    SAVE

L1762:  DEFB $0B          ; CLASS-0B    LOAD

L1763:  DEFB $0B          ; CLASS-0B    VERIFY

L1764:  DEFB $0B          ; CLASS-0B    MERGE

L1765:  DEFB $08          ; CLASS-08    BEEP
        DEFB $00          ; CLASS-00
        DEFW BEEP         ; $03F8. BEEP routine in ROM 1.

L1769:  DEFB $09          ; CLASS-09    CIRCLE
        DEFB $0E          ; CLASS-0E
        DEFW L1545        ; New CIRCLE routine in ROM 0.

L176D:  DEFB $07          ; CLASS-07    INK

L176E:  DEFB $07          ; CLASS-07    PAPER

L176F:  DEFB $07          ; CLASS-07    FLASH

L1770:  DEFB $07          ; CLASS-07    BRIGHT

L1771:  DEFB $07          ; CLASS-07    INVERSE

L1772:  DEFB $07          ; CLASS-07    OVER

L1773:  DEFB $08          ; CLASS-08    OUT
        DEFB $00          ; CLASS-00
        DEFW COUT         ; $1E7A. OUT routine in ROM 1.

L1777:  DEFB $06          ; CLASS-06    BORDER
        DEFB $00          ; CLASS-00
        DEFW BORDER       ; $2294. BORDER routine in ROM 1.

L177B:  DEFB $0E          ; CLASS-0E    DEF FN
        DEFW L1A7A        ; New DEF FN routine in ROM 0.

L177E:  DEFB $06          ; CLASS-06    OPEN #
        DEFB ','          ; $2C. ','
        DEFB $0A          ; CLASS-0A
        DEFB $00          ; CLASS-00
        DEFW OPEN         ; $1736. OPEN # routine in ROM 1.

L1784:  DEFB $06          ; CLASS-06    CLOSE #
        DEFB $00          ; CLASS-00
        DEFW CLOSE        ; $16E5. CLOSE # routine in ROM 1.

L1788:  DEFB $0E          ; CLASS-0E    FORMAT
        DEFW L05FB        ; FORMAT routine in ROM 0.

L178B:  DEFB $0A          ; CLASS-0A    MOVE
        DEFB ','          ; $2C. ','
        DEFB $0A          ; CLASS-0A
        DEFB $0C          ; CLASS-0C
        DEFW L1ADE        ; Just execute a RET.

L1791:  DEFB $0E          ; CLASS-0E    ERASE
        DEFW L1B9B        ; New ERASE routine in ROM 0.

L1794:  DEFB $0E          ; CLASS-0E    CAT
        DEFW L1B74        ; New CAT routine in ROM 0.

L1797:  DEFB $0C          ; CLASS-0C    SPECTRUM
        DEFW L1ADF        ; SPECTRUM routine in ROM 0.

L179A:  DEFB $0E          ; CLASS-0E    PLAY
        DEFW L16AB        ; PLAY routine in ROM 0.

; (From Logan & O'Hara's 48K ROM disassembly):
; The requirements for the different command classes are as follows:
; CLASS-00 - No further operands.
; CLASS-01 - Used in LET. A variable is required.
; CLASS-02 - Used in LET. An expression, numeric or string, must follow.
; CLASS-03 - A numeric expression may follow. Zero to be used in case of default.
; CLASS-04 - A single character variable must follow.
; CLASS-05 - A set of items may be given.
; CLASS-06 - A numeric expression must follow.
; CLASS-07 - Handles colour items.
; CLASS-08 - Two numeric expressions, separated by a comma, must follow.
; CLASS-09 - As for CLASS-08 but colour items may precede the expressions.
; CLASS-0A - A string expression must follow.
; CLASS-0B - Handles cassette/RAM disk routines.

; In addition the 128 adds the following classes:
; CLASS-0C - Like class 00 but calling ROM 0. (Used by SPECTRUM, MOVE, COPY, NEW, GO SUB, RETURN)
; CLASS-0D - Like class 06 but calling ROM 0. (Used by CLEAR, RUN)
; CLASS-0E - Handled in ROM 0. (Used by PLAY, ERASE, CAT, FORMAT, CIRCLE, LPRINT, LLIST, DRAW, DATA, READ, LIST, DIM, INPUT, PRINT, FOR, IF)

; ------------------------------------------
; The 'Main Parser' Of the BASIC Interpreter
; ------------------------------------------
; The parsing routine of the BASIC interpreter is entered at $179D (ROM 0) when syntax is being checked,
; and at $1826 (ROM 0) when a BASIC program of one or more statements is to be executed.
; This code is similar to that in ROM 1 at $1B17.

L179D:  RES  7,(IY+$01)   ; FLAGS. Signal 'syntax checking'.
        RST  28H          ;
        DEFW E_LINE_NO    ; $19FB. CH-ADD is made to point to the first code after any line number
        XOR  A            ;
        LD   ($5C47),A    ; SUBPPC. Set to $00.
        DEC  A            ;
        LD   ($5C3A),A    ; ERR_NR. Set to $FF.
        JR   L17AF        ; Jump forward to consider the first statement of the line.

; ------------------
; The Statement Loop
; ------------------
; Each statement is considered in turn until the end of the line is reached.

L17AE:  RST  20H          ; Advance CH-ADD along the line.

L17AF:  RST  28H          ;
        DEFW SET_WORK     ; $16BF. The work space is cleared.
        INC  (IY+$0D)     ; SUBPPC. Increase SUBPPC on each passage around the loop.
        JP   M,L1900      ; Only '127' statements are allowed in a single line. Jump to report "C Nonsense in BASIC".

        RST  18H          ; Fetch a character.
        LD   B,$00        ; Clear the register for later.
        CP   $0D          ; Is the character a 'carriage return'?
        JP   Z,L1851      ; jump if it is.

        CP   ':'          ; $3A. Go around the loop again if it is a ':'.
        JR   Z,L17AE      ;

;A statement has been identified so, first, its initial command is considered

        LD   HL,L180F     ; Pre-load the machine stack with the return address.
        PUSH HL           ;

        LD   C,A          ; Save the command temporarily
        RST  20H          ; in the C register whilst CH-ADD is advanced again.
        LD   A,C          ;
        SUB  $CE          ; Reduce the command's code by $CE giving the range indexed from $00.
        JR   NC,L17E2     ; Jump for DEF FN and above.

        ADD  A,$CE        ;
        LD   HL,L1797     ;
        CP   $A3          ; Is it 'SPECTRUM'?
        JR   Z,L17EE      ; Jump if so into the scanning loop with this address.

        LD   HL,L179A     ;
        CP   $A4          ; Is it 'PLAY'?
        JR   Z,L17EE      ; Jump if so into the scanning loop with this address.

        JP   L1900        ; Produce error report "C Nonsense in BASIC".

L17E2:  LD   C,A          ; Move the command code to BC (B holds $00).
        LD   HL,L16CA     ; The base address of the syntax offset table.
        ADD  HL,BC        ;
        LD   C,(HL)       ;
        ADD  HL,BC        ; Find address for the command's entries in the parameter table.
        JR   L17EE        ; Jump forward into the scanning loop with this address.

;Each of the command class routines applicable to the present command are executed in turn.
;Any required separators are also considered.

L17EB:  LD   HL,($5C74)   ; T_ADDR. The temporary pointer to the entries in the parameter table.

L17EE:  LD   A,(HL)       ; Fetch each entry in turn.
        INC  HL           ; Update the pointer to the entries for the next pass.
        LD   ($5C74),HL   ; T_ADDR.

        LD   BC,L17EB     ; Pre-load the machine stack with the return address.
        PUSH BC           ;

        LD   C,A          ; Copy the entry to the C register for later.
        CP   $20          ;
        JR   NC,L1808     ; Jump forward if the entry is a 'separator'.

        LD   HL,L18A3     ; The base address of the 'command class' table.
        LD   B,$00        ;
        ADD  HL,BC        ; Index into the table.
        LD   C,(HL)       ;
        ADD  HL,BC        ; HL=base + code + (base + code).
        PUSH HL           ; HL=The starting address of the required command class routine.

        RST  18H          ; Before making an indirect jump to the command class routine pass the command code
        DEC  B            ; to the A register and set the B register to $FF.
        RET               ; Return to the stacked address.

; --------------------------
; The 'Separator' Subroutine
; --------------------------
; The report 'Nonsense in BASIC is given if the required separator is not present.
; But note that when syntax is being checked the actual report does not appear on the screen - only the 'error marker'.
; This code is similar to that in ROM 1 at $1B6F.

L1808:  RST  18H          ; The current character is
        CP   C            ; fetched and compared to the entry in the parameter table.
        JP   NZ,L1900     ; Give the error report if there is not a match.

        RST  20H          ; Step past a correct character
        RET               ; and return.

; ---------------------------------
; The 'Statement Return' Subroutine
; ---------------------------------
; After the correct interpretation of a statement, a return is made to this entry point.
; This code is similar to that in ROM 1 at $1B76.

L180F:  CALL L0590        ; Check for BREAK
        JR   C,L1818      ; Jump if pressed.

        CALL L0566        ; Produce error report.
        DEFB $14          ; "L Break into program"

L1818:  BIT  7,(IY+$0A)   ; NSPPC - statement number in line to be jumped to
        JP   NZ,L1896     ; Jump forward if there is not a 'jump' to be made.

        LD   HL,($5C42)   ; NEWPPC, line number to be jumped to.
        BIT  7,H          ;
        JR   Z,L183A      ; Jump forward unless dealing with a further statement in the editing area.

; --------------------------
; The 'Line Run' Entry Point
; --------------------------
; This entry point is used wherever a line in the editing area is to be 'run'.
; In such a case the syntax/run flag (bit 7 of FLAGS) will be set.
; The entry point is also used in the syntax checking of a line in the editing area
; that has more than one statement (bit 7 of FLAGS will be reset).
; This code is similar to that in ROM 1 at $1B8A.

L1826:  LD   HL,$FFFE     ; A line in the editing area is considered as line '-2'.
        LD   ($5C45),HL   ; PPC.

        LD   HL,($5C61)   ; WORKSP. Make HL point to the end marker of the editing area.
        DEC  HL           ;
        LD   DE,($5C59)   ; E_LINE. Make DE point to the location before the end marker of the editing area.
        DEC  DE           ;
        LD   A,($5C44)    ; NSPPC. Fetch the number of the next statement to be handled.
        JR   L1870        ; Jump forward.

; -------------------------
; The 'Line New' Subroutine
; -------------------------
; There has been a jump in the program and the starting address of the new line has to be found.
; This code is similar to that in ROM 1 at 1B9E.

L183A:  RST  28H          ;
        DEFW LINE_ADDR    ; $196E. The starting address of the line, or the 'first line after' is found.
        LD   A,($5C44)    ; NSPPC. Collect the statement number.
        JR   Z,L185E      ; Jump forward if the required line was found.

        AND  A            ; Check the validity of the statement number - must be zero.
        JR   NZ,L188B     ; Jump if not to produce error report "N Statement lost".

        LD   B,A          ; Also check that the 'first
        LD   A,(HL)       ; line after' is not after the
        AND  $C0          ; actual 'end of program'.
        LD   A,B          ;
        JR   Z,L185E      ; Jump forward with valid addresses; otherwise signal the error 'OK'.

        CALL L0566        ; Produce error report.
        DEFB $FF          ; "0 OK"

; -----------
; REM Routine
; -----------
; The return address to STMT-RET is dropped which has the effect of forcing the rest of the
; line to be ignored.
; This code is similar to that in ROM 1 at $1BB2.

L1850:  POP  BC           ; Drop the statement return address.

; ----------------------
; The 'Line End' Routine
; ----------------------
; If checking syntax a simple return is made but when 'running' the address held by NXTLIN
; has to be checked before it can be used.
; This code is similar to that in ROM 1 at $1BB3.

L1851:  BIT  7,(IY+$01)   ;
        RET  Z            ; Return if syntax is being checked.

        LD   HL,($5C55)   ; NXTLIN.
        LD   A,$C0        ; Return if the address is after the end of the program - the 'run' is finished.
        AND  (HL)         ;
        RET  NZ           ;

        XOR  A            ; Signal 'statement zero' before proceeding.

; ----------------------
; The 'Line Use' Routine
; ----------------------
; This  routine has three functions:
;  i.  Change statement zero to statement '1'.
;  ii.  Find the number of the new line and enter it into PPC.
;  iii. Form the address of the start of the line after.
; This code is similar to that in ROM 1 at $1BBF.

L185E:  CP   $01          ; Statement zero becomes statement 1.
        ADC  A,$00        ;
        LD   D,(HL)       ; The line number of the line to be used is collected and
        INC  HL           ; passed to PPC.
        LD   E,(HL)       ;
        LD   ($5C45),DE   ; PPC.
        INC  HL           ;
        LD   E,(HL)       ; Now find the 'length' of the line.
        INC  HL           ;
        LD   D,(HL)       ;
        EX   DE,HL        ; Switch over the values.
        ADD  HL,DE        ; Form the address of the start of the line after in HL and the
        INC  HL           ; location before the 'next' line's first character in DE.

; -----------------------
; The 'Next Line' Routine
; -----------------------
; On entry the HL register pair points to the location after the end of the 'next' line
; to be handled and the DE register pair to the location before the first character of the line.
; This applies to lines in the program area and also to a line in the editing area - where the
; next line will be the same line again whilst there are still statements to be interpreted.
; This code is similar to that in ROM 1 at $1BD1.

L1870:  LD   ($5C55),HL   ; NXTLIN. Set NXTLIN for use once the current line has been completed.
        EX   DE,HL        ;
        LD   ($5C5D),HL   ; CH_ADD. CH_ADD points to the location before the first character to be considered.
        LD   D,A          ; The statement number is fetched.
        LD   E,$00        ; The E register is cleared in case the 'Each Statement' routine is used.
        LD   (IY+$0A),$FF ; NSPPC. Signal 'no jump'.
        DEC  D            ;
        LD   (IY+$0D),D   ; SUB_PPC. Statement number-1.
        JP   Z,L17AE      ; Jump if the first statement.

        INC  D            ; For later statements the 'starting address' has to be found.
        RST  28H          ;
        DEFW EACH_STMT    ; $198B.
        JR   Z,L1896      ; Jump forward unless the statement does not exist.

L188B:  CALL L0566        ; Produce error report.
        DEFB $16          ; "N Statement lost"

; --------------------------
; The 'CHECK-END' Subroutine
; --------------------------
; This is called when the syntax of the edit-line is being checked. The purpose of the routine is to
; give an error report if the end of a statement has not been reached and to move on to the next
; statement if the syntax is correct.
; The routine is the equivalent of routine CHECK_END in ROM 1 at $1BEE.

L188F:  BIT  7,(IY+$01)   ; Very like CHECK-END at 1BEE in ROM 1
        RET  NZ           ; Return unless checking syntax.

        POP  BC           ; Drop scan loop and statement return addresses.
        POP  BC           ;

; -----------------------
; The 'STMT-NEXT' Routine
; -----------------------
; If the present character is a 'carriage return' then the 'next statement' is on the 'next line',
; if ':' it is on the same line; but if any other character is found then there is an error in syntax.
; The routine is the equivalent of routine STMT_NEXT in ROM 1 at $1BF4.

L1896:  RST  18H          ; Fetch the present character.
        CP   $0D          ; Consider the 'next line' if
        JR   Z,L1851      ; it is a 'carriage return'.

        CP   ':'          ; $3A. Consider the 'next statement'
        JP   Z,L17AE      ; if it is a ':'.

        JP   L1900        ; Otherwise there has been a syntax error so produce "C Nonsense in BASIC".

; -------------------------
; The 'Command Class' Table
; -------------------------

L18A3:  DEFB L18C7-$      ; CLASS-00 -> $18C7 (ROM 0) = $24
        DEFB L18E7-$      ; CLASS-01 -> $18E7 (ROM 0) = $43
        DEFB L18EB-$      ; CLASS-02 -> $18EB (ROM 0) = $46
        DEFB L18C4-$      ; CLASS-03 -> $18C4 (ROM 0) = $1E
        DEFB L18F3-$      ; CLASS-04 -> $18F3 (ROM 0) = $4C
        DEFB L18C8-$      ; CLASS-05 -> $18C8 (ROM 0) = $20
        DEFB L18FC-$      ; CLASS-06 -> $18FC (ROM 0) = $53
        DEFB L1908-$      ; CLASS-07 -> $1908 (ROM 0) = $5E
        DEFB L18F8-$      ; CLASS-08 -> $18F8 (ROM 0) = $4D
        DEFB L1932-$      ; CLASS-09 -> $1932 (ROM 0) = $86
        DEFB L1904-$      ; CLASS-0A -> $1904 (ROM 0) = $57
        DEFB L1936-$      ; CLASS-0B -> $1936 (ROM 0) = $88
        DEFB L18B5-$      ; CLASS-0C -> $18B5 (ROM 0) = $06
        DEFB L18B2-$      ; CLASS-0D -> $18B2 (ROM 0) = $02
        DEFB L18B6-$      ; CLASS-0E -> $18B6 (ROM 0) = $05

; -----------------------------------
; The 'Command Classes - 0C, 0D & 0E'
; -----------------------------------
; For commands of class-0D a numeric expression must follow.

L18B2:  RST  28H          ; Code 0D enters here.
        DEFW FETCH_NUM    ; $1CDE.

;The commands of class-0C must not have any operands. e.g. SPECTRUM.

L18B5:  CP   A            ; Code 0C enters here. Set zero flag.

;The commands of class-0E may be followed by a set of items. e.g. PLAY.

L18B6:  POP  BC           ; Code 0E enters here.
                          ; Retrieve return address.
        CALL Z,L188F      ; If handling commands of classes 0C & 0D and syntax is being
                          ; checked move on now to consider the next statement.
        EX   DE,HL        ; Save the line pointer in DE.

; After the command class entries and the separator entries in the parameter table have
; been considered the jump to the appropriate command routine is made.
; The routine is similar to JUMP-C-R in ROM 1 at $1C16.

        LD   HL,($5C74)   ; T_ADDR.
        LD   C,(HL)       ; Fetch the pointer to the entries in the parameter table
        INC  HL           ; and fetch the address of the
        LD   B,(HL)       ; required command routine.
        EX   DE,HL        ; Exchange the pointers back.
        PUSH BC           ; Make an indirect jump to the command routine.
        RET               ;

; -----------------------------------
; The 'Command Classes - 00, 03 & 05'
; -----------------------------------
; These routines are the equivalent of the routines in ROM 1 starting at $1C0D.

; The commands of class-03 may, or may not, be followed by a number. e.g. RUN & RUN 200.

L18C4:  RST  28H          ; Code 03 enters here.
        DEFW FETCH_NUM    ; $1CDE. A number is fetched but zero is used in cases of default.

;The commands of class-00 must not have any operands. e.g. COPY & CONTINUE.

L18C7:  CP   A            ; Code 00 enters here. Set the zero flag.

;The commands of class-05 may be followed by a set of items. e.g. PRINT & PRINT "222".

L18C8:  POP  BC           ; Code 05 enters here. Drop return address.
        CALL Z,L188F      ; If handling commands of classes 00 & 03 and syntax is being
                          ; checked move on now to consider the next statement.
        EX   DE,HL        ; Save the line pointer in DE.

        LD   HL,($5C74)   ; T_ADDR. Fetch the pointer to the entries in the parameter table.
        LD   C,(HL)       ;
        INC  HL           ;
        LD   B,(HL)       ; Fetch the address of the required command routine.
        EX   DE,HL        ; Exchange the pointers back.
        PUSH HL           ; Save command routine address.

        LD   HL,L18E6     ; The address to return to (the RET below).
        LD   (RETADDR),HL ; $5B5A. Store the return address.
        LD   HL,YOUNGER   ; $5B14. Paging subroutine.
        EX   (SP),HL      ; Replace the return address with the address of the YOUNGER routine.
        PUSH HL           ; Save the original top stack item.
        LD   H,B          ;
        LD   L,C          ; HL=Address of command routine.
        EX   (SP),HL      ; Put onto the stack so that an indirect jump will be made to it.
        JP   SWAP         ; $5B00. Switch to other ROM and 'return' to the command routine.

;Comes here after ROM 1 has been paged in, the command routine called, ROM 0 paged back in.

L18E6:  RET               ; Simply make a return.

; ------------------------
; The 'Command Class - 01'
; ------------------------
; Command class 01 is concerned with the identification of the variable in a LET, READ or INPUT statement.

L18E7:  RST  28H          ; Delegate handling to ROM 1.
        DEFW CLASS_01     ; $1C1F.
        RET               ;

; ------------------------
; The 'Command Class - 02'
; ------------------------
; Command class 02 is concerned with the actual calculation of the value to be assigned in a LET statement.

L18EB:  POP  BC           ; Code 02 enters here. Delegate handling to ROM 1.
        RST  28H          ;
        DEFW VAL_FET_1    ; $1C56. "... used by LET, READ and INPUT statements to
                          ;         first evaluate and then assign values to the
                          ;         previously designated variable" (Logan/O'Hara)
        CALL L188F        ; Move on to the next statement if checking syntax
        RET               ; else return here.

; ------------------------
; The 'Command Class - 04'
; ------------------------
; The command class 04 entry point is used by FOR & NEXT statements.

L18F3:  RST  28H          ; Code 04 enters here. Delegate handling to ROM 1.
        DEFW CLASS_04     ; $1C6C.
        RET               ;

; ------------------------
; The 'Command Class - 08'
; ------------------------
; Command class 08 allows for two numeric expressions, separated by a comma, to be evaluated.

L18F7:  RST  20H          ; [Redundant byte]

L18F8:  RST  28H          ; Delegate handling to ROM 1.
        DEFW EXPT_2NUM    ; $1C7A.
        RET               ;

; ------------------------
; The 'Command Class - 06'
; ------------------------
; Command class 06 allows for a single numeric expression to be evaluated.

L18FC:  RST  28H          ; Code 06 enters here. Delegate handling to ROM 1.
        DEFW EXPT_1NUM    ; $1C82.
        RET               ;

; ----------------------------
; Report C - Nonsense in BASIC
; ----------------------------
; This is a duplication of the code at $11F5 (ROM 0) and $1582 (ROM 0).

L1900:  CALL L0566        ; Produce error report.
        DEFB $0B          ; "C Nonsense in BASIC"

; ------------------------
; The 'Command Class - 0A'
; ------------------------
; Command class 0A allows for a single string expression to be evaluated.

L1904:  RST  28H          ; Code 0A enters here. Delegate handling to ROM 1.
        DEFW EXPT_EXP     ; $1C8C.
        RET               ;

; ------------------------
; The 'Command Class - 07'
; ------------------------
; Command class 07 is the command routine for the six colour item commands.
; Makes the current temporary colours permanent.

L1908:  BIT  7,(IY+$01)   ; The syntax/run flag is read.
        RES  0,(IY+$02)   ; TV_FLAG. Signal 'main screen'.
        JR   Z,L1915      ; Jump ahead if syntax checking.

        RST  28H          ; Only during a 'run' call TEMPS to ensure the temporary
        DEFW TEMPS        ; $0D4D.   colours are the main screen colours.

L1915:  POP  AF           ; Drop the return address.
        LD   A,($5C74)    ; T_ADDR.
        SUB  (L176D & $00FF)+$28 ; Reduce to range $D9-$DE which are the token codes for INK to OVER.
        RST  28H          ;
        DEFW CO_TEMP_4    ; $21FC. Change the temporary colours as directed by the BASIC statement.
        CALL L188F        ; Move on to the next statement if checking syntax.

        LD   HL,($5C8F)   ; ATTR_T. Now the temporary colour
        LD   ($5C8D),HL   ; ATTR_P.   values are made permanent
        LD   HL,$5C91     ; P_FLAG.
        LD   A,(HL)       ; Value of P_FLAG also has to be considered.

;The following instructions cleverly copy the even bits of the supplied byte to the odd bits.
;In effect making the permanent bits the same as the temporary ones.

        RLCA              ; Move the mask leftwards.
        XOR  (HL)         ; Impress onto the mask
        AND  $AA          ; only the even bits of the
        XOR  (HL)         ; other byte.
        LD   (HL),A       ; Restore the result.
        RET               ;

; ------------------------
; The 'Command Class - 09'
; ------------------------
; This routine is used by PLOT, DRAW & CIRCLE statements in order to specify the default conditions
; of 'FLASH 8; BRIGHT 8; PAPER 8;' that are set up before any embedded colour items are considered.

L1932:  RST  28H          ; Code 09 enters here. Delegate handling to ROM 1.
        DEFW CLASS_09     ; $1CBE.
        RET

; ------------------------
; The 'Command Class - 0B'
; ------------------------
; This routine is used by SAVE, LOAD, VERIFY & MERGE statements.

L1936:  POP  AF           ; Drop the return address.

        LD   A,(FLAGS3)   ; $5B66.
        AND  $0F          ; Clear LOAD/SAVE/VERIFY/MERGE indication bits.
        LD   (FLAGS3),A   ; $5B66.

        LD   A,($5C74)    ; T_ADDR-lo.
        SUB  1+(L1761 & $00FF) ; Correct by $74 so that SAVE = $00, LOAD = $01, VERIFY = $02, MERGE = $03.
        LD   ($5C74),A    ; T_ADDR-lo.
        JP   Z,L11C7      ; Jump to handle SAVE.

        DEC  A            ;
        JP   Z,L11CE      ; Jump to handle LOAD.

        DEC  A            ;
        JP   Z,L11D5      ; Jump to handle VERIFY.

        JP   L11DC        ; Jump to handle MERGE.

; ----------
; IF Routine
; ----------
; On entry the value of the expression between the IF and the THEN is the
; 'last value' on the calculator stack. If this is logically true then the next
; statement is considered; otherwise the line is considered to have been finished.

L1955:  POP  BC           ; Drop the return address.
        BIT  7,(IY+$01)   ;
        JR   Z,L196C      ; Jump forward if checking syntax.

;Now 'delete' the last value on the calculator stack

L195C:  LD   HL,($5C65)   ; STKEND.
        LD   DE,$FFFB     ; -5
        ADD  HL,DE        ; The present 'last value' is deleted.
        LD   ($5C65),HL   ; STKEND. HL point to the first byte of the value.
        RST  28H          ;
        DEFW TEST_ZERO    ; $34E9. Is the value zero?
        JP   C,L1851      ; If the value was 'FALSE' jump to the next line.

L196C:  JP   L17AF        ; But if 'TRUE' jump to the next statement (after the THEN).

; -----------
; FOR Routine
; -----------
; This command routine is entered with the VALUE and the LIMIT of the FOR statement already
; on the top of the calculator stack.

L196F:  CP   $CD          ; Jump forward unless a 'STEP' is given.
        JR   NZ,L197C     ;

        RST  20H          ; Advance pointer
        CALL L18FC        ; Indirectly call EXPT_1NUM in ROM 1 to get the value of the STEP.
        CALL L188F        ; Move on to the next statement if checking syntax.
        JR   L1994        ; Otherwise jump forward.

;There has not been a STEP supplied so the value '1' is to be used.

L197C:  CALL L188F        ; Move on to the next statement if checking syntax.
        LD   HL,($5C65)   ; STKEND.
        LD   (HL),$00     ;
        INC  HL           ;
        LD   (HL),$00     ;
        INC  HL           ;
        LD   (HL),$01     ;
        INC  HL           ;
        LD   (HL),$00     ;
        INC  HL           ;
        LD   (HL),$00     ; Place a value of 1 on the calculator stack.
        INC  HL           ;
        LD   ($5C65),HL   ; STKEND.

;The three values on the calculator stack are the VALUE (v), the LIMIT (l) and the STEP (s).
;These values now have to be manipulated. Delegate handling to ROM 1.

L1994:  RST  28H          ;
        DEFW F_REORDER    ; $1D16.
        RET               ;

; ------------
; READ Routine
; ------------

L1998:  RST  20H          ; Come here on each pass, after the first, to move along the READ statement.

L1999:  CALL L18E7        ; Indirectly call CLASS_01 in ROM 1 to consider whether the variable has
                          ; been used before, and find the existing entry if it has.
        BIT  7,(IY+$01)   ;
        JR   Z,L19D0      ; Jump forward if checking syntax.

        RST  18H          ; Save the current pointer CH_ADD in X_PTR.
        LD   ($5C5F),HL   ; X_PTR.

        LD   HL,($5C57)   ; DATADD.
        LD   A,(HL)       ; Fetch the current DATA list pointer
        CP   $2C          ; and jump forward unless a new
        JR   Z,L19B9      ; DATA statement has to be found.

        LD   E,$E4        ; The search is for 'DATA'.
        RST  28H          ;
        DEFW LOOK_PROG    ; $1D86.
        JR   NC,L19B9     ; Jump forward if the search is successful.

        CALL L0566        ; Produce error report.
        DEFB $0D          ; "E Out of Data"

; Pick up a value from the DATA list.

L19B9:  INC  HL           ; Advance the pointer along the DATA list.
        LD   ($5C5D),HL   ; CH_ADD.
        LD   A,(HL)       ;
        RST  28H          ;
        DEFW VAL_FET_1    ; $1C56. Fetch the value and assign it to the variable.
        RST  18H          ;

        LD   ($5C57),HL   ; DATADD.
        LD   HL,($5C5F)   ; X_PTR. Fetch the current value of CH_ADD and store it in DATADD.

        LD   (IY+$26),$00 ; X_PTR_hi. Clear X_PTR.
        LD   ($5C5D),HL   ; CH_ADD. Make CH-ADD once again point to the READ statement.
        LD   A,(HL)       ;

L19D0:  RST  18H          ; GET the present character
        CP   ','          ; $2C. Check if it is a ','.

L19D3:  JR   Z,L1998      ; If it is then jump back as there are further items.

        CALL L188F        ; Return if checking syntax
        RET               ; or here if not checking syntax.

; ------------
; DATA Routine
; ------------
; During syntax checking a DATA statement is checked to ensure that it contains a series
; of valid expressions, separated by commas. But in 'run-time' the statement is passed by.

L19D9:  BIT  7,(IY+$01)   ; Jump forward unless checking syntax.
        JR   NZ,L19EA     ;

;A loop is now entered to deal with each expression in the DATA statement.

L19DF:  RST  28H          ;
        DEFW SCANNING     ; $24FB. Scan the next expression.
        CP   ','          ; $2C. Check for the correct separator ','.
        CALL NZ,L188F     ; but move on to the next statement if not matched.
        RST  20H          ; Whilst there are still expressions to be checked
        JR   L19DF        ; go around again.

;The DATA statement has to be passed-by in 'run-time'.

L19EA:  LD   A,$E4        ; It is a 'DATA' statement that is to be passed-by.

;On entry the A register will hold either the token 'DATA' or the token 'DEF FN'
;depending on the type of statement that is being 'passed-by'.

L19EC:  RST  28H          ;
        DEFW PASS_BY      ; $1E39. Delegate handling to ROM 1.
        RET

; -----------
; RUN Routine
; -----------
; The parameter of the RUN command is passed to NEWPPC by calling the GO TO command routine.
; The operations of 'RESTORE 0' and 'CLEAR 0' are then performed before a return is made.

L19F0:  RST  28H
        DEFW GO_TO        ; $1E67.

        LD BC,$0000       ; Now perform a 'RESTORE 0'.
        RST  28H
        DEFW REST_RUN     ; $1E45.
        JR   L19FE        ; Exit via the CLEAR command routine.

; -------------
; CLEAR Routine
; -------------
; This routine allows for the variables area to be cleared, the display area cleared
; and RAMTOP moved. In consequence of the last operation the machine stack is rebuilt
; thereby having the effect of also clearing the GO SUB stack.

L19FB:  RST  28H          ;
        DEFW FIND_INT2    ; $1E99. Fetch the operand - using zero by default.

L19FE:  LD   A,B          ; Jump forward if the operand is
        OR   C            ; other than zero. When called
        JR   NZ,L1A06     ; from RUN there is no jump.

        LD   BC,($5CB2)   ; RAMTOP. Use RAMTOP if the parameter is 0.

L1A06:  PUSH BC           ; BC = Address to clear to. Save it.
        LD   DE,($5C4B)   ; VARS.
        LD   HL,($5C59)   ; E LINE.
        DEC  HL           ;
        RST  28H          ; Delete the variables area.
        DEFW RECLAIM      ; $19E5.
        RST  28H          ; Clear the screen
        DEFW CLS          ; $0D6B.

;The value in the BC register pair which will be used as RAMTOP is tested to ensure it
;is neither too low nor too high.

        LD   HL,($5C65)   ; STKEND. The current value of STKEND
        LD   DE,$0032     ; is increased by 50 before
        ADD  HL,DE        ; being tested. This forms the
        POP  DE           ; ADE = address to clear to lower limit.
        SBC  HL,DE        ;
#ifdef BUG_FIXES
        CCF               ;@ [*BUG FIX*]
        JR   C,BF5_CONT   ;@ [*BUG FIX*]
#else
        JR   NC,L1A29     ; Ramtop no good.
#endif

        LD   HL,($5CB4)   ; P_RAMT. For the upper test the value
#ifndef BUG_FIXES
        AND  A            ; for RAMTOP is tested against P_RAMT.
        SBC  HL,DE        ;
        JR   NC,L1A2D     ; Jump forward if acceptable.

L1A29:  CALL L0566        ; Produce error report.
        DEFB $15          ; "M Ramtop no good"
#else
        SBC  HL,DE        ;

BF5_CONT:                 ;@ [*BUG FIX*]
        JP   C,BUG_FIX5   ;@ [*BUG FIX*]
#endif

L1A2D:  LD   ($5CB2),DE   ; RAMTOP.
        POP  DE           ; Retrieve interpreter return address from stack
        POP  HL           ; Retrieve 'error address' from stack
        POP  BC           ; Retrieve the GO SUB stack end marker.
                          ; [*BUG* - It is assumed that the top of the GO SUB stack will be empty and hence only
                          ; contain the end marker. This will not be the case if CLEAR is used within a subroutine,
                          ; in which case BC will now hold the calling line number and this will be stacked in place
                          ; of the end marker. When a RETURN command is encountered, the GO SUB stack appears to contain
                          ; an entry since the end marker was not the top item. An attempt to return is therefore made.
                          ; The CLEAR command handler within the 48K Spectrum ROM does not make any assumption about
                          ; the contents of the GO SUB stack and instead always re-inserts the end marker. The bug could
                          ; be fixed by inserting the line LD BC,$3E00 after the POP BC. Credit: Ian Collier (+3), Paul Farrow (128)]
#ifdef BUG_FIXES
        LD   BC,$3E00     ;@ [*BUG_FIX*]
#endif
        LD   SP,($5CB2)   ; RAMTOP.
        INC  SP           ;
        PUSH BC           ; Stack the GO SUB stack end marker.
        PUSH HL           ; Stack 'error address'.
        LD   ($5C3D),SP   ; ERR_SP.
        PUSH DE           ; Stack the interpreter return address.
        RET

; --------------
; GO SUB Routine
; --------------
; The present value of PPC and the incremented value of SUBPPC are stored on the GO SUB stack.

L1A41:  POP  DE           ; Save the return address.
        LD   H,(IY+$0D)   ; SUBPPC. Fetch the statement number and increment it.
        INC  H            ;
        EX   (SP),HL      ; Exchange the 'error address' with the statement number.
        INC  SP           ; Reclaim the use of a location.

        LD   BC,($5C45)   ; PPC.
        PUSH BC           ; Next save the present line number.
        PUSH HL           ; Return the 'error address' to the machine stack
        LD   ($5C3D),SP   ; ERR-SP.  and reset ERR-SP to point to it.
        PUSH DE           ; Stack the return address.

        RST  28H          ;
        DEFW GO_TO        ; $1E67. Now set NEWPPC & NSPPC to the required values.

        LD   BC,$0014     ; But before making the jump make a test for room.
        RST  28H          ;
        DEFW TEST_ROOM    ; $1F05. Will automatically produce error '4' if out of memory.
        RET

; --------------
; RETURN Routine
; --------------
; The line number and the statement number that are to be made the object of a 'return'
; are fetched from the GO SUB stack.

L1A5D:  POP  BC           ; Fetch the return address.
        POP  HL           ; Fetch the 'error address'.
        POP  DE           ; Fetch the last entry on the GO SUB stack.
        LD   A,D          ; The entry is tested to see if
        CP   $3E          ; it is the GO SUB stack end marker.
        JR   Z,L1A74      ; Jump if it is.

        DEC  SP           ; The full entry uses three locations only.
        EX   (SP),HL      ; Exchange the statement number with the 'error address'.
        EX   DE,HL        ; Move the statement number.
        LD   ($5C3D),SP   ; ERR_SP. Reset the error pointer.
        PUSH BC           ; Replace the return address.
        LD   ($5C42),HL   ; NEWPPC. Enter the line number.
        LD   (IY+$0A),D   ; NSPPC.  Enter the statement number.
        RET               ;

L1A74:  PUSH DE           ; Replace the end marker and
        PUSH HL           ; the 'error address'.

        CALL L0566        ; Produce error report.
        DEFB $06          ; "7 RETURN without GO SUB"

; --------------
; DEF FN Routine
; --------------
; During syntax checking a DEF FN statement is checked to ensure that it has the correct form.
; Space is also made available for the result of evaluating the function.
; But in 'run-time' a DEF FN statement is passed-by.

L1A7A:  BIT  7,(IY+$01)
        JR   Z,L1A85      ; Jump forward if checking syntax.

        LD   A,$CE        ; Otherwise bass-by the
        JP   L19EC        ; 'DEF FN' statement.

;First consider the variable of the function.

L1A85:  SET  6,(IY+$01)   ; Signal 'a numeric variable'.
        RST  28H          ;
        DEFW ALPHA        ; $2C8D. Check that the present code is a letter.
        JR   NC,L1AA4     ; Jump forward if not.

        RST  20H          ; Fetch the next character.
        CP   '$'          ; $24.
        JR   NZ,L1A98     ; Jump forward unless it is a '$'.

        RES  6,(IY+$01)   ; Change bit 6 as it is a string variable.
        RST  20H          ; Fetch the next character.

L1A98:  CP   '('          ; $28. A '(' must follow the variable's name.
        JR   NZ,L1AD8     ; Jump forward if not.

        RST  20H          ; Fetch the next character
        CP   ')'          ; $29. Jump forward if it is a ')'
        JR   Z,L1AC1      ; as there are no parameters of the function.

;A loop is now entered to deal with each parameter in turn.

L1AA1:  RST  28H          ;
        DEFW ALPHA        ; $2C8D.

L1AA4:  JP   NC,L1900     ; The present code must be a letter.

        EX   DE,HL        ; Save the pointer in DE.
        RST  20H          ; Fetch the next character.
        CP   '$'          ; $24.
        JR   NZ,L1AAF     ; Jump forward unless it is a '$'.

        EX   DE,HL        ; Otherwise save the new pointer in DE instead.
        RST  20H          ; Fetch the next character.

L1AAF:  EX   DE,HL        ; Move the pointer to the last character of the name to HL.
        LD   BC,$0006     ; Now make six locations after that last character.
        RST  28H          ;
        DEFW MAKE_ROOM    ; $1655.
        INC  HL           ;
        INC  HL           ;
        LD   (HL),$0E     ; Enter a 'number marker' into the first of the new locations.
        CP   ','          ; $2C. If the present character is a ',' then jump back as
        JR   NZ,L1AC1     ; there should be a further parameter.

        RST  20H          ;
        JR   L1AA1        ; Otherwise jump out of the loop.

;Next the definition of the function is considered.

L1AC1:  CP   ')'          ; $29. Check that the ')' does exist.
        JR   NZ,L1AD8     ; Jump if not.

        RST  20H          ; The next character is fetched.
        CP   '='          ; $3D. It must be an '='.
        JR   NZ,L1AD8     ; Jump if not.

        RST  20H          ; Fetch the next character.
        LD   A,($5C3B)    ; FLAGS.
        PUSH AF           ; Save the nature (numeric or string) of the variable
        RST  28H          ;
        DEFW SCANNING     ; $24FB. Now consider the definition as an expression.
        POP  AF           ; Fetch the nature of the variable.

        XOR  (IY+$01)     ; FLAGS. Check that it is of the same type
        AND  $40          ; as found for the definition.

L1AD8:  JP   NZ,L1900     ; Give an error report if required.

        CALL L188F        ; Move on to consider the next statement in the line.

; ------------
; MOVE Routine
; ------------

L1ADE:  RET               ; Simply return.

; ----------------
; SPECTRUM Routine
; ----------------
; [*BUG* - The 'P' channel data should be overwritten so that the ZX Printer can then be used.  Credit: Paul Farrow and Andrew Owen]

L1ADF:  LD   SP,($5C3D)   ; ERR_SP. Purge the stack.
        POP  HL           ; Remove error handler address.

        LD   HL,MAIN_4    ; $1303. The main execution loop.
        PUSH HL           ;
        LD   HL,PRINT_A_1+$0003 ; $0013. Address of a $FF byte to generate error 0 OK.
        PUSH HL           ;
        LD   HL,ERROR_1   ; $0008. The address of the error handler.
        PUSH HL           ;
        LD   A,$20        ; Force 48K mode.
        LD   (BANK_M),A   ; $5B5C.
        RES  3,(IY+$30)   ; FLAGS2. Signal caps lock unset.
        RES  4,(IY+$01)   ; FLAGS. Signal not 128K mode.
        JP   SWAP         ; $5B00. Swap to ROM 1 and return via a RST $08 / DEFB $FF.

; -------------
; LLIST Routine
; -------------

L1B00:  LD   A,$03        ; Printer channel.
        JR   L1B06        ; Jump ahead to join LIST.

; ------------
; LIST Routine
; ------------

L1B04:  LD   A,$02        ; Main screen channel.

L1B06:  LD   (IY+$02),$00 ; TV_FLAG. Signal 'an ordinary listing in the main part of the screen'.
        RST  28H          ;
        DEFW SYNTAX_Z     ; $2530.
        JR   Z,L1B12      ; Do not open the channel if checking syntax.

        RST  28H          ;
        DEFW CHAN_OPEN    ; $1601. Open the channel.

L1B12:  RST  28H          ;
        DEFW GET_CHAR     ; $0018. [Could just do RST $18]
        RST  28H          ;
        DEFW STR_ALTER    ; $2070. See if the stream is to be changed.
        JR   C,L1B32      ; Jump forward if unchanged.

        RST  28H
        DEFW GET_CHAR     ; $0018. Get current character.
        CP   $3B          ; Is it a ';'?
        JR   Z,L1B25      ; Jump if it is.

        CP   ','          ; $2C. Is it a ','?
        JR   NZ,L1B2D     ; Jump if it is not.

L1B25:  RST  28H          ;
        DEFW NEXT_CHAR    ; $0020. Get the next character.
        CALL L18FC        ; Indirectly call EXPT-1NUM in ROM 1 to check that
                          ; a numeric expression follows, e.g. LIST #5,20.
        JR   L1B35        ; Jump forward with it.

L1B2D:  RST  28H          ;
        DEFW USE_ZERO     ; $1CE6. Otherwise use zero and
        JR   L1B35        ; jump forward.

;Come here if the stream was unaltered.

L1B32:  RST  28H          ;
        DEFW FETCH_NUM    ; $1CDE. Fetch any line or use zero if none supplied.

L1B35:  CALL L188F        ; If checking the syntax of the edit-line move on to the next statement.
        RST  28H          ;
        DEFW LIST_5+3     ; $1825. Delegate handling to ROM 1.
        RET

; ----------------------
; RAM Disk SAVE! Routine
; ----------------------

L1B3C:  LD   (OLDSP),SP   ; $5B81. Save SP.
        LD   SP,TSTACK+1  ; $5BFF. Use temporary stack.

        CALL L1C26        ; Create new catalogue entry.

        LD   BC,(HD_0B)   ; $5B72. get the length of the file.
        LD   HL,$FFF7     ; -9 (9 is the length of the file header).
        OR   $FF          ; Extend the negative number into the high byte.
        SBC  HL,BC        ; AHL=-(length of file + 9)
        CALL L1C82        ; Check for space in RAM disk (produce "4 Out of memory" if no room).

        LD   BC,$0009     ; File header length.
        LD   HL,HD_00     ; $5B71. Address of file header.
        CALL L1D3B        ; Store file header to RAM disk.

        LD   HL,(HD_0D)   ; $5B74. Start address of file data.
        LD   BC,(HD_0B)   ; $5B72. Length of file data.
        CALL L1D3B        ; Store bytes to RAM disk.
        CALL L1CE5        ; Update catalogue entry (leaves logical RAM bank 4 paged in).

PATCH:  LD   A,$05        ; Page in logical RAM bank 5 (physical RAM bank 0).
        CALL L1BF3        ;

        LD   SP,(OLDSP)   ; $5B81. Use original stack.
        RET               ;

; ------------
; CAT! Routine
; ------------

L1B74:  RST  28H          ; Get the current character.
        DEFW GET_CHAR     ; $0018. [Could just do RST $18 here]
        CP   '!'          ; $21. Is it '!'?
        JP   NZ,L1900     ; Jump to "C Nonsense in BASIC" if not.

        RST  28H          ; Get the next character.
        DEFW NEXT_CHAR    ; $0020. [Could just do RST $20 here]
        CALL L188F        ; Check for end of statement.

        LD   A,$02        ; Select main screen.
        RST  28H          ;
        DEFW CHAN_OPEN    ; $1601.

        LD   (OLDSP),SP   ; $5B81. Store SP.
        LD   SP,TSTACK+1  ; $5BFF. Use temporary stack.

        CALL L205F        ; Print out the catalogue.

#ifndef BUG_FIXES
        LD   A,$05        ; Page in logical RAM bank 5 (physical RAM bank 0).
        CALL L1BF3        ;

        LD   SP,(OLDSP)   ; $5B81. Use original stack.
        RET               ;
#else
	JR   PATCH

; ----------------
; RENUMBER Bug Fix
; ----------------
PATCH3:
	LD   HL,(RNFIRST) ; $5B6D. Starting line number for Renumber.
	RET  NC

	POP  HL		  ; Drop return address.
	JP   L33B9
#endif

; --------------
; ERASE! Routine
; --------------

L1B9B:  RST  28H          ; Get character from BASIC line.
        DEFW GET_CHAR     ; $0018.
        CP   '!'          ; $21. Is it '!'?
        JP   NZ,L1900     ; Jump to "C Nonsense in BASIC" if not.

        CALL L136F        ; Get the filename into N_STR1.
        CALL L188F        ; Make sure we've reached the end of the BASIC statement.

        LD   (OLDSP),SP   ; $5B81. Store SP.
        LD   SP,TSTACK+1  ; $5BFF. Use temporary stack.

        CALL L1EEE        ; Do the actual erasing (leaves logical RAM bank 4 paged in).

#ifndef BUG_FIXES
        LD   A,$05        ; Restore RAM configuration.
        CALL L1BF3        ; Page in logical RAM bank 5 (physical RAM bank 0).

        LD   SP,(OLDSP)   ; $5B81. Use original stack.
        RET               ;
#else
	JR   PATCH

	DEFB $00, $00, $00, $00
	DEFB $00, $00, $00, $00
#endif


; ==================================
; RAM DISK COMMAND ROUTINES - PART 2
; ==================================

; -------------------------
; Load Header from RAM Disk
; -------------------------

L1BBD:  LD   (OLDSP),SP   ; $5B81. Store SP.
        LD   SP,TSTACK+1  ; $5BFF. Use temporary stack.

        CALL L1CC4        ; Find file (return details pointed to by IX). Leaves logical RAM bank 4 paged in.

;The file exists else the call above would have produced an error "h file does not exist"

        LD   HL,HD_00     ; $5B71. Load 9 header bytes.
        LD   BC,$0009     ;
        CALL L1DC6        ; Load bytes from RAM disk.

#ifndef BUG_FIXES
        LD   A,$05        ; Restore RAM configuration.
        CALL L1BF3        ; Page in logical RAM bank 5 (physical RAM bank 0).

        LD   SP,(OLDSP)   ; $5B81. Use original stack.
        RET               ;
#else
	JR   PATCH

; ------------------
; Parse Line Bug Fix
; ------------------

BUG_FIX6:
        RST  28H          ;@ [*BUG FIX*]
        DEFW FP_TO_BC     ;@ [*BUG FIX*]
        LD   HL,(RNLINE)  ;@ [*BUG FIX*] $5b92. HL=Address of the current line's length bytes.
        RET               ;@ [*BUG FIX*]

	DEFB $00
#endif

; ------------------
; Load from RAM Disk
; ------------------
; Used by LOAD, VERIFY and MERGE. Note that VERIFY will simply perform a LOAD.
; Entry: HL=Destination address.
;        DE=Length (will be greater than zero).
;        IX=File descriptor.
;        IX=Address of catalogue entry (IX+$10-IX+$12 points to the address of the file's data, past its header).
;        HD_00-HD_11 holds file header information.

L1BDA:  LD   (OLDSP),SP   ; $5B81. Store SP
        LD   SP,TSTACK+1  ; $5BFF. Use temporary stack.

        LD   B,D          ;
        LD   C,E          ; BC=Length.
        CALL L1DC6        ; Load bytes from RAM disk.
        CALL L1CE5        ; Update catalogue entry (leaves logical RAM bank 4 paged in).

        LD   A,$05        ; Restore RAM configuration.
        CALL L1BF3        ; Page in logical RAM bank 5 (physical RAM bank 0).

        LD   SP,(OLDSP)   ; $5B81. Use original stack.
        RET               ;


; ========================
; PAGING ROUTINES - PART 1
; ========================

; ---------------------
; Page Logical RAM Bank
; ---------------------
; This routine converts between logical and physical RAM banks and pages the
; selected bank in.
; Entry: A=Logical RAM bank.

L1BF3:  PUSH HL           ; Save BC and HL.
        PUSH BC           ;

        LD   HL,L1C10     ; Physical banks used by RAM disk.
        LD   B,$00        ;
        LD   C,A          ; BC=Logical RAM bank.
        ADD  HL,BC        ; Point to table entry.
        LD   C,(HL)       ; Look up physical page.

        DI                ; Disable interrupts whilst paging.
        LD   A,(BANK_M)   ; $5B5C. Fetch the current configuration.
        AND  $F8          ; Mask off current RAM bank.
        OR   C            ; Include new RAM bank.
        LD   (BANK_M),A   ; $5B5C. Store the new configuration.
        LD   BC,$7FFD     ;
        OUT  (C),A        ; Perform the page.
        EI                ; Re-enable interrupts.

        POP  BC           ; Restore BC and HL.
        POP  HL           ;
        RET               ;

; -------------------------------
; Physical RAM Bank Mapping Table
; -------------------------------

L1C10:  DEFB $01          ; Logical bank $00.
        DEFB $03          ; Logical bank $01.
        DEFB $04          ; Logical bank $02.
        DEFB $06          ; Logical bank $03.
        DEFB $07          ; Logical bank $04.
        DEFB $00          ; Logical bank $05.


; ==================================
; RAM DISK COMMAND ROUTINES - PART 3
; ==================================

; -----------------
; Compare Filenames
; -----------------
; Compare filenames at N_STR1 and IX.
; Exit: Zero flag set if filenames match.
;       Carry flag set if filename at DE is alphabetically lower than filename at IX.

L1C16:  LD   DE,N_STR1    ; $5B67.

; Compare filenames at DE and IX

L1C19:  PUSH IX           ;
        POP  HL           ;
        LD   B,$0A        ; Maximum of 10 characters.

L1C1E:  LD   A,(DE)       ;
        INC  DE           ;
        CP   (HL)         ; compare each character.
        INC  HL           ;
        RET  NZ           ; Return if characters are different.

        DJNZ L1C1E        ; Repeat for all characters of the filename.

        RET               ;

; --------------------------
; Create New Catalogue Entry
; --------------------------
; Add a catalogue entry with filename contained in N_STR1.
; Exit: HL=Address of next free catalogue entry.
;       IX=Address of newly created catalogue entry.

L1C26:  CALL L1CA1        ; Find entry in RAM disk area, returning IX pointing to catalogue entry (leaves logical RAM bank 4 paged in).
        JR   Z,L1C2F      ; Jump ahead if does not exist.

        CALL L0566        ; Produce error report.
        DEFB $20          ; "e File already exists"

L1C2F:  PUSH IX           ;
        LD   BC,$3FEC     ; 16384-20 (maximum size of RAM disk catalogue).
        ADD  IX,BC        ; IX grows downwards as new RAM disk catalogue entries added.
                          ; If adding the maximum size to IX does not result in the carry flag being set
                          ; then the catalogue is full, so issue an error report "4 Out of Memory".
        POP  IX           ;
        JR   NC,L1C9D     ; Jump if out of memory.

        LD   HL,$FFEC     ; -20 (20 bytes is the size of a RAM disk catalogue entry).
        LD   A,$FF        ; Extend the negative number into the high byte.
        CALL L1C82        ; Ensure space in RAM disk area.

        LD   HL,FLAGS3    ; $5B66.
        SET  2,(HL)       ; Signal editing RAM disk catalogue.

        PUSH IX           ;
        POP  DE           ; DE=Address of new catalogue entry.
        LD   HL,N_STR1    ; $5B67. Filename.

L1C4D:  LD   BC,$000A     ; 10 characters in the filename.
        LDIR              ; Copy the filename.

        SET  0,(IX+$13)   ; Indicate catalogue entry requires updating.

        LD   A,(IX+$0A)   ; Set the file access address to be the
        LD   (IX+$10),A   ; start address of the file.
        LD   A,(IX+$0B)   ;
        LD   (IX+$11),A   ;
        LD   A,(IX+$0C)   ;
        LD   (IX+$12),A   ;

        XOR  A            ; Set the fill length to zero.
        LD   (IX+$0D),A   ;
        LD   (IX+$0E),A   ;
        LD   (IX+$0F),A   ;

        LD   A,$05        ;
        CALL L1BF3        ; Logical RAM bank 5 (physical RAM bank 0).

        PUSH IX           ;
        POP  HL           ; HL=Address of new catalogue entry.
        LD   BC,$FFEC     ; -20 (20 bytes is the size of a catalogue entry).
        ADD  HL,BC        ;
        LD   (SFNEXT),HL  ; $5B83. Store address of next free catalogue entry.
        RET               ;

; --------------------------
; Adjust RAM Disk Free Space
; --------------------------
; Adjust the count of free bytes within the RAM disk.
; The routine can produce "4 Out of memory" when adding.
; Entry: AHL=Size adjustment (negative when a file added, positive when a file deleted).
;        A=Bit 7 set for adding data, else deleting data.

L1C82:  LD   DE,(SFSPACE) ; $5B85.
        EX   AF,AF'       ; A'HL=Requested space.

        LD   A,(SFSPACE+2) ; $5B87. ADE=Free space on RAM disk.
        LD   C,A          ; CDE=Free space.

        EX   AF,AF'       ; AHL=Requested space.
        BIT  7,A          ; A negative adjustment, i.e. adding data?
        JR   NZ,L1C99     ; Jump ahead if so.

;Deleting data

        ADD  HL,DE        ;
        ADC  A,C          ; AHL=Free space left.

L1C92:  LD   (SFSPACE),HL ; $5B85. Store free space.
        LD   (SFSPACE+2),A ; $5B87.
        RET               ;

;Adding data

L1C99:  ADD  HL,DE        ;
        ADC  A,C          ;
        JR   C,L1C92      ; Jump back to store free space if space left.

L1C9D:  CALL L0566        ; Produce error report.
        DEFB 03           ; "4 Out of memory"

; ---------------------------------
; Find Catalogue Entry for Filename
; ---------------------------------
; Entry: Filename stored at N_STR1 ($5B67).
; Exit : Zero flag set if file does not exist.
;        If file exists, IX points to catalogue entry.
;        Always leaves logical RAM bank 4 paged in.

L1CA1:  LD   A,$04        ; Page in logical RAM bank 4 (physical RAM bank 7).
        CALL L1BF3        ;

        LD   IX,$EBEC     ; Point to first catalogue entry.

L1CAA:  LD   DE,(SFNEXT)  ; $5B83. Pointer to last catalogue entry.
        OR   A            ; Clear carry flag.
        PUSH IX           ;
        POP  HL           ; HL=First catalogue entry.
        SBC  HL,DE        ;
        RET  Z            ; Return with zero flag set if end of catalogue reached
                          ; and hence filename not found.

        CALL L1C16        ; Test filename match with N_STR1 ($5B67).
        JR   NZ,L1CBD     ; Jump ahead if names did not match.

        OR   $FF          ; Reset zero flag to indicate filename exists.
        RET               ;

L1CBD:  LD   BC,$FFEC     ; -20 bytes (20 bytes is the size of a catalogue entry).
        ADD  IX,BC        ; Point to the next directory entry.
        JR   L1CAA        ; Test the next name.

; ------------------
; Find RAM Disk File
; ------------------
; Find a file in the RAM disk matching name held in N_STR1,
; and return with IX pointing to the catalogue entry.

L1CC4:  CALL L1CA1        ; Find entry in RAM disk area, returning IX pointing to catalogue entry (leaves logical RAM bank 4 paged in).
        JR   NZ,L1CCD     ; Jump ahead if it exists.

        CALL L0566        ; Produce error report.
        DEFB $23          ; "h File does not exist"

L1CCD:  LD   A,(IX+$0A)   ; Take the current start address (bank + location)
        LD   (IX+$10),A   ; and store it as the current working address.
        LD   A,(IX+$0B)   ;
        LD   (IX+$11),A   ;
        LD   A,(IX+$0C)   ;
        LD   (IX+$12),A   ;

        LD   A,$05        ; Page in logical RAM bank 5 (physical RAM bank 0).
        CALL L1BF3        ;
        RET               ; [Could have saved 1 byte by using JP $1BF3 (ROM 0)]

; ----------------------
; Update Catalogue Entry
; ----------------------
; Entry: IX=Address of catalogue entry (IX+$10-IX+$12 points to end of the file).
; Exits with logical RAM bank 4 paged in.

L1CE5:  LD   A,$04        ; Page in logical RAM bank 4 (physical RAM bank 7).
        CALL L1BF3        ;

        BIT  0,(IX+$13)   ;
        RET  Z            ; Ignore if catalogue entry does not require updating.

        RES  0,(IX+$13)   ; Indicate catalogue entry updated.

        LD   HL,FLAGS3    ; $5B66.
        RES  2,(HL)       ; Signal not editing RAM disk catalogue.

        LD   L,(IX+$10)   ; Points to end address within logical RAM bank.
        LD   H,(IX+$11)   ;
        LD   A,(IX+$12)   ; Points to end logical RAM bank.

        LD   E,(IX+$0A)   ; Start address within logical RAM bank.
        LD   D,(IX+$0B)   ;
        LD   B,(IX+$0C)   ; Start logical RAM bank.
        OR   A            ; Clear carry flag.
        SBC  HL,DE        ; HL=End address-Start address. Maximum difference fits within 14 bits.

        SBC  A,B          ; A=End logical RAM bank-Start logical RAM bank - 1 if addresses overlap.
        RL   H            ;
        RL   H            ; Work out how many full banks of 16K are being used.
        SRA  A            ; Place this in the upper two bits of H.
        RR   H            ;
        SRA  A            ;
        RR   H            ; HL=Total length.

        LD   (IX+$0D),L   ; Length within logical RAM bank.
        LD   (IX+$0E),H   ;
        LD   (IX+$0F),A   ;

;Copy the end address of the previous entry into the new entry

        LD   L,(IX+$10)   ; End address within logical RAM bank.
        LD   H,(IX+$11)   ;
        LD   A,(IX+$12)   ; End logical RAM bank.
        LD   BC,$FFEC     ; -20 bytes (20 bytes is the size of a catalogue entry).
        ADD  IX,BC        ; Address of next catalogue entry.
        LD   (IX+$0A),L   ; Start address within logical RAM bank.
        LD   (IX+$0B),H   ;
        LD   (IX+$0C),A   ; Start logical RAM bank.
        RET               ;

; ----------------------
; Save Bytes to RAM Disk
; ----------------------
; Entry: IX=Address of catalogue entry.
;        HL=Source address in conventional RAM.
;        BC=Length.
; Advances IX+$10-IX+$12 as bytes are saved so that always points to next location to fill,
; eventually pointing to the end of the file.

L1D3B:  LD   A,B          ; Check whether a data length of zero was requested.
        OR   C            ;
        RET  Z            ; Ignore if so since all bytes already saved.

        PUSH HL           ; Save the source address.
        LD   DE,$C000     ; DE=The start of the upper RAM bank.
        EX   DE,HL        ; HL=The start of the RAM bank. DE=Source address.
        SBC  HL,DE        ; HL=RAM bank start - Source address.
        JR   Z,L1D64      ; Jump ahead if saving bytes from $C000.

        JR   C,L1D64      ; Jump ahead if saving bytes from an address above $C000.

;Source is below $C000

        PUSH HL           ; HL=Distance below $C000 (RAM bank start - Source address).
        SBC  HL,BC        ;
        JR   NC,L1D5B     ; Jump if requested bytes are all below $C000.

;Source spans across $C000

        LD   H,B          ;
        LD   L,C          ; HL=Requested length.
        POP  BC           ; BC=Distance below $C000.
        OR   A            ;
        SBC  HL,BC        ; HL=Bytes occupying upper RAM bank.
        EX   (SP),HL      ; Stack it. HL=Source address.
        LD   DE,$C000     ; Start of upper RAM bank.
        PUSH DE           ;
        JR   L1D83        ; Jump forward.

;Source fits completely below upper RAM bank (less than $C000)

L1D5B:  POP  HL           ; Forget the 'distance below $C000' count.
        POP  HL           ; HL=Source address.
        LD   DE,$0000     ; Remaining bytes to transfer.
        PUSH DE           ;
        PUSH DE           ; Stack dummy Start of upper RAM bank.
        JR   L1D83        ; Jump forward.

;Source fits completely within upper RAM bank (greater than or equal $C000)

L1D64:  LD   H,B          ;
        LD   L,C          ; HL=Requested length.
        LD   DE,$0020     ; DE=Length of buffer.
        OR   A            ;
        SBC  HL,DE        ; HL=Requested length-Length of buffer = Buffer overspill.
        JR   C,L1D73      ; Jump if requested length will fit within the buffer.

;Source spans transfer buffer

        EX   (SP),HL      ; Stack buffer overspill. HL=$0000.
        LD   B,D          ;
        LD   C,E          ; BC=Buffer length.
        JR   L1D78        ; Jump forward.

;Source fits completely within transfer buffer

L1D73:  POP  HL           ; HL=Destination address.
        LD   DE,$0000     ; Remaining bytes to transfer.
        PUSH DE           ; Stack 'transfer buffer in use' flag.

;Transfer a block

L1D78:  PUSH BC           ; Stack the length.
        LD   DE,DISKBUF   ; $5B98. Transfer buffer.
        LDIR              ; Transfer bytes.
        POP  BC           ; BC=Length.
        PUSH HL           ; HL=New source address.
        LD   HL,DISKBUF   ; $5B98. Transfer buffer.

L1D83:  LD   A,$04        ; Page in logical RAM bank 4 (physical RAM bank 7).
        CALL L1BF3        ;

        LD   E,(IX+$10)   ;
        LD   D,(IX+$11)   ; Fetch the address from the current logical RAM bank.
        LD   A,(IX+$12)   ; Logical RAM bank.
        CALL L1BF3        ; Page in appropriate logical RAM bank.

L1D94:  LDI               ; Transfer a byte from the file to the required RAM disk location or transfer buffer.
        LD   A,D          ;
        OR   E            ; Has DE been incremented to $0000?
        JR   Z,L1DB3      ; Jump if end of RAM bank reached.

L1D9A:  LD   A,B          ;
        OR   C            ;
        JP   NZ,L1D94     ; Repeat until all bytes transferred.

        LD   A,$04        ; Page in logical RAM bank 4 (physical RAM bank 7).
        CALL L1BF3        ;

        LD   (IX+$10),E   ;
        LD   (IX+$11),D   ; Store the next RAM bank source address.

        LD   A,$05        ; Page in logical RAM bank 5 (physical RAM bank 0).
        CALL L1BF3        ;

        POP  HL           ; HL=Source address.
        POP  BC           ; BC=Length.
        JR   L1D3B        ; Re-enter this routine to transfer another block.

;The end of a RAM bank has been reached so switch to the next bank

L1DB3:  LD   A,$04        ; Page in logical RAM bank 4 (physical RAM bank 7).
        CALL L1BF3        ;

        INC  (IX+$12)     ; Increment to the new logical RAM bank.
        LD   A,(IX+$12)   ; Fetch the new logical RAM bank.
        LD   DE,$C000     ; The start of the RAM disk
        CALL L1BF3        ; Page in next RAM bank.
        JR   L1D9A        ; Jump back to transfer another block.

; ------------------------
; Load Bytes from RAM Disk
; ------------------------
; Used for loading file header and data.
; Entry: IX=RAM disk catalogue entry address. IX+$10-IX+$12 points to the next address to fetch from the file.
;        HL=Destination address.
;        BC=Requested length.

L1DC6:  LD   A,B          ; Check whether a data length of zero was requested.
        OR   C            ;
        RET  Z            ; Ignore if so since all bytes already loaded.

        PUSH HL           ; Save the destination address.
        LD   DE,$C000     ; DE=The start of the upper RAM bank.
        EX   DE,HL        ; HL=The start of the RAM bank. DE=Destination address.
        SBC  HL,DE        ; HL=RAM bank start - Destination address.
        JR   Z,L1DF6      ; Jump if destination is $C000.
        JR   C,L1DF6      ; Jump if destination is above $C000.

;Destination is below $C000

L1DD4:  PUSH HL           ; HL=Distance below $C000 (RAM bank start - Destination address).
        SBC  HL,BC        ;
        JR   NC,L1DEB     ; Jump if requested bytes all fit below $C000.

;Code will span across $C000

        LD   H,B          ;
        LD   L,C          ; HL=Requested length.
        POP  BC           ; BC=Distance below $C000.
        OR   A            ;
        SBC  HL,BC        ; HL=Bytes destined for upper RAM bank.
        EX   (SP),HL      ; Stack it. HL=Destination address.
        LD   DE,$0000     ; Remaining bytes to transfer.
        PUSH DE           ;
        LD   DE,$C000     ; Start of upper RAM bank.
        PUSH DE           ;
        EX   DE,HL        ; HL=Start of upper RAM bank.
        JR   L1E0F        ; Jump forward.

;Code fits completely below upper RAM bank (less than $C000)

L1DEB:  POP  HL           ; Forget the 'distance below $C000' count.
        POP  HL           ; HL=Destination address.
        LD   DE,$0000     ; Remaining bytes to transfer.
        PUSH DE           ;
        PUSH DE           ; Stack dummy Start of upper RAM bank.
        PUSH DE           ;
        EX   DE,HL        ; HL=$0000, DE=Destination address.
        JR   L1E0F        ; Jump forward.

;Code destined for upper RAM bank (greater than or equal to $C000)

L1DF6:  LD   H,B          ;
        LD   L,C          ; HL=Requested length.
        LD   DE,$0020     ; DE=Length of buffer.
        OR   A            ;
        SBC  HL,DE        ; HL=Requested length-Length of buffer = Buffer overspill.
        JR   C,L1E05      ; Jump if requested length will fit within the buffer.

;Code will span transfer buffer

        EX   (SP),HL      ; Stack buffer overspill. HL=$0000.
        LD   B,D          ;
        LD   C,E          ; BC=Buffer length.
        JR   L1E0A        ; Jump forward.

;Code will all fit within transfer buffer

L1E05:  POP  HL           ; HL=Destination address.
        LD   DE,$0000     ; Remaining bytes to transfer.
        PUSH DE           ; Stack 'transfer buffer in use' flag.

L1E0A:  PUSH BC           ; Stack the length.
        PUSH HL           ; Stack destination address.
        LD   DE,DISKBUF   ; $5B98. Transfer buffer.

;Transfer a block

L1E0F:  LD   A,$04        ; Page in logical RAM bank 4 (physical RAM bank 7).
        CALL L1BF3        ;

        LD   L,(IX+$10)   ; RAM bank address.
        LD   H,(IX+$11)   ;
        LD   A,(IX+$12)   ; Logical RAM bank.
        CALL L1BF3        ; Page in appropriate logical RAM bank.

;Enter a loop to transfer BC bytes, either to required destination or to the transfer buffer

L1E20:  LDI               ; Transfer a byte from the file to the required location or transfer buffer.
        LD   A,H          ;
        OR   L            ; Has HL been incremented to $0000?
        JR   Z,L1E4B      ; Jump if end of RAM bank reached.

L1E26:  LD   A,B          ;
        OR   C            ;
        JP   NZ,L1E20     ; Repeat until all bytes transferred.

        LD   A,$04        ; Page in logical RAM bank 4 (physical RAM bank 7).
        CALL L1BF3        ;

        LD   (IX+$10),L   ;
        LD   (IX+$11),H   ; Store the next RAM bank destination address.

        LD   A,$05        ; Page in logical RAM bank 5 (physical RAM bank 0).
        CALL L1BF3        ;

        POP  DE           ; DE=Destination address.
        POP  BC           ; BC=Length.

        LD   HL,DISKBUF   ; $5B98. Transfer buffer.
        LD   A,B          ;
        OR   C            ; All bytes transferred?
        JR   Z,L1E46      ; Jump forward if so.

        LDIR              ; Transfer code in buffer to the required address.

L1E46:  EX   DE,HL        ; HL=New destination address.
        POP  BC           ; BC=Remaining bytes to transfer.
        JP   L1DC6        ; Re-enter this routine to transfer another block.

;The end of a RAM bank has been reached so switch to the next bank

L1E4B:  LD   A,$04        ; Page in logical RAM bank 4 (physical RAM bank 7).
        CALL L1BF3        ;

        INC  (IX+$12)     ; Increment to the new logical RAM bank.
        LD   A,(IX+$12)   ; Fetch the new logical RAM bank.
        LD   HL,$C000     ; The start of the RAM disk.
        CALL L1BF3        ; Page in next logical RAM bank.
        JR   L1E26        ; Jump back to transfer another block.

; ----------------------------------------------------------
; Transfer Bytes to Logical RAM Bank 4 (Physical RAM Bank 7)
; ----------------------------------------------------------
; This routine is used to transfer bytes from the current RAM bank into logical RAM bank 4.
; It is used to copy bytes from conventional RAM to the editor workspace variables. ????
; It is also accessible from the vector table entry at $0106.
; Entry: HL=Source address in conventional RAM.
;        DE=Destination address in logical RAM bank 4 (physical RAM bank 7).
;        BC=Number of bytes to save.
; Exit : HL=Address after the end of the source, i.e. source address + number bytes to save.
;        DE=Address after the end of destination, i.e. destination address + number bytes to save.

L1E5E:  PUSH AF           ; Save AF.

        LD   A,(BANK_M)   ; $5B5C. Fetch current physical RAM bank configuration.
        PUSH AF           ; Save it.
        PUSH HL           ; Save source address.
        PUSH DE           ; Save destination address.
        PUSH BC           ; Save length.

        LD   IX,N_STR1+3  ; $5B6A.

        LD   (IX+$10),E   ; Store destination address as the current address pointer.
        LD   (IX+$11),D   ;
        LD   (IX+$12),$04 ; Destination is in logical RAM bank 4 (physical RAM bank 7).

        CALL L1D3B        ; Store bytes to RAM disk.

;Entered here by load vector routine

L1E77:  LD   A,$05        ; Page in logical RAM bank 5 (physical RAM bank 0).
        CALL L1BF3        ;

        POP  BC           ; Get length.
        POP  DE           ; Get destination address.
        POP  HL           ; Get source address.

        ADD  HL,BC        ; HL=Address after end of source.
        EX   DE,HL        ; DE=Address after end of source. HL=Destination address.
        ADD  HL,BC        ; HL=Address after end of destination.
        EX   DE,HL        ; HL=Address after end of source. DE=Address after end of destination.

        POP  AF           ; Get original RAM bank configuration.
        LD   BC,$7FFD     ;
        DI                ; Disable interrupts whilst paging.
        OUT  (C),A        ;
        LD   (BANK_M),A   ; $5B5C.
        EI                ; Re-enable interrupts.

        LD   BC,$0000     ; Signal all bytes loaded/saved.
        POP  AF           ; Restore AF.
        RET               ;

; ------------------------------------------------------------
; Transfer Bytes from Logical RAM Bank 4 (Physical RAM Bank 7)
; ------------------------------------------------------------
; This routine is used to transfer bytes from logical RAM bank 4 into the current RAM bank.
; It is used to copy bytes from the editor workspace variables to conventional RAM. ????
; It is also accessible from the vector table entry at $0109.
; Entry: HL=Source address in logical RAM bank 4 (physical RAM bank 7).
;        DE=Destination address in current RAM bank.
;        BC=Number of bytes to load.
; Exit : HL=Address after the end of the source, i.e. source address + number bytes to load.
;        DE=Address after the end of destination, i.e. destination address + number bytes to load.

L1E93:  PUSH AF           ; Save AF.

        LD   A,(BANK_M)   ; $5B5C. Fetch current physical RAM bank configuration.
        PUSH AF           ; Save it.
        PUSH HL           ; Save source address.
        PUSH DE           ; Save destination address.
        PUSH BC           ; Save length.

        LD   IX,N_STR1+3  ; $5B6A.

        LD   (IX+$10),L   ; Store source address as the current address pointer.
        LD   (IX+$11),H   ;
        LD   (IX+$12),$04 ; Source is in logical RAM bank 4 (physical RAM bank 7).

        EX   DE,HL        ; HL=Destination address.
        CALL L1DC6        ; Load bytes from RAM disk.
        JR   L1E77        ; Join the save vector routine above.


; ========================
; PAGING ROUTINES - PART 2
; ========================

; ----------------------------
; Use Normal RAM Configuration
; ----------------------------
; Page in physical RAM bank 0 and use normal stack.
; All registers are preserved.

L1EAF:  EX   AF,AF'       ; Save A and the flags.

        LD   A,$00        ; Physical RAM bank 0.
        DI                ; Disable interrupts whilst paging.
        CALL L1EC9        ; Page in physical RAM bank 0.
        POP  AF           ; AF=Address on stack when CALLed.
        LD   (TARGET),HL  ; $5B58. Save the value of HL.
        LD   HL,(OLDSP)   ; $5B81. Fetch the old stack.
        LD   (OLDSP),SP   ; $5B81. Save the current stack.
        LD   SP,HL        ; Use the old stack.
        EI                ; Re-enable interrupts.
        LD   HL,(TARGET)  ; $5B58. Restore the value of HL.
        PUSH AF           ; Re-stack the return address.

        EX   AF,AF'       ; Restore A and the flags.
        RET               ;

; ---------------
; Select RAM Bank
; ---------------
; Used twice by the ROM to select either physical RAM bank 0 or physical RAM bank 7.
; However, it could in theory also be used to set other paging settings.
; Entry: A=RAM bank number.

L1EC9:  PUSH BC           ; Save BC
        LD   BC,$7FFD     ;
        OUT  (C),A        ; Perform requested paging.
        LD   (BANK_M),A   ; $5B5C.
        POP  BC           ; Restore BC.
        RET               ;

; -------------------------------
; Use Workspace RAM Configuration
; -------------------------------
; Page in physical RAM bank 7 and use workspace stack.
; All registers are preserved.

L1ED4:  EX   AF,AF'       ; Save A and the flags.

        DI                ; Disable interrupts whilst paging.

        POP  AF           ; Fetch return address.
        LD   (TARGET),HL  ; $5B58. Save the value of HL.

        LD   HL,(OLDSP)   ; $5B81. Fetch the old stack.
        LD   (OLDSP),SP   ; $5B81. Save the current stack.
        LD   SP,HL        ; Use the old stack.

        LD   HL,(TARGET)  ; $5B58. Restore the value of HL.
        PUSH AF           ; Stack return address.

        LD   A,$07        ; RAM bank 7.
        CALL L1EC9        ; Page in RAM bank 7.
        EI                ; Re-enable interrupts.

        EX   AF,AF'       ; Restore A and the flags.
        RET               ;


; ==================================
; RAM DISK COMMAND ROUTINES - PART 4
; ==================================

; ---------------------
; Erase a RAM Disk File
; ---------------------
; N_STR1 contains the name of the file to erase.

L1EEE:  CALL L1CA1        ; Find entry in RAM disk area, returning IX pointing to catalogue entry (leaves logical RAM bank 4 paged in).
        JR   NZ,L1EF7     ; Jump ahead if it was found. [Could have saved 3 bytes by using JP Z,$1CCD (ROM 0)]

        CALL L0566        ; Produce error report.
        DEFB $23          ; "h File does not exist"

L1EF7:  LD   L,(IX+$0D)   ; AHL=Length of file.
        LD   H,(IX+$0E)   ;
        LD   A,(IX+$0F)   ; Bit 7 of A will be 0 indicating to delete rather than add.
        CALL L1C82        ; Free up this amount of space.

        PUSH IY           ; Preserve current value of IY.

        LD   IY,(SFNEXT)  ; $5B83. IY points to next free catalogue entry.
        LD   BC,$FFEC     ; BC=-20 (20 bytes is the size of a catalogue entry).
        ADD  IX,BC        ; IX points to the next catalogue entry

        LD   L,(IY+$0A)   ; AHL=First spare byte in RAM disk file area.
        LD   H,(IY+$0B)   ;
        LD   A,(IY+$0C)   ;

        POP  IY           ; Restore IY to normal value.

        LD   E,(IX+$0A)   ; BDE=Start of address of next RAM disk file entry.
        LD   D,(IX+$0B)   ;
        LD   B,(IX+$0C)   ;
        OR   A            ;
        SBC  HL,DE        ;
        SBC  A,B          ;
        RL   H            ;
        RL   H            ;
        SRA  A            ;
        RR   H            ;
        SRA  A            ;
        RR   H            ; HL=Length of all files to be moved.

        LD   BC,$0014     ; 20 bytes is the size of a catalogue entry.
        ADD  IX,BC        ; IX=Catalogue entry to delete.

        LD   (IX+$10),L   ; Store file length in the 'deleted' catalogue entry.
        LD   (IX+$11),H   ;
        LD   (IX+$12),A   ;

        DI                ;

        LD   BC,$FFEC     ; -20 (20 bytes is the size of a catalogue entry).
        ADD  IX,BC        ; IX=Next catalogue entry.

        LD   L,(IX+$0A)   ; DHL=Start address of next RAM disk file entry.
        LD   H,(IX+$0B)   ;
        LD   D,(IX+$0C)   ;

        LD   BC,$0014     ; 20 bytes is the size of a catalogue entry.
        ADD  IX,BC        ; IX points to catalogue entry to delete.

        LD   A,D          ; Page in logical RAM bank for start address of entry to delete.
        CALL L1BF3        ;

        LD   A,(BANK_M)   ; $5B5C.
        LD   E,A          ; Save current RAM bank configuration in E.
        LD   BC,$7FFD     ; Select physical RAM bank 7.
        LD   A,$07        ;
        OUT  (C),A        ; Page in selected RAM bank.
        EXX               ; DHL'=Start address of next RAM disk file entry.

        LD   L,(IX+$0A)   ; DHL=Start of address of RAM disk file entry to delete.
        LD   H,(IX+$0B)   ;
        LD   D,(IX+$0C)   ;

        LD   A,D          ;
        CALL L1BF3        ; Page in logical RAM bank for file entry (will update BANK_M).

        LD   A,(BANK_M)   ; $5B5C.
        LD   E,A          ; Get RAM bank configuration for the file in E.
        LD   BC,$7FFD     ;
        EXX               ; DHL=Start address of next RAM disk file entry.

; At this point we have the registers and alternate registers pointing
; to the actual bytes in the RAM disk for the file to be deleted and the next file,
; with length bytes of the catalogue entry for the file to be deleted containing
; the length of bytes for all subsequent files that need to be moved down in memory.
; A loop is entered to move all of these bytes where the delete file began.

; DHL holds the address of the byte to be moved
; E contains the value which should be OUTed to $5B5C to page in the relevant RAM page.

L1F79:  LD   A,$07        ; Select physical RAM bank 7.
        OUT  (C),A        ; Page in selected RAM bank.

        LD   A,(IX+$10)   ; Decrement end address.
        SUB  $01          ;
        LD   (IX+$10),A   ;
        JR   NC,L1F9B     ; If no carry then the decrement is finished.

        LD   A,(IX+$11)   ; Otherwise decrement the middle byte.
        SUB  $01          ;
        LD   (IX+$11),A   ;
        JR   NC,L1F9B     ; If no carry then the decrement is finished.

        LD   A,(IX+$12)   ; Otherwise decrement the highest byte.
        SUB  $01          ;
        LD   (IX+$12),A   ;
        JR   C,L1FCB      ; Jump forward if finished moving the file.

L1F9B:  OUT  (C),E        ; Page in RAM bank containing the next file.
        LD   A,(HL)       ; Get the byte from the next file.
        INC  L            ; Increment DHL.
        JR   NZ,L1FB2     ; If not zero then the increment is finished.

        INC  H            ; Otherwise increment the middle byte.
        JR   NZ,L1FB2     ; If not zero then the increment is finished.

        EX   AF,AF'       ; Save the byte read from the next file.
        INC  D            ; Advance to next logical RAM bank for the next file.

        LD   A,D          ;
        CALL L1BF3        ; Page in next logical RAM bank for next file entry (will update BANK_M).

        LD   A,(BANK_M)   ; $5B5C.
        LD   E,A          ; Get RAM bank configuration for the next file in E.
        LD   HL,$C000     ; The next file continues at the beginning of the next RAM bank.
        EX   AF,AF'       ; Retrieve the byte read from the next file.

L1FB2:  EXX               ; DHL=Address of file being deleted.

        OUT  (C),E        ; Page in next RAM bank containing the next file.

        LD   (HL),A       ; Store the byte taken from the next file.
        INC  L            ; Increment DHL.
        JR   NZ,L1FC8     ; If not zero then the increment is finished.

        INC  H            ; Otherwise increment the middle byte.
        JR   NZ,L1FC8     ; If not zero then the increment is finished.

        INC  D            ; Advance to next logical RAM bank for the file being deleted.

        LD   A,D          ;
        CALL L1BF3        ; Page in next logical RAM bank for file being deleted entry (will update BANK_M).

        LD   A,(BANK_M)   ; $5B5C.
        LD   E,A          ; Get RAM bank configuration for the file being deleted in E.
        LD   HL,$C000     ; The file being deleted continues at the beginning of the next RAM bank.

L1FC8:  EXX               ; DHL=Address of byte in next file.
                          ; DHL'=Address of byte in file being deleted.
        JR   L1F79        ;

;The file has been moved

L1FCB:  LD   A,$04        ; Page in logical RAM bank 4 (physical RAM bank 7).
        CALL L1BF3        ;

        LD   A,$00        ;
        LD   HL,$0014     ; AHL=20 bytes is the size of a catalogue entry.

L1FD5:  CALL L1C82        ; Delete a catalogue entry.

        LD   E,(IX+$0D)   ;
        LD   D,(IX+$0E)   ;
        LD   C,(IX+$0F)   ; CDE=File length of file entry to delete.

        LD   A,D          ;
        RLCA              ;
        RL   C            ;
        RLCA              ;
        RL   C            ; C=RAM bank.
        LD   A,D          ;
        AND  $3F          ; Mask off upper bits to leave length in this bank (range 0-16383).
        LD   D,A          ; DE=Length in this bank.

        PUSH IX           ; Save address of catalogue entry to delete.

L1FEE:  PUSH DE           ;
        LD   DE,$FFEC     ; -20 (20 bytes is the size of a catalogue entry).
        ADD  IX,DE        ; Point to next catalogue entry.
        POP  DE           ; DE=Length in this bank.

        LD   L,(IX+$0A)   ;
        LD   H,(IX+$0B)   ;
        LD   A,(IX+$0C)   ; AHL=File start address.
        OR   A            ;
        SBC  HL,DE        ; Will move into next RAM bank?
        SUB  C            ;
        BIT  6,H          ;
        JR   NZ,L2009     ; Jump if same RAM bank.

        SET  6,H          ; New address in next RAM bank.
        DEC  A            ; Next RAM bank.

L2009:  LD   (IX+$0A),L   ;
        LD   (IX+$0B),H   ;
        LD   (IX+$0C),A   ; Save new start address of file.

        LD   L,(IX+$10)   ;
        LD   H,(IX+$11)   ;
        LD   A,(IX+$12)   ; Fetch end address of file.
        OR   A            ;
        SBC  HL,DE        ; Will move into next RAM bank?
        SUB  C            ;
        BIT  6,H          ;
        JR   NZ,L2026     ; Jump if same RAM bank.

        SET  6,H          ; New address in next RAM bank.
        DEC  A            ; Next RAM bank.

L2026:  LD   (IX+$10),L   ;
        LD   (IX+$11),H   ;
        LD   (IX+$12),A   ; Save new end address of file.

        PUSH IX           ;
        POP  HL           ; HL=Address of next catalogue entry.

        PUSH DE           ;
        LD   DE,(SFNEXT)  ; $5B83.
        OR   A            ;
        SBC  HL,DE        ; End of catalogue reached?
        POP  DE           ; DE=Length in this bank.
        JR   NZ,L1FEE     ; Jump if not to move next entry.

        LD   DE,(SFNEXT)  ; $5B83. Start address of the next available catalogue entry.

        POP  HL           ;
        PUSH HL           ; HL=Start address of catalogue entry to delete.

        OR   A            ;
        SBC  HL,DE        ;
        LD   B,H          ;
        LD   C,L          ; BC=Length of catalogue entries to move.
        POP  HL           ;
        PUSH HL           ; HL=Start address of catalogue entry to delete.
        LD   DE,$0014     ; 20 bytes is the size of a catalogue entry.
        ADD  HL,DE        ; HL=Start address of previous catalogue entry.
        EX   DE,HL        ; DE=Start address of previous catalogue entry.
        POP  HL           ; HL=Start address of catalogue entry to delete.
        DEC  DE           ; DE=End address of catalogue entry to delete.
        DEC  HL           ; HL=End address of next catalogue entry.
        LDDR              ; Move all catalogue entries.

        LD   HL,(SFNEXT)  ; $5B83. Start address of the next available catalogue entry.
        LD   DE,$0014     ; 20 bytes is the size of a catalogue entry.
        ADD  HL,DE        ;
        LD   (SFNEXT),HL  ; $5B83. Store the new location of the next available catalogue entry.
        RET               ;

; ------------------------
; Print RAM Disk Catalogue
; ------------------------
; This routine prints catalogue filenames in alphabetically order.
; It does this by repeatedly looping through the catalogue to find
; the next 'highest' name.

L205F:  LD   A,$04        ; Page in logical RAM bank 4
        CALL L1BF3        ;  (physical RAM bank 7)

        LD   HL,L20AE     ; HL points to ten $00 bytes, the initial comparison filename.

L2067:  LD   BC,L20B8     ; BC point to ten $FF bytes.
        LD   IX,$EBEC     ; IX points to first catalogue entry.

L206E:  CALL L0590        ; Check for BREAK.

        PUSH IX           ; Save address of catalogue entry.

        EX   (SP),HL      ; HL points to current catalogue entry. Top of stack points to ten $00 data.
        LD   DE,(SFNEXT)  ; $5B83. Find address of next free catalogue entry.
        OR   A            ;
        SBC  HL,DE        ; Have we reached end of catalogue?

        POP  HL           ; Fetch address of catalogue entry.
        JR   Z,L209E      ; Jump ahead if end of catalogue reached.

        LD   D,H          ;
        LD   E,L          ; DE=Current catalogue entry.
        PUSH HL           ;
        PUSH BC           ;
        CALL L1C19        ; Compare current filename (initially ten $00 bytes).
        POP  BC           ;
        POP  HL           ;
        JR   NC,L2097     ; Jump if current catalogue name is 'above' the previous.

        LD   D,B          ;
        LD   E,C          ; DE=Last filename
        PUSH HL           ;
        PUSH BC           ;
        CALL L1C19        ; Compare current filename (initially ten $FF bytes).
        POP  BC           ;
        POP  HL           ;
        JR   C,L2097      ; Jump if current catalogue name is 'below' the previous.

        PUSH IX           ;
        POP  BC           ; BC=Address of current catalogue entry name.

L2097:  LD   DE,$FFEC     ; -20 (20 bytes is the size of a catalogue entry).
        ADD  IX,DE        ; Point to next catalogue entry.
        JR   L206E        ; Check next filename.

L209E:  PUSH HL           ; HL points to current catalogue entry.
        LD   HL,L20B8     ; Address of highest theoretical filename data.
        OR   A            ;
        SBC  HL,BC        ; Was a new filename to print found?
        POP  HL           ;
        RET  Z            ; Return if all filenames printed.

        LD   H,B          ;
        LD   L,C          ; HL=Address of current catalogue entry name.
        CALL L20C2        ; Print the catalogue entry.
        JR   L2067        ; Repeat for next filename.

; -----------------------------
; Print Catalogue Filename Data
; -----------------------------

L20AE:  DEFB $00, $00, $00, $00, $00  ; Lowest theoretical filename.
        DEFB $00, $00, $00, $00, $00

L20B8:  DEFB $FF, $FF, $FF, $FF, $FF  ; Highest theoretical filename.
        DEFB $FF, $FF, $FF, $FF, $FF

; ----------------------------
; Print Single Catalogue Entry
; ----------------------------
; Entry: HL=Address of filename.
;        BC=Address of filename.

L20C2:  PUSH HL           ; Save address of filename.

        PUSH BC           ;
        POP  HL           ; [No need to transfer BC to HL since they already have the same value].

        LD   DE,N_STR1    ; $5B67. Copy the filename to N_STR1 so that it
        LD   BC,$000A     ;        is visible when this RAM bank is paged out.
        LDIR              ;

        LD   A,$05        ; Page in logical RAM bank 5 (physical RAM bank 0).
        CALL L1BF3        ;

        LD   HL,(OLDSP)   ; $5B81.
        LD   (OLDSP),SP   ; $5B81. Save temporary stack.
        LD   SP,HL        ; Use original stack.

        LD   HL,N_STR1    ; $5B67. HL points to filename.
        LD   B,$0A        ; 10 characters to print.

L20DF:  LD   A,(HL)       ; Print each character of the filename.
        PUSH HL           ;
        PUSH BC           ;
        RST  28H          ;
        DEFW PRINT_A_1    ; $0010.
        POP  BC           ;
        POP  HL           ;
        INC  HL           ;
        DJNZ L20DF        ;

        LD   A,$0D        ; Print a newline character.
        RST  28H          ;
        DEFW PRINT_A_1    ; $0010.

        RST  28H          ;
        DEFW TEMPS        ; $0D4D. Copy permanent colours to temporary colours.

        LD   HL,(OLDSP)   ; $5B81.
        LD   (OLDSP),SP   ; $5B81. Save original stack.
        LD   SP,HL        ; Switch back to temporary stack.

        LD   A,$04        ; Page in logical RAM bank 4 (physical RAM bank 7).
        CALL L1BF3        ;

        POP  HL           ; HL=Address of filename.
        RET               ;


; ===============
; EDITOR ROUTINES
; ===============

; --------
; ????
; --------

L2101:  LD   HL,($FF62)   ; ???? Start address of a BASIC line in the Screen Buffer, used when copying a BASIC Line from Screen Buffer into the Editing Workspace.
        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        OR   A            ;
        SBC  HL,DE        ;
        CALL L213A        ; ???? A=HL*8. A=Row number
        LD   C,A          ;

        LD   A,$15        ; ????

        LD   HL,ED_FLGS   ; Point to the editor flags.
        BIT  7,(HL)       ; ????
        RES  7,(HL)       ;
        JR   NZ,L2123     ;

        LD   HL,($FF22)   ; ???? holds the next available address within the Screen Buffer when displaying a program.
        OR   A            ;
        SBC  HL,DE        ;
        CALL L213A        ; ???? A=HL*8.

L2123:  SUB  C            ;
        INC  A            ;
        LD   B,A          ;
        LD   A,C          ;
        BIT  7,A          ;
        JR   Z,L212C      ;

        XOR  A            ; Start at row 0.

L212C:  PUSH AF           ;
        PUSH BC           ;
        CALL L2EBF        ; Print Screen Buffer row.
        POP  BC           ;
        POP  AF           ;
        INC  A            ; Increment the row number.
        CP   $16          ; Reached row 22?
        RET  Z            ; Return if so.

        DJNZ L212C        ; Repeat for next row.

        RET               ;

; ----------
; A = HL * 8
; ----------
; Note that the initial state of the carry flag affects the low byte
; of the multiplication but since it is the high byte that is required
; the effects of the carry flag can be ignored.
; Entry: HL=Value to multiple.
;        Carry flag set as required.
; Exit : A=HL*8.

L213A:  LD   A,L          ;
        RLA               ;
        RL   H            ; HL=HL*2.
        RLA               ;
        RL   H            ; HL=HL*4.
        RLA               ;
        RL   H            ; HL=HL*8.

        LD   A,H          ; A=HL*8.
        RET               ;

; --------
; ????
; --------

L2146:  PUSH BC           ;
        PUSH DE           ;

        CALL L2B95        ; ???? Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.
        LD   (ED_LINE),BC ; $5B67. Store the line number of the BASIC line that contains the cursor.

; Exit: DE=Address within the Screen Buffer of the next BASIC line if there is one, else the next available Screen Buffer address.
;       HL=Address within the Screen Buffer of the start of the current BASIC line.
;       BC=Line number of the BASIC line that contains the cursor.


        POP  DE           ;
        PUSH HL           ;

        CALL L2388        ; Copy ???? from the Screen Buffer to the editing workspace, trimming out any null characters if present.

        LD   B,H          ; ????
        LD   C,L          ;
        POP  DE           ;
        POP  HL           ;
        RET  C            ; Return if the copying was not successful.
                          ; [Note that the call to $2388 always returns with the carry flag reset and hence this test is redundant]

; --------
; ???? populate rows in screen buffer
; --------
; Entry: HL=Address after the BASIC line.
;        DE=Start address of the BASIC line
;        BC=Address of the editing workspace.

L2159:  LD   A,$0A        ; Signal first row and first statement of a BASIC line.
        LD   (HD_0B+1),A  ; $5B73. Save as the display flags.

        OR   A            ; Clear the carry flag.
        SBC  HL,DE        ; HL=Length of the BASIC line.

;Determine how many rows are required to hold the BASIC line. The bits 5 and above of HL
;hold the fully populated row count, with bits 0-4 holding the character count within the
;final partially filled row.

        LD   A,L          ;
        OR   $1F          ; Force the final row character count to 31.
        LD   L,A          ;
        INC  HL           ; Increment the length such that the whole row count increases. Note that this
                          ; always rounds up even if there was not a partially filled final row.

        CALL L213A        ; A=HL*8, i.e. A holds the number of rows required to contain the BASIC line.

        LD   H,B          ; HL=Address of the BASIC line in the editing workspace.
        LD   L,C          ;

        LD   B,A          ; B=Number of rows required to contain the BASIC line.

;Enter a loop to populate as many rows of the Screen Buffer as are spanned by the BASIC line

L216C:  PUSH BC           ; Save the row counter.

        CALL L2899        ; Copy a row of the BASIC line into a row of the Screen Buffer. The display flags will be updated.
        CALL L2CA6        ; Null any remaining positions within this row of the Screen Buffer.

        BIT  1,A          ; Has the first row of the next BASIC line been reached?
        JR   NZ,L2194     ; Jump ahead if so. [This path could be taken due to the rounding up of the row count]

;There is another row of the current BASIC line to copy

        POP  BC           ; Fetch the row counter.
        DJNZ L216C        ; Repeat copying the remaining rows of the BASIC line.

;All specified rows populated but the still on ???? a row of basic line

        PUSH HL           ;
        CALL L2BC4        ; ???? scroll?
        POP  HL           ;
        LD   B,$01        ; Signal to populate one more row in the Screen Buffer.
        JR   C,L216C      ; Jump back if ???? to populate another row.

;????

        LD   HL,($FF22)   ; ???? holds the next available address within the Screen Buffer when displaying a program.
        LD   (HL),$FF     ; ???? remove cursor?

;Produce a warning rasp

        LD   D,$00        ;
        LD   E,(IY-$02)   ; RASP. Fetch the length of a warning rasp.
        LD   HL,$1A90     ; The rasp duration.
        RST  28H          ;
        DEFW BEEPER       ; $03B5. Produce a tone.
        RET               ;

;All rows of the BASIC line have been inserted into the Screen Buffer

L2194:  POP  BC           ; Fetch the row counter.
        DEC  B            ;
        RET  Z            ; ???? return if all specified rows populated?

L2197:  PUSH BC           ;
        CALL L3206        ; ????
        POP  BC           ;
        DJNZ L2197        ;

        RET               ;

; --------
; ???? copy a row of a BASIC line into the Screen Buffer
; --------
; Entry: BC=???? Address of the current BASIC line.
;        DE=???? address within the Screen Buffer?
; Exit : BC=Address of the next BASIC line.

L219F:  LD   L,$00        ; Count of ???? number of rows of BASIC line copied into the Screen Buffer.
        PUSH HL           ; Save the row counter.

        LD   A,$0A        ; Signal first row and first statement of a BASIC line.
        LD   (HD_0B+1),A  ; $5B73. Save as the display flags.

;Enter a loop to process each row of the BASIC line ????

L21A7:  LD   A,(HD_0B+1)  ; $5B73. Fetch the display flags.
        BIT  1,A          ; Is this the first row of the BASIC line?
        JR   Z,L21CC      ; Jump ahead if not.

;Processing the first row of the BASIC line

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).

        LD   H,B          ;
        LD   L,C          ; HL=Address of the current BASIC line.
        PUSH DE           ; Save the current Screen Buffer address.

        RST  28H          ; Find the address of the next BASIC line within the program area, returning it in DE.
        DEFW NEXT_ONE     ; $19B8. Also returns the address of the specified BASIC line in HL.

        LD   B,D          ; BC=Address of the next BASIC line.
        LD   C,E          ;
        PUSH BC           ; Save the address of the next BASIC line.

        CALL L2921        ; Attempt to copy all of the current BASIC line into the editing workspace.

        POP  BC           ; Fetch the address of the next BASIC line.
        POP  DE           ; Fetch the current Screen Buffer address.
        RET  C            ; Return if there is no current BASIC line.
                          ; [*BUG* - If this return is taken then the stack still contains the counter ???? and
                          ; hence a crash will occur. Credit: Paul Farrow]
                          ;???? can this bug ever occur? probably never taken. solution is pop/push surrounding ret

;The current BASIC line exists and was copied successfully to the editing workspace

        PUSH DE           ; Save registers.
        PUSH BC           ;
        PUSH HL           ;

        CALL L3680        ; De-tokenise the BASIC line held in the editing workspace.

        POP  HL           ; Restore registers.
        POP  BC           ;
        POP  DE           ;

        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

;Joins here when not the first row of the BASIC line. The editing workspace already contains
;a de-tokenised version of the BASIC line

L21CC:  PUSH BC           ; Save the address of the next BASIC line.

        CALL L2899        ; Copy a row of the BASIC line into a row of the Screen Buffer. The display flags will be updated.
        CALL L2CA6        ; Null any remaining positions within this row of the Screen Buffer.

;        Bit 0   : ????
;        Bit 1   : 1=On first row of the BASIC line.
;        Bit 2   : 1=Not within a quoted string.
;        Bit 3   : 1=Start of a new statement within the BASIC line.

        LD   A,(HD_0B+1)  ; $5B73. Fetch the display flags.
        POP  BC           ; Fetch the address of the next BASIC line.
        OR   A            ;
        JR   C,L21E1      ; [*BUG* - will never take the jump. Credit: Paul Farrow] ???? cause any problems?

        EX   (SP),HL      ;
        INC  L            ; Fetch the ???? row counter from the stack, increment it and then re-stack it.
        EX   (SP),HL      ;

        BIT  1,A          ; Is this the first row of the BASIC line?
        JR   Z,L21A7      ; Jump back if it is not.

;???? nothing in this routine changes the value of the display flags


;Exit the routine if the first row of the BASIC line

L21E1:  POP  HL           ; Fetch the ???? counter.

        EX   AF,AF'       ; Save the state of the flags. [Redundant instruction as flags never subsequently tested]

        LD   A,L          ; Fetch the column counter.
        LD   (ED_COL),A   ; $5B6B. ???? store the column counter

        EX   AF,AF'       ; Restore the state of the flags. [Redundant instruction as flags never subsequently tested]
        RET               ;


; =======================================
; BASIC EDITING MODE KEY HANDLER ROUTINES
; =======================================

; ---------------------------------------------------------------
; BASIC Editing Mode: EDIT Key Handler Routine (Main Screen Area)
; ---------------------------------------------------------------

L21E9:  POP  HL           ; ????
        RES  6,(IY-$3B)   ; $5BFF. Signal that the Editor keyword parameter is not out of range.

;????

L21EE:  CALL L2341        ; Initialise lower edit screen area.

;Return address after the first key press following an error and also when ????

L21F1:  LD   A,($5C8D)    ; ATTR_P. Save the permanent attribute colours.
        PUSH AF           ; 

        LD   A,($5C48)    ; BORDCR. Set the temporary and permanent to match the border colour.
        LD   ($5C8F),A    ; ATTR_T.
        LD   ($5C8D),A    ; ATTR_P.

        LD   A,$16        ; Row 22.
        CALL L2EBF        ; Print Screen Buffer row.

        POP  AF           ;
        LD   ($5C8D),A    ; ATTR_P. Restore the permanent attribute colours.

        LD   HL,L21F1     ; Stack a return address to this routine ????
        PUSH HL           ;

L220B:  BIT  6,(IY-$3B)   ; $5BFF. Is the Editor keyword parameter out of range?
        JP   Z,L2415      ; Jump ahead if not.

;The editor keyword parameter is out of range

        RES  6,(IY-$3B)   ; $5BFF. Clear the Editor keyword parameter out of range flag.

        RST  28H          ;
        DEFW CLS_LOWER    ; $0D6E. Clear the lower display screen editing area.

        XOR  A            ; Channel 0, the lower editing area.
        RST  28H          ;
        DEFW CHAN_OPEN    ; $1601. Open channel 0, i.e. the lower editing area.

        LD   DE,L04F9     ; "p PARAMETRO MAL".
        CALL L0537        ; Produce error report.

        LD   SP,TSTACK+1  ; $5BFF. Re-initialise the stack.
        JP   L23D2        ; Jump to restart the editor.

; -----------------------------------------------------------------------
; BASIC Editing Mode: CURSOR-LEFT Key Handler Routine (Lower Screen Area)
; -----------------------------------------------------------------------
; Exit: Zero flag set if cannot shift left, i.e. at row 0, column 0.

L2229:  LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   A,L          ;
        AND  $1F          ; Mask off the column.
        RET  Z            ; Return if at column 0.

        DEC  HL           ; Move to previous column.
        LD   (ED_POS),HL  ; $5B92. Store the new cursor position.
        RET               ;

; ------------------------------------------------------------------------
; BASIC Editing Mode: CURSOR-RIGHT Key Handler Routine (Lower Screen Area)
; ------------------------------------------------------------------------
; Exit: Carry flag set to indicate the cursor was moved.

L2235:  LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        CALL L26AE        ; Does the cursor position hold a null character?
        RET  Z            ; Return if it does.

        INC  HL           ; Advance to the next column.
        LD   (ED_POS),HL  ; $5B92. Store as the new cursor position.
        SCF               ; Signal the cursor could be moved.
        RET               ;

; ------------------------------------------------------------------
; BASIC Editing Mode: DELETE Key Handler Routine (Lower Screen Area)
; ------------------------------------------------------------------

L2242:  CALL L2229        ; Shift left one position via the CURSOR-LEFT routine, storing the new cursor position.
        RET  Z            ; Return if cannot shift left, i.e. at column 0.

;HL holds the offset of the new position within the Screen Buffer.

        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,DE        ; Add the offset location within the Screen Buffer.
        LD   A,(HL)       ; Fetch the character.
        CP   $08          ; Is it a colour control code parameter?
        JR   NC,L225B     ; Jump ahead if not.

;The character to be deleted is a parameter byte of a colour control code.

        DEC  HL           ; Point to the previous character that holds the colour control code.
        PUSH HL           ; Save the location.
        CALL L2264        ; Delete the parameter byte by shifting all subsequent characters along.
        CALL L2229        ; Shift left one position via the CURSOR-LEFT routine, storing the new cursor position.
        POP  HL           ; Fetch the location of the colour control code.
        JR   L2264        ; Jump ahead to delete the colour control code character by shifting all subsequent characters along.

L225B:  CP   $15          ; Is it a colour control code?
        JR   NC,L2264     ; Jump ahead if not.

;The character to be deleted is a colour control code.

        PUSH HL           ; Save the location of the colour control code.
        CALL L2264        ; Delete the colour control code by shifting all subsequent characters along.
        POP  HL           ; Fetch the location of the colour control code.

;Shift all characters along until the end of the lower screen area.

L2264:  LD   D,H          ; Transfer the destination location into DE.
        LD   E,L          ;
        INC  HL           ; Point to the first character to shift along.

L2267:  LD   A,(HL)       ; Fetch the character at the current position.
        LDI               ; Shift the character (even if the $FF terminator byte).
        INC  A            ; Test whether all characters have been shifted, i.e. character $FF found.
        JR   NZ,L2267     ; Jump back if not to shift the next character.

        RET               ;

; ------------------------------------
; Editor Main Loop (Lower Screen Area) ????
; ------------------------------------
; A key has been pressed and the editor is in the BASIC editing mode and the
; lower screen edit area is being used. This routine is used by the Editor main loop.
; Entry: A=Key code.
; Exit : Carry flag reset if the character could not be inserted.
;        A=Key code if character could not be inserted.

L226E:  PUSH AF           ; Save the key code.

        LD   HL,$02DE     ; Offset to row 22.

        LD   A,($5C3A)    ; ERR_NR.
        INC  A            ; Has there been an error?
        JR   NZ,L2280     ; Jump ahead if there has not.

;An error has occurred

        CALL L26AE        ; Does the cursor position hold a null character?
        JR   Z,L2280      ; Jump ahead if it does. ???? clear error?

;The cursor position holds a non-null character ????

        POP  AF           ; Fetch the key code.
        OR   A            ; Reset the carry flag to indicate the character could not be inserted.
        RET               ;

;An error has not occurred, or an error has occurred but has already been displayed ????

L2280:  CALL L2847        ; Is the cursor at the end of the Screen Buffer?
        LD   L,E          ;
        LD   H,D          ; HL=Address of the first unused position at the end of the Screen Buffer.
        DEC  HL           ; Point to the last used character.
        JR   Z,L228A      ; Jump ahead if the cursor is at the last position.

;The cursor is not at the end of the Screen Buffer so shuffle all characters along to make
;room for the new key press character.

        LDDR              ; Shift all characters after the cursor along.

L228A:  POP  AF           ; Fetch the key code.
        LD   (DE),A       ; Store it in the Screen Buffer.

        JR   L2235        ; Shift the cursor to the right.

; ----------------------------------------------------------------------
; BASIC Editing Mode: ENTER/EDIT Key Handler Routine (Lower Screen Area)
; ----------------------------------------------------------------------
; This routine handles the condition of the ENTER or EDIT key being pressed when the cursor is using the lower editing area.
; If the lower editing area is empty when the key is pressed then a switch to the main display is made and the BASIC program listed.

L228E:  LD   HL,L21EE     ; Change the stacked return address to be into the EDIT key handler routine. ????
        EX   (SP),HL      ;

        LD   HL,$02C0     ; Offset to row 22, column 0.
        CALL L284A        ; Is the cursor at the start of row 22, i.e. an null row?
        EX   DE,HL        ; HL=Address of the cursor, DE=First unused location within Screen Buffer, BC=Number of bytes until end of Screen Buffer.
        JR   NZ,L22AC     ; Jump if the cursor is not at the start of row 22, i.e. characters have been typed.

;The cursor is at the start of row 22 within the Screen Buffer, i.e. the edit line is empty

        CALL L234B        ; Blank row 22 of the Screen Buffer to $FF (null).

        LD   A,$16        ; Row 22.
        CALL L2EBF        ; Print Screen Buffer row.

        LD   A,($5AC1)    ; Fetch the attribute cell at row 22, column 1 and
        LD   ($5AC0),A    ; erase the cursor at attribute cell row 22, column 0.

        JP   L35D0        ; Jump to switch to the main edit area, displaying the program from the current edit line.

;The cursor is not at the start of the Screen Buffer, i.e. row 22 contains characters

L22AC:  LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.

        LD   (HL),$0D     ; Insert a carriage return at the location of the cursor.
        PUSH HL           ; Save the location of the cursor/carriage return.

        LD   HL,$02C0     ; Offset to row 22, column 0.
        ADD  HL,DE        ; HL=Address of start of row 22 within the Screen Buffer.
        POP  DE           ; Fetch the location of the cursor/carriage return.

        PUSH DE           ; Save the location of the cursor/carriage return.
        CALL L2388        ; Copy the BASIC line on row 22 of the Screen Buffer to the editing workspace.

        PUSH HL           ; Save the address of the editing workspace.

        CALL L234B        ; Blank row 22 of the Screen Buffer to $FF (null).

        LD   A,$16        ; Row 22.
        CALL L2EBF        ; Print the blanked Screen Buffer row.

        POP  HL           ; Fetch the address of the editing workspace.
        POP  DE           ; Fetch the location of the cursor/carriage return.

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).

        PUSH DE           ; Save the location of the cursor/carriage return.
        PUSH HL           ; Save the address of the editing workspace, containing the BASIC line.

        CALL L32CB        ; Is there a valid editor keyword line?

        POP  HL           ; Fetch the address of the editing workspace, containing the BASIC line.
        POP  DE           ; Fetch the location of the cursor/carriage return.
        JR   NC,L22E4     ; Jump if not a valid editor keyword line.

;There is a valid Editor keyword line, i.e. one of the four new editor keywords has been entered correctly
;At this stage, all commands support 0, 1 or 2 numeric parameters, and a range check has been performed to test
;that each parameter is between 1 and 9999. The only exception to this is the EDITAR command which also supports
;the name of a string variable as its parameter.

        LD   A,(HD_00)    ; $5B71. Fetch the Editor keyword index number (0=Edit string variable, 1=Delete, 2=Edit line, 3=Width, 4=Renumber).
        ADD  A,A          ; Double it to generate an offset into the Keyword handler jump table.
        LD   HL,L237B     ; Editor keyword handler table.
        LD   E,A          ;
        LD   D,$00        ;
        ADD  HL,DE        ; Find the location of the address of the handler routine in the table.

        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        JP   L257A        ; Jump ahead to fetch the handler routine address and execute it.

;The entered line does not form a valid new Editor command.
;[*BUG* - The syntax check of a new editor command can failed because a parameter was out of range even though a valid
;keyword was specified. Although the 'invalid parameter' flag held in $5BFF was set, it is not tested here
;before an attempt is made to interpret the line as a standard command. This attempt will generally result in
;an error report '2'. However, the code at $220B (ROM 0) will be executed when a new key press occurs and will
;test whether the 'invalid parameter' flag is set. If it is then the message 'Parameter error' is produced, although
;no error report letter code or line number information is shown. Credit: Paul Farrow]

L22E4:  

;[The bug can be fixed by inserting the following instructions. Credit: Paul Farrow]
;
;       BIT  6,(IY-$3B)   ; $5BFF. Was the parameter out of range flag set?
;       JP   NZ,$0EC8     ; Jump if so to produce error report "n Out of range".

        CALL L23A1        ; Attempt to execute the line.
        BIT  7,(IY+$00)   ; ERR_NR. Did an error occur?
        CALL NZ,L1ED4     ; If an error did not occur then select Workspace RAM configuration (physical RAM bank 7).
        JP   NZ,L2F20     ; Jump if an error did not occur. ???? list program to screen buffer and display file

;An error occurred

        LD   (IY+$00),$FF ; ERR_NR. Clear the error.
        CALL L2359        ; Insert a bug symbol within the edit line area.

        OR   A            ; Clear the carry flag.
        EX   DE,HL        ; DE=E_LINE which holds the de-tokenised BASIC line, HL=Address of the bug symbol in the workspace.
        SBC  HL,DE        ; HL=Offset within the workspace to the error marker.

        LD   BC,$02C0     ; 704=22*32.
        ADD  HL,BC        ; Offset to the lower screen area, i.e. row 22.
        LD   (ED_POS),HL  ; $5B92. Store as the cursor offset position.

        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,BC        ; Offset to the start of row 22.
        PUSH HL           ; Save the address of the start of row 22 in the Screen buffer.

        LD   HL,($5C61)   ; WORKSP. Fetch the address of the temporary workspace area.
        DEC  HL           ; Point to the terminator.
        DEC  HL           ; Point to the last character of the edit line.
        CALL L285F        ; BC=Length of the edit line. HL=E_LINE.

        POP  DE           ; Fetch the address of the start of row 22 in the Screen buffer.
        LD   A,C          ;
        CP   $20          ; Does the edit line conists of 32 characters or more?
        JR   C,L2327      ; Jump if there are less.

;There are 32 characters typed in the edit line area

        LD   C,$1F        ; Column 31.
        PUSH HL           ; Save the address of E_LINE.

        LD   HL,ED_POS    ; $5B92. The cursor offset position within the Screen Buffer.
        LD   A,$DE        ; Low byte of cursor offset for position row 23 column 30.
        CP   (HL)         ; Is the cursor at column 31 or above?
        JR   NC,L2326     ; Jump ahead if not.

;The cursor is at column 31 or above so force it to be in column 31

        INC  A            ; Row 23 column 31.
        LD   (HL),A       ; Set the cursor offset position to row 23 column 31.

L2326:  POP  HL           ; Fetch the address of E_LINE.

;HL=Address of E_LINE where the edited line resides (conventional RAM).
;DE=Address if the start of row 22 in the Screen buffer (logical RAM bank 4, physical RAM bank 7).
;BC=Length of the edited line.

L2327:  CALL L1E5E        ; Transfer the edited line to the Screen Buffer (using the Save RAM Disk vector entry routine).

        LD   A,$16        ; Row 22.
        CALL L2EBF        ; Copy the Screen Buffer row to the display file.

        CALL L257F        ; Wait for a key press.
        PUSH AF           ; Save the key code.

        CALL L2235        ; Attempt to shift the cursor to the right.
        CALL C,L2242      ; If it was moved then delete the character to the left, i.e. the bug symbol.

        POP  AF           ; Fetch the key code.
        LD   HL,L21F1     ; Change the stacked return address to be into the Editor.
        EX   (SP),HL      ;
        JP   L2418        ; Jump ahead to process the key press code.

; ---------------------------------
; Initialise Lower Edit Screen Area
; ---------------------------------

L2341:  SET  3,(IY-$3B)   ; $5BFF. Signal using lower edit screen area.

        LD   HL,$02C0     ; Row 22, column 0.
        LD   (ED_POS),HL  ; $5B92. Store as new cursor position.

; ----------------------------
; Blank Lower Edit Screen Area
; ----------------------------

L234B:  LD   BC,$0020     ; 32 columns.
        LD   A,$16        ; Row 22.
        CALL L3168        ; Blank row of Screen Buffer contents to $FF (null).

; -----------------------------------------------------------------------
; BASIC Editing Mode: SHIFT-TOGGLE Key Handler Routine (Main Screen Area)
; -----------------------------------------------------------------------

L2353:  LD   HL,FLAGS3    ; $5B66.
        SET  0,(HL)       ; Signal BASIC/Calculator mode.
        RET               ;

; -------------------------------------
; Insert Error Marker in Edit Line Area
; -------------------------------------
; This routine is reponsible for de-tokenising a BASIC and inserting a 'bug' error marker
; symbol at the error postion within the line.
; Exit: HL=Points to the start of the de-tokenised BASIC line.

L2359:  LD   HL,($5C59)   ; E_LINE.
        PUSH HL           ; Save the address of E_LINE, i.e. the start of the BASIC line.

        CALL L3680        ; De-tokenise the BASIC line.

        LD   HL,($5C5F)   ; X_PTR. Address of the character after the error marker.
        CALL L29A2        ; Create room for 1 byte at HL.
        LD   A,$FE        ; 'Bug' symbol.
        LD   (DE),A       ; Store a bug symbol in the edit line area at the error marker location.

        POP  HL           ; Fetch the address of E_LINE, i.e. the start of the BASIC line.
        RET               ;

; --------------------------------------------------------
; BASIC Editing Mode Keys Action Table - Lower Screen Area 
; --------------------------------------------------------

L236B:  DEFB $08          ; Key code: Cursor Left.
        DEFW L2229        ; CURSOR-LEFT handler routine.
        DEFB $09          ; Key code: Cursor Right.
        DEFW L2235        ; CURSOR-RIGHT handler routine.
        DEFB $0C          ; Key code: Delete.
        DEFW L2242        ; DELETE handler routine.
        DEFB $0D          ; Key code: Enter.
        DEFW L228E        ; ENTER handler routine.
        DEFB $07          ; Key code: Edit.
        DEFW L228E        ; EDIT handler routine.
        DEFB $00          ; End Marker.

; ---------------------------------
; Editor Keyword Handler Jump Table
; ---------------------------------

L237B:  DEFW L38D7        ; EDITAR (edit string variable) routine.
        DEFW L3581        ; BORRAR (delete) routine
        DEFW L35C7        ; EDITAR (edit line) routine.
        DEFW L35BA        ; WIDTH (width) routine
        DEFW L33E5        ; NUMERO (renumber) routine.

; ---------------------------------------------------------------------------------------
; Copy the BASIC Line Containing the Cursor from Screen Buffer into the Editing Workspace
; ---------------------------------------------------------------------------------------

L2385:  CALL L275A        ; Find the address after the BASIC line containing the cursor, returning it in DE.

; ---------------------------------------------------------------
; Copy a BASIC Line from Screen Buffer into the Editing Workspace
; ---------------------------------------------------------------
; Entry: HL=Start address of a BASIC line in the Screen Buffer.
;        DE=Address after the BASIC line in the Screen Buffer.
; Exit:  Carry flag reset to indicate success.
;        HL=Address of the area created in the editing workspace.
;        DE=Address of the last byte copied into the editing workspace.

L2388:  LD   ($FF62),HL   ; Save the start address.

        PUSH HL           ; Save the start address.
        CALL L2867        ; Filter out all null characters between the start and end addresses in the Screen Buffer.
        POP  HL           ; Fetch the start address.

;HL holds the start address and DE holds the new end address once all null characters have been trimmed out

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        CALL L298A        ; Create room in the editing workspace for the BASIC line.
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

;HL holds the start address, BC holds the room created, and DE the address of the area created in the editing workspace for the BASIC line

        PUSH DE           ; Save the address of the area created in the editing workspace.

        CALL L1E93        ; Copy the characters from the Screen Buffer to the editing workspace.
        DEC  DE           ; Point to the last destination byte copied.

        POP  HL           ; Fetch the address of the area created in the editing workspace.
        AND  A            ; Signal success.
        RET               ;

; ---------------------------
; Attempt to Execute the Line
; ---------------------------
; Entry: HL=Address of the typed in line to execute.

L23A1:  PUSH HL           ; Save the address of the line.
        CALL L3620        ; Tokenise the typed in line.
        POP  HL           ; Fetch the start address the line.

        CALL L0244        ; Attempt to execute the tokenised line.

        LD   HL,FLAGS3    ; $5B66.
        RES  0,(HL)       ; Signal Editor mode.

        LD   HL,($5C59)   ; E_LINE. Point to the edit line area.
        RST  28H          ;
        DEFW REMOVE_FP    ; $11A7. Remove hidden floating point number representations from the edit line.

; ------------
; Produce Beep
; ------------
; Used to produce success or error beep from above, and also called to produce the start-up beep (same tone as success beep).

L23B4:  LD   HL,$00A0     ;
        BIT  7,(IY+$00)   ; ERR_NR. Did an error occur?
        JR   NZ,L23BF     ; Jump ahead if not.

        LD   H,$02        ; Use a different tone for the error beep.

L23BF:  LD   DE,$0032     ;
        RST  28H          ;
        DEFW BEEPER       ; $03B5. Produce a tone.
        RET               ;

; ---------------
; Editor Start Up
; ---------------

L23C6:  CALL L23B4        ; Produce the start up beep.

        LD   HL,TSTACK+1  ; $5BFF. Point to the top of the temporary stack.
        LD   (OLDSP),HL   ; $5B81. Store as the 'old' stack.

        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

; --------------
; Editor Restart
; --------------
; Joins here upon a parameter error when the EDIT key is pressed.

L23D2:  CALL L30BF        ; Construct 'Copy Character' routine in RAM.

        LD   HL,$EC00     ;
        LD   ($FF24),HL   ; Store the address of the Screen Buffer.

        LD   A,$FF        ;
        LD   ($5C3A),A    ; ERR_NR. Set no error.

        SET  3,(IY+$01)   ; FLAGS. Select L-Mode.

        LD   HL,$0000     ;
        LD   (ED_EDIT),HL ; $5B94. Signal no line number to edit.

        LD   HL,$5AC0     ; Address of row 22 of the attributes file.
        LD   (ED_ATTA),HL ; $5B69. Store as the address of the cursor within the attributes file.

        LD   A,($5C8D)    ; ATTR_P.
        LD   (ED_ATTP),A  ; $5B77. Store the permanent attribute colours as the colour at the cursor location.

        CALL L2341        ; Initialise lower edit screen area.

        LD   HL,L21F1     ; ????
        PUSH HL           ;

        CALL L2599        ; Wait for a key press.
        JR   L2418        ; Jump ahead to process the key press.

; ----------------
; Editor Main Loop ???? upper area or lower area?
; ----------------

L2402:  LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   ($FF22),HL   ; ???? holds the next available address within the Screen Buffer when displaying a program.
        LD   ($FF62),HL   ; ???? Start address of a BASIC line in the Screen Buffer, used when copying a BASIC Line from Screen Buffer into the Editing Workspace.

        LD   SP,TSTACK+1  ; $5BFF. Use a temporary stack.

;Return entry point into the Editor after executing a key code handler routine within
;the main screen area

L240E:  CALL L2101        ; ????

;Return entry point into the Editor ????

L2411:  LD   HL,L240E     ; Return address to the Editor.
        PUSH HL           ; Stack it.

;Entry point into the Editor from the EDIT key press handler and ???? invalid keyword?

L2415:  CALL L257F        ; Wait for a key press.

;Enters here with the first key press after the Editor starts up or after an error has occurred

L2418:  PUSH AF           ; Save the key code.

        LD   D,$00        ;
        LD   E,(IY-$01)   ; PIP. Fetch the note value. 
        LD   HL,$00C8     ;
        RST  28H          ;
        DEFW BEEPER       ; $03B5. Produce a key click.

        POP  AF           ; Fetch the key code.

        LD   HL,ED_FLGS   ; $5BFF. Editor flags.
        RES  5,(HL)       ; Signal not to copy the Screen Buffer to the display.

        CP   $A3          ; Is it a keypad code?
        JP   NC,L2553     ; Jump if a keypad code to locate and execute the key code handler routine.

        CP   $20          ; Is it a printable code?
        JR   NC,L2466     ; Jump ahead if so.

        CP   $10          ; Is it a colour control code?
        JR   NC,L2458     ; Jump ahead if so.

        CP   $07          ; Is it a cursor key?
        JP   NC,L2553     ; Jump if so to locate and execute the key code handler routine.

;Key press display control codes $00-$06.
;A single byte is used to encode whether a FLASH or BRIGHT control and also the ON/OFF status value.
;The byte is formatted as follows:
;
; +---+---+---+---+---+---+---+---+
; |   |   |   |   |   | c | c | p |
; +---+---+---+---+---+---+---+---+
;
; Bits cc represents control code (%00 for FLASH, %01 for BRIGHT and %10 for INVERSE), and p represents the status value (%0 for OFF to %1 for ON).

        LD   B,$00        ; B will hold the parameter value.
        AND  A            ; Clear the carry flag.
        RRA               ; A=$00-$03 (though value $11 is not valid).
        RL   B            ; Extract the parameter value ($00 or $01).
        ADD  A,$12        ; A=$12 for FLASH, $13 for BRIGHT and $14 for INVERSE.

;Joins here from the colour control codes routine below

L2444:  PUSH BC           ; Save registers.
        PUSH HL           ;

        CALL L2466        ; Process the control code.

        POP  HL           ; Restore registers.
        POP  BC           ;
        RET  NC           ; Return if the character could not be processed.

        LD   A,B          ; Fetch the parameter byte ($00 or $01).
        PUSH HL           ;

        CALL L2466        ; Process the parameter value.

        POP  HL           ;
        LD   A,$0C        ; Control code ????
        JP   NC,L2553     ; Jump if the parameter could not be processed to execute the key code handler for ????.

        RET               ; The control code was processed successfully.

;Key press colour control codes $10-$1F.
;A single byte is used to encode whether an INK or PAPER control and also the colour value.
;The byte is formatted as follows:
;
; +---+---+---+---+---+---+---+---+
; |   |   |   | c | c | p | p | p |
; +---+---+---+---+---+---+---+---+
;
;Bits cc represents control code (%10 for INK and %11 for PAPER), and ppp represents the colour value (%000 for BLACK to %111 for WHITE).

L2458:  LD   C,A          ; Save the control byte.
        AND  $07          ;
        LD   B,A          ; B=$00-$07. The control colour, i.e. the parameter value.

        LD   A,C          ; Fetch the control byte.
        AND  $F8          ; Keep the control code bits only.
        RRA               ;
        RRA               ;
        RRA               ; A=$02-$03.
        ADD  A,$0E        ; A=$10 for INK or $11 for PAPER.
        JR   L2444        ; Jump to process the control code and parameter.

;Printable character codes $20-$A2, and also formed colour control codes $10-$13 (and their parameter byte)

L2466:  BIT  4,(HL)       ; 1=Variable editing mode, 0=BASIC editing mode.
        JP   NZ,L3DAD     ; Jump if string variable editing mode.

;BASIC editing mode

        BIT  3,(HL)       ; 1=Lower edit screen area, 0=Main edit screen area.
        JP   NZ,L226E     ; Jump if lower edit screen area being used.

;Main edit screen area being used

        LD   HL,FLAGS3    ; $5B66.
        SET  1,(HL)       ; Signal BASIC/Calculator mode.

        PUSH AF           ; Save the key code.

        CALL L2847        ; Is the cursor at the end of the Screen Buffer?

        LD   H,D          ;
        LD   L,E          ; HL=Address of the first unused position at the end of the Screen Buffer.
        DEC  HL           ; Point to the last used character.
        EX   AF,AF'       ; Save the zero flag. It will be set if the cursor is at the end of the Screen Buffer.

        POP  AF           ; Fetch the key code.

        PUSH DE           ; Save the address of the first unused position at the end of the Screen Buffer.
        EX   AF,AF'       ; Is the cursor at this last position?
        JR   Z,L2484      ; Jump ahead if it is.

;The cursor is not at the end of the Screen Buffer so shuffle all characters along to make
;room for the new key press character.

        LDDR              ; Shift all characters after the cursor along.

L2484:  EX   AF,AF'       ; Retrieve the key code.
        LD   (DE),A       ; Store it in the Screen Buffer.

        POP  DE           ; Fetch the address of the last used position within the Screen Buffer.
        LD   B,D          ;
        LD   C,E          ; BC=Address of the last used position within the Screen Buffer.

        INC  DE           ; Point to the new first unused position at the end of the Screen Buffer.

        CALL L2146        ; ????

        LD   HL,($FF22)   ; ???? holds the next available address within the Screen Buffer when displaying a program.
        CALL L24A8        ; ???? Search forwards in the Screen Buffer for a non-null character.
        JR   NZ,L2498     ; Jump ahead if a non-null character was found.

        LD   ($FF1E),HL   ; ???? Next Line Screen Buffer Mapping.

L2498:  CALL L26B9        ; ???? CURSOR-RIGHT key handler routine.

        LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        DEC  HL           ;
        CALL L26AE        ; Does the cursor position hold a null character?
        INC  HL           ;
        SCF               ; Signal ????
        RET  NZ           ; Return if it does not.

        JP   L26B9        ; ???? CURSOR-RIGHT key handler routine.

; -------------------------------------------------------------
; Search Forwards in the Screen Buffer for a Non-Null Character
; -------------------------------------------------------------
; This routine searches to the right for the first non-null character.
; Entry: HL=Address within the Screen Buffer to search from.
; Exit : Zero flag reset if a non-null character was found.

L24A8:  PUSH HL           ; Save the address within the Screen Buffer.

        LD   DE,$FE80     ; ???? Address of the Banner Display Buffer. ???? end of Screen Buffer?
        EX   DE,HL        ; HL=Address of the Banner Display Buffer, DE=Address within the Screen Buffer.
        OR   A            ;
        SBC  HL,DE        ; HL=Maximum number of characters to search.
        EX   DE,HL        ; HL=Address within the Screen Buffer, DE=Maximum number of characters to search.

L24B1:  LD   A,(HL)       ; Does the location hold a null character?
        INC  A            ;
        JR   NZ,L24BB     ; Jump ahead if so to make a return with zero flag reset.

;The location holds a null character

        INC  HL           ; Next character location.
        DEC  DE           ; Decrement the character counter.
        LD   A,D          ;
        OR   E            ;
        JR   NZ,L24B1     ; Repeat for all buffer characters.

;A non-null character was not found so return with the zero flag set

L24BB:  POP  HL           ; Restore the address within the Screen Buffer.
        RET               ;

; -----------------------------------------------------------------
; BASIC Editing Mode: DELETE Key Handler Routine (Main Screen Area)
; -----------------------------------------------------------------

L24BD:  LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   A,L          ;
        OR   H            ;
        RET  Z            ; Return if it is at the top left location, i.e. nothing to delete.

;There is a position to the left of the cursor so move the cursor offset position

        DEC  HL           ; Move to the previous location.
        JR   L24C9        ; Continue in the DELETE-RIGHT routine, i.e. delete the character since it is now to the right of the cursor location.

; -----------------------------------------------------------------------
; BASIC Editing Mode: DELETE-RIGHT Key Handler Routine (Main Screen Area)
; -----------------------------------------------------------------------

L24C6:  LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.

;Joins here from the DELETE key handler routine

L24C9:  LD   A,(FLAGS3)   ; $5B66.
        OR   $02          ; Signal a delete operation.
        LD   (FLAGS3),A   ; $5B66.

        CALL L26AE        ; Does the cursor position hold a null character?
        RET  Z            ; Return if it does since there is nothing to delete.

        DEC  A            ; Restore the code of the character at the cursor position.
        CP   $08          ; Is it a cursor editing or colour control?
        JR   NC,L24E5     ; Jump ahead if so.

;Colour values $00-$07, i.e. must be part of an INK or PAPER control code

        PUSH HL           ; Save the cursor offset position.

        CALL L24EE        ; Delete the colour value.
        CALL L2640        ; Move the cursor left one position.

        POP  HL           ; Retrieve the cursor offset position.
        DEC  HL           ; Move to the previous location.
        JR   L24EE        ; Jump ahead to delete the colour control.

;It is a cursor, colour control or printable code

L24E5:  CP   $15          ; Is it a colour control code?
        JR   NC,L24EE     ; Jump ahead if it is not.

;It is a colour control code (INK, PAPER, FLASH, BRIGHT or INVERSE) and so there is the control code and its parameter to delete

        PUSH HL           ; Save the cursor offset position.
        CALL L24EE        ; Delete the control code, then continue below to delete the parameter value.
        POP  HL           ; Retrieve the cursor offset position.

;Delete a character

L24EE:  LD   IX,EB_FLGS   ; $5B72. ????
        RES  5,(IX+$00)   ; ???? assume rows will not need to be shifted up

        LD   (ED_POS),HL  ; $5B92. Store the new cursor offset position.
        LD   A,L          ;
        OR   H            ;
        JR   Z,L251A      ; Jump if the cursor is in the top left position, i.e. nothing to delete.

;There is a character available to delete

        DEC  HL           ; Move to the previous position.
        CALL L26AE        ; Does this position hold a null character?
        INC  HL           ; Move back to the current position.
        JR   NZ,L251A     ; Jump if it does not.

;The previous position holds a null character

        PUSH HL           ; Save the current position.

        CALL L2B95        ; ???? Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.

; Exit: DE=Address within the Screen Buffer of the next BASIC line if there is one, else the next available Screen Buffer address.
;       HL=Address within the Screen Buffer of the start of the current BASIC line.
;       BC=Line number of the BASIC line that contains the cursor.

        LD   BC,($FF24)   ; Fetch the address of the Screen Buffer.
        AND  A            ;
        SBC  HL,BC        ; HL=????

        POP  DE           ; Fetch the current position.
        PUSH DE           ;
        SBC  HL,DE        ;
        JR   Z,L2519      ; Jump if ????

        SET  5,(IX+$00)   ; ???? must shift rows up

L2519:  POP  HL           ;

;Joins here when the cursor is at the top left position and hence there is nothing to delete

L251A:  CALL L284A        ; Is the cursor at the end of the Screen Buffer?
        PUSH DE           ;
        LD   D,H          ;
        LD   E,L          ;
        JR   Z,L2525      ; Jump ahead if so.

;The cursor is not at the end of the Screen Buffer

        INC  HL           ;
        LDIR              ; ???? Shuffle bytes along.

L2525:  DEC  DE           ;
        POP  BC           ;
        CALL L2146        ;
        JP   C,L301B      ; Jump if ???? to copy the Screen Buffer to the display file.

        LD   HL,($FF22)   ; ???? holds the next available address within the Screen Buffer when displaying a program.
        CALL L24A8        ; ???? Search forwards in the Screen Buffer for a non-null character.
        JR   NZ,L2538     ;

        LD   ($FF1E),HL   ; ???? Next Line Screen Buffer Mapping.

L2538:  LD   IX,EB_FLGS   ; $5B72.
        BIT  5,(IX+$00)   ; ???? rows need shifting up?
        JP   Z,L301B      ; Jump if not ???? to copy the Screen Buffer to the display file.

        LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   A,L          ;
        OR   $1F          ;
        LD   L,A          ;
        LD   (ED_POS),HL  ; $5B92. ????

        CALL L25D3        ; Move the cursor up one row.
        JP   L301B        ; Jump to copy the Screen Buffer to the display file.

; --------------------------------
; Execute Key Code Handler Routine
; --------------------------------
; This routine executes the key handler routine for the specified key code.
; The handler used for a key code depends on which editing mode is active.
; Entry: HL=$5BFF (ED_FLGS, Editor flags system variable).
;        A=Key code.
;
; The following table indicates via a 'x' which functions are supported in each editing mode.
;
; Mode 1=BASIC editing within main screen area.
; Mode 2=BASIC editing within lower screen area.
; Mode 3=String variable editing.
;
; Code  Function            Mode: 1   2   3
; ----  --------                  -   -   -
; $07   EDIT                      x   x   x
; $08   CURSOR-LEFT               x   x   x
; $09   CURSOR-RIGHT              x   x   x
; $0A   CURSOR-DOWN               x   -   x
; $0B   CURSOR-UP                 x   -   x
; $0C   DELETE                    x   x   x
; $0D   ENTER                     x   x   x
; $A5   END-OF-DATA               -   -   x
; $A6   TOP-OF-DATA               -   -   x
; $A7   END-OF-LINE               x   -   x
; $A8   START-OF-LINE             x   -   x
; $A9   CYCLE-MODE                -   -   x
; $AA   DELETE-RIGHT              x   -   x
; $AC   LINE-DOWN                 x   -   x
; $AD   LINE-UP                   x   -   x
; $AE   WORD-RIGHT                -   -   x
; $AF   WORD-LEFT                 -   -   x
; $B0   DELETE-TO-END-OF-ROW      -   -   x
; $B1   DELETE-TO-START-OF-ROW    -   -   x
; $B2   WORD-WRAP-TOGGLE          x   -   x
; $B3   DELETE-WORD-RIGHT         -   -   x
; $B4   DELETE-WORD-LEFT          -   -   x

L2553:  BIT  4,(HL)       ; Variable editing mode or BASIC editing mode?
        JR   Z,L255C      ; Jump if BASIC editing mode.

;Variable editing mode

        LD   HL,L3903     ; HL=Address of the editing keys action table.
        JR   L2575        ; Jump ahead to continue.

;BASIC editing mode

L255C:  BIT  3,(HL)       ; Using lower or main edit screen area?
        JR   Z,L2565      ; Jump if using main edit screen area.

;Lower edit screen area

        LD   HL,L236B     ; Address of the lower screen area key actions table.
        JR   L2575        ; Jump ahead to continue.

;Main edit screen area

L2565:  LD   HL,L2411     ; Stack the return address to the Editor main loop.
        EX   (SP),HL      ;

        PUSH AF           ; Save the key code.
        CALL L2B95        ; Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.
        POP  AF           ; Fetch the key code.
        LD   (ED_LINE),BC ; $5B67. Save the line number of the BASIC line that contains the cursor.

        LD   HL,L35F8     ; Address of the main screen area key actions table.

L2575:  LD   C,A          ; C=Key code.
        CALL L25CA        ; Find the table entry matching this key code.
        RET  NC           ; Return if the key code does not have an associated handler routine.

L257A:  LD   A,(HL)       ; Fetch the handler routine address.
        INC  HL           ;
        LD   H,(HL)       ;
        LD   L,A          ;
        JP   (HL)         ; Jump to the handler routine.

; --------------------
; Wait for a Key Press
; --------------------
; This routine awaits a key press, handling changes of mode. It sets the cursor position to a blue square with white ink,
; restoring the cell colour after a key has been pressed.
; Exit: A=Key code.
;
; The range of key control codes supported and returned is as follows:
;
; $00   FLASH OFF
; $01   FLASH ON
; $02   BRIGHT OFF
; $03   BRIGHT ON
; $04   INVERSE OFF
; $05   INVERSE ON
; $06   -
; $07   EDIT
; $08   CURSOR LEFT
; $09   CURSOR RIGHT
; $0A   CURSOR DOWN
; $0B   CURSOR UP
; $0C   DELETE
; $0D   ENTER
; $0E   -
; $0F   -
; $10   INK BLACK
; $11   INK BLUE
; $12   INK RED
; $13   INK MAGENTA
; $14   INK GREEN
; $15   INK CYAN
; $16   INK YELLOW
; $17   INK WHITE
; $18   PAPER BLACK
; $19   PAPER BLUE
; $1A   PAPER RED
; $1B   PAPER MAGENTA
; $1C   PAPER GREEN
; $1D   PAPER CYAN
; $1E   PAPER YELLOW
; $1F   PAPER WHITE
; ...
; $A5   END OF PROGRAM
; $A6   TOP OF PROGRAM
; $A7   END OF LINE
; $A8   START OF LINE
; $A9   TOGGLE
; $AA   DELETE RIGHT
; $AC   TEN ROWS DOWN
; $AD   TEN ROWS UP
; $AE   WORD RIGHT
; $AF   WORD LEFT
; $B0   DELETE TO END OF LINE
; $B1   DELETE TO START OF LINE
; $B2   SHIFT TOGGLE
; $B3   DELETE WORD RIGHT
; $B4   DELETE WORD LEFT

L257F:  LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   DE,$5800     ; Address of the attributes file.
        ADD  HL,DE        ; HL=Location of the cursor position within the attributes file.
        LD   A,(HL)       ; Fetch the attribute cell colour.
        LD   (ED_ATTA),HL ; $5B69. Store the address of the cursor position within the attributes file.
        LD   (ED_ATTP),A  ; $5B77. Store the original attribute value located at the cursor position.

        AND  $C0          ; Keep the flash and bright bits.
        XOR  $CF          ; Toggle the flash and bright bits, and set paper to blue and ink to white.
        LD   (HL),A       ; Replace the attribute cell value.

        RES  0,(IY+$07)   ; MODE. Cancel 'E' mode.

L2596:  CALL L2DEC        ; Display editor banner.

L2599:  LD   HL,$5C08     ; LAST_K.
        LD   A,$FF        ;
        LD   (HL),A       ; Clear the last key value.

L259F:  CP   (HL)         ; Has a key been pressed?
        JR   Z,L259F      ; Jump back if no key has been pressed.

        RES  5,(IY+$01)   ; FLAGS. Clear the new key flag.

        LD   A,(HL)       ; Fetch the key code.
        CP   $06          ; Is it the print comma position character?
        JR   Z,L25B3      ; Jump ahead if so to handle via ROM 1.

        CP   $0E          ; Is it a cursor key, Edit, Delete or Enter number?
        JR   C,L25BE      ; Jump ahead if so.

        CP   $10          ; Is it a colour or position control code?
        JR   NC,L25BE     ; Jump ahead if so.

;Drop down here with codes $0E and $0F

L25B3:  CP   $06          ; Is it a mode code? Zero flag will be reset if so.
        RST  28H          ;
        DEFW KEY_M_CL     ; $10DB. Handle CAPS LOCK code and 'mode' codes via ROM 1.
        RES  3,(IY+$02)   ; TVFLAG. Signal the mode has not changed.

        JR   L2596        ; Jump back to await another key press.

;It is a cursor key, Edit, Delete, Enter, colour control or position control code

L25BE:  LD   E,A          ; Save the key code.

        LD   A,(ED_ATTP)  ; $5B77. Fetch the original value of the attribute cell where the cursor is displayed.
        LD   HL,(ED_ATTA) ; $5B69. Fetch the address of the cursor position within the attributes file.
        LD   (HL),A       ; Restore the cell with the original value.

        LD   A,E          ; Fetch the key code.
        RET               ;

; -------------------------
; Find Key Code Table Entry
; -------------------------
; Entry: HL=Address of the table to search.
;        C =Key code to find.
; Exit:  Carry flag set if a match was found.

L25C8:  INC  HL           ; Advance to point at the next table entry key code.
        INC  HL           ;

;Entry point

L25CA:  LD   A,(HL)       ; Fetch the key code field from the table entry.
        AND  A            ;
        RET  Z            ; Return if the end of the table has been reached, with the carry flag reset.

        CP   C            ; Has the specified key code been found?
        INC  HL           ; Point to the first byte of the handler routine address.
        JR   NZ,L25C8     ; Jump if not to test the next table entry.

        SCF               ; Signal that a match was found.
        RET               ;

; --------------------------------------------------------------------
; BASIC Editing Mode: CURSOR-UP Key Handler Routine (Main Screen Area)
; --------------------------------------------------------------------
; Move up 1 row, attempting to place the cursor as close to the preferred column number as possible.
; Exit: Carry flag set if the cursor was moved, else reset if at the top of the program.
;       Zero flag set if the BASIC line containing the cursor has not changed.

L25D3:  LD   HL,EB_FLGS   ; $5B72.
        RES  7,(HL)       ; Signal up/left ????

        LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   DE,$0020     ;
        OR   A            ;
        SBC  HL,DE        ; Subtract 32 positions to move up 1 row.
        JR   NC,L2619     ; Jump if new position is still within the Screen Buffer, i.e. on row 0 or above,
                          ; to locate the nearest non-null character and store cursor at this position.

;Moving up off the screen

        CALL L2CE4        ; ???? scroll down in Screen Buffer?
        RET  NC           ; Return if at top of the BASIC program.

        JR   L2619        ; Jump ahead to store the new cursor position.

; ----------------------------------------------------------------------
; BASIC Editing Mode: CURSOR-DOWN Key Handler Routine (Main Screen Area)
; ----------------------------------------------------------------------
; Exit: A=New cursor column number. ????
;       Carry flag set if the cursor was moved.
;       Zero flag set if ???? the BASIC line containing the cursor has not changed.

L25E9:  LD   HL,EB_FLGS   ; $5B72.
        SET  7,(HL)       ; Signal down/right ????

        LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   DE,$02A0     ; 672=21 rows.
        OR   A            ;
        SBC  HL,DE        ;
        JR   C,L25FF      ; Jump if the cursor is before row 21.

;On row 21

        CALL L2CB1        ; ????
        LD   A,$FF        ; Signal ????
        RET  NC           ;

;Before row 21 or ????

L25FF:  LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   BC,$0020     ;
        ADD  HL,BC        ; Move down 32 positions, i.e. 1 row.
        PUSH HL           ; Save the new cursor position address.

        LD   A,L          ;
        AND  $E0          ; Keep only the row bits, i.e. set to column 0.
        LD   L,A          ;
        LD   BC,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,BC        ; HL=Start of the row in the Screen Buffer.
        CALL L24A8        ; Search to the remainder of the Screen Buffer for a non-null character.

        POP  HL           ; HL=New cursor position.
        JR   NZ,L2619     ; Jump if a non-null character was found.

;A non-null character was not found, i.e. the remainder of the Screen Buffer is completely empty

        LD   A,$00        ; ???? Set the cursor column number to $00.
#ifndef BUG_FIXES
        RET  Z            ; [*BUG* - This should just be RET but since the zero flag is always reset by this point then the bug is harmless. Credit: Paul Farrow]
#else
	RET
#endif

;A non-null character was found after the new cursor position, so locate its address.
;Joins here from the CURSOR-UP key handler routine.

L2619:  CALL L26AE        ; Does the new cursor position hold a null character?
        JR   NZ,L265F     ; Jump ahead if it does not.

;The new cursor location holds a null character, so scan to the left until the first non-null character is found.
;If no characters are found to the left on this row then a search will subsequently be made to the right.

L261E:  LD   A,L          ;
        AND  $1F          ; Reached column 0?
        JR   Z,L262D      ; Jump ahead if so.

;Not yet reached column 0

        DEC  HL           ; Previous location.
        CALL L26B2        ; Does this location contain a null character?
        JR   Z,L261E      ; Jump back if it does.

;A non-null character has been found

        INC  HL           ; Move to the null character to the right.
        JP   L265F        ; Jump ahead to continue.

;Column 0 was reached and hence there are no characters to the left. Therefore perform a search to the right.

L262D:  PUSH HL           ; Save the location address.

L262E:  INC  HL           ; Move to the next location.
        CALL L26B2        ; Does the location contain a null character?
        POP  BC           ; Fetch the address of the previous location.
        JR   NZ,L265F     ; Jump ahead if a non-null character was found.

;A null character was found

        PUSH BC           ; Save the location address
        LD   A,L          ;
        AND  $1F          ; Keep the column number.
        CP   $1F          ; Reached column 31?
        JR   NZ,L262E     ; Jump back if not to move right one position.

;Column 31 has been reached and so there are no characters on the row, so use column number 31

        POP  HL           ; Fetch the location address.
        JR   L265F        ; Jump ahead to continue.

; ----------------------------------------------------------------------
; BASIC Editing Mode: CURSOR-LEFT Key Handler Routine (Main Screen Area)
; ----------------------------------------------------------------------
; Exit: A=New cursor column number.
;       Carry flag set if the cursor was moved.
;       Zero flag set if the BASIC line containing the cursor has not changed.

L2640:  LD   HL,EB_FLGS   ; $5B72.
        RES  7,(HL)       ; Signal up/left ????

        LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position within the Screen Buffer.

;Joins here from the CURSOR-RIGHT key handler routine

L2648:  LD   A,H          ; At top left of screen?
        OR   L            ;
        SCF               ; Set the carry flag to ensure that a return does not happen if the following call is not made.
        CALL Z,L2CE4      ; If at top left of screen then scroll down ????
        RET  NC           ; Return if ????

        DEC  HL           ;
        CALL L26AE        ; Does the cursor position hold a null character?
        JR   NZ,L265F     ; Jump if it does not.

        LD   (ED_POS),HL  ; $5B92. Store the new cursor position.
        DEC  HL           ;
        CALL L26B2        ; Does the location contain a null character?
        INC  HL           ;
        JR   Z,L2648      ; Jump back if it does.

;Joins here from the CURSOR-RIGHT/CURSOR-DOWN/CURSOR-UP key handler routines when a character on the row below/above exists

L265F:  LD   DE,(ED_POS)  ; $5B92. Fetch the current cursor offset position.
        PUSH DE           ; Save it.

        LD   (ED_POS),HL  ; $5B92. Store the new cursor offset position.
        CALL L2B95        ; Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.
                          ; Also returns the line number of the BASIC line that contains the new cursor in BC.

        LD   HL,(ED_LINE) ; $5B67. Fetch the line number of the BASIC line that currently contains the cursor.
        OR   A            ;
        SBC  HL,BC        ; Is the new cursor position within a different BASIC line?
        POP  HL           ; Fetch the current cursor offset position.
        SCF               ; Signal the cursor was moved.
        RET  Z            ; Return if the BASIC line containing the cursor has not changed.

        LD   A,(FLAGS3)   ; $5B66.
        BIT  1,A          ; Is a delete operation being performed?
        JR   NZ,L267D     ; Jump ahead if so.

;A cursor move operation is being performed

        OR   $1F          ; Set the cursor column number to 31 (the top 3 bits of A will be 0).
        RET               ; Returns with the zero and carry flags reset.
                          ; [*BUG* - The carry flag has been corrupted by the OR instruction, thereby signalling that the cursor
                          ; could not be moved. This affects the LINE-DOWN key handler routine ($274D) and causes it to place
                          ; the cursor at the end of the next line instead of at the beginning. The bug could be fixed by inserting
                          ; a SCF instruction before the return is made. Credit: Paul Farrow]

;A delete operation is being performed

L267D:  LD   DE,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   (ED_POS),HL  ; $5B92. Store the new cursor offset position.

; --------
; ???? a delete operation and now moved to different basic line so syntax check/insert line?
; --------
;???? called from elsewhere

L2684:  PUSH DE           ; Save the original cursor offset position.

        CALL L2693        ; ???? execute? syntax check?

        POP  HL           ; Fetch the original cursor offset position.
        LD   (ED_POS),HL  ; $5B92. Restore the original cursor position.

        CALL L2F20        ; ???? list program to screen buffer and display file

        OR   $FF          ; Reset the zero flag to signal ???? it is used at $2786
        SCF               ; Set the carry flag to signal ????
        RET               ;

; --------
; ????
; --------

L2693:  CALL L2385        ; ???? Transfer bytes from physical RAM bank 7 to ???? via RAM Disk load routine.

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).

        CALL L23A1        ; Attempt to execute the line.
        BIT  7,(IY+$00)   ; Has an error occurred?
        JP   Z,L281C      ; Jump if so to ????.

;An error has not occurred

        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        CALL L2B95        ; ???? Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.
        LD   (ED_LINE),BC ; $5B67. Store the line number of the BASIC line that contains the cursor.

; Exit: DE=Address within the Screen Buffer of the next BASIC line if there is one, else the next available Screen Buffer address.
;       HL=Address within the Screen Buffer of the start of the current BASIC line.
;       BC=Line number of the BASIC line that contains the cursor.


        RET               ;

; -------------------------------------------
; Does Cursor Location Hold a Null Character?
; -------------------------------------------
; This routine checks whether the location of the cursor contains a $FF character.
; Entry: HL=Offset to the cursor.
; Exit : Zero flag set if the character was $FF.

L26AE:  LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.

; ------------------------------------
; Does Location Hold a Null Character?
; ------------------------------------
; This routine checks whether a specified offset location contains a $FF character.
; Entry: HL=Base address.
;        DE=Offset location.
; Exit : Zero flag set if the character was $FF.

L26B2:  ADD  HL,DE        ; Point to the location of the character.
        LD   A,(HL)       ; Fetch the character.
        OR   A            ; Clear the carry flag.
        SBC  HL,DE        ; Point back to the original address.

        INC  A            ; Set the zero flag if the character was $FF.
        RET               ;

; -----------------------------------------------------------------------
; BASIC Editing Mode: CURSOR-RIGHT Key Handler Routine (Main Screen Area)
; -----------------------------------------------------------------------

L26B9:  LD   HL,EB_FLGS   ; $5B72.
        SET  7,(HL)       ; Signal down/right ????

        LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.

L26C1:  PUSH HL           ;
        LD   DE,$02BF     ; 703=21 rows + 31 columns.
        OR   A            ;
        SBC  HL,DE        ; At the end of the screen?
        POP  HL           ;
        JR   C,L26D3      ; Jump if not.

;At last column on the last row of the screen

L26CB:  CALL L2CB1        ; ????
        INC  HL           ;
        JP   NC,L2648     ; ????

        DEC  HL           ;

;Not at the end of the screen or ????

L26D3:  PUSH HL           ;
        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,DE        ;
        CALL L24A8        ; ???? Search forwards in the Screen Buffer for a non-null character.
        POP  HL           ;
        JR   Z,L26CB      ;

        INC  HL           ;
        CALL L26AE        ; Does the cursor position hold a null character?
        JP   NZ,L265F     ; Jump if it does not.

        DEC  HL           ;
        CALL L26B2        ; Does the location contain a null character?
        INC  HL           ;
        JR   Z,L26C1      ; Jump ahead if it does.

        JP   L265F        ; Continue via the CURSOR-LEFT key handler routine.

; ------------------------------------------------------------------------
; BASIC Editing Mode: START-OF-LINE Key Handler Routine (Main Screen Area)
; ------------------------------------------------------------------------
; Move to the start of the current BASIC line.
;
; Symbol: |<--
;         |<--

L26F0:  CALL L2B95        ; Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor, returning it in HL.

;Joins here from the END-OF-LINE key handler routine to set the cursor at the new location specified by HL.

L26F3:  CALL L26FE        ; Set the cursor at Screen Buffer address corresponding to the start of the current BASIC line.

        BIT  5,(IY-$3B)   ; $5BFF. Copy the Screen Buffer to the display?
        RET  Z            ; Return if not required.

        JP   L301B        ; Jump to copy the Screen Buffer to the display file.

; ---------------------------------------------------------
; Set Cursor at Specified Location within the Screen Buffer
; ---------------------------------------------------------
; Entry: HL=Address within the Screen Buffer to set cursor at.

;???? if the cursor is above or below the Screen Buffer then the address of the Screen Buffer can be set above or below
; the true Screen Buffer address

L26FE:  LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        OR   A            ;
        SBC  HL,DE        ; Determine the offset into the Screen Buffer of the cursor.
        JR   NC,L2718     ; Jump if the cursor is within the Screen Buffer.

;The cursor is 'above' the Screen Buffer. Extract the column number and set the cursor at this column position
;on the first row in the Screen Buffer.

        ADD  HL,DE        ; Restore the address to set the cursor at.
        PUSH HL           ; Save it

        LD   BC,$0000     ; Row offset within the Screen Buffer, i.e. the first row of the Screen Buffer.
        CALL L272F        ; Extract the column number of the cursor address and set this as the cursor offset within the Screen Buffer.

        POP  HL           ; Fetch the address to set the cursor at.
        LD   A,L          ;
        AND  $E0          ; Set the column number to 0.
        LD   L,A          ;
        LD   ($FF24),HL   ; Store the start address of the row containing the cursor at the address of the Screen Buffer.
        RET               ;

;The cursor is within or after the Screen Buffer. HL holds the offset into the Screen Buffer of the cursor.

L2718:  LD   BC,$02C0     ; 704=22 rows.
        LD   (ED_POS),HL  ; $5B92. Store the offset in the Screen Buffer of the new cursor position.
        SBC  HL,BC        ; Is the cursor beyond the Screen Buffer?
        RET  C            ; Return if it is not, i.e. the cursor is within the Screen Buffer.

;The cursor is beyond the Screen Buffer

        PUSH HL           ; HL specifies how many bytes beyond the Screen Buffer the cursor is.

        LD   A,L          ;
        OR   $1F          ; Force the offset beyond the Screen Buffer to be at column 31.
        LD   L,A          ;
        INC  HL           ; Increment the offset to column 0 of the next row.

        ADD  HL,DE        ; Determine the offset from the start of the Screen Buffer [???? how large is the Screen Buffer?]
        LD   ($FF24),HL   ; Store as the next available address within the Screen Buffer, i.e. beyond the Screen Buffer.

        POP  HL           ; Fetch the number of bytes that the cursor is beyond the Screen Buffer.

        LD   BC,$02A0     ; 672=21 rows.

;Place the cursor on row 21 but keep the current column position

; ------------------------------------------------------------------
; Set Cursor at Current Column on Specified Row in the Screen Buffer
; ------------------------------------------------------------------
; This routine is to set the cursor on a specified row within the Screen Buffer but to maintain
; its current column position.
; Entry: HL=Cursor offset.
;        BC=Offset to a row within the Screen Buffer.

L272F:  LD   A,L          ; Fetch the low byte of the offset beyond the Screen Buffer.
        LD   H,$00        ;
        AND  $1F          ; Keep only the column number.
        LD   L,A          ; HL=Column number.
        ADD  HL,BC        ; Determine the offset to the column within the Screen Buffer.
        LD   (ED_POS),HL  ; $5B92. Store this as the new cursor position.
        RET               ;

; ----------------------------------------------------------------------
; BASIC Editing Mode: END-OF-LINE Key Handler Routine (Main Screen Area)
; ----------------------------------------------------------------------
; Move to the end of the current BASIC line.
;
; Symbol: -->|
;         -->|

L273A:  CALL L275A        ; Find the address after the BASIC line containing the cursor, returning it in DE. HL points to the start of the BASIC line.
        EX   DE,HL        ; HL=Address after the BASIC line containing the cursor.
        JR   L26F3        ; Continue via the START-OF-LINE key handler routine to set the cursor at the new location.

; ------------------------------------------------------------------
; BASIC Editing Mode: LINE-UP Key Handler Routine (Main Screen Area)
; ------------------------------------------------------------------
; Move to the beginning of the previous BASIC line, or to the beginning of the current BASIC line if it
; is the first row of the first line of the BASIC program.
;
; Symbol: / \/ \
;          |  |

L2740:  SET  5,(IY-$3B)   ; $5BFF. Signal to copy the Screen Buffer to the display.

L2744:  CALL L25D3        ; Move the cursor up one row.
        JR   NC,L26F0     ; ???? Jump if cannot move the cursor up a row, i.e. the cursor is already on the first row of the first BASIC line.
                          ; The cursor will be positioned at the beginning of the current BASIC line.

        JR   Z,L2744      ; Jump back if the cursor is still within the same BASIC line.

;The cursor has moved to the previous BASIC line

        JR   L26F0        ; Move to the beginning of the line.

; --------------------------------------------------------------------
; BASIC Editing Mode: LINE-DOWN Key Handler Routine (Main Screen Area)
; --------------------------------------------------------------------
; Move to the start of the next BASIC line, or to the end of the current BASIC line if it
; is the final line of the BASIC program. Note that a bug causes this routine to move to
; the end of the next BASIC line instead of the start.
;
; Symbol:  |  |
;         \ /\ /

L274D:  SET  5,(IY-$3B)   ; $5BFF. Signal to copy the Screen Buffer to the display.

L2751:  CALL L25E9        ; Move the cursor down one row.
        JR   NC,L273A     ; Jump if cannot move the cursor down a row, i.e. the cursor is already on the last row of the final BASIC line.
                          ; The cursor will be positioned at the end of the current BASIC line.

        JR   Z,L2751      ; Jump back if the cursor is still within the same BASIC line.

;[A bug in the cursor down routine at $25E9 means that this path is never taken. Instead the routine
;always exits via $273A and hence the cursor is always positioned at the end of the following BASIC line.]

        JR   L26F0        ; Move to the beginning of the line.

; -----------------------------------------------------------
; Find the Address After the BASIC Line Containing the Cursor
; -----------------------------------------------------------
; Exit: DE=Address after the end of the BASIC line containing the cursor.
;       HL=Start address of the BASIC line.

L275A:  CALL L2B95        ; Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.

;DE=Address within the Screen Buffer of the next BASIC line if there is one, else the next available Screen Buffer address.
;HL=Address within the Screen Buffer of the start of the current BASIC line.

;Enter a loop to find the last character of the BASIC line. The loop searches backwards, skipping over null characters until
;a non-null character is found

L275D:  DEC  DE           ; Previous location.
        LD   A,(DE)       ; Does the location contain a null character?
        INC  A            ;
        JR   Z,L275D      ; Jump back if it does.

;The last character of the BASIC line has been found

        PUSH HL           ; Save the address of the start of the BASIC line.

        SCF               ;
        SBC  HL,DE        ; Test whether the start address is before the end address that was found.

        POP  HL           ; Fetch the address of the start of the BASIC line.
        INC  DE           ; Point to the next available location within the Screen Buffer after the BASIC line.
        RET  C            ; Return if the start address was before the end address.

;The start address was equal to the end address

        LD   D,H          ; Return the start address of the BASIC line.
        LD   E,L          ;
        RET               ;

; ----------------------------------------------------------------
; BASIC Editing Mode: ENTER Key Handler Routine (Main Screen Area)
; ----------------------------------------------------------------

L276C:  LD   HL,FLAGS3    ; $5B66.
        SET  1,(HL)       ; Signal ????

        LD   HL,L240E     ; Return address to the Editor.
        EX   (SP),HL      ; Place it at the top of the stack.

        LD   HL,ED_POS    ; $5B92. Point to the cursor offset position store.
        LD   A,(HL)       ; Fetch the low byte of the cursor offset position.
        AND  $E0          ; Move the cursor position to the start of the row, i.e. column 0.
        LD   (HL),A       ;

        CALL L25E9        ; Move the cursor down one row.
        SET  5,(IY-$3B)   ; $5BFF. Signal to copy the Screen Buffer to the display.
        JR   NC,L2786     ; Jump if the cursor could not be moved down. [Quicker to have jumped to $2788 (ROM 0)]

;The cursor could be moved down

        RET  Z            ; Return if ???? the row is empty?

L2786:  JR   C,L27F6      ; Jump if the cursor could be moved down to ????

;The cursor could not be moved down

        INC  A            ; ????
        JR   Z,L27AF      ; Jump if ????

;????

        CALL L27DF        ; ????

        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        EX   DE,HL        ; DE=Address of the Screen Buffer, HL=Address of the cursor location.
        PUSH HL           ; Save the address of the cursor location.
        SBC  HL,DE        ; Calculate the offset.
        LD   (ED_POS),HL  ; $5B92. Store the new cursor offset position.

        POP  DE           ; Fetch the address of the cursor location.
        LD   BC,$02C0     ; 704=22*32.
        SBC  HL,BC        ; Is the cursor offset at or after row 22?
        JR   NC,L27A6     ; Jump if so to move the cursor to the start of row 21.

;The cursor offset position is before row 22

        CALL L3283        ; ????
        JP   L301B        ; Jump to copy the Screen Buffer to the display file.

;Move cursor to the start of row 21

L27A6:  LD   HL,$02A0     ; Row 21 (672=21*32).
        LD   (ED_POS),HL  ; $5B92. Store the new cursor offset position.
        JP   L301B        ; Jump to copy the Screen Buffer to the display file.

;????

L27AF:  LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   D,H          ;
        LD   E,L          ; DE=Cursor offset position.
        CALL L27DF        ; ????

L27B7:  CALL L2F15        ; Move cursor down a row within the the Screen Buffer

        LD   HL,$02A0     ; Offset to row 21 (672=21*32).
        LD   (ED_POS),HL  ; $5B92. Store as the cursor offset position.

        CALL L2B25        ; ????

        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   BC,$02A0     ; Offset to row 21 (672=21*32).
        ADD  HL,BC        ; HL=Address of row 21 in the Screen Buffer.

        LD   D,H          ;
        LD   E,L          ; DE=Address of row 21 in the Screen Buffer.

        DEC  HL           ; HL=Address of row 20 colum 31 in the Screen Buffer.
        LD   A,(HL)       ;
        INC  A            ; Does this location contain a null character?
        JR   NZ,L27B7     ; Jump back if it does not to ????

        CALL L3283        ; ????

        LD   BC,$0020     ; 32 columns.
        LD   A,$15        ; Row 21.
        CALL L3168        ; Blank row of Screen Buffer contents to $FF (null).
        JP   L301B        ; Jump to copy the Screen Buffer to the display file.

; --------
; ????
; --------

L27DF:  EX   DE,HL        ;
        CALL L2684        ;
        LD   DE,($FF1E)   ; ???? Next Line Screen Buffer Mapping.
        LD   A,E          ;
        OR   $1F          ;
        LD   E,A          ;
        INC  DE           ;
        LD   ($FF1E),DE   ; ???? Next Line Screen Buffer Mapping.

        LD   HL,FLAGS3    ; $5B66.
        SET  1,(HL)       ;
        RET               ;

; --------
; ???? the cursor could be moved down?
; --------

L27F6:  LD   HL,FLAGS3    ; $5B66.
        SET  1,(HL)       ;

        CALL L2B95        ; ???? Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.

; Exit: DE=Address within the Screen Buffer of the next BASIC line if there is one, else the next available Screen Buffer address.
;       HL=Address within the Screen Buffer of the start of the current BASIC line.
;       BC=Line number of the BASIC line that contains the cursor.

        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        PUSH HL           ;
        OR   A            ;
        SBC  HL,DE        ;
        LD   (ED_POS),HL  ; $5B92. Store the new cursor position.
        POP  DE           ;
        CALL L2BC4        ; ????
        CALL L3283        ; ????
        LD   A,C          ;
        CP   $1A          ;
        JR   NZ,L2819     ;

        LD   ($FF1E),DE   ; ???? Next Line Screen Buffer Mapping.

L2819:  JP   L301B        ; Jump to copy the Screen Buffer to the display file.

; --------
; ????
; --------

L281C:  CALL L2359        ; Insert a bug symbol in the edit line area.

        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        CALL L275A        ; Find the address after the BASIC line containing the cursor, returning it in DE. HL points to the start of the BASIC line.
        EX   DE,HL        ; DE=Start address of the BASIC line, HL=Address after the BASIC line.

        LD   BC,($5C59)   ; E_LINE.
        CALL L2159        ; ???? populate rows in screen buffer
        CALL L301B        ; copy the Screen Buffer to the display file.

        CALL L257F        ; Wait for a key press.
        PUSH AF           ; Save the key code.

        CALL L24C6        ; ???? DELETE-RIGHT Key Handler Routine

        LD   A,$FF        ;
        LD   ($5C3A),A    ; ERR_NR. Signal no error.

        POP  AF           ;
        LD   SP,TSTACK+1  ; $5BFF.

        LD   HL,L240E     ; Return address to the Editor.
        PUSH HL           ; Stack it.
        JP   L2418        ; ????

; ----------------------------------
; Is Cursor at End of Screen Buffer?
; ----------------------------------
; Exit: BC=Number of characters to the end of the Screen Buffer.
;       DE=Address of the first unused position.
;       HL=Address of the cursor.
;       Zero flag set if the cursor is at the end of the Screen Buffer.

L2847:  LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.

;Entry point: HL holds the offset position

L284A:  LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,DE        ; HL=Address of the cursor position within the Screen Buffer.

        PUSH HL           ; Save the cursor address.

        LD   BC,$0800     ;
        LD   A,$FF        ; A null character.
        CPIR              ; Search for the next unused position.
        DEC  HL           ; Point back to the null character position.

        POP  DE           ; Fetch the cursor address.
        CALL L285F        ; Determine how many characters from the cursor position to the end of the buffer.

        LD   A,B          ; BC=Holds the number of characters until the end of the Screen Buffer.
        OR   C            ;
        RET               ;

; ------------------------
; BC=HL-DE, Swap HL and DE
; ------------------------
; Exit: BC=HL-DE.
;       DE=HL, HL=DE.

L285F:  AND  A            ;
        SBC  HL,DE        ;
        LD   B,H          ;
        LD   C,L          ; BC=HL-DE.
        ADD  HL,DE        ;
        EX   DE,HL        ; HL=DE, DE=HL.
        RET               ;

; ------------------------------------------------------------
; Filter Out Null Characters from a Block in the Screen Buffer
; ------------------------------------------------------------
; This routine parses a non-tokenised BASIC line in the Screen Buffer and trims out all null characters.
; The trimmed line resides at the original location but will always be the same length as before or shorter.
; Entry: HL=Start address in Screen Buffer.
;        DE=End address in Screen Buffer.
; Exit : DE=New end address.

L2867:  AND  A            ; Clear the carry flag.
        SBC  HL,DE        ; Determine how many bytes to transfer.
        CCF               ;
        RET  C            ; Return if the start address is after the end address.

        ADD  HL,DE        ; Restore the start address.
        LD   BC,$0000     ; BC holds the count of the number of null characters, although this is always expected to be less than 256.

;Enter a loop to scan all characters between the start address and the end address and count the
;number of null characters

L2870:  LD   A,(HL)       ; Fetch a character.
        INC  A            ; Is it a null character?
        JR   NZ,L287E     ; Jump ahead if it is not.

;A null character

        INC  C            ; Increment the count.

;Check whether the end address has been reached before proceeding to scan the next location

L2875:  INC  HL           ; Advance to the next location.
        AND  A            ;
        SBC  HL,DE        ; Has the end address been reached?
        JR   Z,L2893      ; Jump ahead if so.

;The end address has not been reached

        ADD  HL,DE        ; Restore the address.
        JR   L2870        ; Jump back to scan the remaining characters.

;A non-null character

L287E:  SUB  A            ; Set A to $00.
        CP   C            ; Has a null character previously been found?
        JR   Z,L2875      ; Jump back if not to scan the next character.

;A sequence of one or more null characters was found, followed by a non-null character

        EX   DE,HL        ; HL=End address, DE=Address of the non-null character.

        PUSH BC           ; Save the null character counter.

        CALL L285F        ; BC=Number of characters between the start and end addresses, DE=End address, HL=Address of the non-null character.

        POP  DE           ; E=Null character counter.
        PUSH HL           ; Save the address of the non-null character.

        SBC  HL,DE        ; Determine the address of the character if all nulls were removed.
        EX   DE,HL        ; Save in DE.

        POP  HL           ; HL=Address of the non-null character.
        PUSH DE           ; Save the new address of the non-null character.
        LDIR              ; Move all characters down in memory, overwriting the sequence of null characters.

        POP  HL           ; HL=New address of the non-null character.
        JR   L2870        ; Jump back to continue scanning the remaining characters.

;The end address has been reached, and C holds the number of null characters encountered found, i.e. C holds the
;number of trailing null characters

L2893:  EX   DE,HL        ; HL=End address.
        OR   A            ; Clear the carry flag.
        SBC  HL,BC        ; Determine the address without the trailing sequence of null characters.
        EX   DE,HL        ; DE=New end address.
        RET               ;

; --------
; ???? listing BASIC program into Screen Buffer
; --------
; ????
; This routine is called once per row of the Screen Buffer when ???? listing?
; The current BASIC line is held in the editing workspace.
; It always begins with the first row of a BASIC line even if it is above the Screen Buffer.

; Entry:
; HL = address of the start of a row in that line in the editing workspace, or the start of a new statement within a row
; DE = address of start of row in screen buffer

;bug? - if first statement of a multi-statement line ends at the end of a row then a blank row is inserted before the next statement
;       This seems to be integral to how it works.

;called for every character typed in a new line
;can cursor between lines without being triggered

;????


; Exit: B=Number of bytes to null. ?
;        DE=Address of the bytes to null. ?



L2899:  LD   A,(HD_0B+1)  ; $5B73. Fetch the display flags.
        LD   C,A          ; Save the display flags for testing later.

        LD   B,$20        ; B holds a count of the number of characters that can be inserted within this row of the Screen Buffer.

        BIT  3,C          ; Does this row contain the start of a new statement?
        JR   Z,L28C7      ; Jump ahead if it does not, i.e. it is a continuation of an existing statement.

;The row contains the start of a new statement

        DEC  DE           ; Fetch the previous character from the Screen Buffer.
        LD   A,(DE)       ; [Note that when pointing to the start of the Screen Buffer, the previous character is
        INC  DE           ; from the RAM Disk catalogue, but this byte is never $FF ????]
        INC  A            ; Was it a null character?
        JR   Z,L28B2      ; Jump ahead if so. ???? what is this checking?

;????

        PUSH HL           ; Save the start address of the BASIC line within the editing workspace.

        LD   HL,$EC00     ; The address of the Screen Buffer.
        OR   A            ;
        SBC  HL,DE        ; Processing the first row of the Screen Buffer?
        POP  HL           ; Fetch the start address of the BASIC line within the editing workspace.
        RET  NZ           ; Return if not. ???? what is this doing?

;???? return if:
; - not processing the first row of the screen buffer
; - the last character in the previous row of the screen buffer was not null
; - the row contains the start of a new statement
;????

L28B2:  BIT  1,C          ; Is this the first row of the BASIC line?
        JR   NZ,L28C7     ; Jump ahead if it is.

;This is not the first row of the BASIC line, so the row needs to be displayed indented. Each statement of a
;multi-statement line is displayed on a new row, and begins with three null characters followed by a colon.

        LD   A,$FF        ; A null character.
        CALL L291D        ; Store the null character into the Screen Buffer, advance to the next position and decrement the character count.
        CALL L291D        ; Store the null character into the Screen Buffer, advance to the next position and decrement the character count.
        CALL L291D        ; Store the null character into the Screen Buffer, advance to the next position and decrement the character count.

        LD   A,':'        ; $3A. A colon character.
        CALL L291D        ; Store the colon, advance to the next position and decrement the character count.

        INC  HL           ; Advance past the colon character in the editing workspace.

;Joins here when the row is a continuation of an existing statement

L28C7:  CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        LD   A,(HL)       ; Fetch the next character from the editing workspace.
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        CP   $FE          ; Is it the error marker bug symbol?
        JR   NZ,L28DE     ; Jump ahead if not.

;The BASIC line in the editing workspace contains the error marker bug symbol so set the cursor at this location within the Screen Buffer

        PUSH HL           ; HL=Address of the error marker bug sysmbol within the BASIC line in the editing workspace.
        PUSH BC           ; B=Row character counter, C=Display flags.
        PUSH DE           ; DE=Current address within the Screen Buffer.

        EX   DE,HL        ; HL=Current address within the Screen Buffer.
        CALL L26FE        ; Set the cursor to the current address within the Screen Buffer, i.e. at the location of the error marker bug symbol.

        POP  DE           ; DE=Address within the Screen Buffer.
        POP  BC           ; B=Row character counter, C=Display flags.
        POP  HL           ; HL=Address of the error marke bug sysmbol within the BASIC line in the editing workspace.

        LD   A,$FE        ; The error marker bug symbol.

;The current character will be stored in the Screen Buffer, unless it denotes the end of the BASIC line

L28DE:  BIT  2,C          ; Is the current character within a quoted string?
        JR   NZ,L28E6     ; Jump ahead if it is.

;The character is not within a quoted string

        CP   ':'          ; $3A. Has a colon been found, i.e. the start of a new statement?
        JR   Z,L28F7      ; Jump ahead if it has.

;The character is part of the current statement

L28E6:  CP   $0D          ; Has the end of the BASIC line found?
        JR   Z,L2900      ; Jump ahead if it has.

;The end of the BASIC line was not found

        INC  HL           ; Advance to the next character in the BASIC line within the editing workspace.

        CALL L2913        ; Store the character into the Screen Buffer, toggling the 'within quotes' flag if a quote character. Advance to the next position and decrement the character count.
        JR   NZ,L28C7     ; Jump back if there is still room to insert more characters within this row of the Screen Buffer.

;This row of the Screen Buffer has been completely filled. The current statement of the BASIC line must spill onto the next row

L28F0:  LD   A,C          ; Fetch the flags byte.
        AND  $F5          ; Signal not on the first row of the BASIC line and that the row does not contain the start of a new statement.
        LD   (HD_0B+1),A  ; $5B73. Store the new display flags.
        RET               ;

;A colon was found, i.e. the start of a new statement

L28F7:  LD   A,C          ; Fetch the display flags.
        AND  $FD          ; Signal not on the first row of the BASIC line.
        OR   $08          ; Signal the start of a new statement within the BASIC line.
        LD   (HD_0B+1),A  ; $5B73. Store the display flags.
        RET               ;

;The end of the BASIC line was found

L2900:  SET  2,C          ; Ensure the 'within a quoted string' flag is cancelled so that subsequent BASIC lines display correctly.

        XOR  A            ;
        CP   B            ; Has the Screen Buffer row been completely filled?
        JR   Z,L28F0      ; Jump if so to set the display flags to reflect this.

;The Screen Buffer row was not completely filled

        LD   A,C          ; Fetch the display flags.
        AND  $01          ; ???? Keep the ???? flag.
        OR   $0A          ; Signal the first row of a BASIC line and the start of a new statement.
        LD   (HD_0B+1),A  ; $5B73. Store the display flags.

        LD   ($FF22),DE   ; Store the next available address within the Screen Buffer.
        RET               ;

; --------------------------------------------------------------
; Store a Character, Setting 'Within Quotes' Flag as Appropriate
; --------------------------------------------------------------
; This routine is called when listing a BASIC program into the Screen Buffer and is used
; to detect the start and end of quoted strings. It does this by simply toggling a flag each
; time a quote character is encountered.
; Entry: A=Character code.
;        DE=Address to store the byte at.
;        B=Count.
; Exit : B=New count.
;        DE=Address of the location after the stored byte.
;        Zero flag set if B reaches 0.

L2913:  CP   $22          ; Is the character a quote?
        JR   NZ,L291D     ; Jump ahead if not to store the character.

;The character was a quote

        LD   A,$04        ; Toggle the 'within quoted string' flag.
        XOR  C            ;
        LD   C,A          ;

        LD   A,$22        ; Continue to store a quote character.

; -------------------------------------
; Store a Character and Decrement Count
; -------------------------------------
; Entry: A=Byte to store.
;        DE=Address to store the byte at.
;        B=Count.
; Exit : B=New count.
;        DE=Address of the location after the stored byte.
;        Zero flag set if B reaches 0.

L291D:  LD   (DE),A       ; Store the byte.
        INC  DE           ; Advance to the next location.
        DEC  B            ; Decrement the counter.
        RET               ;

; ------------------------------------
; Copy BASIC Line to Editing Workspace
; ------------------------------------
; This routine copies a BASIC line from the the program memory into the editing workspace, trimming out
; hidden floating point numbers.
; Entry: HL=Address of a BASIC line to copy, i.e. points to the line number bytes.
; Exit : Carry flag set if the specified line does not exists.
;        HL=Address of the first keyword within the editing workspace, after the line number representation characters.

L2921:  RST  28H          ;
        DEFW LINE_NO      ; $1695. Fetch the line number.

        LD  A,D           ; Was there a line number?
        OR   E            ;
        SCF               ; Signal there was not a line number.
        RET  Z            ; Return if there was not a line number, i.e. the line does not exist.

;A line number was found

        LD   ($5C49),DE   ; E_PPC. Set it as the current line with program cursor.

        INC  HL           ; Point to the first length byte of the BASIC line.
        LD   C,(HL)       ;
        INC  HL           ;
        LD   B,(HL)       ; BC=Length of the BASIC line.

        INC  HL           ; Point to the first keyword of the BASIC line.

        PUSH HL           ; Save the adddress of the first keyword of the BASIC line.

        PUSH DE           ; Save the line number.

        LD   HL,$000A     ;
        ADD  HL,BC        ; Allow 10 bytes for the line number representation.
        LD   B,H          ;
        LD   C,L          ;
        CALL L298E        ; Create room in the editing workspace for the BASIC line.

        POP  HL           ; Fetch the line number.
        PUSH DE           ; Save the start address of the editing workspace area.

        CALL L2959        ; Create an ASCII representation of the line number within the editing workspace.

        POP  HL           ; Fetch the start address of the editing workspace area.

        EX   (SP),HL      ; Stack the address of the editing workspace, and fetch the adddress of the first keyword of the BASIC line to HL.

;The characters of the BASIC line are now copied into the editing workspace

L2943:  LD   A,(HL)       ; Fetch the next character.
        RST  28H          ;
        DEFW NUMBER       ; $18B6. Skip over an embedded floating point number if present.

        LDI               ; Copy the next character. 
        CP   $0D          ; Has the end of the line been reached?
        JR   NZ,L2943     ; Jump back if not to copy the next character.

        POP  HL           ; Fetch the adddress of the first keyword of the BASIC line.
        OR   A            ; Clear the carry flag to signal that the line existed.
        RET               ;

; ----------------------------------
; Create ASCII Number Representation
; ----------------------------------
; Creates an ASCII representation of a number, replacing leading
; zeros with spaces.
; Entry: HL=Number to test.
;        DE=Address of the buffer to build ASCII representation in.
;
; [Never called]

L2950:  PUSH DE           ; Store the buffer address.

        LD   BC,$D8F0     ; BC=-10000.
        CALL L297D        ; Insert a line number digit into the buffer.

        JR   L295A        ; Jump ahead to continue.

; ---------------------------------------
; Create ASCII Line Number Representation
; ---------------------------------------
; Creates an ASCII representation of a line number, replacing leading
; zeros with spaces. Also used to display row and column numbers when
; in variable edit mode.
; Entry: HL=The line number to convert.
;        DE=Address of the buffer to build ASCII representation in.
; Exit : HL=Address of the first non-'0' character in the buffer.
;        B=Number of non-'0' characters minus 1 in the ASCII representation.

L2959:  PUSH DE           ; Store the buffer address.

L295A:  LD   BC,$FC18     ; BC=-1000.
        CALL L297D        ; Insert how many 1000s there are.

        LD   BC,$FF9C     ; BC=-100.
        CALL L297D        ; Insert how many 100s there are.

        LD   C,$F6        ; BC=-10.
        CALL L297D        ; Insert how many 10s there are.

        LD   A,L          ; A=Remainder.
        ADD  A,'0'        ; $30. Convert into an ASCII character ('0'..'9').
        LD   (DE),A       ; Store it in the buffer.
        INC  DE           ; Point to the next buffer position.

;Now skip over leading zeros

        LD   B,$03        ; Skip over 3 leading zeros at most.
        POP  HL           ; Retrieve the buffer start address.

L2973:  LD   A,(HL)       ; Fetch a character.
        CP   '0'          ; $30. Is it a leading zero?
        RET  NZ           ; Return as soon as a non-'0' character is found.

        LD   (HL),' '     ; $20. Replace it with a space.
        INC  HL           ; Point to the next buffer location.
        DJNZ L2973        ; Repeat until all leading zeros removed.

        RET               ;

; ------------------------
; Insert Line Number Digit
; ------------------------
; This routine effectively works out the result of HL divided by BC. It does this by
; repeatedly adding a negative value until no overflow occurs.
; Entry: HL=Number to test.
;        BC=Negative amount to add.
;        DE=Address of buffer to insert ASCII representation of the number of divisions.
; Exit : HL=Remainder.
;        DE=Next address in the buffer.

L297D:  XOR  A            ; Assume a count of 0 additions.

L297E:  ADD  HL,BC        ; Add the negative value.
        INC  A            ; Increment the counter.
        JR   C,L297E      ; If no overflow then jump back to add again.

        SBC  HL,BC        ; Undo the last step
        DEC  A            ; and the last counter increment.

        ADD  A,'0'        ; $30. Convert to an ASCII character ('0'..'9').
        LD   (DE),A       ; Store it in the buffer.
        INC  DE           ; Point to the next buffer position.
        RET               ;

; -----------------------------------------------------
; Create Room in the Editing Workspace for a BASIC Line
; -----------------------------------------------------
; Entry: HL=Start address.
;        DE=End address.
; Exit : DE=Address of the area created in the editing workspace for the BASIC line.
;        BC=The length of the BASIC line.
;        HL=Start address.

L298A:  EX   DE,HL        ; Swap HL and DE.
        CALL L285F        ; BC=Number of bytes from the start address to the end address. HL and DE swapped back over.

; ---------------------------------------------------------------
; Create Specified Room in the Editing Workspace for a BASIC Line
; ---------------------------------------------------------------
; This routine clears the current contents of the editing workspace and then creates
; the specified number of bytes ready to be filled with another BASIC line.
; Entry: BC=The length of the BASIC line to create room for.
; Exit : DE=Address of the area created in the editing for the BASIC line.
;        BC=The length of the BASIC line.
;        HL=Start address.

L298E:  PUSH HL           ; Save the value of HL.

        PUSH BC           ; Save the length of the BASIC line.

        RST  28H          ;
        DEFW SET_MIN      ; $16B0. Clear the workspace areas.

        LD   HL,($5C59)   ; E_LINE. Fetch the start of the BASIC line workspace.
        LD   A,B          ;
        OR   C            ; Is any space required to be created?
        JR   Z,L299E      ; Jump ahead if not.

        CALL L29A5        ; Create room for the required number of bytes.
        INC  HL           ; Point to the first newly created bytes.

L299E:  POP  BC           ; Fetch the length of the BASIC line.
        EX   DE,HL        ; DE=Address of the workspace area created for the BASIC line.

        POP  HL           ; Restore the value of HL.
        RET               ;

; ----------------------
; Create Room for 1 Byte
; ----------------------
; Creates room for a single byte in the workspace, or automatically produces an error '4' if not.
; The room will be created within the currently paged in memory.
; Entry: HL=Location to create the room at.

L29A2:  LD   BC,$0001     ; Request 1 byte.

;Continue into the following routine

; -----------------------
; Create Room for n Bytes
; -----------------------
; Creates room for multiple bytes in the workspace, or automatically produces an error '4' if not.
; The room will be created within the currently paged in memory.
; Entry: HL=Location to create the room at.
;        BC=Number of bytes to create room for.
; Exit:  HL=Location prior to the created room.
;        DE=Location of the last byte of the created room.

L29A5:  PUSH HL           ;
        PUSH DE           ;
        CALL L29B0        ; Test whether there is space. If it fails this will cause the error
        POP  DE           ; handler in ROM 0 to be called. If MAKE_ROOM were called directly and
        POP  HL           ; and out of memory condition detected then the ROM 1 error handler would
        RST  28H          ; be called instead.
        DEFW MAKE_ROOM    ; $1655. The memory check passed so safely make the room.
        RET

; ------------------
; Room for BC Bytes?
; ------------------
; Test whether there is room for the specified number of bytes in the spare memory,
; producing error "4 Out of memory" if not. This routine is very similar to that at
; $3F66 with the exception that this routine assumes IY points at the system variables.
; Entry: BC=Number of bytes required.
; Exit : Returns if the room requested is available else an error '4' is produced.

L29B0:  LD   HL,($5C65)   ; STKEND.
        ADD  HL,BC        ; Would adding the specified number of bytes overflow the RAM area?
        JR   C,L29C0      ; Jump to produce an error if so.

        EX   DE,HL        ; DE=New end address.
        LD   HL,$0082     ; Would there be at least 130 bytes at the top of RAM?
        ADD  HL,DE        ;
        JR   C,L29C0      ; Jump to produce an error if not.

        SBC  HL,SP        ; If the stack is lower in memory, would there still be enough room?
        RET  C            ; Return if there would.

L29C0:  LD   (IY+$00),$03 ; Signal error "4 Out of Memory".
        JP   L02C0        ; Jump to error handler routine.

; -------------------------
; Is There a BASIC Program?
; -------------------------
; Exit: Zero flag set if there is no BASIC program.

L29C7:  LD   DE,($5C53)   ; PROG.
        LD   HL,($5C4B)   ; VARS.
        OR   A            ;
        SBC  HL,DE        ; Does VAR equal PROG, i.e. no BASIC lines?
        RET               ;

; --------
; ???? Initialise ???? to $00
; --------
; Set ???? addresses $FEC4 to $FF21 to contain $00.

L29D2:  LD   HL,$FEC4     ; ????
        LD   (HL),$00     ;

        LD   D,H          ;
        LD   E,L          ;
        INC  DE           ;
        LD   BC,$005D     ; 93d
        LDIR              ; ???? set FEC4 to FF21 to $00
        RET               ;

; --------
; ????
; --------
; This routine clears the Line Number Mapping List and then locates the locates the nearest BASIC line
; to the specified line number. If a line was found then it is inserted into the Line Number Mapping List.
; If a previous BASIC line exists then it is noted.
; Entry: BC=???? Line number.
; Exit : Zero flag set if a BASIC line at or after the specified line number does not exist.
;        BC=Address of the BASIC line.

L29E0:  PUSH BC           ; Save the specified line number.

        LD   HL,$EC00     ; The start address of the Screen Buffer.
        LD   ($FF24),HL   ; Reset the pointer to the Screen Buffer.

        LD   BC,$1280     ; Blank 148 rows (4736 bytes).

        XOR  A            ;
        LD   ($FEC0),A    ; Signal ????

        CALL L3168        ; Blank the Screen Buffer contents to $FF (null).
        CALL L29C7        ; Check whether there is a BASIC program.
        CALL L29D2        ; Clear the Line Number Mapping List and associated workspace variables. ????

        POP  HL           ; Fetch the specified line number.
        RET  Z            ; Return if there is not a BASIC program.

;A BASIC program exists

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        RST  28H          ; Fetch the address of the BASIC line with the specified line number. If there is no such line then the address
        DEFW LINE_ADDR    ; $196E. of the next line is returned. If there is next line the address of the variables area is returned.
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        LD   B,H          ; Save the address of the BASIC line found for the specified line number.
        LD   C,L          ;

        OR   A            ; DE=Address of the previous BASIC line.
        SBC  HL,DE        ; Is there a previous line?
        JR   Z,L2A17      ; Jump ahead if not, i.e. the specified line number returned the first line of the program.

;There is a previous BASIC line

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        LD   A,(DE)       ;
        LD   H,A          ; Fetch the line number of the previous line, storing it in HL.
        INC  DE           ;
        LD   A,(DE)       ;
        LD   L,A          ;
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        LD   ($FEC4),HL   ; Save the address of the previous BASIC line.

;Joins here when there is no previous BASIC line

L2A17:  CALL L2A99        ; Was there a BASIC line available for the specified line number?
        RET  Z            ; Return if there was not, i.e. the address points at the variables area.

;BC holds the address of the BASIC line

        LD   HL,$FEC6     ; The address of the first entry within the Line Number Mapping List.
        LD   DE,$EC00     ; The start address of the Screen Buffer.
        CALL L2AA2        ; Store the line number details in the Line Number Mapping List.

        XOR  A            ; Reset the zero flag to indicate that a BASIC line was found.
        INC  A            ;
        RET               ;

; --------
; ???? List BASIC Program into the Screen Buffer
; --------
; Entry: BC=???? line number

L2A27:  LD   A,$14        ; ???? Set the number of available visible rows in the Screen Buffer to 20.
        LD   ($FEC2),A    ;

        LD   (ED_EDIT),BC ; $5B94. Store the ???? line with cursor

        CALL L29E0        ; ???? Clear the Line Number Mapping List and insert the ???? line number.
        JR   Z,L2A4A      ; Jump if ???? no prog

        CALL L2A99        ; ???? Does the Specified Address Point to the End of the BASIC Program?
        JR   Z,L2A88      ; Jump if it does.

;There is a BASIC line available

        PUSH HL           ;
        CALL L219F        ; ???? copy row of basic line into screen buffer
        POP  HL           ;
        JR   L2A6F        ; ???? jump ahead to continue copying rows.

; --------
; ???? List BASIC Program into the Screen Buffer
; --------
; This routine is used to populate the Screen Buffer with a listing of the BASIC program starting from the specified line
; number. It updates the Line Number Mapping List, which tracks which Screen Buffer row contains the start of each BASIC line.
; Entry: BC=Initial line number to display at top of the Screen buffer.

L2A41:  LD   (ED_EDIT),BC ; $5B94. Save the line number to ???? edit / with the cursor.

        CALL L29E0        ; Clear the Line Number Mapping List, inserting an entry for the line number.
        JR   NZ,L2A57     ; Jump if there was a BASIC line available for the specified line number or after it.

;A BASIC line at or after the specified line number does not exist, perhaps because there is no program, so ensure
;all Line Number Mapping List entries are reset

L2A4A:  LD   HL,$EC00     ; The start address of the screen buffer area within the workspace variables area.
        LD   ($FF24),HL   ; Reset the address of the Screen Buffer.

        LD   ($FEC6),HL   ; Reset the Screen Buffer address of the initial entry in the Line Number Mapping List.
        LD   ($FF1E),HL   ; Reset the Screen Buffer address of the Next Line Screen Buffer Mapping.
        RET               ;

;A BASIC line exists at or after the specified line number, so enter a loop to copy rows of BASIC lines into the
;Screen Buffer until it becomes full or the end of the program is reached

;BC=Address of the next BASIC line
;DE=Next Screen Buffer address

L2A57:  CALL L2A99        ; Does the current address point to the end of the program?
        JR   Z,L2A88      ; Jump if the end of the program has been reached.

;There is another BASIC line available

        PUSH HL           ; Save the address of the next available Line Number Mapping List entry.

;BC=Address of the BASIC line.
;DE=The Screen Buffer address.

; Entry: BC=???? Address of the current BASIC line.
;        DE=???? address within screen buffer?
;        AF'=???? counter

        CALL L219F        ; Copy a row of the BASIC line into the Screen Buffer. Returns with BC holding the address of the next BASIC line.

        LD   HL,$FEC0     ; ????
        LD   A,(ED_COL)   ; $5B6B. ???? number of rows copied? if so then update usage at top of file
        ADD  A,(HL)       ;
        LD   (HL),A       ;

        LD   A,($FEC2)    ; ???? number of available visible rows within the screen buffer?
        SUB  (HL)         ; ???? decrement number of available visible rows in the Screen Buffer.
        POP  HL           ; Fetch the address of the next available Line Number Mapping List entry.
        JR   C,L2A79      ; Jump if all visible rows been filled.

;???? is the above code checking whether all rows of a single BASIC line have been copied, up to a max of 22?



;There are still some unfilled rows within the Screen Buffer

L2A6F:  CALL L2A99        ; Is there another BASIC line?
        JR   Z,L2A88      ; Jump ahead if there is not, i.e. the end of the program has been reached.

;Another BASIC line exists

;HL=Address of the next available Line Number Mapping List entry.
;BC=Address of the BASIC line.
;DE=The Screen Buffer address.

        CALL L2AA2        ; Store the new line number in the Line Number Mapping List.
        JR   L2A57        ; Jump back to copy the first row of the new BASIC line into the Screen Buffer.

;All visible Screen Buffer rows have been filled

L2A79:  CALL L2A99        ; Is there another BASIC line?
        JR   Z,L2A88      ; Jump if the end of the program has been reached.

;Another BASIC line exists

        LD   HL,$FF1E     ; Point to the location of the Next Line Screen Buffer Mapping.
        LD   DE,($FF22)   ; Fetch the next available address within the Screen Buffer.
        JP   L2AA2        ; Store the line number in the Next Line Screen Buffer Mapping.

;The end of the program has been reached. At this point the Screen Buffer might or might not be completely filled.
;Set the Next Line Screen Buffer Mapping to signal that there is not next BASIC line.

L2A88:  LD   HL,$FF1E     ; Point to the location of the Next Line Screen Buffer Mapping.
        LD   DE,($FF22)   ; Fetch the next available address within the Screen Buffer.

L2A8F:  LD   (HL),E       ;
        INC  HL           ;
        LD   (HL),D       ; Store the Screen Buffer address.
        INC  HL           ;
        LD   (HL),$00     ; Store a line number of 0 to signal that there is not a BASIC line.
        INC  HL           ;
        LD   (HL),$00     ;
        RET               ;

; -----------------------------------------------------------------
; Does the Specified Address Point to the End of the BASIC Program?
; -----------------------------------------------------------------
; This routine is used to determine whether the address held in BC points to a BASIC line or
; whether the end of the program has been reached and the address points to the variables area.
; Entry: BC=Address of a BASIC line.
; Exit : Zero flag set if the end of the program has been reached.

L2A99:  PUSH HL           ; Save HL.

        LD   HL,($5C4B)   ; VARS.
        OR   A            ;
        SBC  HL,BC        ; Does the line number address point at the variables area?

        POP  HL           ; Restore HL.
        RET               ;

; --------------------------------------
; Store a Line Number Mapping List Entry
; --------------------------------------
; Entry: HL=Address of a Line Number Mapping List entry.
;        DE=The Screen Buffer address.
;        BC=Address of the BASIC line.
; Exit : HL=Address of the next entry in the Line Number Mapping List.

L2AA2:  LD   (HL),E       ; Store the Screen Buffer address.
        INC  HL           ;
        LD   (HL),D       ;
        INC  HL           ; Point to the line number field.

        PUSH DE           ; Save the Screen Buffer address.

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).

        INC  BC           ; Point to the high byte of the line number.
        LD   A,(BC)       ; Fetch the line number high byte.
        LD   D,A          ;
        DEC  BC           ; Point to the low byte of the line number.
        LD   A,(BC)       ; Fetch the line number low byte.

        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        LD   (HL),D       ; Store the line number.
        INC  HL           ;
        LD   (HL),A       ;
        INC  HL           ;

        POP  DE           ; Fetch the Screen Buffer address.
        RET               ;

; ---------------------------------------------------------------------
; Find Line Number and Screen Buffer Address for Location of the Cursor/Error Marker ????
; ---------------------------------------------------------------------
; This routine locates the line number and screen buffer address of the BASIC line that contains the cursor/error marker.
; It is used to locate which BASIC line contains the error marker, and is also used to ????
; Exit: DE=Screen Buffer address, or $0000 if there is no line available.
;       BC=BASIC line number, or $0000 if there is no line available.
;       HL=Address of the entry in the Line Number Mapping List.

L2AB8:  LD   HL,$FEC6     ; Point to the Line Number Mapping List.

        LD   E,(HL)       ; Fetch the first Screen Buffer address.
        INC  HL           ;
        LD   D,(HL)       ;
        DEC  HL           ; Point back to the start of the entry.

        LD   BC,$0000     ; Set BC to indicate no line available.

        LD   A,D          ; Is there at least one valid entry?
        OR   E            ;
        RET  Z            ; Return if not.

;Enter a loop to locate the BASIC line encompasses the specified Screen Buffer address

L2AC5:  LD   E,(HL)       ; Fetch the Screen Buffer address field for the entry.
        INC  HL           ;
        LD   D,(HL)       ;
        INC  HL           ;

        INC  HL           ; Skip over the BASIC line number field.
        INC  HL           ;

        LD   B,H          ; Save the address of the next entry in the mapping list.
        LD   C,L          ;

        LD   A,D          ; Was there a Screen Buffer address defined?
        OR   E            ;
        JR   Z,L2ADF      ; Jump ahead if there was not, i.e. not a valid entry.

;The entry has a Screen Buffer address set

        LD   HL,($FF24)   ; Fetch the address of the ???? cursor/error marker within the Screen Buffer.
        OR   A            ;
        SBC  HL,DE        ; Is this line before, after or at the location of the cursor/error marker????
        JR   Z,L2AE3      ; Jump if it is at the same address.

        JR   C,L2ADF      ; Jump if it is after the cursor. ????

;The line is before the cursor ????

        LD   H,B          ; Fetch the address of the next entry.
        LD   L,C          ;
        JR   L2AC5        ; Jump back to test the next entry.

;Joins here from two places:
;- The end of the entries was found, hence fetch the last entry.
;- The current entry is after the cursor, hence fetch the previous entry.

L2ADF:  DEC  BC           ; Point back to the previous entry.
        DEC  BC           ;
        DEC  BC           ;
        DEC  BC           ;

L2AE3:  LD   H,B          ; Fetch the address of the next entry in the mapping list. 
        LD   L,C          ;

        DEC  HL           ; Point to last byte of the BASIC line number in the previous entry.
        LD   B,(HL)       ;
        DEC  HL           ;
        LD   C,(HL)       ; Fetch the BASIC line number.

        DEC  HL           ; Point back to the Screen Buffer address.
        LD   D,(HL)       ;
        DEC  HL           ;
        LD   E,(HL)       ; Fetch the Screen Buffer address.
        RET               ;

; --------
; ???? Has Final Row of Screen Buffer Been Reached?
; --------
; Exit: Carry flag set if the final row of the Screen Buffer has been reached.

L2AEE:  LD   HL,$FE5F     ; Address of the last character of the final row of the Screen Buffer.
        LD   DE,($FF1E)   ; Fetch the address of the ???? Next Line Screen Buffer Mapping.
        OR   A            ;
        SBC  HL,DE        ; Has the final row been reached?
        RET               ;

; --------
; ????
; --------
; Exit: BC=Address of the Screen Buffer.
;       Zero flag set if ????
;       Carry flag set if ????

L2AF9:  LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   B,H          ;
        LD   C,L          ; BC=Address of the Screen Buffer.
        LD   DE,$02C0     ; 704=22*32.
        ADD  HL,DE        ; HL=Address of row 22.

        LD   DE,($FF1E)   ; Fetch ???? Next Line Screen Buffer Mapping.
        OR   A            ; Clear the carry flag.
        SBC  HL,DE        ;
        RET  C            ; Return if ????

        LD   HL,($FF20)   ; ????
        LD   A,H          ;
        OR   L            ;
        RET               ;

; --------
; ????
; --------

L2B10:  CALL L2AF9        ; ????
        LD   HL,$0020     ;
        JR   NC,L2B20     ; Jump if ????

        CCF               ; Set the carry flag to signal ????
        RET  Z            ; Return if ????

        ADD  HL,BC        ;
        LD   ($FF24),HL   ; ???? Address of Screen Buffer.
        SCF               ;
        RET               ;

L2B20:  RET  Z            ;

        ADD  HL,BC        ;
        LD   ($FF24),HL   ; ???? Address of Screen Buffer.

; --------
; ????
; --------

;???? L2AB8=Find Line Number for a Specified Screen Buffer Address:
; This routine locates the BASIC line number for a given Screen Buffer address.
; It also returns the Screen Buffer address that holds the start of the BASIC line.
; It is used to locate which BASIC line contains the error marker, and is also used to ????
; Exit: DE=Screen Buffer address, or $0000 if there is no line available.
;       BC=BASIC line number, or $0000 if there is no line available.
;       HL=Address of the entry in the Line Number Mapping List.

L2B25:  CALL L2AB8        ; ???? Find the entry in the Line Number Mapping List that encompasses the row containing the cursor.

        INC  HL           ; Advance to the next entry.
        INC  HL           ;
        INC  HL           ;
        INC  HL           ;

        LD   A,(HL)       ;
        INC  HL           ;
        LD   H,(HL)       ;
        LD   L,A          ; HL=Screen Buffer address for the entry.
        OR   H            ; Is this a valid entry?
        JR   NZ,L2B36     ; Jump if the entry does not exit.

;Another entry exists after ???? the cursor location so fetch the next available location within the Screen Buffer

        LD   HL,($FF1E)   ; ???? Next Line Screen Buffer Mapping.

;HL=Address of next available Screen Buffer location, DE=Screen Buffer of BASIC line containing the cursor

L2B36:  SBC  HL,DE        ; HL=Offset from the line containing the cursor to the next available location.
        CALL L213A        ; Determine how many rows span the offset, i.e. A=HL*8.

        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        OR   A            ; Clear the carry flag.
        SBC  HL,DE        ; Is the cursor ???? top program line? on the first line within the Screen Buffer?
        JR   Z,L2B53      ; Jump if so to populate 21 rows of the Screen Buffer.

;The cursor is not at the top of the Screen Buffer

        PUSH HL           ; ???? save -ve offset

;BC=The initial line number to list from.

        ADD  A,$15        ; ???? at least 21 rows?
        CALL L2B55        ; ???? Populate the specified ???? number of rows in the Screen Buffer.

        POP  DE           ; ???? fetch -ve offset

        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,DE        ; ???? add offset, i.e. move up screen buffer
        LD   ($FF24),HL   ; ????
        SCF               ; Signal ????
        RET               ;

; -------------------------------------
; Populate 21 Rows of the Screen Buffer
; -------------------------------------
; Entry: BC=The initial line number to list from.
; Exit : Carry flag set to signal success. ???? ever tested?

L2B53:  LD   A,$15        ; Display up to 21 rows.

; ------------------------------------------------------
; Populate Specified Number of Rows of the Screen Buffer
; ------------------------------------------------------
; Entry: A=Number of rows to display.
;        BC=The initial line number to list from.
; Exit : Carry flag set to signal success. ???? ever tested?

L2B55:  LD   ($FEC2),A    ; Store the number of available Screen Buffer rows to populate.

        CALL L2A41        ; Populate the Screen Buffer starting with the line number held in BC.

        SCF               ; Indicate success. ???? ever tested?
        RET               ;

; -----------------------------------------------------------
; Is Current Screen Buffer at Start of Workspace Buffer Area?
; -----------------------------------------------------------
; Exit: Zero flag set if the current Screen Buffer begins at the start of the buffer space allocated workspace variables area.
;       DE=Number of bytes between the start of the buffer space within the workspace variables area and the current Screen Buffer location.

L2B5D:  LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   B,H          ;
        LD   C,L          ;
        LD   DE,$EC00     ; The the start of the screen buffer area within the workspace variables area.
        OR   A            ;
        SBC  HL,DE        ; Does the current Screen Buffer begins at the start of the buffer space allocated within the workspace variables area?
        RET               ;

; --------
; ????
; --------

L2B69:  CALL L2B5D        ; Is the current Screen Buffer located at the start of the buffer space within the workspace variables area?
        JR   Z,L2B71      ; Jump if it is at the start.

;The current Screen Buffer location is not situated at the start of the buffer space within the workspace variables area.

        ADD  HL,DE        ; Point back to the Screen Buffer location.
        JR   L2B8A        ; Jump ahead to continue.

;The current Screen Buffer location is situated at the start of the buffer space within the workspace variables area.

L2B71:  LD   BC,($FEC4)   ; ???? Is there a previous BASIC line?
        LD   A,B          ;
        OR   C            ;
        RET  Z            ; Return if there is not.

;There is a previous BASIC line

        CALL L2A27        ; ????

        LD   HL,($FECA)   ;
        LD   A,H          ;
        OR   L            ;
        JR   NZ,L2B8A     ;

        LD   HL,($FF1E)   ; ???? Next Line Screen Buffer Mapping.
        LD   A,L          ;
        OR   $1F          ;
        LD   L,A          ;
        INC  HL           ;

L2B8A:  LD   DE,$0020     ;
        OR   A            ;
        SBC  HL,DE        ;
        LD   ($FF24),HL   ;
        SCF               ;
        RET               ;

; ---------------------------------------------------------
; Find Screen Buffer Address of BASIC Line After the Cursor
; ---------------------------------------------------------
; This routine is used to determine the address within the Screen Buffer of the start of the next BASIC line following the current cursor address.
; The routine temporarily changes the workspace variable held at $FF24. Usually this variable points to the start of the Screen Buffer but this
; routine changes it to point to the start of the Screen Buffer row that contains the cursor. This allows it to call the routine at $2AB8 which
; attempts to locate the address mapping list entry for the BASIC line that contains the cursor.
; Exit: DE=Address within the Screen Buffer of the next BASIC line if there is one, else the next available Screen Buffer address.
;       HL=Address within the Screen Buffer of the start of the current BASIC line.
;       BC=Line number of the BASIC line that contains the cursor.

L2B95:  LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   DE,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   A,E          ;
        AND  $E0          ; Mask off the column number to obtain the offset to the start of the row.
        LD   E,A          ; DE=Offset to start of the row containing the cursor.
        ADD  HL,DE        ; HL=Address of the row in the Screen Buffer containing the cursor.
        EX   DE,HL        ; DE=Address of the row in the Screen Buffer containing the cursor, HL=Offset to start of the row containing the cursor..

;The start of the row that the cursor is on has been determined but this might not be the first row of the BASIC line

        LD   BC,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   ($FF24),DE   ; Temporarily set the start of the Screen Buffer to that of the row containing the cursor.
        PUSH BC           ; Save the true address of the Screen Buffer.

        CALL L2AB8        ; Find the entry in the Line Number Mapping List that encompasses the row containing the cursor.

;HL=Next Line Number Mapping List entry, DE=Screen Buffer address, BC=BASIC line number

        INC  HL           ; Advance to the next line entry in the Line Number Mapping List.
        INC  HL           ;
        INC  HL           ;
        INC  HL           ;

        LD   A,(HL)       ; Fetch the Screen Buffer address.
        INC  HL           ;
        LD   H,(HL)       ;
        LD   L,A          ;

        EX   DE,HL        ; DE=Address within the Screen Buffer of the start of the next BASIC line. HL=Screen Buffer address corresponding to the current BASIC line.

        EX   (SP),HL      ; Retrieve the address of the true Screen Buffer to HL, and stack the Screen Buffer address of the start of the current BASIC line.
        LD   ($FF24),HL   ; Restore the true address of the Screen Buffer.

        POP  HL           ; HL=Address within the Screen Buffer of the start of the current BASIC line.

; --------------------------------------------------
; Fetch Screen Buffer Address of the Next BASIC Line
; --------------------------------------------------
; This routine returns the Screen Buffer address of the next BASIC line, or the next available address
; if there is not a next BASIC line.
; Entry: DE=Address within the Screen Buffer of the next BASIC line (or $0000 if there is not one).
; Exit : DE=Address of the next BASIC line, else next available Screen Buffer address.

L2BBC:  LD   A,D          ; Is there a Screen Buffer address defined for the next BASIC line?
        OR   E            ;
        RET  NZ           ; Return if there is, i.e. another BASIC line exists.

        LD   DE,($FF1E)   ; Fetch the address of the first null character, i.e. the next available location within the Screen Buffer.
        RET               ;

; --------
; ????
; --------

L2BC4:  PUSH DE           ;

        CALL L2AEE        ; ???? Has Final Row of Screen Buffer been reached?
        CALL C,L2C3C      ; ???? Jump if so.

        POP  DE           ;
        PUSH DE           ;
        CALL L32B6        ; ????
        LD   H,B          ;
        LD   L,C          ;
        PUSH HL           ;
        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ;
        CALL L2BBC        ; ???? Fetch Screen Buffer Address of the Next BASIC Line
        DEC  DE           ;
        LD   A,E          ;
        OR   $1F          ;
        LD   E,A          ;
        INC  DE           ;
        DEC  BC           ;
        DEC  BC           ;
        DEC  BC           ;
        LD   A,(BC)       ;
        LD   H,A          ;
        DEC  BC           ;
        LD   A,(BC)       ;
        LD   L,A          ;
        LD   BC,$07FF     ;
        ADD  HL,BC        ;
        EX   DE,HL        ;
        OR   A            ;
        SBC  HL,DE        ;
        POP  HL           ;
        POP  DE           ;
        RET  NC           ;

        LD   B,H          ;
        LD   C,L          ;
        LD   HL,($FF1E)   ; ???? Next Line Screen Buffer Mapping.
        SCF               ;
        SBC  HL,DE        ;
        JR   NC,L2C2A     ; ????

        INC  HL           ;
        ADD  HL,DE        ;
        LD   BC,$0020     ;
        ADD  HL,BC        ;
        LD   ($FF1E),HL   ; ???? Next Line Screen Buffer Mapping.
        LD   H,D          ;
        LD   L,E          ;
        LD   BC,($FF24)   ; Fetch the address of the Screen Buffer.
        OR   A            ;
        SBC  HL,BC        ;
        LD   BC,$02C0     ;
        SBC  HL,BC        ;
        RET  NZ           ;

        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   BC,$0020     ; 32 columns.
        ADD  HL,BC        ;
        LD   ($FF24),HL   ;
        LD   ($FF62),HL   ; ???? Start address of a BASIC line in the Screen Buffer, used when copying a BASIC Line from Screen Buffer into the Editing Workspace.
        PUSH DE           ;
        LD   A,$15        ; Row 15.
        CALL L3168        ; Blank row of Screen Buffer contents to $FF (null).
        POP  DE           ;
        SCF               ;
        RET               ;

; --------
; ????
; --------

L2C2A:  PUSH DE           ;
        LD   H,B          ;
        LD   L,C          ;
        PUSH HL           ;
        CALL L2C90        ; ????
        POP  HL           ;
        CALL L2C61        ; ????
        POP  DE           ;
        SET  7,(IY-$3B)   ; $5BFF. ????
        SCF               ;
        RET               ;

; --------
; ????
; --------

L2C3C:  POP  HL           ; ???? Fetch return address?

        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        OR   A            ;
        SBC  HL,DE        ;
        PUSH HL           ;
        CALL L2B25        ; ????
        CALL L2AEE        ; ???? Has Final Row of Screen Buffer Been Reached?
        JR   C,L2C54      ; Jump if so.

; ???? The final row of the Screen Buffer has not been reached

        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        POP  DE           ;
        ADD  HL,DE        ;
        EX   DE,HL        ;
        RET               ;

; ???? The final row of the Screen Buffer has been reached

L2C54:  LD   BC,$0004     ;
        LD   HL,$FF1A     ; ???? Address of the last entry of the Line Number Mapping List.
        LD   DE,$FF1E     ; ???? Next Line Screen Buffer Mapping.
        LDIR              ;

        POP  DE           ;
        RET               ;

; --------
; ????
; --------

L2C61:  LD   BC,$0020     ; +32
        JR   L2C69        ;

L2C66:  LD   BC,$FFE0     ; -32

L2C69:  LD   DE,$FF1E     ; ???? Next Line Screen Buffer Mapping.
        OR   A            ;
        SBC  HL,DE        ;
        JR   Z,L2C85      ;

        ADD  HL,DE        ;
        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ;
        LD   A,D          ;
        OR   E            ;
        JR   Z,L2C80      ;

        DEC  HL           ;
        EX   DE,HL        ;
        ADD  HL,BC        ;
        EX   DE,HL        ;
        LD   (HL),E       ;
        INC  HL           ;
        LD   (HL),D       ;

L2C80:  INC  HL           ;
        INC  HL           ;
        INC  HL           ;
        JR   L2C69        ;

L2C85:  EX   DE,HL        ;
        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ;
        EX   DE,HL        ;
        ADD  HL,BC        ;
        EX   DE,HL        ;
        LD   (HL),D       ;
        DEC  HL           ;
        LD   (HL),E       ;
        RET               ;

; --------
; ????
; --------

L2C90:  PUSH DE           ;
        LD   HL,($FF1E)   ; ???? Next Line Screen Buffer Mapping.
        CALL L285F        ; ???? BC=HL-DE, Swap HL and DE
        JR   Z,L2CA3      ;

        JR   C,L2CA3      ;

        DEC  DE           ;
        LD   HL,$0020     ;
        ADD  HL,DE        ;
        EX   DE,HL        ;
        LDDR              ;

L2CA3:  POP  DE           ;
        LD   B,$20        ;

; ---------------------------------------
; Null to End of Row within Screen Buffer
; ---------------------------------------
; Entry: B=Number of bytes to null.
;        DE=Address of the bytes to null.
; Exit : DE=Points to the byte after the nulled section.

L2CA6:  INC  B            ; Are there any bytes to null?
        DEC  B            ;
        RET  Z            ; Return if not.

        EX   DE,HL        ; HL=Address of bytes to null.

L2CAA:  LD   (HL),$FF     ; Null a byte.
        INC  HL           ;
        DJNZ L2CAA        ; Repeat for all bytes to null.

        EX   DE,HL        ; DE=Points to the byte after the nulled section.
        RET               ;

; --------
; ????
; --------
; Exit: Carry flag set if ???? cursor was moved?

L2CB1:  PUSH HL           ; Save HL.

        CALL L2B95        ; Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.

;DE=Address within the Screen Buffer of the next BASIC line if there is one, else the next available Screen Buffer address.

        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   BC,$02C0     ; 22 rows.
        ADD  HL,BC        ; HL=Address of row 22 within the Screen Buffer.

        LD   A,E          ; Fetch the start address within the Screen Buffer of the next BASIC line.
        OR   $1F          ; Set to column 31.
        LD   E,A          ;

        INC  DE           ; Advance to the next row.
        SBC  HL,DE        ; Has the end of the Screen Buffer been reached?
        JR   NZ,L2CD3     ; Jump ahead if not.

;The end of the Screen Buffer has been reached

        LD   HL,($FF20)   ; ????
        LD   A,L          ;
        OR   H            ;
        JR   Z,L2CD3      ; Jump if ????

        LD   DE,(ED_POS)  ; $5B92. ???? Fetch the cursor position, i.e. offset character position within the screen until the cursor.
        CALL L2693        ; ???? execute????

;The end of the Screen Buffer has not been reached ????

L2CD3:  CALL L2B10        ; ????

        POP  HL           ; Restore HL.
        RET  NC           ; Return if ????

        BIT  5,(IY-$3B)   ; $5BFF. Copy the Screen Buffer to the display?
        CALL Z,L301B      ; If required then copy the Screen Buffer to the display file.

        CALL L2F08        ; Move the cursor up a row in the Screen Buffer.
        SCF               ; Signal ???? cursor was moved?
        RET               ;

; --------
; ???? scroll rows down in Screen Buffer?
; --------
; Entry: HL=Cursor offset position within the Screen Buffer.
; Exit: Carry flag reset if at the top of the BASIC program.

L2CE4:  PUSH HL           ; Save the current cursor offset position.

        CALL L2B95        ; Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.

; Exit: DE=Address within the Screen Buffer of the next BASIC line if there is one, else the next available Screen Buffer address.
;       HL=Address within the Screen Buffer of the start of the current BASIC line.
;       BC=Line number of the BASIC line that contains the cursor.

        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        OR   A            ;
        SBC  HL,DE        ; Is the cursor at the start of the Screen Buffer?
        JR   NZ,L2D0E     ; Jump ahead if it is not.

;The cursor is at the very start of the Screen Buffer

        LD   HL,($FEC4)   ; ???? Is there a previous BASIC line?
        LD   A,L          ;
        OR   H            ;
        JR   Z,L2D0E      ; Jump if there is not????

;???? There is a previous BASIC line

        LD   DE,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        CALL L2693        ; ???? execute?

        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        PUSH HL           ; Save the address.

        LD   BC,($FEC8)   ;
        CALL L2A27        ; ????

        POP  HL           ; Fetch the original address of the Screen Buffer
        LD   ($FF24),HL   ; and store it.

;Joins here when the cursor is not at the start of the Screen Buffer
;???? Joins here when there is not a previous BASIC line

L2D0E:  CALL L2B69        ; ????
        POP  HL           ;
        RET  NC           ;

        PUSH HL           ;

        BIT  5,(IY-$3B)   ; $5BFF. Copy the Screen Buffer to the display?
        CALL Z,L301B      ; If so ???? then copy the Screen Buffer to the display file.

        POP  HL           ; ????
        LD   DE,$0020     ;
        ADD  HL,DE        ;
        SCF               ; Signal 
        RET               ;

; ---------------------------------
; Swap Ink and Paper Attribute Bits
; ---------------------------------
; Entry: A=Attribute byte value.
; Exit : A=Attribute byte value with paper and ink bits swapped.

L2D22:  LD   B,A          ; Save the original colour byte.

        AND  $C0          ; Keep only the flash and bright bits.
        LD   C,A          ;
        LD   A,B          ;
        ADD  A,A          ; Shift ink bits into paper bits.
        ADD  A,A          ;
        ADD  A,A          ;
        AND  $38          ; Keep only the paper bits.
        OR   C            ; Combine with the flash and bright bits.
        LD   C,A          ;

        LD   A,B          ; Get the original colour byte.
        RRA               ;
        RRA               ;
        RRA               ; Shift the paper bits into the ink bits.
        AND  $07          ; Keep only the ink bits.
        OR   C            ; Add with the paper, flash and bright bits.
        RET               ;

; -----------------------------
; Variable Editor Text Messages
; -----------------------------

L2D36:  DEFM "                               " ;
        DEFB ' '+$80      ;
L2D56:  DEFM "LINEA:      COL.:       E/P     " ; Row, Column, Wrap.
        DEFM "             MODO:              " ; Mode.
        DEFB ' '+$80      ;
L2D97:  DEFM "MAYUSCULA"  ; Caps lock.
        DEFB 'S'+$80      ;
L2DA1:  DEFM "GRAF.    "  ; Graphics mode.
        DEFB ' '+$80      ;
L2DAB:  DEFM "EXTENDID"   ; Extended mode.
        DEFB 'O'+$80      ;
L2DB4:  DEFM "SUSTITUCIO" ; Overtype mode.
        DEFB 'N'+$80      ;
L2DBF:  DEFM "INSERCIO"   ; Insert mode.
        DEFB 'N'+$80      ;
L2DC8:  DEFM "S/A        " ; Indent mode.
        DEFB ' '+$80      ;
L2DD4:  DEFM "N"          ; No (wrap off).
        DEFB 'O'+$80      ;
L2DD6:  DEFM "S"          ; Yes (wrap on).
        DEFB 'I'+$80      ;

; -----------------------------------------
; Copy Message into Screen or Banner Buffer
; -----------------------------------------
; Entry: HL=Address of the message to copy.
;        DE=Address within the Screen/Banner Buffer to copy to.
;        C=Indicates case ($00 for uppercase, $20 for lowercase).

L2DD8:  LD   A,(HL)       ; Fetch a character from the message.
        RES  7,A          ; Mask of the terminator bit.
        CP   $41          ; Is it below 'A'?
        JR   C,L2DE4      ; Jump if so.

        CP   $5B          ; Is it above 'Z'?
        JR   NC,L2DE4     ; Jump if so.

        OR   C            ; Make lowercase if required.

L2DE4:  LD   (DE),A       ; Store the character in the buffer.
        INC  DE           ; Move to the next buffer location.
        BIT  7,(HL)       ; Is this the last character in the message?
        INC  HL           ; Move to the next character within the message.
        JR   Z,L2DD8      ; Jump if not to copy the next character.

        RET               ;

; ---------------------
; Display Editor Banner
; ---------------------

L2DEC:  LD   A,($5C48)    ; BORDCR. Fetch the border colour.
        CALL L2D22        ; Swap ink and paper in the colour byte.
        LD   ($5C8F),A    ; ATTR_T. Use it as the temporary colours, i.e. banner shown inverse of border colour.

        LD   C,$00        ; Flag used to denote case, which by default will be uppercase.

        LD   HL,L2D36     ; "                                ".
        LD   DE,$FEA0     ; Address within the Banner Display Buffer.
        BIT  4,(IY-$3B)   ; $5BFF. BASIC or variable editing mode?
        JR   Z,L2E13      ; Jump if BASIC editing mode, thereby blanking the second banner row.

;Variable editing mode

        LD   C,$08        ; The caps lock bit.
        LD   A,(IY+$30)   ; FLAGS2.
        AND  C            ; Mask off all bits to leave only the caps lock bit.
        XOR  C            ; Toggle it.
        ADD  A,A          ;
        ADD  A,A          ; Toggle it to generate upper/lower case flag for ORing with characters.
        LD   C,A          ; Store in C.

        LD   HL,L2D56     ; "LINEA:      COL.:       E/P                  MODO:               ".
        LD   DE,$FE80     ; Address within the Banner Display Buffer.

L2E13:  CALL L2DD8        ; Copy the banner message into the Screen Buffer.

        BIT  1,(IY+$07)   ; MODE. Is graphics mode set?
        JR   Z,L2E25      ; Jump if not.

;Display the GRAPHICS MODE message

        LD   HL,L2DA1     ; "GRAF.     ".
        LD   DE,$FEA0     ; Address within the Screen Buffer to display the graphics mode status.
        CALL L2DD8        ; Copy the 'graphics mode' message into the Banner Display Buffer.

L2E25:  BIT  0,(IY+$07)   ; MODE. Is extended mode set?
        JR   Z,L2E34      ; Jump if not.

;Display the EXTENDED MODE message

        LD   HL,L2DAB     ; "EXTENDIDO".
        LD   DE,$FEA0     ; Address within the Screen Buffer to display the extended mode status.
        CALL L2DD8        ; Copy the 'extended mode' message into the Banner Display Buffer.

L2E34:  BIT  4,(IY-$3B)   ; $5BFF. BASIC or variable editing mode?
        JP   NZ,L2E6D     ; Jump if variable editing mode.

        BIT  3,(IY+$30)   ; FLAGS2. Is caps lock on?
        JR   Z,L2E4A      ; Jump ahead if not.

;Display the CAPS LOCK message

        LD   HL,L2D97     ; "MAYUSCULAS".
        LD   DE,$FEAA     ; Address within Screen Buffer to display caps lock status.
        CALL L2DD8        ; Copy the 'caps lock' message into the Banner Display Buffer.

L2E4A:  LD   B,$20        ; There are 32 columns to display.
        LD   DE,$50E0     ; Display file address of start of row 23, i.e. location to display the banner.
        LD   HL,$FEA0     ; Address of second row within the Banner Display Buffer.

;Print the banner to the display file

L2E52:  PUSH DE           ;
        PUSH HL           ;
        PUSH BC           ;
        CALL L3031        ; Print Banner Display Buffer characters to the display file.
        POP  BC           ; B=Number of columns.
        POP  HL           ; HL=Banner Display Buffer row address.
        POP  DE           ; DE=Display file address where to show the banner.

        LD   C,B          ;
        LD   B,$00        ; BC=32 columns.
        LD   D,$5A        ; Compose attributes file address.
        LD   A,($5C8F)    ; ATTR_T. Fetch the colours to show the banner in.
        CALL L318E        ; Set attributes row for the Banner Display Buffer row.

        LD   A,($5C8D)    ; ATTR_P.
        LD   ($5C8F),A    ; ATTR_T. Restore the temporary colours.
        RET               ;

; Display the banner for the variable editing mode
; ------------------------------------------------

; Display the mode

L2E6D:  LD   A,(EV_FLGS)  ; $5B76. Fetch the editing mode flags.
        AND  $03          ; Keep only the mode bits ($00=Insert, $01=Overtype, $10=Indent).
        LD   HL,L2DB4     ; "SUSTITUCION".
        JR   Z,L2E80      ; Jump ahead if Insert mode.

        LD   HL,L2DBF     ; "INSERCION".
        DEC  A            ;
        JR   Z,L2E80      ; Jump ahead if Overtype mode.

;It is Indent mode

        LD   HL,L2DC8     ; "S/A        ".

L2E80:  LD   DE,$FEB3     ; DE=Address within the Banner Buffer to copy the message to (second row, column 19).
        CALL L2DD8        ; Copy the message into the Banner Buffer.

;Display the status of Word Wrap mode

        LD   DE,$FE9C     ; DE=Address within the Banner Buffer to copy the message to (first row, column 28).
        LD   HL,L2DD4     ; "NO".

        LD   A,(EV_FLGS)  ; $5B76.
        BIT  2,A          ; Is Word Wrap mode enabled?
        JR   Z,L2E95      ; Jump ahead if not.

;Word Wrap mode is enabled so display YES

        INC  HL           ; "SI".
        INC  HL           ;

L2E95:  CALL L2DD8        ; Copy the message into the Banner Buffer.

;Display the cursor row and column position values

        LD   HL,(ED_COL)  ; $5B6B. Fetch the cursor column and row numbers.
        LD   H,$00        ; Discard the row number.
        INC  HL           ; Set the column range from 1.
        LD   DE,$FE91     ; DE=Address within the Banner Buffer to copy the message to (first row, column 17).
        CALL L2959        ; Insert a ASCII representation of the column number into the Banner Buffer.

        LD   HL,(ED_XXXX) ; $5B6E. Fetch the row number. ????
        LD   BC,(ED_ROW)  ; $5B6C. C=Cursor row number.
        LD   B,$00        ; BC=Cursor row number.
        INC  HL           ; Set the row range from 1.
        ADD  HL,BC        ; HL=Row number to display.
        LD   DE,$FE86     ; DE=Address within the Banner Buffer to copy the message to (first row, column 6).
        CALL L2959        ; Insert a ASCII representation of the row number into the Banner Buffer.

;Print the Banner Buffer to the display file

        LD   HL,$FE80     ; Address of first row within the Banner Display Buffer.
        LD   DE,$50C0     ; Display file address of start of row 22, i.e. location to display the banner.
        LD   B,$40        ; There are 64 columns to display.
        JR   L2E52        ; Print the banner to the display file.

; -----------------------
; Print Screen Buffer Row
; -----------------------
; Prints row from the screen buffer to the screen.
; Entry: A=Row number.

L2EBF:  RES  0,(IY-$3B)   ; $5BFF. Signal do not invert attribute values.

        CALL L2EF3        ; HL=A*32. Number of bytes prior to the requested row.
        PUSH HL           ; Save offset to requested row to print.

        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,DE        ; Point to row entry.
        LD   D,H          ;
        LD   E,L          ; DE=Address of row entry.
        EX   (SP),HL      ; Stack address of row entry. HL=Offset to requested row to print.

        PUSH HL           ; Save offset to requested row to print.
        PUSH DE           ; Save address of row entry.
        LD   DE,$5800     ; Attributes file.
        ADD  HL,DE        ; Point to start of corresponding row in attributes file.
        EX   DE,HL        ; DE=Start address of corresponding row in attributes file.
        POP  HL           ; HL=Address of row entry.

        LD   BC,$0020     ; 32 columns.
        LD   A,($5C8F)    ; ATTR_T. Fetch the temporary colours.
        CALL L318E        ; Set the colours for the 32 columns in this row, processing
                          ; any colour control codes from the print string.

        POP  HL           ; HL=Offset to requested row to print.
        LD   A,H          ;
        LD   H,$00        ; Calculate corresponding display file address.
        ADD  A,A          ;
        ADD  A,A          ;
        ADD  A,A          ; A=A*8.
        ADD  A,$40        ; Offset to $4000.
        LD   D,A          ;
        LD   E,H          ;
        ADD  HL,DE        ;
        EX   DE,HL        ; DE=Display file address.

        POP  HL           ; HL=Offset to requested row to print.
        LD   B,$20        ; 32 columns.
        JP   L3031        ; Print one row to the display file.

; ---------
; HL = A*32
; ---------

L2EF3:  ADD  A,A          ; A*2.
        ADD  A,A          ; A*4. Then multiply by 8 in following routine.

; --------
; HL = A*8
; --------

L2EF5:  LD   L,A          ;
        LD   H,$00        ;
        ADD  HL,HL        ; A*2.
        ADD  HL,HL        ; A*4.
        ADD  HL,HL        ; A*8.
        RET               ; Return HL=A*8.

; -------------------------
; Find Amount of Free Space
; -------------------------
; Exit: Carry flag set if no more space, else HL holds the amount of free space.

L2EFC:  LD   HL,$0000     ;
        ADD  HL,SP        ; HL=SP.
        LD   DE,($5C65)   ; STKEND.
        OR   A            ;
        SBC  HL,DE        ; Effectively SP-STKEND, i.e. the amount of available space.
        RET               ;

; ---------------------------------------------
; Move Cursor Up A Row Within The Screen Buffer
; ---------------------------------------------

L2F08:  LD   HL,(ED_POS)  ; $5B92. Fetch the cursor offset position.
        LD   BC,$0020     ; 32 columns.
        OR   A            ;
        SBC  HL,BC        ; Move up a row.
        LD   (ED_POS),HL  ; $5B92. Store the new cursor position.
        RET               ;

; -----------------------------------------------
; Move Cursor Down A Row Within The Screen Buffer
; -----------------------------------------------

L2F15:  LD   BC,$0020     ; 32 columns.
        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,BC        ; Move down a row.
        LD   ($FF24),HL   ; Store the new psotion.
        RET               ;

; --------
; ???? list program to screen buffer and display file
; --------

L2F20:  SET  0,(IY+$30)   ; FLAGS2. Signal screen does not require clearing.

        LD   HL,FLAGS3    ; $5B66.
        RES  1,(HL)       ; ????

        CALL L29C7        ; Check whether there is a BASIC program.
        JR   NZ,L2F37     ; Jump if there is a BASIC program.

;There is no BASIC program so clear the Screen Buffer and hence display file

        LD   BC,$0000     ; There is no ???? line number.
        CALL L2A41        ; Call the list to Screen Buffer routine. This will clear the Line Number Mapping List and clear the Screen Buffer.
        JP   L301B        ; Jump to copy the Screen Buffer to the display file, which will display a blank screen.

;There is a BASIC program

L2F37:  BIT  3,(IY-$3B)   ; $5BFF. Is the lower edit screen area being used?
        JR   Z,L2F7F      ; Jump if ???? using main screen

;Using lower edit screen ????

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).

        LD   HL,($5C49)   ; E_PPC. Fetch the line number of the line with the program cursor.
        LD   DE,($5C6C)   ; S_TOP. Fetch the line number of the top program line in automatic listings.
        AND  A            ;
        SBC  HL,DE        ; Is the line with the program cursor above the top line?
        ADD  HL,DE        ; Reverse the subtraction.
        JR   C,L2F6F      ; Jump if it is above.

;The line with the program cursor is below the top line in automatic listings

        PUSH DE           ; Save the line number of the top program line in automatic listings.

        RST  28H          ;
        DEFW LINE_ADDR    ; $196E. Fetch the address of the BASIC line with the program cursor, returning it in HL.

        LD   DE,$01C0     ; DE holds the number of characters contained in 14 rows.
        EX   DE,HL        ; ????
        SBC  HL,DE        ; HL=offset???? 448 - address of line with program cursor? => -ve?

        EX   (SP),HL      ; Stack the offset. HL=Line number of the top program line in automatic listings.
        RST  28H          ;
        DEFW LINE_ADDR    ; $196E. Fetch the address of the top program line in automatic listings.

        POP  BC           ; BC=???? offset.

;Enter a loop to find top line yet with program cursor line visible? ????

L2F5C:  PUSH BC           ; Save ????
        RST  28H          ;
        DEFW NEXT_ONE     ; $19B8. Fetch the next BASIC line to that held in DE, and the previous in DE.
        POP  BC           ; Fetch ????
        ADD  HL,BC        ; ???? add -ve?
        JR   C,L2F72      ; Jump if ???? cursor line is above (program line + nnnn) ? i.e on screen ?

;???? cursor line is off screen?

        EX   DE,HL        ;
        LD   D,(HL)       ; ????
        INC  HL           ;
        LD   E,(HL)       ;
        DEC  HL           ;
        LD   ($5C6C),DE   ; S_TOP.
        JR   L2F5C        ; ???? does this loop back to keep checking lines until in range?

;The line with the program cursor is above the top program line in automatic listings so use the cursor line
;as the top program line

L2F6F:  LD   ($5C6C),HL   ; S_TOP. Save the line number of the line with the program cursor as the top program line in automatic listings.

;Populate 21 rows of the Screen Buffer beginning with the top program line and copy the rows to the display file

L2F72:  LD   BC,($5C6C)   ; S_TOP. Fetch the top program line in automatic listings.
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        CALL L2B53        ; Populate up to 21 rows in the Screen Buffer starting with the top program line.
        JP   L301B        ; Jump to copy the Screen Buffer to the display file.

; --------
; ???? using main screen
; --------

L2F7F:  CALL L2B95        ; ???? Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.

; Exit: DE=Address within the Screen Buffer of the next BASIC line if there is one, else the next available Screen Buffer address.
;       HL=Address within the Screen Buffer of the start of the current BASIC line.
;       BC=Line number of the BASIC line that contains the cursor.

        LD   A,B          ;
        OR   C            ;
        JR   NZ,L2F89     ; ????

        LD   BC,$2710     ;

L2F89:  LD   (ED_ATTA),BC ; $5B69.
        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        OR   A            ;
        SBC  HL,DE        ;
        PUSH HL           ;
        LD   H,B          ;
        LD   L,C          ;
        RST  28H          ;
        DEFW LINE_ADDR    ; $196E.
        POP  BC           ;
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        JR   Z,L2FB7      ;

        LD   A,(EB_FLGS)  ; $5B72.
        RLA               ;
        JR   C,L2FAA      ; ???? up/left or down/right?

        EX   DE,HL        ;

L2FAA:  CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        RST  28H          ;
        DEFW LINE_NO      ; $1695.
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        LD   (ED_ATTA),DE ; $5B69.

L2FB7:  PUSH BC           ;
        LD   BC,(ED_EDIT)  ; $5B94.
        CALL L2A27        ; ????
        POP  DE           ;
        PUSH DE           ;

L2FC1:  CALL L2B95        ; ???? Find the address within the Screen Buffer of the start of the BASIC line that contains the cursor.

; Exit: DE=Address within the Screen Buffer of the next BASIC line if there is one, else the next available Screen Buffer address.
;       HL=Address within the Screen Buffer of the start of the current BASIC line.
;       BC=Line number of the BASIC line that contains the cursor.

        EX   DE,HL        ;
        LD   HL,(ED_ATTA) ; $5B69.
        LD   A,B          ;
        OR   C            ;
        JR   Z,L2FD2      ;

        SBC  HL,BC        ; ????
        JR   Z,L2FE2      ;

        JR   NC,L2FDA     ;

L2FD2:  CALL L2B69        ; ????
        CALL NC,L2F08     ; Move cursor up a row in the Screen Buffer.
        JR   L2FC1        ;

L2FDA:  CALL L2B10        ; ????
        CALL NC,L2F15     ; If ???? then move cursor down a row within the the Screen Buffer
        JR   L2FC1        ;

L2FE2:  LD   HL,(ED_POS)  ; $5B92.
        LD   BC,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,BC        ;
        LD   BC,($FF1E)   ; ???? Next Line Screen Buffer Mapping.
        SCF               ;
        SBC  HL,BC        ;
        JR   NC,L2FD2     ;

        POP  BC           ;
        PUSH BC           ;
        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,BC        ;
        OR   A            ;
        SBC  HL,DE        ;
        JR   Z,L300C      ;

        JR   C,L3007      ;

        CALL L2B69        ; ????
        JR   Z,L300C      ;

        JR   L2FC1        ;

L3007:  CALL L2B10        ; ????
        JR   C,L2FC1      ;

L300C:  POP  HL           ;
        BIT  5,(IY-$3B)   ; $5BFF. Copy the Screen Buffer to the display?
        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   ($FF62),HL   ; ???? Start address of a BASIC line in the Screen Buffer, used when copying a BASIC Line from Screen Buffer into the Editing Workspace.
        LD   ($FF22),HL   ; ???? holds the next available address within the Screen Buffer when displaying a program.
        RET  NZ           ; Return ???? if display file update not required.

; -----------------------------------
; Print Screen Buffer to Display File
; -----------------------------------

L301B:  CALL L317B        ; Set attributes file from the Screen Buffer.

        LD   DE,$4000     ; DE=First third of display file.
        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   B,E          ; Display 256 characters.
        CALL L3031        ; Display string.

        LD   D,$48        ; Middle third of display file.
        CALL L3031        ; Display string.

        LD   D,$50        ; Last third of display file.
        LD   B,$C0        ; Display 192 characters.

; ----------------------------------------------
; Print Screen Buffer Characters to Display File
; ----------------------------------------------
; Displays ASCII characters, UDGs, graphic characters or two special symbols in the display file,
; but does not alter the attributes file. Character code $FE is used to represent the error marker
; bug symbol and the character code $FF is used to represent a null, which is displayed as a space.
; Entry: DE=Display file address.
;        HL=Points to string to print.
;        B=Number of characters to print.

L3031:  LD   A,(HL)       ; Fetch the character.
        PUSH HL           ; Save string pointer.
        PUSH DE           ; Save display file address.
        CP   $FE          ; Was if $FE (bug) or $FF (null)?
        JR   C,L303C      ; Jump ahead if not.

        SUB  $FE          ; Reduce range to $00-$01.
        JR   L3072        ; Jump ahead to show symbol.

;Comes here if character code if below $FE

L303C:  CP   $20          ; Is it a control character?
        JR   NC,L3047     ; Jump ahead if not.

;Comes here if a control character

        LD   HL,L30D8     ; Graphic for a 'G' (not a normal G though). Used to indicate embedded colour control codes.
        AND  A            ; Clear the carry flag to indicate no need to switch back to RAM bank 7.
        EX   AF,AF'       ; Save the flag.
        JR   L307B        ; Jump ahead to display the symbol.

L3047:  CP   $80          ; Is it a graphic character or UDG?
        JR   NC,L3059     ; Jump ahead if so.

;Comes here if an ASCII character

        CALL L2EF5        ; HL=A*8.
        LD   DE,($5C36)   ; CHARS.
        ADD  HL,DE        ; Point to the character bit pattern.
        POP  DE           ; Fetch the display file address.
        CALL $FF28        ; Copy character into display file (via RAM Routine).
                          ; Can't use routine at $307C (ROM 0) since it does not perform a simple return.
        JR   L30A0        ; Continue with next character.

;Comes here if a graphic character or UDG

L3059:  CP   $90          ; Is it a graphic character?
        JR   NC,L3061     ; Jump ahead if not.

;Comes here if a graphic character

        SUB  $7F          ; Reduce range to $01-$10.
        JR   L3072        ; Jump ahead to display the symbol.

;Comes here if a UDG

L3061:  SUB  $90          ; Reduce range to $00-$6D.
        CALL L2EF5        ; HL=A*8.

        POP  DE           ; Fetch display file address.
        CALL L1EAF        ; Use Normal RAM Configuration (RAM bank 0) to allow access to character bit patterns.
        PUSH DE           ; Save display file address.

        LD   DE,($5C7B)   ; UDG. Fetch address of UDGs.
        SCF               ; Set carry flag to indicate need to switch back to RAM bank 7.
        JR   L3079        ; Jump ahead to locate character bit pattern and display the symbol.

;Come here if (HL) was $FE or $FF, or with a graphic character.
;At this point A=$00 if (HL) was $FE indicating a bug symbol, or $01 if (HL) was $FF indicating a null,
;or A=$01-$10 if a graphic character.

L3072:  LD   DE,L30E0     ; Start address of the graphic character bitmap table.
        CALL L2EF5        ; HL=A*8 -> $0000 or $0008.
        AND  A            ; Clear carry flag to indicate no need to switch back to RAM bank 7.

L3079:  EX   AF,AF'       ; Save switch bank indication flag.
        ADD  HL,DE        ; Point to the symbol bit pattern data.

L307B:  POP  DE           ; Fetch display file address. Drop through into routine below.

; ------------------------------------
; Copy A Character <<< RAM Routine >>>
; ------------------------------------
; Routine copied to RAM at $FF36-$FF55 by subroutine at $30BF (ROM 0).
; Also used in ROM from above routine.
;
; This routine copies 8 bytes from HL to DE. It increments HL and D after
; each byte, restoring D afterwards.
; It is used to copy a character into the display file.
; Entry: HL=Character data.
;        DE=Display file address.

L307C:  LD   C,D          ; Save D.

        LD   A,(HL)       ;
        LD   (DE),A       ; Copy byte 1.

        INC  HL           ;
        INC  D            ;
        LD   A,(HL)       ;
        LD   (DE),A       ; Copy byte 2.

        INC  HL           ;
        INC  D            ;
        LD   A,(HL)       ;
        LD   (DE),A       ; Copy byte 3.

        INC  HL           ;
        INC  D            ;
        LD   A,(HL)       ;
        LD   (DE),A       ; Copy byte 4.

        INC  HL           ;
        INC  D            ;
        LD   A,(HL)       ;
        LD   (DE),A       ; Copy byte 5.

        INC  HL           ;
        INC  D            ;
        LD   A,(HL)       ;
        LD   (DE),A       ; Copy byte 6.

        INC  HL           ;
        INC  D            ;
        LD   A,(HL)       ;
        LD   (DE),A       ; Copy byte 7.

        INC  HL           ;
        INC  D            ;
        LD   A,(HL)       ;
        LD   (DE),A       ; Copy byte 8.

        LD   D,C          ; Restore D. <<< Last byte copied to RAM >>>

; When the above routine is used in ROM, it drops through to here.

L309C:  EX   AF,AF'       ; Need to switch back to RAM bank 7?
        CALL C,L1ED4      ; If so then switch to use Workspace RAM configuration (physical RAM bank 7).

L30A0:  POP  HL           ; Fetch address of string data.
        INC  HL           ; Move to next character.
        INC  DE           ; Advance to next display file column.
        DJNZ L3031        ; Repeat for all requested characters.

        RET               ;

; ---------------------------------
; Toggle ROMs 1 <<< RAM Routine >>>
; ---------------------------------
; Routine copied to RAM at $FF28-$FF35 by subroutine at $30BF (ROM 0).
;
; This routine toggles to the other ROM than the one held in BANK_M.
; Entry: A'= Current paging configuration.

L30A6:  PUSH BC           ; Save BC

        DI                ; Disable interrupts whilst paging.

        LD   BC,$7FFD     ;
        LD   A,(BANK_M)   ; $5B5C. Fetch current paging configuration.
        XOR  $10          ; Toggle ROMs.
        OUT  (C),A        ; Perform paging.
        EI                ; Re-enable interrupts.
        EX   AF,AF'       ; Save the new configuration in A'. <<< Last byte copied to RAM >>>

; ---------------------------------
; Toggle ROMs 2 <<< RAM Routine >>>
; ---------------------------------
; Routine copied to RAM at $FF56-$FF60 by subroutine at $30BF (ROM 0).
;
; This routine toggles to the other ROM than the one specified.
; It is used to page back to the original configuration.
; Entry: A'= Current paging configuration.

L30B4:  EX   AF,AF'       ; Retrieve current paging configuration.
        DI                ; Disable interrupts whilst paging.
        LD   C,$FD        ; Restore Paging I/O port number.
        XOR  $10          ; Toggle ROMs.
        OUT  (C),A        ; Perform paging.
        EI                ; Re-enable interrupts.

        POP  BC           ; Restore BC.
        RET               ; <<< Last byte copied to RAM >>>

; -----------------------------------------
; Construct 'Copy Character' Routine in RAM
; -----------------------------------------
; This routine copies 3 sections of code into RAM to construct a single
; routine that can be used to copy the bit pattern for a character into
; the display file.
;
; Copy $30A6-$30B3 (ROM 0) to $FF28-$FF35 (14 bytes).
; Copy $307C-$309B (ROM 0) to $FF36-$FF55 (32 bytes).
; Copy $30B4-$30BE (ROM 0) to $FF56-$FF60 (11 bytes).

L30BF:  LD   HL,L30A6     ; Point to the 'page in other ROM' routine.
        LD   DE,$FF28     ; Destination RAM address.
        LD   BC,$000E     ;
        LDIR              ; Copy the routine.

        PUSH HL           ;
        LD   HL,L307C     ; Copy a character routine.
        LD   C,$20        ;
        LDIR              ; Copy the routine.

        POP  HL           ; HL=$30B4 (ROM 0), which is the address of the 'page back to original ROM' routine.
        LD   C,$0B        ;
        LDIR              ; Copy the routine.
        RET               ;

; --------------
; Character Data
; --------------

;Graphic control code indicator

L30D8:  DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $3C          ; 0 0 1 1 1 1 0 0      XXXX
        DEFB $62          ; 0 1 1 0 0 0 1 0     XX   X
        DEFB $60          ; 0 1 1 0 0 0 0 0     XX
        DEFB $6E          ; 0 1 1 0 1 1 1 0     XX XXX
        DEFB $62          ; 0 1 1 0 0 0 1 0     XX   X
        DEFB $3E          ; 0 0 1 1 1 1 1 0      XXXX
        DEFB $00          ; 0 0 0 0 0 0 0 0

;Error marker (character code $FE)

L30E0:  DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $6C          ; 0 1 1 0 1 1 0 0     XX XX
        DEFB $10          ; 0 0 0 1 0 0 0 0       X
        DEFB $54          ; 0 1 0 1 0 1 0 0     X X X
        DEFB $BA          ; 1 0 1 1 1 0 1 0    X XXX X
        DEFB $38          ; 0 0 1 1 1 0 0 0      XXX
        DEFB $54          ; 0 1 0 1 0 1 0 0     X X X
        DEFB $82          ; 1 0 0 0 0 0 1 0    X     X

;Null character (character code $FF)

L30E8:  DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $00          ; 0 0 0 0 0 0 0 0

L30F0:  DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $00          ; 0 0 0 0 0 0 0 0
        DEFB $00          ; 0 0 0 0 0 0 0 0

L30F8:  DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 

L3100:  DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 

L3108:  DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX

L3110:  DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX

L3118:  DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX

L3120:  DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX

L3128:  DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        
L3130:  DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX

L3138:  DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX

L3140:  DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX

L3148:  DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $00          ; 0 0 0 0 0 0 0 0 
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX

L3150:  DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $0F          ; 0 0 0 0 1 1 1 1        XXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX

L3158:  DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $F0          ; 1 1 1 1 0 0 0 0    XXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX

L3160:  DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX
        DEFB $FF          ; 1 1 1 1 1 1 1 1    XXXXXXXX

; ---------------------------
; Blank Screen Buffer Content
; ---------------------------
; Sets the specified number of screen buffer positions from the specified row to $FF.
; Entry: A=Row number.
;        BC=Number of bytes to set.

L3168:  LD   D,$FF        ; The character to set the screen buffer contents to.

L316A:  CALL L2EF3        ; HL=A*32. Offset to the specified row.
        LD   A,D          ;
        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,DE        ; HL=Address of first column in the requested row.
        LD   E,L          ;
        LD   D,H          ;
        INC  DE           ; DE=Address of second column in the requested row.
        LD   (HL),A       ; Store the character in the first column.
        DEC  BC           ;
        LDIR              ; Copy the character to all remaining positions.
        RET               ;

; --------------------------------------
; Set Attributes File from Screen Buffer
; --------------------------------------
; This routine parses the screen buffer string contents looking for colour
; control codes and changing the attributes file contents correspondingly.

L317B:  RES  0,(IY-$3B)   ; $5BFF. Signal do not invert attribute value.

        LD   DE,$5800     ; The start of the attributes file.
        LD   BC,$02C0     ; 22 rows of 32 columns.
        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   A,($5C8D)    ; ATTR_P.
        LD   ($5C8F),A    ; ATTR_T. Use the permanent colours.

; --------------------------------------
; Set Attributes for a Screen Buffer Row
; --------------------------------------
; Entry: A=Colour byte.
;        HL=Address within screen buffer.
;        BC=Number of characters.
;        DE=Address within attributes file.

L318E:  EX   AF,AF'       ; Save the colour byte.

;The main loop returns here on each iteration

L318F:  PUSH BC           ; Save the number of characters.

        LD   A,(HL)       ; Fetch a character from the buffer.
        CP   $FF          ; Is it null?
        JR   NZ,L319D     ; Jump ahead if not.

        LD   A,($5C8D)    ; ATTR_P. Get the default colour byte.
        LD   (DE),A       ; Store it in the attributes file.
        INC  HL           ; Point to next screen buffer position.
        INC  DE           ; Point to next attributes file position.
        JR   L31FA        ; Jump ahead to handle the next character.

;Not a null character

L319D:  EX   AF,AF'       ; Get the colour byte.
        LD   (DE),A       ; Store it in the attributes file.
        INC  DE           ; Point to the next attributes file position.
        EX   AF,AF'       ; Save the colour byte.
        INC  HL           ; Point to the next screen buffer position.

        CP   $15          ; Is the string character OVER or above?
        JR   NC,L31FA     ; Jump if it is to handle the next character.

        CP   $10          ; Is the string character below INK?
        JR   C,L31FA      ; Jump if it is to handle the next character.

;Screen buffer character is INK, PAPER, FLASH, BRIGHT or INVERSE.

        DEC  HL           ; Point back to the previous screen buffer position.
        JR   NZ,L31B5     ; Jump if not INK.

;Screen character was INK so insert the new ink into the attribute byte.

        INC  HL           ; Point to the next screen buffer position.
        LD   A,(HL)       ; Fetch the ink colour from the next screen buffer position.
        LD   C,A          ; and store it in C.
        EX   AF,AF'       ; Get the colour byte.
        AND  $F8          ; Mask off the ink bits.
        JR   L31F8        ; Jump ahead to store the new attribute value and then to handle the next character.

L31B5:  CP   $11          ; Is the string character PAPER?
        JR   NZ,L31C4     ; Jump ahead if not.

;Screen character was PAPER so insert the new paper into the attribute byte.

        INC  HL           ; Point to the next screen buffer position.
        LD   A,(HL)       ; Fetch the paper colour from the next screen buffer position.
        ADD  A,A          ;
        ADD  A,A          ;
        ADD  A,A          ; Multiple by 8 so that ink colour become paper colour.
        LD   C,A          ;
        EX   AF,AF'       ; Get the colour byte.
        AND  $C7          ; Mask off the paper bits.
        JR   L31F8        ; Jump ahead to store the new attribute value and then to handle the next character.

L31C4:  CP   $12          ; Is the string character FLASH?
        JR   NZ,L31D1     ; Jump ahead if not.

;Screen character was FLASH

        INC  HL           ; Point to the next screen buffer position.
        LD   A,(HL)       ; Fetch the flash status from the next screen buffer position.
        RRCA              ; Shift the flash bit into bit 0.
        LD   C,A          ;
        EX   AF,AF'       ; Get the colour byte.
        AND  $7F          ; Mask off the flash bit.
        JR   L31F8        ; Jump ahead to store the new attribute value and then to handle the next character.

L31D1:  CP   $13          ; Is the string character BRIGHT?
        JR   NZ,L31DF     ; Jump ahead if not.

;Screen character was BRIGHT

        INC  HL           ; Point to the next screen buffer position.
        LD   A,(HL)       ; Fetch the bright status from the next screen buffer position.
        RRCA              ;
        RRCA              ; Shift the bright bit into bit 0.
        LD   C,A          ;
        EX   AF,AF'       ; Get the colour byte.
        AND  $BF          ; Mask off the bright bit.
        JR   L31F8        ; Jump ahead to store the new attribute value and then to handle the next character.

L31DF:  CP   $14          ; Is the string character INVERSE?
        INC  HL           ; Point to the next screen buffer position.
        JR   NZ,L31FA     ; Jump ahead if not to handle the next character.

;Screen character was INVERSE

        LD   C,(HL)       ; Fetch the inverse status from the next screen buffer position.
        LD   A,(ED_FLGS)  ; $5BFF. Fetch inverting status (Bit 0 is 0 for non-inverting, 1 for inverting).
        XOR  C            ; Invert status.
        RRA               ; Shift status into the carry flag.
        JR   NC,L31FA     ; Jump if not inverting to handle the next character.

        LD   A,$01        ; Signal inverting is active.
        XOR  (IY-$3B)     ; $5BFF.
        LD   (ED_FLGS),A  ; $5BFF. Store the new status.
        EX   AF,AF'       ; Get the colour byte.

        CALL L2D22        ; Swap ink and paper in the colour byte.

L31F8:  OR   C            ; Combine the old and new colour values.
        EX   AF,AF'       ; Save the new colour byte.

L31FA:  POP  BC           ; Fetch the number of characters.
        DEC  BC           ;
        LD   A,B          ;
        OR   C            ;
        JP   NZ,L318F     ; Repeat for all characters.

        EX   AF,AF'       ; Get colour byte.
        LD   ($5C8F),A    ; ATTR_T. Make it the new temporary colour.
        RET               ;

; --------
; ????
; --------

L3206:  PUSH DE           ;
        LD   HL,($FF1E)   ; ???? Next Line Screen Buffer Mapping.
        SCF               ;
        SBC  HL,DE        ;
        JR   C,L327C      ; ???? Jump to null row ????

        CALL L32B6        ; ????
        JR   Z,L3221      ;

        LD   HL,($FF1E)   ; ???? Next Line Screen Buffer Mapping.
        PUSH HL           ;
        LD   H,B          ;
        LD   L,C          ;
        CALL L2C66        ; ????
        POP  HL           ;
        LD   ($FF1E),HL   ; ???? Next Line Screen Buffer Mapping.

L3221:  POP  DE           ;
        PUSH DE           ;
        LD   HL,($FF1E)   ; ???? Next Line Screen Buffer Mapping.
        PUSH HL           ;
        LD   A,L          ;
        AND  $E0          ;
        LD   L,A          ;
        OR   A            ;
        SBC  HL,DE        ;
        POP  HL           ;
        JR   Z,L324A      ;

        LD   BC,$0020     ;
        OR   A            ;
        SBC  HL,BC        ;
        LD   ($FF1E),HL   ; ???? Next Line Screen Buffer Mapping.
        OR   A            ;
        SBC  HL,DE        ;
        LD   A,L          ;
        OR   $1F          ;
        LD   L,A          ;
        INC  HL           ;
        LD   B,H          ;
        LD   C,L          ;
        LD   HL,$0020     ;
        ADD  HL,DE        ;
        LDIR              ;

L324A:  LD   HL,($FF20)   ;
        LD   A,H          ;
        OR   L            ;
        JR   Z,L327C      ; ???? Jump to null row ????

;???? inserting a basic line?

        PUSH DE           ;
        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        RST  28H          ;
        DEFW LINE_ADDR    ; $196E.
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        POP  DE           ;
        PUSH DE           ;
        LD   B,H          ;
        LD   C,L          ;
        POP  HL           ;
        CALL L2AA2        ; ???? Store Line Number Mapping List Entry


;Is there definitely a basic line? if there might not be then the bug in $219F could cause a crash

        CALL L219F        ; ???? copy row of basic line into screen buffer

        LD   DE,($FF22)   ; ???? holds the next available address within the Screen Buffer when displaying a program.
        LD   HL,$FF1E     ; ???? Next Line Screen Buffer Mapping.
        CALL L2A99        ; ???? Does the Specified Address Point to the End of the BASIC Program?
        JR   NZ,L3277     ;

        CALL L2A88        ; ????
        JR   L327A        ;

; ????

L3277:  CALL L2AA2        ; ???? Store Line Number Mapping List Entry

L327A:  POP  DE           ;
        RET               ;

; ????

L327C:  LD   B,$20        ; Null a row of characters.
        CALL L2CA6        ; ???? null some bytes (DE=addr, B=len) to remainder of displayed line????

        POP  DE           ;
        RET               ;

; --------
; ????
; --------

L3283:  PUSH DE           ;
        CALL L32B6        ; ????
        JR   NC,L32A7     ;

        PUSH BC           ;
        LD   HL,$FF1A     ; ???? Address of the last entry of the Line Number Mapping List.
        OR   A            ;
        SBC  HL,BC        ;
        LD   B,H          ;
        LD   C,L          ;
        LD   HL,$FF19     ;
        LD   DE,$FF1D     ;
        LD   A,B          ;
        OR   C            ;
        JR   NZ,L32A4     ;

        LD   HL,($FF1C)   ;
        LD   ($FF20),HL   ;
        JR   L32A6        ;

L32A4:  LDDR 
                          ;
L32A6:  POP  BC           ;

L32A7:  LD   H,B          ;
        LD   L,C          ;
        POP  DE           ;
        PUSH BC           ;
        CALL L2A8F        ;
        LD   HL,$0000     ;
        LD   (ED_LINE),HL ; $5B67.
        POP  BC           ;
        RET               ;

; --------
; ???? scan through mapping list?
; --------

L32B6:  LD   BC,$FEC6     ;

L32B9:  LD   A,(BC)       ;
        LD   L,A          ;
        INC  BC           ;
        LD   A,(BC)       ;
        DEC  BC           ;
        LD   H,A          ;
        OR   L            ;
        RET  Z            ;

        SBC  HL,DE        ;
        CCF               ;
        RET  C            ;

        INC  BC           ;
        INC  BC           ;
        INC  BC           ;
        INC  BC           ;
        JR   L32B9        ;


; =======================
; Editor Keyword Routines
; =======================

; -----------------------------
; Is Valid Editor Keyword Line?
; -----------------------------
; This routine checks whether one of the four new Editor keywords has been entered, including
; validating the parameters. The new keywords are BORRAR (delete), EDITAR (edit), ANCHO (width)
; and NUMERO (renumber).
; Entry: HL=Address of the line to parse.
; Exit:  Carry flag reset if not a valid Editor keyword line, else carry flag set if end
;        of line was found immediately after the keyword, i.e. no parameters.

L32CB:  XOR  A            ;
        LD   (KPARAMS),A  ; $5B72. Clear the count of the number of parameters.

        LD   ($5C5D),HL   ; CH_ADD. Store the address of the line to parse.

        CALL L3307        ; Test whether one of the four new editor keywords was entered.
        RET  NC           ; Return if not an editor keyword.

;A match with a new editor keyword was found, with the B register indicating which one:
;  1 = Delete.
;  2 = Edit.
;  3 = Width.
;  4 = Renumber.

        LD   A,B          ; Fetch the matching entry number.
        LD   (KINDEX),A   ; $5B71. Save it for testing later.

        RST  18H          ; Get current character.
        CP   $0D          ; Was a carriage return found, i.e. the end of the line?
        SCF               ; Signal no parameter specified.
        RET  Z            ; Return if end of the line was found.

        PUSH HL           ; Save the address of the next character.
        CALL L3398        ; Check that a valid number of numeric parameters follows.
        POP  HL           ; HL=Address of the next character.
        LD   ($5C5D),HL   ; CH_ADD. Restore this as the address of the next character.
        JP   C,L334B      ; Jump if a valid number of numeric parameters was found.

;The only new command which can support a non-numeric parameter is the EDITAR keyword

        LD   HL,KINDEX    ; $5B71. Point to the keyword index number.
        DEC  (HL)         ;
        DEC  (HL)         ; Test whether it was "EDITAR" (Edit). This also changes the index value of the keyword to 0.
        JR   Z,L32F3      ; Jump ahead if so.

L32F1:  OR   A            ; Clear the carry flag to indicate not a valid EDITAR line.
        RET               ;

;The "EDITAR" keyword was found so check whether it is followed by a string variable

L32F3:  RST  18H          ; Get current character.
        LD   (KPARAM1),HL ; $5B6D. Save it for later.

        RST  28H          ;
        DEFW ALPHA        ; $2C8D. Is it a letter?
        RET  NC           ; Return if not with the carry flag reset.

        RST  20H          ; Get next character from BASIC line.
        CP   '$'          ; $24. Is it a string variable?
        JR   NZ,L32F1     ; Jump if not to return with the carry flag reset.

        RST  20H          ; Get next character from BASIC line.
        CP   $0D          ; Was a carriage return found, i.e. the end of the line?
        JR   NZ,L32F1     ; Jump if not to return with the carry flag reset.

        SCF               ; Signal valid EDITAR line found.
        RET               ;

; -----------------------
; Test for Editor Keyword
; -----------------------
; This routine checks whether one of the four new Editor keywords has been entered.
; A partial match is all that is required, even just the initial character, and is not case sensitive.
; For example, the EDITAR keyword can be entered as E, ED, EDI, EDIT, EDITA or EDITAR.
; Exit: Zero flag set and carry flag reset if no match found,
;       else carry flag set if a match found and B indicates which entry.

L3307:  RST  18H          ; Get current character.
        EX   DE,HL        ; DE=Address of next printable character.

        LD   HL,L332F     ; HL=Editor keyword string table.

L330C:  LD   B,(HL)       ; Fetch entry number.
        INC  HL           ; Point to the start of the keyword.
        LD   A,(DE)       ; Fetch the first character from the BASIC line.

L330F:  AND  $DF          ; Convert to uppercase.
        CP   (HL)         ; Does it match the character in the table entry?
        JR   NZ,L3322     ; Jump if not to test the next entry.

        INC  HL           ; Point to the next character in the table entry.
        INC  DE           ; Point to the next character in the BASIC line.
        LD   A,(DE)       ; Fetch the next character from the BASIC line.
        RST  28H          ;
        DEFW ALPHA        ; $2C8D. Is it a letter?
        CCF               ;
        JR   NC,L330F     ; Jump if a letter to test if it matches the current character in the table entry.

        LD   ($5C5D),DE   ; CH_ADD. Store as the address of the next character to processing.
        RET               ;

;A match was not found so skip to the next entry

L3322:  INC  HL           ; Point to the next character within the table entry.
        LD   A,(HL)       ;
        AND  A            ;
        RET  Z            ; Return if the end marker was found.

        CP   $1F          ; Was a printable character found?
        JR   NC,L3322     ; Jump back if so to skip over the remaining characters of this keyword.

        JR   L330C        ; Jump back to test the next table entry.

; ==============
; Unused Routine
; ==============

L332C:  SCF               ;
        RST  20H          ; Advance the pointer into the BASIC line.
        RET               ;

; ---------------
; Editor Keywords
; ---------------

L332F:  DEFB $01          ;
        DEFM "BORRAR"     ; Delete.
        DEFB $02          ;
        DEFM "EDITAR"     ; Edit.
        DEFB $03          ;
        DEFM "ANCHO"      ; Width.
        DEFB $04          ;
        DEFM "NUMERO"     ; Renumber.
        DEFB $00          ; End Marker.

; ----------------------------------------------
; Process the Parameters of a New Editor Keyword
; ----------------------------------------------
; This routine tests that there is room for the hidden floating point representation of the
; parameters, and ensures that the parameter values are converted into integer values.

L334B:  RST  18H          ; Get current character.
        CALL L337C        ; Check that there is room to store the hidden floating point representation?
        RST  28H          ;
        DEFW DEC_TO_FP    ; $2C9B. Convert the number in the BASIC line into the floating point form.

        RST  18H          ; Get current character.
        PUSH AF           ;

        RST  28H          ;
        DEFW FP_TO_BC     ; $2DA2. Convert the floating point value to an integer.
        LD   (KPARAM1),BC ; $5B6D. Store the first parameter.
        CALL L3376        ; Increment the parameter count.

        POP  AF           ;
        CP   ','          ; $2C. Is the current character a comma, indicating a second parameter?
        JR   NZ,L3383     ; Jump ahead to continue if only a single parameter.

        RST  20H          ; Get next character from BASIC line.
        CALL L337C        ; Check that there is room to store the hidden floating point representation?
        RST  28H          ;
        DEFW DEC_TO_FP    ; $2C9B. Convert the number in the BASIC line into the floating point form.
        RST  28H          ;
        DEFW FP_TO_BC     ; $2DA2. Convert the floating point value to an integer.
        LD   (KPARAM2),BC ; $5B6F. Store the second parameter.
        CALL L3376        ; Increment the parameter count.
        JR   L3383        ; Jump ahead to continue.

; -------------------------
; Increment Parameter Count
; -------------------------

L3376:  LD   HL,KPARAMS   ; $5B72. Point to the parameter count store.
        INC  (HL)         ; Increment the count of the number of parameters.
        SCF               ; [Redundant instruction as never subsequently tested]
        RET               ;

; --------------------------------------
; Room for Hidden Floating Point Number?
; --------------------------------------
; This routine will only return if there is room available, otherwise error '4' is
; automatically produced.
 
L337C:  LD   BC,$0006     ;
        CALL L29B0        ; Is there room to insert 6 bytes for the hidden floating point form?
        RET               ; [Could have saved 1 byte by using JP $29B0]

; ---------------------------------
; Check All Parameters within Range
; ---------------------------------
; Exit: Carry flag set if all parameters are within range.

L3383:  CALL L33D3        ; Is the first parameter within range?
        JR   NC,L3393     ; Jump if not.

        LD   A,(KPARAMS)  ; $5B72. Fetch the number of parameters.
        CP   $02          ; Were they 2?
        SCF               ; Signal that the signle parameter is within range.
        RET  NZ           ; Return if not.

        CALL L33D8        ; Is the second parameter within range?
        RET  C            ; Return if so.

;A parameter was out of range

L3393:  SET  6,(IY-$3B)   ; $5BFF. Signal parameter out of range.
        RET               ;

; -------------------------------
; Check Editor Keyword Parameters
; -------------------------------
; The valid number of parameters is 0, 1 or 2.
; Exit: Carry flag set if a valid number of numeric parameters found, with B holding the number of parameters.

L3398:  LD   B,$00        ; B will hold a count of the number of parameters.
        JR   L339D        ; Jump ahead.

L339C:  RST  20H          ; Get next character from BASIC line.

L339D:  RST  28H          ;
        DEFW NUMERIC      ; $2D1B. Is it numeric?
        JR   C,L33A4      ; Jump if not.

        JR   L339C        ; Jump back until the first non-numeric character is found.
                          ; [Could have saved 2 bytes by using JR NC,$339C instead of these two instructions]

L33A4:  CP   ','          ; $2C. Is the next character a comma?
        JR   NZ,L33AB     ; Jump if not.

        INC  B            ; Increment the count of the number of parameters.
        JR   L339C        ; Jump back to test if another parameter.

;The end of the parameters was found

L33AB:  RST  18H          ; Get current character.
        CP   $0D          ; Was it the end of the line?
        JR   Z,L33B2      ; Jump if so.

L33B0:  OR   A            ; Clear the carry flag to indicate that an unexpected character was found.
        RET               ;

L33B2:  LD   A,$01        ; Were there 0, 1 or 2 parameters?
        CP   B            ;
        JR   C,L33B0      ; Jump if there were more.

        SCF               ; Set the carry flag to indicate a valid instruction.
        RET               ;

; ----------------------------------
; Line Number Reference Out of Range
; ----------------------------------
; This routine is used by the Renumber and Delete keyword routines.

L33B9:  CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        JR   L3393        ; Return signalling that a value was out of range.

; -----------------------
; Use Default Parameters?
; -----------------------
; This routine is used by the Renumber and Edit keyword routines.
 
L33BE:  LD   HL,$000A     ; The default parameter values.

        LD   A,(KPARAMS)  ; $5B72. Fetch the number of parameters.
        AND  A            ;
        JR   Z,L33CC      ; Jump if there were none to use the default for both.

        CP   $01          ; Was there a single parameter?
        JR   Z,L33CF      ; Jump if so to set a second parameter value.

        RET               ; Both parameters were specified so simply return.

L33CC:  LD   (KPARAM1),HL ; $5B6D. Store a default first parameter value.

L33CF:  LD   (KPARAM2),HL ; $5B6F. Store a default second parameter value
        RET               ;

; -------------------------------
; Keyword Parameter within Range?
; -------------------------------
; This rouine tests whether the parameters of one of the new Editor keywords is
; within the range 1 to 9999.
; Exit: Carry flag set if within range.

L33D3:  LD   HL,(KPARAM1) ; $5B6D. Fetch the value of the first parameter.
        JR   L33DB        ; Jump ahead.

L33D8:  LD   HL,(KPARAM2) ; $5B6F. Fetch the value of the second parameter.

L33DB:  LD   A,L          ; Is the parameter value 0?
        OR   H            ;
        RET  Z            ; Return if so.

        LD   DE,$2710     ; 10000.
        OR   A            ; Is the parameter value 9999 or less?
        SBC  HL,DE        ;
        RET  


; ========================
; Keyword Handler Routines
; ========================

; -----------------------------------------
; NUMERO (Renumber) Keyword Handler Routine
; -----------------------------------------
; Renumber a block of BASIC lines, using the specified start line value and using the specified step size.
;
; Usage: NUMERO {n1}, {n2}
;
; where: n1 is the new first line number. If omitted then a default start line number of 10 is used.
;        n2 is the step size to use for renumbering. If omitted then a default step size of 10 is used.

L33E5:  CALL L33BE        ; Check whether to use default values for the start and step values.
        CALL L29C7        ; Check whether there is a BASIC program.
        RET  Z            ; Return if there is not since there is nothing to renumber.

L33EC:  CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).

        CALL L3548        ; DE=Count of the number of BASIC lines.
        LD   HL,(RNSTEP)  ; $5B6F. Fetch the line number increment for Renumber.
        RST  28H          ;
        DEFW HL_MULT_DE   ; $30A9. HL=HL*DE in ROM 1. HL=Number of lines * Line increment = New last line number.
                          ; [*BUG* - If there are more than 6553 lines then an arithmetic overflow will occur and hence
                          ; the test below to check if line 9999 would be exceeded will fail. The carry flag will be set
                          ; upon such an overflow and simply needs to be tested. The bug can be resolved by following the
                          ; call to HL_MULT_DE with a JP C,$33B9 (ROM 0) instruction. Credit: Ian Collier (+3), Andrew Owen (128)]
        EX   DE,HL        ; DE=Offset of new last line number from the first line number

#ifndef BUG_FIXES
        LD   HL,(RNFIRST) ; $5B6D. Starting line number for Renumber.
#else
        CALL PATCH3       ;@
#endif
        ADD  HL,DE        ; HL=New last line number.
        LD   DE,$2710     ; 10000.
        OR   A            ;
        SBC  HL,DE        ; Would the last line number above 9999?
        JP   NC,L33B9     ; Jump if so to return since Renumber cannot proceed.

;There is a program that can be renumbered

        LD   HL,($5C53)   ; PROG. HL=Address of first BASIC line.

L3409:  RST  28H          ; Find the address of the next BASIC line from the
        DEFW NEXT_ONE     ; $19B8.  location pointed to by HL, returning it in DE.

        INC  HL           ; Advance past the line number bytes to point
        INC  HL           ; at the line length bytes.
        LD   (RNLINE),HL  ; $5B94. Store the address of the BASIC line's length bytes.

        INC  HL           ; Advance past the line length bytes to point
        INC  HL           ; at the command.
        LD   (RNNEXT),DE  ; $5B6B. Store the address of the next BASIC line.

L3417:  LD   A,(HL)       ; Get a character from the BASIC line.
        RST  28H          ; Advance past a floating point number, if present.
        DEFW NUMBER       ; $18B6.

        CP   $0D          ; Is the character an 'ENTER'?
        JR   Z,L3424      ; Jump if so to examine the next line.

        CALL L346E        ; Parse the line, renumbering any tokens that may be followed by a line number.
        JR   L3417        ; Repeat for all remaining character until end of the line.

L3424:  LD   DE,(RNNEXT)  ; $5B6B. DE=Address of the next BASIC line.
        LD   HL,($5C4B)   ; VARS. Fetch the address of the end of the BASIC program.
        AND  A            ;
        SBC  HL,DE        ; Has the end of the BASIC program been reached?
        EX   DE,HL        ; HL=Address of start of the current BASIC line.
        JR   NZ,L3409     ; Jump back if not to examine the next line.

;The end of the BASIC program has been reached so now it is time to update
;the line numbers and line lengths.

        CALL L3548        ; DE=Count of the number of BASIC lines.
        LD   B,D          ;
        LD   C,E          ; BC=Count of the number of BASIC lines.
        LD   DE,$0000     ;
        LD   HL,($5C53)   ; PROG. HL=Address of first BASIC line.

L343C:  PUSH BC           ; BC=Count of number of lines left to update.
        PUSH DE           ; DE=Index of the current line.

        PUSH HL           ; HL=Address of current BASIC line.

        LD   HL,(RNSTEP)  ; $5B6F. HL=Renumber line increment.
        RST  28H          ; Calculate new line number offset, i.e. Line increment * Line index.
        DEFW HL_MULT_DE   ; $30A9. HL=HL*DE in ROM 1.
        LD   DE,(RNFIRST) ; $5B6D. The initial line number when renumbering.
        ADD  HL,DE        ; HL=The new line number for the current line.
        EX   DE,HL        ; DE=The new line number for the current line.

        POP  HL           ; HL=Address of current BASIC line.

        LD   (HL),D       ; Store the new line number for this line.
        INC  HL           ;
        LD   (HL),E       ;
        INC  HL           ;
        LD   C,(HL)       ; Fetch the line length.
        INC  HL           ;
        LD   B,(HL)       ;
        INC  HL           ;
        ADD  HL,BC        ; Point to the next line.

        POP  DE           ; DE=Index of the current line.
        INC  DE           ; Increment the line index.

        POP  BC           ; BC=Count of number of lines left to update.
        DEC  BC           ; Decrement counter.
        LD   A,B          ;
        OR   C            ;
        JR   NZ,L343C     ; Jump back while more lines to update.

        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        LD   (RNLINE),BC  ; $5B94. Clear the address of line length bytes of the 'current line being renumbered'.
                          ; [No need to clear this]
        JP   L2F20        ; ???? list program to screen buffer and display file

; -------------------------
; Tokens Using Line Numbers
; -------------------------
; A list of all tokens that maybe followed by a line number and hence
; require consideration.

L3467:  DEFB $CA          ; 'LINE'.
        DEFB $F0          ; 'LIST'.
        DEFB $E1          ; 'LLIST'.
        DEFB $EC          ; 'GO TO'.
        DEFB $ED          ; 'GO SUB'.
        DEFB $E5          ; 'RESTORE'.
        DEFB $F7          ; 'RUN'.

; -----------------------------------------------
; Parse a Line Renumbering Line Number References
; -----------------------------------------------
; This routine examines a BASIC line for any tokens that may be followed by a line number reference
; and if one is found then the new line number if calculated and substituted for the old line number
; reference. Although checks are made to ensure an out of memory error does not occur, the routine
; simply returns silently in such scenarios and the renumber routine will continue onto the next BASIC
; line.
; Entry: HL=Address of current character in the current BASIC line.
;        A=Current character.

L346E:  INC  HL           ; Point to the next character.
        LD   (RNPOS),HL   ; $5B79. Store it.

        EX   DE,HL        ; DE=Address of next character.
        LD   BC,$0007     ; There are 7 tokens that may be followed by a line
        LD   HL,L3467     ; number, and these are listed in the table at $3467 (ROM 0).
        CPIR              ; Search for a match for the current character.
        EX   DE,HL        ; HL=Address of next character.
        RET  NZ           ; Return if no match found.

;A token that might be followed by a line number was found. If it is followed by a
;line number then proceed to renumber the line number reference. Note that the statements
;such as GO TO VAL "100" will not be renumbered. The line numbers of each BASIC line will
;be renumbered as the last stage of the renumber process at $3431 (ROM 0).

        LD   C,$00        ; Counts the number of digits in the current line number representation.
                          ; B will be $00 from above.

L347F:  LD   A,(HL)       ; Fetch the next character.
        CP   ' '          ; $20. Is it a space?
        JR   Z,L349F      ; Jump ahead if so to parse the next character.

        RST  28H          ;
        DEFW NUMERIC      ; $2D1B. Is the character a numeric digit?
        JR   NC,L349F     ; Jump if a numeric digit to parse the next character.

        CP   '.'          ; $2E. Is it a decimal point?
        JR   Z,L349F      ; Jump ahead if so to parse the next character.

        CP   $0E          ; Does it indicate a hidden number?
        JR   Z,L34A3      ; Jump ahead if so to process it.

        OR   $20          ; Convert to lower case.
        CP   'e'          ; $65. Is it an exponent 'e'?
        JR   NZ,L349B     ; Jump if not to parse the next character.

        LD   A,B          ; Have any digits been found?
        OR   C            ;
        JR   NZ,L349F     ; Jump ahead to parse the next character.

;A line number reference was not found

L349B:  LD   HL,(RNPOS)   ; $5B79. Retrieve the address of the next character.
        RET               ;

L349F:  INC  BC           ; Increment the number digit counter.
        INC  HL           ; Point to the next character.
        JR   L347F        ; Jump back to parse the character at this new address.

;An embedded number was found

L34A3:  LD   (RNLEN),BC   ; $5B71. Note the number of digits in the old line number reference.

        PUSH HL           ; Save the address of the current character.

        RST  28H          ;
        DEFW NUMBER       ; $18B6. Advance past internal floating point representation, if present.

        CALL L357B        ; Skip over any spaces.

        LD   A,(HL)       ; Fetch the new character.
        POP  HL           ; HL=Address of the current character.
        CP   ':'          ; $3A. Is it ':'?
        JR   Z,L34B7      ; Jump if so.

        CP   $0D          ; Is it 'ENTER'?
        RET  NZ           ; Return if not.

;End of statement/line found

L34B7:  INC  HL           ; Point to the next character.

        RST  28H          ;
        DEFW STACK_NUM    ; $33B4. Move floating point number to the calculator stack.
        RST  28H          ;
        DEFW FP_TO_BC     ; $2DA2. Fetch the number line to BC. [*BUG* - This should test the carry flag to check whether
                          ; the number was too large to be transferred to BC. If so then the line number should be set to 9999,
                          ; as per the instructions at $34CA (ROM 0). As a result, the call the LINE_ADDR below can result in a crash.
                          ; The bug can be resolved using a JR C,$34CA (ROM 0) instruction. Credit: Ian Collier (+3), Andrew Owen (128)]
        LD   H,B          ;
        LD   L,C          ; Transfer the number line to HL.

#ifndef BUG_FIXES
        RST  28H          ; Find the address of the line number specified by HL.
        DEFW LINE_ADDR    ; $196E. HL=Address of the BASIC line, or the next one if it does not exist.
#else
        CALL PATCH2       ;@
#endif
        JR   Z,L34CF      ; Jump if the line exists.

        LD   A,(HL)       ; Has the end of the BASIC program been reached?
#ifndef BUG_FIXES
        CP   $80          ; [*BUG* - This tests for the end of the variables area and not the end of the BASIC program area. Therefore,
                          ; the renumber routine will not terminate properly if variables exist in memory when it is called.
                          ; Executing CLEAR prior to renumbering will overcome this bug.
                          ; It can be fixed by replacing CP $80 with the instructions AND $C0 / JR Z,$34CF (ROM 0). Credit: Ian Collier (+3), Andrew Owen (128)]
        JR   NZ,L34CF     ; Jump ahead if not.
#else
        AND  $C0          ;@ [*BUG FIX*]
        JR   Z,L34CF      ;@ [*BUG FIX*]
#endif

L34CA:  LD   HL,$270F     ; Make the reference point to line 9999.
        JR   L34E0        ; Jump ahead to update the reference to use the new line number.

;The reference line exists

L34CF:  LD   (RNEND),HL   ; $5B77. Store the address of the referenced line.
        CALL L3550        ; DE=Count of the number of BASIC lines up to the referenced line.
        LD   HL,(RNSTEP)  ; $5B96. Fetch the line number increment.
        RST  28H          ;
        DEFW HL_MULT_DE   ; $30A9. HL=HL*DE in ROM 1. HL=Number of lines * Line increment = New referenced line number.
                          ; [An overflow could occur here and would not be detected. The code at $33F7 (ROM 0)
                          ; should have trapped that such an overflow would occur and hence there would have been
                          ; no possibility of it occurring here.]
        LD   DE,(RNFIRST) ; $5B94. Starting line number for Renumber.
        ADD  HL,DE        ; HL=New referenced line number.

;HL=New line number being referenced

L34E0:  LD   DE,RNBUF     ; $5B73. Temporary buffer to generate ASCII representation of the new line number.
        PUSH HL           ; Save the new line number being referenced.
        CALL L2959        ; Create the ASCII representation of the line number in the buffer.

        LD   E,B          ;
        INC  E            ;
        LD   D,$00        ; DE=Number of digits in the new line number.

        PUSH DE           ; DE=Number of digits in the new line number.
        PUSH HL           ; HL=Address of the first non-'0' character in the buffer.

        LD   L,E          ;
        LD   H,$00        ; HL=Number of digits in the new line number.
        LD   BC,(RNLEN)   ; $5B71. Fetch the number of digits in the old line number reference.
        OR   A            ;
        SBC  HL,BC        ; Has the number of digits changed?
        LD   (RNLEN),HL   ; $5B71. Store the difference between the number of digits in the old and new line numbers.
        JR   Z,L3512      ; Jump if they are the same length.

        JR   C,L3508      ; Jump if the new line number contains less digits than the old.

;The new line number contains more digits than the old line number

        LD   B,H          ;
        LD   C,L          ; BC=Length of extra space required for the new line number.
        LD   HL,(RNPOS)   ; $5B79. Fetch the start address of the old line number representation within the BASIC line.
        CALL L29A5        ; Create room for extra line number characters.
        JR   L3512        ; Jump ahead to update the number digits.

;The new line number contains less digits than the old line number

L3508:  DEC  BC           ; BC=Number of digits in the old line number reference.
        DEC  E            ; Decrement number of digits in the new line number.
L350A:  JR   NZ,L3508     ; Repeat until BC has been decremented by the number of digits in the new line number,
                          ; thereby leaving BC holding the number of digits in the BASIC line to be discarded.

        LD   HL,(RNPOS)   ; $5B79. Fetch the start address of the old line number representation within the BASIC line.
        RST  28H          ;
        DEFW RECLAIM_2    ; $19E8. Discard the redundant bytes.

;The appropriate amount of space now exists in the BASIC line so update the line number value

L3512:  LD   DE,(RNPOS)   ; $5B79. Fetch the start address of the old line number representation within the BASIC line.
        POP  HL           ; HL=Address of the first non-'0' character in the buffer.
        POP  BC           ; BC=Number of digits in the new line number.
        LDIR              ; Copy the new line number into place.

        EX   DE,HL        ; HL=Address after the line number text in the BASIC line.
        LD   (HL),$0E     ; Store the hidden number marker.

        POP  BC           ; Retrieve the new line number being referenced.
        INC  HL           ; HL=Address of the next position within the BASIC line.
        PUSH HL           ;

        RST  28H          ;
        DEFW STACK_BC     ; $2D2B. Put the line number on the calculator stack, returning HL pointing to it.
                          ; [*BUG* - This stacks the new line number so that the floating point representation can be copied.
                          ; However, the number is not actually removed from the calculator stack. Therefore the
                          ; amount of free memory reduces by 5 bytes as each line with a line number reference is renumbered.
                          ; A call to FP_TO_BC (at $2DA2 within ROM 1) after the floating point form has been copied would fix
                          ; the bug. Note that all leaked memory is finally reclaimed when control is returned to the Editor but the
                          ; bug could prevent large programs from being renumbered. Credit: Paul Farrow]
        POP  DE           ; DE=Address of the next position within the BASIC line.
        LD   BC,$0005     ;
        LDIR              ; Copy the floating point form into the BASIC line.
        EX   DE,HL        ; HL=Address of character after the newly inserted floating point number bytes.
        PUSH HL           ;

#ifndef BUG_FIXES
        LD   HL,(RNLINE)  ; $5B92. HL=Address of the current line's length bytes.
#else
        CALL BUG_FIX6     ;@ [*BUG FIX*]
#endif
        PUSH HL           ;

        LD   E,(HL)       ;
        INC  HL           ;
        LD   D,(HL)       ; DE=Existing length of the current line.
        LD   HL,(RNLEN)   ; $5B71. HL=Change in length of the line.
        ADD  HL,DE        ;
        EX   DE,HL        ; DE=New length of the current line.

        POP  HL           ; HL=Address of the current line's length bytes.
        LD   (HL),E       ;
        INC  HL           ;
        LD   (HL),D       ; Store the new length.

        LD   HL,(ED_COL)  ; $5B6B. HL=Address of the next BASIC line.
        LD   DE,(RNLEN)   ; $5B71. DE=Change in length of the current line.
        ADD  HL,DE        ;
        LD   (ED_COL),HL  ; $5B6B. Store the new address of the next BASIC line.

        POP  HL           ; HL=Address of character after the newly inserted floating point number bytes.
        RET               ;

; -------------------------------
; Count the Number of BASIC Lines
; -------------------------------
; This routine counts the number of lines in the BASIC program, or if entered at $3550 (ROM 0) counts
; the number of lines in the BASIC program up to the address specified in HD_0F+1.
; Exit: DE=Number of lines.

L3548:  LD   HL,($5C4B)   ; VARS. Fetch the address of the variables
        LD   (RNEND),HL   ; $5B77.  and store it.
        JR   L355C        ; Jump ahead.

L3550:  LD   HL,($5C53)   ; PROG. Fetch the start of the BASIC program
        LD   DE,(RNEND)   ; $5B77.  and compare against the end address
        OR   A            ; to determine whether there is a BASIC program.
        SBC  HL,DE        ;
        JR   Z,L3576      ; Jump if there is no BASIC program.

L355C:  LD   HL,($5C53)   ; PROG. Fetch the start address of the BASIC program.
        LD   BC,$0000     ; A count of the number of lines.

L3562:  PUSH BC           ; Save the line number count.

        RST  28H          ; Find the address of the next BASIC line from the
        DEFW NEXT_ONE     ; $19B8.  location pointed to by HL, returning it in DE.

        LD   HL,(RNEND)   ; $5B77. Fetch the end address.
        AND  A            ;
        SBC  HL,DE        ;
        JR   Z,L3573      ; Jump if end hass been reached.

        EX   DE,HL        ; HL=Address of current line.

        POP  BC           ; Retrieve the line number count.
        INC  BC           ; Increment line number count.
        JR   L3562        ; Jump back to look for the next line.

L3573:  POP  DE           ; Retrieve the number of BASIC lines and
        INC  DE           ; increment since originally started on a line.
        RET               ;

;No BASIC program

L3576:  LD   DE,$0000     ; There are no BASIC lines.
        RET               ;

; -----------
; Skip Spaces
; -----------

L357A:  INC  HL           ; Point to the next character.

L357B:  LD   A,(HL)       ; Fetch the next character.
        CP   ' '          ; $20. Is it a space?
        JR   Z,L357A      ; Jump if so to skip to next character.

        RET               ;

; ---------------------------------------
; BORRAR (Delete) Keyword Handler Routine
; ---------------------------------------
; Delete a block of BASIC lines.
;
; Usage: BORRAR n1, n2
;
; where: n1=Lower line number to delete.
;        n2=Upper line number to delete.

L3581:  CALL L35F2        ; Were two parameters specified?
        JP   NZ,L3393     ; Jump if not.

        CALL L29C7        ; Is there a BASIC program?
        RET  Z            ; Return if not since there are no lines available for deletion.

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).

        LD   DE,(RNFIRST) ; $5B6D. Fetch the first parameter, the lower line number.
        LD   HL,(RNSTEP)  ; $5B6F. Fetch the second parameter, the upper line number.
        OR   A            ;
        SBC  HL,DE        ;
        JP   C,L33B9      ; Jump if second line number is lower than the first line number.

        EX   DE,HL        ; HL=Lower line number.
        RST  28H          ;
        DEFW LINE_ADDR    ; $196E. Returns address of the line in HL.
        JP   NZ,L33B9     ; Jump if the line does not exist to signal an invalid parameter.

        PUSH HL           ; Save the address of the lower line.
        LD   HL,(RNSTEP)  ; $5B6F. Fetch the second parameter, the upper line number.
        RST  28H          ;
        DEFW LINE_ADDR    ; $196E. Returns address of the line in HL, and the previous line in DE.
        JR   Z,L35AC      ; Jump ahead if the line exists.

        EX   DE,HL        ; The second line does not exist so use the address of the previous line that does exists.

L35AC:  RST  28H          ;
        DEFW NEXT_ONE     ; $19B8. Find the address of the line immediately after the upper line, into DE.
        POP  HL           ; HL=Address of the lower line.
        EX   DE,HL        ; DE=Address of the lower line, HL=Address of the upper line.
        RST  28H          ;
        DEFW RECLAIM      ; $19E5. Delete address range from DE (start of lower line) to HL-1 (last byte of upper line).
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        JP   L2F20        ; ???? relist the program?

; -------------------------------------
; WIDTH (Width) Keyword Handler Routine
; -------------------------------------
; Set the number of columns per row in the RS232 printer output. Note that a second parameter may be specified but
; is ignored. There is also no range checking on the first parameter, although only the least significant byte is used.
; This supports a range of 0 to 255, where a value of 0 (the default value when no parameter is specified) was intended
; to set the number columns back to the default value of 80. However, the code is flawed and a value of 0 will get stored
; as is, whereas any other value causes the default of 80 to be used. 
;
; Usage: WIDTH {n1}
;
; where: n1=New number of columns per row. If omitted then a default value of 80 is supposed to be used.

; [*BUG* - This routine should really check that a single parameter was specified by testing that $5B72 holds $01. As it stands,
; 0, 1, or 2 parameters are accepted. If no parameters are specified then $5B6D will hold a rubbish value. It can be fixed as follows. Credit: Paul Farrow]
;
;       LD   A,(KPARAMS)  ; $5B72. Fetch the number of keyword parameters.
;       CP   $01          ; Are there 1?
;       JP   NZ,L3393     ; Jump if not.

L35BA:  LD   HL,(KPARAM1) ; $5B6D. Fetch the first parameter.
        LD   A,L          ; Keep the lower byte only.
        AND  A            ;
#ifndef BUG_FIXES
        JR   Z,L35C3      ; Jump ahead if the new width is 0. [*BUG* - This should be JR NZ,$35C3. It results in only a width
                          ; value of 0 being accepted, i.e. no parameter specified. Any other value causes the default of 80 to be used. Credit: Paul Farrow]
                          ; [The severity of this bug explains why the Spanish 128 user manual does not make any mention of the WIDTH command. Credit: Andrew Owen]
#else
        JR   NZ,L35C3     ;@
#endif

        LD   A,$50        ; Use a default value of 80.

L35C3:  LD   (WIDTH),A    ; $5B64. Set the new system variable WIDTH.
        RET               ;

; ------------------------------------------
; EDITAR (Edit Line) Keyword Handler Routine
; ------------------------------------------
; Set the cursor on the specified line number.
;
; Usage: EDITAR n1
;
; where: n1=Line number.

L35C7:  CALL L33BE        ; Set a default parameter value of 10 if omitted.
        LD   HL,(KPARAM1) ; $5B6D. Fetch the first parameter value.
        LD   (ED_EDIT),HL ; $5B94. Store it as the edit line with cursor.

; -------------------------------
; Switch to Main Edit Screen Area
; -------------------------------
; This routine is call by the ENTER/EDIT key handler routine when in BASIC editing mode, the lower editing
; screen area is active and the editing line is empty. It switches to the main editing screen area and lists
; the program from the line with the program cursor. ????

L35D0:  LD   HL,$0000     ; Set the cursor at the start of the Screen Buffer.
        LD   (ED_POS),HL  ; $5B92. Store the cursor offset position.

        LD   BC,(ED_EDIT) ; $5B94. Fetch the number of the line to edit.
        CALL L2B53        ; Populate 21 rows of the Screen Buffer starting with the line to edit.

        RES  3,(IY-$3B)   ; Signal using main edit screen area.
        SET  0,(IY+$30)   ; Signal the screen requires clearing.

        LD   HL,FLAGS3    ; $5B66.
        RES  0,(HL)       ; 0=Editor mode.
        RES  1,(HL)       ; ???? 1=BASIC/Calculator mode, 0=Editor mode / 1=Delete operation, 0=Cursor move operation. ???? might be 1=line changed (Enter, cursor down, delete), 0=unchanged

        CALL L301B        ; Copy the Screen Buffer to the display file.
        JP   L2402        ; Jump to the Editor main loop.

; ----------------------------------------
; Are There Two Editor Keyword Parameters?
; ----------------------------------------
; Exit: Carry flag set if there are less than two Editor keyword parameters.

L35F2:  LD   A,(KPARAMS)  ; $5B72. Fetch the number of keyword parameters.
        CP   $02          ; Are there 2?
        RET               ;

; -------------------------------------------------------
; BASIC Editing Mode Keys Action Table - Main Screen Area 
; -------------------------------------------------------

L35F8:  DEFB $08          ; Key code: Cursor Left.
        DEFW L2640        ; CURSOR-LEFT handler routine.
        DEFB $09          ; Key code: Cursor Right.
        DEFW L26B9        ; CURSOR-RIGHT handler routine.
        DEFB $0A          ; Key code: Cursor Down.
        DEFW L25E9        ; CURSOR-DOWN handler routine.
        DEFB $0B          ; Key code: Cursor Up.
        DEFW L25D3        ; CURSOR-UP handler routine.
        DEFB $0C          ; Key code: Delete.
        DEFW L24BD        ; DELETE handler routine.
        DEFB $0D          ; Key code: Enter.
        DEFW L276C        ; ENTER handler routine.
        DEFB $AA          ; Key code: Extend Mode + Shift + K.
        DEFW L24C6        ; DELETE-RIGHT handler routine.
        DEFB $07          ; Key code: Edit.
        DEFW L21E9        ; EDIT handler routine.
        DEFB $B2          ; Key code: Extend Mode + Q
        DEFW L2353        ; SHIFT-TOGGLE handler routine.
        DEFB $A8          ; Key code: Extend Mode Symbol Shift + 2, or Graph Y.
        DEFW L26F0        ; START-OF-LINE handler routine.
        DEFB $A7          ; Key code: Extend Mode + M, or Graph + X.
        DEFW L273A        ; END-OF-LINE handler routine.
        DEFB $AD          ; Key code: Extend Mode + P.
        DEFW L2740        ; LINE-UP handler routine.
        DEFB $AC          ; Key code: Symbol Shift + I.
        DEFW L274D        ; LINE-DOWN handler routine.
        DEFB $00          ; End Marker.

; ---------------------
; Tokenise a BASIC Line
; ---------------------
; This routine is used to tokenise a typed in line. It is called when attempting to execute a line.
; It is iterates through the typed in line, attempting to identify a sequence of non-spce characters
; as keywords. If a keyword is identified then the typed in characters are replaced by the token
; character code. Parsing stops once the end of the line has been reached, denoted by an 'Enter' character.
; Entry: HL=Address of the typed in line to tokenise.
; Exit : HL=Address of the last character in the tokenised line.

L3620:  LD   A,(HL)       ; Fetch the current typed in current character.
        CALL L36E0        ; Skip past a quoted string if present.
        CP   $0D          ; Was the end of the line found?
        RET  Z            ; Return if so.

        EX   DE,HL        ; DE=Address of the next typed in character, i.e. potential start of a keyword.

        LD   HL,L36F1     ; Point to the Token string table.

L362B:  PUSH DE           ; Save the address of the typed in characters.

        LD   B,(HL)       ; Fetch the token character code.
        INC  HL           ; Advance to the start of the token string representation.

L362E:  LD   A,(DE)       ; Fetch the next typed in character.
        BIT  7,(HL)       ; Has the next token character code been found?
        JR   NZ,L3659     ; Jump if so.

        CP   (HL)         ; Does the current character match the token string representation?
        JR   NZ,L363F     ; Jump if not.

        INC  DE           ; Point to the next typed in character.
        INC  HL           ; Point to the next token string representation character.
        LD   A,(DE)       ; Fetch the next typed in character.
        CP   $0D          ; Has the end of the line been found?
        JR   NZ,L362E     ; Jump back if not to check for a match against the next token string representation character.

;The end of the typed in line was found before a token match was found

        JR   L3647        ; Jump ahead.

;Token string representation did not match

L363F:  LD   A,$20        ; ' '.
        CP   (HL)         ; Is the next token string representation character a space?
        JR   NZ,L3647     ; Jump if it is not, i.e. the token does not match.

;A space in the token string representation exists, i.e. "GO TO", "GO SUB, "DEF FN", "OPEN #" or "CLOSE #".

        INC  HL           ; Skip to the next character in the token string representation.
        JR   L362E        ; Jump back to check for a match against the next token string representation character.

;A token match was not found

L3647:  BIT  7,(HL)       ; Has the next token character code been reached?
        JR   NZ,L3659     ; Jump ahead if so since the string representation must have matched completely.

        POP  DE           ; Restore the address of the typed in characters into DE.

;Skip over the remainder of the mis-matched token string representation

L364C:  INC  HL           ; Advance to the next token string representation character.
        LD   A,(HL)       ; Fetch the character.
        RLA               ; Is bit 7 set, i.e. the start of the next token character code found or end of table marker found?
        JR   NC,L364C     ; Jump back until it is.

        LD   A,(HL)       ;
        CP   $80          ; Was the end of the table found?
        JR   NZ,L362B     ; Jump if not to test the next token entry in the table.

;The end of the table was found, and hence no match found

        INC  DE           ; Advance to the next typed in character.
        JR   L3670        ; Jump ahead.

;The next token character code was reached, and hence a match was found.
;A leading and/or a trailing space is deemed part of the keyword if present.
;The typed in keyword is replaced with the equivalent token character code.

L3659:  CP   $20          ; ' '. Is there a trailing space?
        JR   Z,L365E      ; Jump if so.

        DEC  DE           ; Point back to the last character of the typed in word.

; DE points to the last character of the keyword or the trailing space if there is one.

L365E:  POP  HL           ; Fetch the address of the typed in characters into HL.
        DEC  HL           ;
        LD   A,(HL)       ; Fetch the character before the typed in word.
        CP   $20          ; ' '. Was there a leading space?
        JR   Z,L3666      ; Jump if it was.

        INC  HL           ; Point to the first character of the typed in word.

; HL points to the first character of the keyword or the leading space if there is one.

L3666:  LD   (HL),B       ; Overwrite the first character of the word with the matched token character code.

        INC  HL           ; Point to the second character of the typed in keyword.
        INC  DE           ; Point to the character after the typed in keyword.
        EX   DE,HL        ; HL=Character after the typed in keyword. DE=Second character in typed in keyword.

        PUSH BC           ; Save the character token code.
        RST  28H          ;
        DEFW RECLAIM      ; $19E5. Delete the remaining bytes of the typed in keyword (from DE to HL-1).
        POP  BC           ; Fetch the character token code.
        EX   DE,HL        ; DE=Address of character after the inserted token, i.e. the next typed in character.

;Joins here when a keyword match was not found

L3670:  EX   DE,HL        ; HL=Address of the next typed in character.
        LD   A,B          ; Fetch the matching token character code (will be $AC for AT if no match found).
        CP   $EA          ; Is it 'REM'?
        JP   NZ,L3620     ; Jump back if not to test whether the next character is the start of a new token.

;The 'REM' token matched

        LD   A,$0D        ; 'Enter'.
        LD   BC,$0800     ; 2048 bytes.
        CPIR              ; Search for the end of the line.
        DEC  HL           ; Point back at the end of the line.
        RET               ;

; ------------------------
; De-Tokenise a BASIC Line
; ------------------------
; This routine is used to de-tokenise a BASIC line. It is iterates through the line, replacing
; token characters with their string representations. Parsing stops once the end of the line has
; been reached, denoted by an 'Enter' character.
; Entry: HL=Address of the BASIC line to de-tokenise.
; Exit : HL=Address of the last character in the de-tokenised line.

L3680:  LD   A,(HL)       ; Fetch the character.
        CP   $A3          ; Found a token character?
        JR   NC,L368B     ; Jump if so.

;A printable character was found

        CP   $0D          ; Is it 'Enter'?
        RET  Z            ; Return if so.

        INC  HL           ; Point to the next character
        JR   L3680        ; Jump back to process the next character.

;A token character was found

L368B:  PUSH HL           ; Save the address of token character in the BASIC line.

        LD   HL,L36F1     ; Point to the Token string table.
        LD   BC,$01E7     ; Search the entire table for the token. [Only needs be $01D6]
        CPIR              ; Search for a matching token.

;[Note that this routine always assumes a match will be found]

        LD   A,$7F        ; The boundary test value between printable codes and tokens.
        PUSH HL           ; Save the address of the matching entry in the Token table.
        LD   BC,$FFFF     ; BC will count the length of the string representation of the token.

L369A:  INC  HL           ; Point to the next character in the table.
        INC  BC           ; Increment the string length counter.
        CP   (HL)         ; Has the start of the next token entry or end of the table been found?
        JR   NC,L369A     ; Jump back if not.

;The end of the string representation has been located, and BC holds the length of the string representation

        POP  DE           ; Fetch the address of the matching entry in the Token table.

        XOR  A            ; Signal no leading or trailing space required.

        LD   HL,L384D     ; Is it 'FN' to 'AT', i.e. a function requiring a trailing space?
        OR   A            ;
        SBC  HL,DE        ;
        JR   C,L36BA      ; Jump ahead if so to include a trailing space only.

        LD   HL,L3708     ; Is it '<=' to 'PI', i.e. no leading or trailing space required?
        SBC  HL,DE        ;
        JR   NC,L36BD     ; Jump ahead if so.

        INC  BC           ; Add one extra byte for a leading space.
        INC  A            ; Signal to print a leading space.

        LD   HL,L3717     ; Is it 'OPEN#' or 'CLOSE#', i.e. only a leading space required?
        OR   A            ;
        SBC  HL,DE        ;
        JR   NC,L36BD     ; Jump ahead if so.

;Joins here when only a trailing space is required, or for all other keywords that require
;both a leading a trailing space

L36BA:  OR   $02          ; Signal to print a trailing space.
        INC  BC           ; Add one extra byte for the trailing space.

;Joins here when no leading or trailing space is required, also for OPEN# and CLOSE#
;which require only a leading space. The A register indicates whether a leading or a
;trailing space is required ($00 for neither, $01=Leading space, $02=Trailing space, $03=Both).
;BC holds a count of the number of bytes required to insert the string representation, including
;the leading and trailing spaces if required.

L36BD:  POP  HL           ; Fetch the address of the token character in the BASIC line.
        PUSH DE           ; Save the address of the matching entry in the Token table.

        CALL L29A5        ; Create room for the string representation of the token, including the leading trailing spaces if required.

        POP  DE           ; Fetch the address of the matching entry in the Token table.
        EX   DE,HL        ; HL=Address of the matching entry in the Token table.
        INC  DE           ; Point to the start of the newly inserted room.

        RRA               ; Is a leading space required?
        PUSH AF           ; Save the trailing space flag.
        JR   NC,L36CD     ; Jump ahead if a leading space is not required.

;A leading space is required

        LD   A,$20        ; ' '.
        LD   (DE),A       ; Insert a leading space.
        INC  DE           ; Point to the next insertion location.

;Joins here when a leading space is not required

L36CD:  LD   A,$7F        ; The boundary test value used to detect the start of the next Token table entry.

L36CF:  LDI               ; Copy a character of the keyword string into the BASIC line.
        CP   (HL)         ; Is the next character the start of a new token entry within the table?
        JR   NC,L36CF     ; Jump back if it is not.

;All characters of the token string representation have now been copied into the BASIC line

        POP  AF           ; Fetch the trailing space flag.
        RRA               ; Is a trailing space required?
        JR   NC,L36DC     ; Jump ahead if not.

;A trailing space is required

        LD   A,$20        ; ' '.
        LD   (DE),A       ; Insert a trailing space.

        INC  HL           ; [*BUG* - This should be INC DE to point to the next character in the BASIC line.
                          ; The result is that on the next iteration the space that has just been inserted will
                          ; be processed and skipped over. Credit: Paul Farrow]

L36DC:  EX   DE,HL        ; DE=Next character in the BASIC line to process.
        JP   L3680        ; Jump back to process the next character.

; ------------------------------------
; Skip Over a Quoted String if Present
; ------------------------------------
; This routine is used to skip over a string message within quotes when tokenising a BASIC line.
; Note that the routine sets the carry flag to indicate its sucess status but this return flag is
; never subsequently checked.
; Exit: Carry flag set if a quoted string is not present or was successfully skipped over.
;       Carry flag reset if the end of the line was found whilst within a quoted string.

L36E0:  CP   $22          ; Was it an opening quote?
        SCF               ; Signal not within a quoted string.
        RET  NZ           ; Return if not.

L36E4:  INC  HL           ; Point to the next character.
        LD   A,(HL)       ; Fetch the character.
        CP   $0D          ; Has the end of the line been found?
        RET  Z            ; Return if so.

        CP   $22          ; Has a closing quote been found?
        JR   NZ,L36E4     ; Jump back if not to test the next character.

        INC  HL           ; Point to the character after the closing quote.
        LD   A,(HL)       ; Fetch the character.
        SCF               ; Signal not within a quoted string.
        RET               ;

; ----------------------
; The Token String Table
; ----------------------

;These keywords do not require a leading or trailing space

L36F1:  DEFB $C7          ; '<='.
        DEFM "<="         ;
        DEFB $C8          ; '>='.
        DEFM ">="         ;
        DEFB $C9          ; '<>'.
        DEFM "<>"         ;
        DEFB $A5          ; 'RND'.
        DEFM "RND"        ;
        DEFB $A6          ; 'INKEY$'.
        DEFM "INKEY$"     ;
        DEFB $A7          ; 'PI'.
        DEFM "PI"         ;

;These keywords require a leading space only

L3708:
#ifdef BUG_FIXES
        DEFB $CB          ; 'THEN'.
        DEFM "THEN"       ;
#endif
        DEFB $D3          ; 'OPEN #'.
        DEFM "OPEN #"     ;
        DEFB $D4          ; 'CLOSE #'.
        DEFM "CLOSE #"    ;

;These keywords require both a leading and a trailing space

L3717:  DEFB $C5          ; 'OR'.
        DEFM "OR"         ;
        DEFB $C6          ; 'AND'.
        DEFM "AND"        ;
        DEFB $CA          ; 'LINE'.
        DEFM "LINE"       ;
#ifndef BUG_FIXES
        DEFB $CB          ; 'THEN'. [*BUG* - An expression such as "THEN LET" is displayed as "THEN  LET". Credit: Andrew Owen]
        DEFM "THEN"       ;         [The bug can be fixed by moving the THEN entry into the table at $3708 (ROM 0). Credit: Paul Farrow]
#endif
        DEFB $CC          ; 'TO'.
        DEFM "TO"         ;
        DEFB $CD          ; 'STEP'.
        DEFM "STEP"       ;
        DEFB $CE          ; 'DEF FN'.
        DEFM "DEF FN"     ;
        DEFB $CF          ; 'CAT'.
        DEFM "CAT"        ;
        DEFB $D0          ; 'FORMAT'.
        DEFM "FORMAT"     ;
        DEFB $D1          ; 'MOVE'.
        DEFM "MOVE"       ;
        DEFB $D2          ; 'ERASE'.
        DEFM "ERASE"      ;
        DEFB $D5          ; 'MERGE'.
        DEFM "MERGE"      ;
        DEFB $D6          ; 'VERIFY'.
        DEFM "VERIFY"     ;
        DEFB $D7          ; 'BEEP'.
        DEFM "BEEP"       ;
        DEFB $D8          ; 'CIRCLE'.
        DEFM "CIRCLE"     ;
        DEFB $D9          ; 'INK'.
        DEFM "INK"        ;
        DEFB $DA          ; 'PAPER'.
        DEFM "PAPER"      ;
        DEFB $DB          ; 'FLASH'.
        DEFM "FLASH"      ;
        DEFB $DC          ; 'BRIGHT'.
        DEFM "BRIGHT"     ;
        DEFB $DD          ; 'INVERSE'.
        DEFM "INVERSE"    ;
        DEFB $DE          ; 'OVER'.
        DEFM "OVER"       ;
        DEFB $DF          ; 'OUT'.
        DEFM "OUT"        ;
        DEFB $E0          ; 'LPRINT'.
        DEFM "LPRINT"     ;
        DEFB $E1          ; 'LLIST'.
        DEFM "LLIST"      ;
        DEFB $E2          ; 'STOP'.
        DEFM "STOP"       ;
        DEFB $E3          ; 'READ'.
        DEFM "READ"       ;
        DEFB $E4          ; 'DATA'.
        DEFM "DATA"       ;
        DEFB $E5          ; 'RESTORE'.
        DEFM "RESTORE"    ;
        DEFB $E6          ; 'NEW'.
        DEFM "NEW"        ;
        DEFB $E7          ; 'BORDER'.
        DEFM "BORDER"     ;
        DEFB $E8          ; 'CONTINUE'.
        DEFM "CONTINUE"   ;
        DEFB $E9          ; 'DIM'.
        DEFM "DIM"        ;
        DEFB $EA          ; 'REM'.
        DEFM "REM"        ;
        DEFB $EB          ; 'FOR'.
        DEFM "FOR"        ;
        DEFB $EC          ; 'GO TO'.
        DEFM "GO TO"      ;
        DEFB $ED          ; 'GO SUB'.
        DEFM "GO SUB"     ;
        DEFB $EE          ; 'INPUT'.
        DEFM "INPUT"      ;
        DEFB $EF          ; 'LOAD'.
        DEFM "LOAD"       ;
        DEFB $F0          ; 'LIST'.
        DEFM "LIST"       ;
        DEFB $F1          ; 'LET'.
        DEFM "LET"        ;
        DEFB $F2          ; 'PAUSE'.
        DEFM "PAUSE"      ;
        DEFB $F3          ; 'NEXT'.
        DEFM "NEXT"       ;
        DEFB $F4          ; 'POKE'.
        DEFM "POKE"       ;
        DEFB $F5          ; 'PRINT'.
        DEFM "PRINT"      ;
        DEFB $F6          ; 'PLOT'.
        DEFM "PLOT"       ;
        DEFB $F7          ; 'RUN'.
        DEFM "RUN"        ;
        DEFB $F8          ; 'SAVE'.
        DEFM "SAVE"       ;
        DEFB $F9          ; 'RANDOMIZE'.
        DEFM "RANDOMIZE"  ;
        DEFB $FA          ; 'IF'.
        DEFM "IF"         ;
        DEFB $FB          ; 'CLS'.
        DEFM "CLS"        ;
        DEFB $FC          ; 'DRAW'.
        DEFM "DRAW"       ;
        DEFB $FD          ; 'CLEAR'.
        DEFM "CLEAR"      ;
        DEFB $FE          ; 'RETURN'.
        DEFM "RETURN"     ;
        DEFB $FF          ; 'COPY'.
        DEFM "COPY"       ;
        DEFB $A3          ; 'SPECTRUM'.
        DEFM "SPECTRUM"   ;
        DEFB $A4          ; 'PLAY'.
        DEFM "PLAY"       ;

;These keywords require a trailing space only

L384D:  DEFB $A8          ; 'FN'.
        DEFM "FN"         ;
        DEFB $A9          ; 'POINT'.
        DEFM "POINT"      ;
        DEFB $AA          ; 'SCREEN$'.
        DEFM "SCREEN$"    ;
        DEFB $AB          ; 'ATTR'.
        DEFM "ATTR"       ;
        DEFB $AD          ; 'TAB'.
        DEFM "TAB"        ;
        DEFB $AE          ; 'VAL$'.
        DEFM "VAL$"       ;
        DEFB $AF          ; 'CODE'.
        DEFM "CODE"       ;
        DEFB $B0          ; 'VAL'.
        DEFM "VAL"        ;
        DEFB $B1          ; 'LEN'.
        DEFM "LEN"        ;
        DEFB $B2          ; 'SIN'.
        DEFM "SIN"        ;
        DEFB $B3          ; 'COS'.
        DEFM "COS"        ;
        DEFB $B4          ; 'TAN'.
        DEFM "TAN"        ;
        DEFB $B5          ; 'ASN'.
        DEFM "ASN"        ;
        DEFB $B6          ; 'ACS'.
        DEFM "ACS"        ;
        DEFB $B7          ; 'ATN'.
        DEFM "ATN"        ;
        DEFB $B8          ; 'LN'.
        DEFM "LN"         ;
        DEFB $B9          ; 'EXP'.
        DEFM "EXP"        ;
        DEFB $BA          ; 'INT'.
        DEFM "INT"        ;
        DEFB $BB          ; 'SQR'.
        DEFM "SQR"        ;
        DEFB $BC          ; 'SGN'.
        DEFM "SGN"        ;
        DEFB $BD          ; 'ABS'.
        DEFM "ABS"        ;
        DEFB $BE          ; 'PEEK'.
        DEFM "PEEK"       ;
        DEFB $BF          ; 'IN'.
        DEFM "IN"         ;
        DEFB $C0          ; 'USR'.
        DEFM "USR"        ;
        DEFB $C1          ; 'STR$'.
        DEFM "STR$"       ;
        DEFB $C2          ; 'CHR$'.
        DEFM "CHR$"       ;
        DEFB $C3          ; 'NOT'.
        DEFM "NOT"        ;
        DEFB $C4          ; 'BIN'.
        DEFM "BIN"        ;
        DEFB $AC          ; 'AT'.
        DEFM "AT"         ;

        DEFB $80          ; End Marker.


; =====================
; VARIABLE EDITING MODE ????
; =====================

; -----------------------------------
; Clear Screen Buffer Row with Spaces
; -----------------------------------
; Entry: A=Row number.

L38CA:  LD   BC,$0020     ; 32 columns.
        LD   D,' '        ; $20.
        JP   L316A        ; Fill specified row of Screen Buffer with spaces.

; -------
; DE=A*32
; -------
; Entry: A=Value to multiply by 32.
; Exit : DE=Result of multiplying A by 32.
;
; [Never called]

L38D2:  CALL L2EF3        ; HL=A*32.
        EX   DE,HL        ; DE=A*32.
        RET               ;

; -----------------------------------------------------
; EDITAR (Edit String Variable) Keyword Handler Routine
; -----------------------------------------------------
; Launch the full screen string editor to edit the specified string variable.
; There is not a limit to the size of the string variable's content, and the editor
; will scroll the screen as appropriate to display of all the content. The EDIT key
; is used to exit the string variable editor, in which case any trailing spaces or
; Enter characters will be trimmed. Whenever Enter is pressed the remainder of the
; row is filled with null characters and the cursor is shifted to the next row. The
; string editor uses the three editing modes (Insert, Overtype and Indent) along
; with the Word Wrap setting. The modes operate as follows:
;
; Insert   - Text will be inserted at the cursor location, shifting characters on
;            the current line to the right. However, characters will not be shifted
;            onto the next row and so characters can only be inserted while the row
;            is not completely filled.
;
; Overtype - Typing new text will replace the text at the current cursor location,
;            and will fill null characters at the end of the row. Unlike the Insert
;            mode the newly typed text will also span over onto the next row. 
;
; Indent   - Selecting this mode will set the indentation column as per the current
;            cursor location (capping at column 26). Each time Enter is pressed, the
;            cursor is moved to the next row but at the indentation column position;
;            all prior characters on that row are set to nulls. Switching to the Insert
;            or Overtype modes will reset the indentation column to column 0.
;
; If the Word Wrap setting is on then typing a word that spans into the row below cause
; that whole word to be shifted so that it all appears on the row below (starting at the
; active indentation column). The word will not be shifted back to the previous row should
; characters subsequently be deleted.
;
; Usage: EDITAR n$
;
; where: n$=Name of a string variable. It the variable does not already exists then it is created.

L38D7:  CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        CALL L3EB2        ; Find the specified string variable, or create it if it does not exist.
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        SET  7,(HL)       ; ????
        SET  6,(HL)       ; Signal not to update the display file during the ???? operation.
        PUSH HL           ; Save the address of the string variable editing flags.

        LD   B,$16        ; 22 rows.

L38EA:  PUSH BC           ;
        CALL L3953        ; ???? this uses bit 7 of EV_FLGS -> copy variable to screen buffer ????
        POP  BC           ;
        DJNZ L38EA        ; Repeat for all rows.

        POP  HL           ; Fetch the address of the string variable editing flags.
        RES  7,(HL)       ; ????

        CALL L301B        ; Copy the Screen Buffer to the display file.

;Returns here when ????
;???? why return here?

L38F7:  LD   HL,L38F7     ; ???? Stack a return address.
        PUSH HL           ;

        LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        RES  6,(HL)       ; Signal that the display file can be updated.
        JP   L2415        ; Jump to the main editor loop to wait for a new key press.

; ---------------------------------------
; Variable Editing Mode Keys Action Table
; ---------------------------------------
; Each editing key code maps to the appropriate handling routine.
; This includes those keys which mirror the functionality of the
; add-on keypad; these are found by trapping the keyword produced
; by the keystrokes in 48K mode.

L3903:  DEFB $0C          ; Key code: Delete.
        DEFW L3BB4        ; DELETE handler routine.
        DEFB $AA          ; Key code: Extend Mode + Shift + K.
        DEFW L3BB0        ; DELETE-RIGHT handler routine.
        DEFB $07          ; Key code: Edit.
        DEFW L3F27        ; EDIT handler routine.
        DEFB $A9          ; Key code: Extend Mode + Symbol Shift + 8, or Graph + Z.
        DEFW L3F7C        ; CYCLE-MODE handler routine.
        DEFB $08          ; Key code: Cursor Left.
        DEFW L3B71        ; CURSOR-LEFT handler routine.
        DEFB $09          ; Key code: Cursor Right.
        DEFW L3B23        ; CURSOR-RIGHT handler routine.
        DEFB $0B          ; Key code: Cursor up.
        DEFW L3B88        ; CURSOR-UP handler routine.
        DEFB $0A          ; Key code: Cursor Down.
        DEFW L3B3D        ; CURSOR-DOWN handler routine.
        DEFB $AF          ; Key code: Extend Mode + I.
        DEFW L3C0D        ; WORD-LEFT handler routine.
        DEFB $AE          ; Key code: Extend Mode + Shift + J.
        DEFW L3C45        ; WORD-RIGHT handler routine.
        DEFB $AD          ; Key code: Extend Mode + P.
        DEFW L3C63        ; PAGE-UP handler routine.
        DEFB $AC          ; Key code: Symbol Shift + I.
        DEFW L3C7F        ; PAGE-DOWN handler routine.
        DEFB $A8          ; Key code: Extend Mode Symbol Shift + 2, or Graph Y.
        DEFW L3BA0        ; START-OF-LINE handler routine.
        DEFB $A7          ; Key code: Extend Mode + M, or Graph + X.
        DEFW L3BA9        ; END-OF-LINE handler routine.
        DEFB $A6          ; Key code: Extend Mode + N, or Graph + W.
        DEFW L3D58        ; TOP-OF-DATA handler routine.
        DEFB $0D          ; Key code: Enter.
        DEFW L3E55        ; ENTER handler routine.
        DEFB $A5          ; Key code: Extend Mode + T, or Graph + V.
        DEFW L3D65        ; END-OF-DATA handler routine.
        DEFB $B4          ; Key code: Extend Mode + E.
        DEFW L3CA0        ; DELETE-WORD-LEFT handler routine.
        DEFB $B3          ; Key code: Extend Mode + W.
        DEFW L3CC4        ; DELETE-WORD-RIGHT handler routine.
        DEFB $B1          ; Key code: Extend Mode + K.
        DEFW L3CEF        ; DELETE-TO-START-OF-ROW handler routine.
        DEFB $B0          ; Key code: Extend Mode + J.
        DEFW L3D07        ; DELETE-TO-END-OF-ROW handler routine.
        DEFB $B2          ; Key code: Extend Mode + Q.
        DEFW L3F74        ; WORD-WRAP-TOGGLE handler routine.
        DEFB $00          ; End marker.

; --------
; ????
; --------
; This routine ???? hunts backwards from next row to find first non-space character 
; Entry: HL=????
; Exit : Zero flag reset if a non-space character was found.
;        HL=Address of the non-space character.
;        BC=Column number after the non-space character, or $00 if all spaces found.

L3946:  LD   BC,$0020     ; ???? Up to 32 characters will be searched.
        LD   A,' '        ; $20.
        ADD  HL,BC        ; ???? Point to the next row.

L394C:  DEC  HL           ; Next location to test.
        CP   (HL)         ; Does it contains a space?
        RET  NZ           ; Return if it does.

        DEC  C            ; Decrement the search counter.
        JR   NZ,L394C     ; Repeat if there are further locations to test.

;A non-space character was not found

        RET               ;

; --------
; Variable Editing Mode: ???? populate one row of screen buffer ????
; --------
;used in variable editing mode to scroll down screen buffer / copy variable into screen buffer ????

; Exit: Carry flag set if successful.

L3953:  CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).

        CALL L2EFC        ; HL=Amount of free memory.
        LD   DE,$02E2     ; ???? 738 bytes
        SBC  HL,DE        ;
        JP   C,L3ACB      ; Jump if there is not enough available memory, returning with carry flag reset and switching to Workspace RAM configuration (physical RAM bank 7).

;There is enough memory to ????

        LD   HL,(EV_ADDR) ; $5B72. Fetch the address of the variable's content.
        LD   DE,(EV_LEN)  ; $5B74. Fetch the length of the variable.
        ADD  HL,DE        ; Point to the address after the variable.
        PUSH HL           ; Save it.

        LD   DE,(EV_XXXX) ; $5B70. ???? address of the variable contents being displayed ????
        SBC  HL,DE        ; ???? length of the variable content to display ????

        POP  DE           ; Fetch the address after the variable.
        PUSH DE           ; Save it again.

;Enter a loop to count the number of 'Enter' characters within the displayed content of the variable ????

        LD   BC,$0000     ; BC counts the number of 'Enter' characters within the displayed content of the variable.

L3975:  DEC  DE           ; Point to the previous character of the variable's content.

        LD   A,(DE)       ; Fetch a character.
        CP   $0D          ; Has 'Enter' been found?
        JR   NZ,L397C     ; Jump ahead if not.

        INC  BC           ; Increment the 'Enter' count.

L397C:  DEC  HL           ; Decrement the length of the content to check.
        LD   A,H          ;
        OR   L            ;
        JR   NZ,L3975     ; Jump back if there are further characters to check.

;The number of 'Enter' characters is held in BC.

        POP  HL           ; Fetch the address after the variable.
        DEC  BC           ; Decrement the 'Enter' count.
        LD   A,B          ;
        OR   C            ; Is there only the single 'Enter' appended when editing began?
        JR   Z,L39BA      ; Jump if so to append another 'Enter' character.

;There is at least one 'Enter' character within the string variable.

L3987:  LD   HL,EV_FLGS   ; $5B76.
        BIT  7,(HL)       ; ????
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        CALL Z,L39C9      ; If ???? then ????

        LD   BC,$02A0     ; 21 rows of 32 columns.
        LD   HL,$0020     ; Offset to the next row.
        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,DE        ;
        LDIR              ; Move all rows up by one, overwriting row 0.

        CALL L3A4C        ; ????

        LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        BIT  6,(HL)       ; Can the display file be updated?
        CALL Z,L301B      ; If yes then copy the Screen Buffer to the display file.

        LD   HL,(ED_XXXX) ; $5B6E. ????
        INC  HL           ;
        LD   (ED_XXXX),HL ; $5B6E.

        SUB  A            ; The A register will hold $00.
        LD   HL,ED_ROW    ; $5B6C.
        CP   (HL)         ; Is the cursor on row 0?
        SCF               ; Signal success.
        RET  Z            ; Return if so.

        DEC  (HL)         ; Move the cursor to the row above.
        RET               ;

; The string variable does not contain any 'Enter' characters.
; HL=Address after the variable.

L39BA:  CALL L29A2        ; Create room for 1 byte at HL.
        INC  HL           ; Point to newly created byte.
        LD   (HL),$0D     ; Insert an 'Enter' character at the end of the string variable.

        LD   HL,(EV_LEN)  ; $5B74. Increment the length of the variable.
        INC  HL           ;
        LD   (EV_LEN),HL  ; $5B74.

        JR   L3987        ; Jump back to continue ????

; --------
; ????
; --------

L39C9:  LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        CALL L3A27        ; ????
        INC  HL           ;
        LD   (EV_XXXX),HL ; $5B70. ????
        RET               ;

; --------
; ???? move up a row in the screen buffer
; --------
; ???? called by the cursor up and page up key handler string variable editor routines

L39D4:  LD   HL,(ED_XXXX) ; $5B6E.
        LD   A,H          ;
        OR   L            ;
        SCF               ;
        RET  Z            ;

        SUB  A            ;
        CALL L3AD0        ; HL=Address of row 21 in the Screen Buffer.
        CALL L3946        ; ???? does the row contain any non-space characters?
        JR   Z,L3A11      ; ???? jump if all spaces

;A non-space character was found

L39E4:  CALL L3A24        ;

L39E7:  CALL L3AD0        ; HL=Address of row 21 in the Screen Buffer.
        LD   B,D          ;
        LD   C,E          ;
        DEC  HL           ;
        EX   DE,HL        ;
        LD   HL,$0020     ;
        ADD  HL,DE        ;
        EX   DE,HL        ;
        LDDR              ;
        CALL L3A7A        ;

        LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        BIT  6,(HL)       ; Can the display file be updated?
        CALL Z,L301B      ; If yes then copy the Screen Buffer to the display file.

        LD   HL,(ED_XXXX) ; $5B6E.
        DEC  HL           ;
        LD   (ED_XXXX),HL ; $5B6E.
        LD   A,$15        ;
        LD   HL,ED_ROW    ; $5B6C.
        CP   (HL)         ;
        RET  Z            ;

        INC  (HL)         ;
        SUB  A            ;
        RET               ;

; --------
; ???? row contains all spaces
; --------

L3A11:  LD   HL,(EV_ADDR) ; $5B72.
        DEC  HL           ;
        LD   DE,(EV_LEN)  ; $5B74.
        ADD  HL,DE        ;
        LD   DE,(EV_XXXX) ; $5B70. ????
        SBC  HL,DE        ;
        JR   Z,L39E7      ;

        JR   L39E4        ;

; --------
; ????
; --------

L3A24:  CALL L3AD0        ; HL=Address of row 21 in the Screen Buffer.

;Joins here from ???? with HL pointing to the start address of the Screen Buffer

L3A27:  PUSH HL           ; Save the Screen Buffer row address.

        CALL L3946        ; ???? does the row contain any non-space characters?
        PUSH AF           ; Save the return flags.
        PUSH BC           ; ???? C=Column number after the non-space character

        INC  C            ; ????
        LD   HL,(EV_LEN)  ; $5B74. ????
        ADD  HL,BC        ;
        LD   (EV_LEN),HL  ; $5B74.

        LD   HL,(EV_XXXX) ; $5B70. ???? address of ????
        DEC  HL           ; Point to the prior address ????

; Entry: HL=Location prior to the location to create the room at.
;        BC=Number of bytes to create room for.

        CALL L3AC4        ; Create room within conventional memory.

        POP  BC           ;
        POP  AF           ; Restore the flags which indicate where a non-space character was found.
        POP  HL           ; Fetch the Screen Buffer row address.
        LD   DE,(EV_XXXX) ; $5B70. ????
        JR   Z,L3A48      ; Jump if a non-space character was found.

;???? all space so copy ????

; Exit : HL=Address of the non-space character.
;        BC=Column number after the non-space character, or $00 if all spaces found.



; Entry: HL=Source address in logical RAM bank 4 (physical RAM bank 7).
;        DE=Destination address in current RAM bank.
;        BC=Number of bytes to load.

        CALL L1E93        ; ???? Copy bytes from logical RAM bank 4 (physical bank 7).

; Exit : HL=Address after the end of the source, i.e. source address + number bytes to load.
;        DE=Address after the end of destination, i.e. destination address + number bytes to load.


L3A48:  EX   DE,HL        ;
        LD   (HL),$0D     ; ???? insert 'Enter'
        RET               ;

; --------
; ????
; --------

L3A4C:  LD   A,$15        ; Row 21.
        CALL L38CA        ; Clear row 21 in the Screen Buffer with spaces.

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        CALL L3B15        ; ???? search the row for the 'Enter' character from address (RNSTEP+1) ????
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        JP   C,L3AF1      ; Jump if 'Enter' not found.

;An 'Enter' character was found within the row

        CALL L3AD0        ; HL=Address of row 21 in the Screen Buffer.
        EX   DE,HL        ; DE=Address of row 21 in the Screen Buffer, HL=Offset to row 21.

        LD   A,$0D        ; The code for 'Enter'.
        LD   HL,(EV_XXXX) ; $5B70. ????

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        PUSH HL           ;

        LD   BC,$0000     ; Holds a count of the number of characters until the 'Enter' was found.

;Enter a loop to find the next 'Enter' characeter

L3A6D:  CP   (HL)         ; Has an 'Enter' character been found?
        JR   Z,L3A74      ; Jump ahead if so.

        INC  HL           ; Advance to the next Screen buffer location.
        INC  BC           ; Increment the count.
        JR   L3A6D        ; Jump back to test the next location.

;The 'Enter' character was found and BC holds the number of characters searched before it was found

L3A74:  POP  HL           ; HL=????
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        JR   L3AA1        ; Jump ahead to continue.

; --------
; ????
; --------

L3A7A:  SUB  A            ;
        CALL L38CA        ; Clear row ???? in the Screen Buffer with ????.
        LD   HL,(EV_XXXX) ; $5B70.
        DEC  HL           ;
        LD   A,$0D        ;
        LD   BC,$0000     ;
        LD   DE,(EV_ADDR) ; $5B72.

L3A8B:  DEC  HL           ;
        PUSH HL           ;
        AND  A            ;
        SBC  HL,DE        ;
        POP  HL           ;
        JR   C,L3A99      ;

        CP   (HL)         ;
        JR   Z,L3A99      ;

        INC  C            ;
        JR   L3A8B        ;

L3A99:  INC  HL           ;
        LD   (EV_XXXX),HL ; $5B70.
        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.

; Joins here ????

L3AA1:  LD   A,C          ;
        AND  A            ;
        JR   Z,L3AAA      ;

        PUSH BC           ;
        CALL L1E5E        ; ???? Transfer bytes to physical RAM bank 7 via RAM Disk save routine.
        POP  BC           ;

L3AAA:  INC  BC           ;
        LD   HL,(EV_LEN)  ; $5B74.
        OR   A            ;
        SBC  HL,BC        ;
        LD   (EV_LEN),HL  ; $5B74.
        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        LD   HL,(EV_XXXX) ; $5B70.
        RST  28H          ;
        DEFW $19E8        ;
        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        RET               ;

; ------------------------------------------
; Create Room for 1 Byte in Conventional RAM
; ------------------------------------------
; Creates room for a single byte in the workspace, or automatically produces an error '4' if not.
; The room will be created within the conventional memory.
; Entry: HL=Location prior to the location to create the room at.

L3AC1:  LD   BC,$0001     ; Space for 1 byte.

;Continue into the following routine

; -------------------------------------------
; Create Room for n Bytes in Conventional RAM
; -------------------------------------------
; Creates room for multiple bytes in the workspace, or automatically produces an error '4' if not.
; The room will be created within the conventional memory.
; Entry: HL=Location prior to the location to create the room at.
;        BC=Number of bytes to create room for.

L3AC4:  INC  HL           ; Point to the loction to insert the first new byte.
        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).
        CALL L29A5        ; Create room for the specified number of bytes.

;Entry point from routine ????

L3ACB:  CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).
        OR   A            ; Clear the carry flag to signal success [never tested].
        RET               ;

; --------------------------------------------
; Fetch Address Of Row 21 In The Screen Buffer
; --------------------------------------------

L3AD0:  LD   DE,$02A0     ; Offset to row 21.
        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,DE        ; HL=Address of row 21 in the Screen Buffer.
        RET               ;

; ----------------------------------
; Fetch Character At Cursor Position
; ----------------------------------
; Exit: Zero flag set if the character is a space.
;       Carry flag set if the character is a control code.
;       HL=Address of the cursor within the Screen Buffer.

L3AD8:  PUSH BC           ; Save the C register, which holds the column number.

        LD   A,(ED_ROW)   ; $5B6C. Fetch the cursor row position.
        CALL L2EF3        ; HL=A*32. Calculate the offset to the row.
        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,DE        ; Point to the start of the row in the buffer.
        LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        LD   E,A          ;
        LD   D,$00        ;
        ADD  HL,DE        ; Point to the cursor position within the buffer.
        LD   A,(HL)       ; Fetch the character at the cursor position.

        POP  BC           ; Fetch the C register, which holds the column number.
        LD   B,D          ; B=$00.

        CP   $20          ; Is the character at the cursor position a space?
        RET               ;

; --------
; ???? search backwards looking for a space.
; --------
; ???? enter not found within row

L3AF1:  LD   B,$1F        ;
        DEC  HL           ;
        DEC  HL           ;
        PUSH HL           ;

L3AF6:  LD   A,(HL)       ;
        CP   ' '          ; $20.
        JR   Z,L3B0F      ;

        DEC  HL           ;
        DJNZ L3AF6        ;

        POP  HL           ;
        CALL L3AC1        ; Create space for 1 byte in conventional memory.
        INC  HL           ;
        LD   (HL),$0D     ; Insert an 'Enter' into the newly created byte.

        LD   HL,(EV_LEN)  ; $5B74. Increment the length of the variable.
        INC  HL           ;
        LD   (EV_LEN),HL  ; $5B74.

        JP   L3A4C        ; ????

; --------
; ???? found space
; --------

L3B0F:  LD   (HL),$0D     ; Insert an 'Enter' character.
        POP  HL           ;
        JP   L3A4C        ; ????

; --------
; ????
; --------
; Exit: Carry flag set if 'Enter' was found.
;       HL=Address of the 'Enter' character at the end of the row.

L3B15:  LD   HL,(EV_XXXX) ; $5B70. Fetch the address of ????
        LD   B,$21        ; There are 33 characters in the line to test.

L3B1A:  LD   A,(HL)       ; Fetch a character.
        CP   $0D          ; Is it 'Enter'?
        RET  Z            ; Return if it is.

        INC  HL           ; Next location.
        DJNZ L3B1A        ; Repeat for all locations.

        SCF               ; Signal that 'Enter' was not found.
        RET               ;


; ==========================================
; VARIABLE EDITING MODE KEY HANDLER ROUTINES
; ==========================================

; -------------------------------------------------------
; Variable Editing Mode: CURSOR-RIGHT Key Handler Routine
; -------------------------------------------------------
; Move right 1 character.
; Exit: Carry flag set if cursor moved.

L3B23:  LD   HL,ED_COL    ; $5B6B. Point to the cursor column number.
        LD   A,$1F        ;
        CP   (HL)         ; Is the cursor at column 31?
        JR   Z,L3B2F      ; Jump if so.

        INC  (HL)         ; Advance to the next column within this row.
        SCF               ; Signal the cursor could be moved.
        JR   L3B5E        ; Jump to generate the position offset for the new cursor row.

;Cursor at column 31

L3B2F:  LD   A,(ED_IDNT)  ; $5B6D. Fetch the indentation count and
        LD   (HL),A       ; set as the new cursor column number.

        PUSH HL           ;
        CALL L3B3D        ; Move down 1 row (via the CURSOR-DOWN Key Handler routine).
        POP  HL           ;
        RET  C            ; Return if the cursor could be moved.

;The cursor cannot be moved to the right so keep it at column 31

        LD   (HL),$1F     ; Column 31.
        JR   L3B5E        ; Jump to generate position offset for the new cursor row, with the carry flag reset.

; ------------------------------------------------------
; Variable Editing Mode: CURSOR-DOWN Key Handler Routine
; ------------------------------------------------------
; Move down 1 row.
; Exit: Carry flag set if cursor moved.

L3B3D:  LD   A,(ED_ROW)   ; $5B6C. Fetch the cursor row number.
        CP   $15          ; Is the cursor on row 21?
        JR   NZ,L3B48     ; Jump if not to move down a row.

;The cursor is on row 21

        CALL L3D9B        ; ???? Is there more string variable content available?
        RET  Z            ; Return if there is not.

; ------------------------------------------------------
; Variable Editing Mode: ???? move down a row
; ------------------------------------------------------

L3B48:  LD   HL,ED_ROW    ; $5B6C. Point to the cursor row number.
        INC  (HL)         ; Advance cursor to the next row.
        LD   A,$16        ; Reached row 22?
        CP   (HL)         ;
        JR   NZ,L3B59     ; Jump ahead if not.

;Row 22 reached

        CALL L3953        ; ???? scroll down screen buffer ????

        LD   HL,ED_ROW    ; $5B6C. Point to the cursor row number.
        LD   (HL),$15     ; Set cursor on row 21.

L3B59:  CALL L3B5E        ; Generate position offset for the new cursor row.
        SCF               ; Signal the cursor could be moved.
        RET               ;

; -------------------------------------------------------------
; Variable Editing Mode: Generate Cursor Screen Position Offset
; -------------------------------------------------------------

L3B5E:  PUSH AF           ; Save the state of the carry flag.

        LD   A,(ED_ROW)   ; $5B6C. Fetch the cursor row number.
        CALL L2EF3        ; HL=A*32. Generate position offset to the start of the cursor row.
        LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column number.
        LD   E,A          ;
        LD   D,$00        ;
        ADD  HL,DE        ; Generate the cursor position offset.
        LD   (ED_POS),HL  ; $5B92. Store the cursor position offset.

        POP  AF           ; Restore the state of the carry flag.
        RET               ;

; ------------------------------------------------------
; Variable Editing Mode: CURSOR-LEFT Key Handler Routine
; ------------------------------------------------------
; Move left 1 character.
; Exit: Carry flag reset if cursor moved.

L3B71:  LD   HL,ED_COL    ; $5B6B. Point to the cursor column number.
        SUB  A            ; A=0;
        CP   (HL)         ; Is the cursor at column 0 within this row?
        JR   Z,L3B7C      ; Jump if so.

        DEC  (HL)         ; Move to the previous column.
        OR   A            ; Clear the carry flag to indicate the cursor could be moved.
        JR   L3B5E        ; Jump to generate the position offset for the new cursor row.

;Cursor at column 0

L3B7C:  LD   (HL),$1F     ; Set the new cursor column position as column 31.

        PUSH HL           ;
        CALL L3B88        ; Move up 1 row (via the CURSOR-UP Key Handler routine).
        POP  HL           ;
        RET  NC           ; Return if the cursor was moved.

;The cursor could not be moved to the left so keep it at column 0

        LD   (HL),$00     ; Set the new cursor column position as column 0.
        JR   L3B5E        ; Jump to generate position offset for the new cursor row, with the carry flag set.

; ----------------------------------------------------
; Variable Editing Mode: CURSOR-UP Key Handler Routine
; ----------------------------------------------------
; Move up 1 row.
; Exit: Carry flag reset if cursor moved.

L3B88:  LD   HL,ED_ROW    ; $5B6C. Point to the cursor row number.
        DEC  (HL)         ; Move to the previous row.
        LD   A,$FF        ;
        CP   (HL)         ; Has the cursor moved off the screen, i.e. before row 0?
        JR   NZ,L3B5E     ; Jump if not to generate position offset for the new cursor row, with the carry flag set.

;The cursor is at the top of the screen

        PUSH HL           ;
        CALL L39D4        ; ???? move up a row in the screen buffer?
        POP  HL           ;
        LD   (HL),$00     ; Keep the cursor on row 0. [Could have saved 3 bytes by using JR $3B84 (ROM 0)]
        JP   L3B5E        ; Jump to generate the position offset for the new cursor row.

; ==============
; Unused Routine - ???? should the routine above jump to here? A bug?
; ==============

L3B9B:  DEC  HL           ; Point at the cursor column number.
        LD   (HL),$1F     ; Set the cursor at column 31.
        JR   L3B5E        ; Jump to generate the position offset for the new cursor row.

; --------------------------------------------------------
; Variable Editing Mode: START-OF-LINE Key Handler Routine
; --------------------------------------------------------
; Move to the start of the current line.
;
; Symbol: |<--
;         |<--

L3BA0:  LD   HL,ED_COL    ; $5B6B. Point to the cursor column position.
        LD   A,(ED_IDNT)  ; $5B6D. Fetch the indentation column.
        LD   (HL),A       ; Set the cursor at the indentation column in this row.
        JR   L3B5E        ; Jump to generate the position offset for the new cursor row.

; ------------------------------------------------------
; Variable Editing Mode: END-OF-LINE Key Handler Routine
; ------------------------------------------------------
; Move to the end of the current line.
;
; Symbol: -->|
;         -->|

L3BA9:  LD   HL,ED_COL    ; $5B6B. Point to the cursor column position.
        LD   (HL),$1F     ; Set the cursor position to column 31.

        JR   L3B5E        ; Jump to generate the position offset for the new cursor row.

; -------------------------------------------------------
; Variable Editing Mode: DELETE-RIGHT Key Handler Routine
; -------------------------------------------------------
; Delete a character to the right.
;
; Symbol: DEL
;         -->

L3BB0:  CALL L3B23        ; Move the cursor right one character via the CURSOR-RIGHT key handler.
        RET  NC           ; Return if the cursor could not be moved.

;Continue below to delete the character to the left

; -------------------------------------------------
; Variable Editing Mode: DELETE Key Handler Routine
; -------------------------------------------------
; Delete a character to the left. If a colour control code is encountered then both the
; colour control code and its parameter value will be deleted.
;
; Symbol: DEL
;         <--

L3BB4:  CALL L3AD8        ; Fetch the character at the cursor position.
        DEC  HL           ; Point to the previous character.
        LD   A,(HL)       ; Fetch the previous character.
        CP   $08          ; Is it a cursor editing or colour control?
        JR   NC,L3BC2     ; Jump ahead if so.

;The previous character is a colour parameter value, i.e. colour values $00-$07, for an INK or PAPER control code
;and so both parameter value and the colour control code need to be deleted

        CALL L3BCC        ; Delete the colour control parameter value.
        JR   L3BCC        ; Delete the colour control code.

;The previous character is a cursor, colour control or printable code

L3BC2:  CP   $15          ; Is it a colour control code?
        JR   NC,L3BCC     ; Jump ahead if it is not.

;The previous character is a colour control code (INK, PAPER, FLASH, BRIGHT or INVERSE) and so there is the control code and its parameter to delete

        CALL L3BCC        ; Delete the colour control code.
        CALL L3B23        ; Move the cursor right one character via the CURSOR-RIGHT key handler to point at the colour control parameter value.

;Continue below to delete the colour control parameter value

; ---------------------------------------------------
; Variable Editing Mode: Delete Character to the Left
; ---------------------------------------------------
; This routine deletes a single character byte from the Screen Buffer prior to the cursor location.
; It is called by the DELETE key handler routine when in variable editing mode.

L3BCC:  LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        LD   B,A          ;
        LD   A,$20        ; Column 32.
        SUB  B            ;
        LD   C,A          ; A=Number of characters to the end of the row.

        LD   A,B          ; Fetch the cursor column position.
        LD   B,$00        ; BC=Number of characters to the end of the row.

        LD   DE,(ED_POS)  ; $5B92. Fetch the offset within the screen buffer to the cursor position.
        LD   HL,($FF24)   ; Fetch the address of the Screen Buffer.
        ADD  HL,DE        ; HL=Address of the cursor position within the Screen Buffer.
        DEC  HL           ; Point to the previous character.
        AND  A            ; Is the cursor in column 0?
        JR   NZ,L3BE7     ; Jump ahead if it is not.

;The cursor is in column 0

        LD   (HL),$20     ; Change the character in column 0 to a space.
        JR   L3BEC        ; Jump ahead.

;The cursor is not in column 0, so shift all character to the right of the cursor to the left

L3BE7:  LD   D,H          ;
        LD   E,L          ; DE=Address of the location prior to the cursor position within the Screen Buffer.
        INC  HL           ; HL=Address of the cursor position within the Screen Buffer.
        LDIR              ; Shift all characters from the cursor location to the end of the row one position to the left.

;Now that all characters have been shifted to the left, ensure that the last character of the row is reset to hold a space

L3BEC:  LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        PUSH AF           ; Save it.

        LD   A,$1F        ; Column 31.
        LD   (ED_COL),A   ; $5B6B. Store a temporary cursor column position.

        CALL L3AD8        ; Fetch the address of the temporary cursor position, i.e. column 31.

        LD   (HL),$20     ; Change the character to a space.

        POP  AF           ; Fetch the cursor column position.
        LD   (ED_COL),A   ; $5B6B. Restore the cursor column position.

        CALL L3B71        ; Move the cursor to the left via the CURSOR-LEFT key handler routine.

        LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        BIT  6,(HL)       ; Can the display file be updated?
        RET  NZ           ; Return if not.

        LD   A,(ED_ROW)   ; $5B6C. Fetch the cursor row position.
        JP   L2EBF        ; Jump to copy the Screen Buffer row to the display file.

; ----------------------------------------------------
; Variable Editing Mode: WORD-LEFT Key Handler Routine
; ----------------------------------------------------
; This routine moves to the last character of the previous word, skipping over any null characters
; (i.e. indentation columns or end of line null characters) and moving/scrolling to the previous
; row as necessary. If the last charactre of the first word of the variable is reached then the next
; shift will set the cursor at the start of the word.
;
; Symbol: <--
;         <--

L3C0D:  CALL L3AD8        ; Fetch the character at the cursor position.
        JR   Z,L3C22      ; Jump ahead if it is a space.

;The character at the cursor position is not a space

        LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        LD   B,A          ;
        LD   A,(ED_IDNT)  ; $5B6D. Fetch the indentation column.
        CP   B            ;
        JR   Z,L3C22      ; Jump if the start of the row has been reached.

;The cursor is not on a space or at the start of the row

        CALL L3C2C        ; Move the cursor left one character.
        RET  C            ; Return if the cursor could not be moved.

        JR   L3C0D        ; Jump back to move left again.

;The cursor position holds a space or is at the indentation column for the row

L3C22:  CALL L3C2C        ; Move the cursor left one character, skipping over any indentation columns and moving to the end of the previous row as necessary.
        RET  C            ; Return if the cursor could not be moved.

        CALL L3AD8        ; Fetch the character at the cursor position.
        JR   Z,L3C22      ; Jump back if it is a space.

        RET               ; Return with the cursor on the last character of the previous word.

; -----------------------------------------------------
; Variable Editing Mode: Move Cursor Left One Character
; -----------------------------------------------------
; This routine will skip over any null characters within a row, shifting the cursor to the end of the previous row.
; Exit: Carry flag reset if the cursor was moved.

L3C2C:  CALL L3B71        ; Move cursor position to the left via the CURSOR-LEFT key handler routine.
        RET  C            ; Return if the cursor could not be moved.

;The cursor was moved left, potentially to the end of the previous row

        CALL L3C36        ; Is the cursor at a column containing a null character?
        JR   C,L3C2C      ; Jump back if so to shift the cursor left again.

        RET               ; The cursor is now on the next editable character to the left.

; ------------------------------------------------------------
; Variable Editing Mode: Check if Cursor is at Editable Column
; ------------------------------------------------------------
; Exit: Carry flag set if cursor is before or after the editable positions within the row.

L3C36:  LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        LD   B,A          ;
        LD   A,$1F        ; After column 31?
        SUB  B            ;
        RET  C            ; Return if the cursor is after column 31.

;The cursor is at or before column 31

        LD   A,(ED_IDNT)  ; $5B6D. Fetch indentation column.
        LD   C,A          ;
        LD   A,B          ; Fetch the cursor column position.
        SUB  C            ; Is the cursor before the start of the row, i.e. before the indentation column?
        RET               ;

; -----------------------------------------------------
; Variable Editing Mode: WORD-RIGHT Key Handler Routine
; -----------------------------------------------------
; This routine moves to the start of the next word, or the first editable character of the next row
; (which could be mid-way through a word).
;
; Symbol: -->
;         -->

L3C45:  CALL L3AD8        ; Fetch the character at the cursor position.
        JR   Z,L3C59      ; Jump ahead if it is a space.

;The character at the cursor position is not a space

        LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        LD   B,A          ;
        LD   A,$1F        ; Column 31.
        CP   B            ;
        JR   Z,L3C59      ; Jump if at column 31 to shift the cursor to the start of the next row.

;The cursor is before column 31

        CALL L3B23        ; Move the cursor right one character via the CURSOR-RIGHT key handler.
        RET  NC           ; Return if the cursor can not be moved.

        JR   L3C45        ; Jump back to move right again.

;At column 31 or the cursor position contains a space, so skip over spaces until the start of the word

L3C59:  CALL L3B23        ; Move the cursor right one character via the CURSOR-RIGHT key handler.
        RET  NC           ; Return if the cursor could not be moved.

        CALL L3AD8        ; Fetch the character at the cursor position.
        JR   Z,L3C59      ; Jump back if it contains a space to move the cursor again.

        RET               ; The start of the next word has been found so return.

; --------------------------------------------------
; Variable Editing Mode: PAGE-UP Key Handler Routine
; --------------------------------------------------
; Move up 21 rows, i.e. page up a screen.
;
; Symbol: / \/ \
;          |  |

L3C63:  LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        SET  6,(HL)       ; Signal not to update the display file during the move operation.

        LD   HL,(ED_COL)  ; $5B6B. Fetch the cursor position.
        PUSH HL           ; Save it.

        LD   B,$15        ; 21 rows.

L3C6E:  PUSH BC           ; Save the row counter.
        CALL L39D4        ; ???? move up a row in the screen buffer?
        POP  BC           ; Fetch the row counter.
        DJNZ L3C6E        ; Repeat for all rows.

        POP  HL           ; Fetch the original cursor position.
        LD   (ED_COL),HL  ; $5B6B. Restore the cursor position.

        CALL L301B        ; Copy the Screen Buffer to the display file.
        JP   L3B5E        ; Jump to generate the position offset for the new cursor row.

; ----------------------------------------------------
; Variable Editing Mode: PAGE-DOWN Key Handler Routine
; ----------------------------------------------------
; Move down 21 rows, i.e. page down a screen.
;
; Symbol:  |  |
;         \ /\ /
    
L3C7F:  LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        SET  6,(HL)       ; Signal not to update the display file during the move operation.

        LD   HL,(ED_COL)  ; $5B6B. Fetch the cursor position.
        PUSH HL           ; Save it.

        LD   A,$15        ; Row 21.
        LD   (ED_ROW),A   ; $5B6C. Store the new cursor row position.

        LD   B,$15        ; 21 rows.

L3C8F:  PUSH BC           ; Save the row counter.
        CALL L3B3D        ; Move down 1 row via the CURSOR-DOWN key handler.
        POP  BC           ; Fetch the row counter.
        DJNZ L3C8F        ; Repeat for all rows.

#ifdef BUG_FIXES
        JR   L3C75        ;@

; --------------------
; Parse a Line Bug Fix
; --------------------

PATCH2:
        RST  28H          ;@ Find the address of the line number specified by HL.
        DEFW LINE_ADDR    ;@ $196E. HL=Address of the BASIC line, or the next one if it does not exist.        JP   NC,P2_RET    ;
        RET  NC           ;@

        POP  HL           ;@ Discard patch return address.
        JP   L34CA        ;@
#else
        POP  HL           ; Fetch the original cursor position.
        LD   (ED_COL),HL  ; $5B6B. Restore the cursor position.
        CALL L301B        ; Copy the Screen Buffer to the display file.
        JP   L3B5E        ; Jump to generate the position offset for the new cursor row.
#endif

; -----------------------------------------------------------
; Variable Editing Mode: DELETE-WORD-LEFT Key Handler Routine
; -----------------------------------------------------------
; This routine deletes to the start of the current word that the cursor is on, or if it is on the first
; character of a word then it deletes to the start of the previous word.
;
; Symbol: <-- DEL
;         <--

L3CA0:  CALL L3D86        ; Is the cursor at the start of the Screen Buffer?
        JR   Z,L3CAF      ; Jump ahead if so. [Would have saved 1 byte by using RET Z]

;The cursor is not at the start of the Screen Buffer.

        CALL L3CBC        ; Does the current character hold a space? Returns pointing to the previous character.
        JR   Z,L3CAF      ; Jump if it does.

;The current location does not contain a space.

        CALL L3BB4        ; Delete the character to the left.
        JR   L3CA0        ; Jump back to test/delete the next character.

;A space has been found and so all spaces are removed until a non-space character is encountered
;or the start of the Screen Buffer is reached.

L3CAF:  CALL L3D86        ; Is the cursor at the start of the Screen Buffer?
        RET  Z            ; Return if it is.

        CALL L3CBC        ; Does the current character hold a space? Returns pointing to the previous character.
        RET  NZ           ; Return if it does not.

;The current location contains a space.

        CALL L3BB4        ; Delete the space.
        JR   L3CAF        ; Jump back to delete any additional spaces.

; -------------------------------------------------------------------------------------------
; Variable Editing Mode: Test Whether the Current Position in the Screen Buffer Holds a Space
; -------------------------------------------------------------------------------------------
; Exit: Zero flag set if the current character holds a space.

L3CBC:  CALL L3AD8        ; Fetch the character at the cursor position.
        DEC  HL           ; Point to the previous location.
        LD   A,(HL)       ; Fetch the character.
        CP   $20          ; Is it a space?
        RET               ;

; ------------------------------------------------------------
; Variable Editing Mode: DELETE-WORD-RIGHT Key Handler Routine
; ------------------------------------------------------------
; This routine deletes to the start of the next word. If the current
; character contains a space, then the routine will delete this and
; will test whether the next location contains the start of a new word.
; The routine can delete up to 32 consecutive spaces before giving up
; on finding the start of a new word.
;
; Symbol: --> DEL
;         -->

L3CC4:  CALL L3D91        ; Has the end of row 21 of the Screen Buffer been reached?
        JR   Z,L3CD3      ; Jump ahead if so.

        CALL L3AD8        ; Fetch the character at the cursor position.
        JR   Z,L3CD3      ; Jump ahead if it contains a space.

        CALL L3BB0        ; Delete the character to the right via the Variable Editing Mode DELETE-RIGHT handler routine.
        JR   L3CC4        ; Jump back to test the next character.

;The cursor position contains a space or the cursor is at the end of row 21

L3CD3:  LD   B,$20        ; Skip over at most 32 spaces.

L3CD5:  PUSH BC           ; Save the space counter.

        CALL L3D91        ; Has the end of row 21 of the Screen Buffer been reached?
        JR   Z,L3CE7      ; Jump if so to make a return.

        CALL L3AD8        ; Fetch the character at the cursor position.
        JR   NZ,L3CE7     ; Jump to make a return if the position does not contain a space.

;The position contains a space

        CALL L3BB0        ; Delete the character to the right via the Variable Editing Mode DELETE-RIGHT handler routine.

        POP  BC           ; Fetch the space counter.
        DJNZ L3CD5        ; Repeat if allowed to delete more spaces.

        RET               ;

L3CE7:  POP  BC           ; Drop the space counter.
        RET               ;

; ----------------------------------------------------------------------
; Variable Editing Mode: Display Screen Buffer Row Containing the Cursor
; ----------------------------------------------------------------------
; This routine is used to refresh the row containing the cursor in the display file.
; It is used by the Variable Editing Mode DELETE-TO-START-OF-ROW and DELETE-TO-END-OF-ROW
; handler routines.

L3CE9:  LD   A,(ED_ROW)   ; $5B6C. Fetch the number of the row containing the cursor.
        JP   L2EBF        ; Jump to copy the Screen Buffer row to the display file.

; -----------------------------------------------------------------
; Variable Editing Mode: DELETE-TO-START-OF-ROW Key Handler Routine
; -----------------------------------------------------------------
; Delete to the start of the current row.
;
; Symbol: |<-- DEL
;         |<--

L3CEF:  LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        SET  6,(HL)       ; Signal not to update the display file during the delete operation.

        CALL L3CF9        ; Deletes all characters to the left until the start of the current row is reached.
        JR   L3CE9        ; Update the Screen Buffer row containing the cursor to the display file.

; ---------------------------------------------
; Variable Editing Mode: Delete to Start of Row
; ---------------------------------------------
; This routine deletes all characters to the left until the start of the current row is reached.

L3CF9:  LD   A,(ED_IDNT)  ; $5B6D. Fetch the starting column in this row, i.e. the indentation level.
        LD   B,A          ;
        LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column number.
        CP   B            ; Has the start of the row been reached?
        RET  Z            ; Return if so.

        CALL L3BB4        ; Delete the character to the left.
        JR   L3CF9        ; Jump back to test the next character.

; ---------------------------------------------------------------
; Variable Editing Mode: DELETE-TO-END-OF-ROW Key Handler Routine
; ---------------------------------------------------------------
; Delete to the end of the current line.
; ???? does this always delete a whole row, no matter the starting col?
;
; Symbol: -->| DEL
;         -->|
    
L3D07:  LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        SET  6,(HL)       ; Signal not to update the display file during the delete operation.

        LD   A,(ED_COL)   ; $5B6B. Fetch the column number of the cursor.
        AND  A            ; At column 0?
        JR   Z,L3D26      ; Jump ahead if so. ???? because removes whole row?

        CALL L3D17        ; ???? delete until end of row/next 32 chars????
        JR   L3CE9        ; Update the Screen Buffer row containing the cursor to the display file.

; --------
; Variable Eidting Mode: ???? delete 32 characters to the right following the cursor unless at column 31
; --------
; If not at column 31, then this routine will delete the next 32 characters to the right, spanning
; on to the next row as necessary.
; Entry: A=Cursor column number.

L3D17:  LD   B,A          ; Fetch the cursor column number.
        LD   A,$1F        ; Is the cursor at column 31?
        SUB  B            ;
        RET  Z            ; Return if it is.

;Enter a loop to attempt to delete 32 characters to the right. Even if there are no more characters
;to delete, all remaining iterations are performed

        LD   B,$20        ; Character counter.

L3D1E:  PUSH BC           ; Save the counter.

        CALL L3BB0        ; Delete the character to the right via the Variable Editing Mode DELETE-RIGHT handler routine.

        POP  BC           ; Fetch the counter.
        DJNZ L3D1E        ; Repeat if there are further characters to delete.

        RET               ;

; --------
; ???? cursor at column 0
; --------
; This routine is called by the Variable Editing Mode DELETE-TO-END-OF-ROW key handler routine.

L3D26:  CALL L3AD8        ; Fetch the character at the cursor position.
        LD   DE,$0020     ; 32 characters, i.e. 1 row.
        EX   DE,HL        ;
        ADD  HL,DE        ; Advance to the next row.

        LD   A,(ED_ROW)   ; $5B6C. Fetch the cursor row position.
        LD   C,A          ;
        LD   A,$15        ;
        SUB  C            ; Has row 21 been reached?
        JR   Z,L3D40      ; Jump if on row 21.

;Row 21 has not been reached.
;The A register holds the number of rows below (and including) the cursor.

        PUSH HL           ; Save the new row address.
        CALL L2EF3        ; HL=A*32.
        LD   B,H          ;
        LD   C,L          ; BC=Number of characters in all visible rows from the cursor onwards.
        POP  HL           ; Fetch the new row address.
        LDIR              ; Move all rows up by one.

;Row 21 is to be deleted and replaced with the next data from the variable's content.
;Joins here if the cursor was already on row 21.

L3D40:  CALL L3D9B        ; ???? Is there more string variable content available?
        JR   Z,L3D4B      ; Jump if there is not.

;There is more string variable data available so populate row 21

        CALL L3A4C        ; ???? populate row 21 ????
        JP   L301B        ; Jump to copy the Screen Buffer to the display file.

;There is not more string variable data to populate row 21 with

L3D4B:  LD   A,$15        ; Row 21.
        LD   BC,$0020     ; 32 columns.
        LD   D,' '        ; $20.
        CALL L316A        ; Fill row 21 of the Screen Buffer with spaces.

        JP   L301B        ; Jump to copy the Screen Buffer to the display file.

; ------------------------------------------------------
; Variable Editing Mode: TOP-OF-DATA Key Handler Routine
; ------------------------------------------------------
; Move to the start of the first row. This is achieved by repeatedly moving up
; one row at a time until the cursor can no longer be moved. The display is not
; updated while the moves are occurring.
;
; Symbol: ------
;         / \/ \
;          |  |

L3D58:  LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        SET  6,(HL)       ; Signal not to update the display file during the move operation.

L3D5D:  CALL L3B88        ; Move up 1 row (the display will not be updated).
        JR   NC,L3D5D     ; Repeat if the cursor was moved.

        JP   L301B        ; Jump to copy the Screen Buffer to the display file. [Could have saved 1 byte by using JR $3D55 (ROM 0)]

; ------------------------------------------------------
; Variable Editing Mode: END-OF-DATA Key Handler Routine
; ------------------------------------------------------
; Move to the end of the last row. This is achieved by repeatedly moving down one row at a time
; until the cursor can no longer be moved. The display is not updated while the moves are occurring.
; The routine is also called by the EDIT key handler routine when in string variable editing mode.
; The EDIT key handler sets the editing mode flag to indicate that BASIC mode is selected so that a
; return is made without printing the Screen Buffer to the display file.
;
; Symbol:   |  |
;          \ /\ /
;          ------

L3D65:  LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        SET  6,(HL)       ; Signal not to update the display file during the move operation.

L3D6A:  CALL L3B3D        ; Move down 1 row.
        JR   C,L3D6A      ; Repeat if the cursor was moved.

        LD   A,$1F        ; Column 31.
        LD   (ED_COL),A   ; $5B6B. Set the cursor position at column 31.

;Find the last character on the row

L3D74:  CALL L3AD8        ; Fetch the character at the cursor position.
        JR   NZ,L3D7E     ; Jump if the position does not contain a space.

;The position contains a space so move left until a non-space character is encountered

        CALL L3B71        ; Move to the left via the CURSOR-LEFT key handler routine.
        JR   NC,L3D74     ; Jump back if the cursor was moved.

L3D7E:  BIT  4,(IY-$3B)   ; $5BFF. BASIC or variable editing mode?
        RET  Z            ; Return if BASIC editing mode.

        JP   L301B        ; Jump to copy the Screen Buffer to the display file. [Could have saved 1 byte by using JR $3D55 (ROM 0)]

; --------
; ???? test if start of screen buffer has been reached
; --------

L3D86:  CALL L3B5E        ; Generate position offset for the new cursor row.
        LD   A,H          ;
        OR   L            ; Is the offset at the start of the Screen Buffer?

        LD   HL,(ED_XXXX) ; $5B6E. Fetch the ???? what does this test?
        OR   H            ;
        OR   L            ;
        RET               ;

; --------
; ????
; --------
; This routine
; Exit: Zero flag reset if the cursor is at the last editing position.
;       HL=The cursor position offset.

;row number in ED_ROW
;col number in ED_COL

L3D91:  CALL L3B5E        ; Generate position offset for the new cursor row.

        LD   DE,$02BF     ; 703=21*32 + 31.
        OR   A            ;
        SBC  HL,DE        ; Is the cursor at the last editing position?
        RET  NZ           ; Return if not.

; --------
; Variable Editing Mode: ???? is there more content available?
; --------
; Exit: Zero flag set if there is not more data available to display.
;       HL=Address of the last byte of the string variable's content.

L3D9B:  LD   HL,(EV_LEN)  ; $5B74. Fetch the length of the string variable.
        DEC  HL           ;
        LD   DE,(EV_ADDR) ; $5B72. Fetch the address of string variable's content.
        ADD  HL,DE        ; Point to the last byte of the string variable's content.

        LD   DE,(EV_XXXX) ; $5B70. ????
        PUSH HL           ; Save the address of the last byte of the string variable.
        SBC  HL,DE        ; ????
        POP  HL           ; Restore the address of the last byte of the string variable.
        RET               ;

; --------
; Variable Editing Mode: Insert Character ????
; --------
; A key has been pressed and the editor is in the string variable editing mode. This routine is used by the Editor main loop.
; Entry: A=Key code.
; Exit : Carry flag set to indicate the key was handled.

L3DAD:  LD   C,A          ; Save the new character.

        LD   HL,EV_FLGS   ; $5B76. String Variable Editor flags.
        BIT  3,(HL)       ; Is the cursor within a word?
        JR   NZ,L3DDF     ; Jump ahead if so.

;The cursor is not within a word

        LD   A,(HL)       ; Fetch the variable edit flags.
        AND  $03          ; Extract the mode.
        JP   NZ,L3FA3     ; Jump if not insert mode.

;Insert mode

L3DBB:  CALL L3AD8        ; Fetch the address of the cursor position.
        LD   (HL),C       ; Insert the new character.

        LD   A,(ED_ROW)   ; $5B6C. A=Cursor row position.
        CALL L2EBF        ; Print Screen Buffer row.

        CALL L3B23        ; Move the cursor right one character via the CURSOR-RIGHT key handler.
        CALL NC,L3E55     ; If the cursor can not be moved then process the string via the ENTER key handler.

        LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        LD   B,A          ;
        LD   A,(ED_IDNT)  ; $5B6D. Fetch the indentation column.
        SUB  B            ; ????
        SCF               ; Signal the key was handled.
        RET  NZ           ; ????

        LD   HL,EV_FLGS   ; $5B76. String Variable Editor flags.
        BIT  2,(HL)       ; In Word Wrap mode?
        RET  Z            ; Return if not.

;In Word Wrap mode

        SET  3,(HL)       ; Signal within a word.

        SCF               ; Signal the key was handled.
        RET               ;

;The cursor is within a word

L3DDF:  CP   $20          ; Was SPACE pressed?
        JR   Z,L3DF4      ; Jump ahead if so.

;SPACE was not pressed so the cursor will remain within the word

        PUSH BC           ; Save the new key code.

        CALL L3DFB        ; ???? insert character

        LD   A,(ED_ROW)   ; $5B6C. Fetch the cursor row position.
        DEC  A            ; Point to the previous row.
        CALL L2EBF        ; Print Screen Buffer row.

        POP  BC           ; Fetch the new key code.
        CALL L3DF4        ; Signal that the cursor is not within a word.

        JR   L3DBB        ; Jump back to insert the character.

;SPACE was pressed so the cursor is no longer within a word

L3DF4:  LD   HL,EV_FLGS   ; $5B76. String Variable Editor flags.
        RES  3,(HL)       ; Signal that the cursor is not within a word.

        SCF               ; Signal the key was handled.
        RET               ;

; ---------------------------------------
; Variable Editing Mode: Insert Character ???? in what mode?
; ---------------------------------------
; A key has been pressed and the editor is in the string variable editing mode.
; The cursor is within a word and SPACE was not pressed.

;???? does this need to shift all characters?
;???? why do nothing if on row 0? it is doing something with previous row.
;???? does nothing if space is not column 31 of previous row.
;???? does the text build bottom upwards?

L3DFB:  LD   A,(ED_ROW)   ; $5B6C. Fetch the cursor row position.
        AND  A            ; Is the cursor on row 0?
        RET  Z            ; Return if it is.

        CALL L3AD8        ; Fetch the address of the cursor position.
        LD   A,L          ;
        AND  $E0          ; Mask off the column bits.
        LD   L,A          ;
        DEC  HL           ; HL=Address of column 31 of the previous row.

        LD   A,(HL)       ; Fetch the character in column 31 of the previous row.
        CP   $20          ; Is it a space?
        RET  Z            ; Return if so.

	LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        SET  6,(HL)       ; Signal not to update the display file during the ???? operation.

        LD   HL,(ED_COL)  ; $5B6B. Fetch the cursor position.
        PUSH HL           ; Save it.

        CALL L3AD8        ; Fetch the address of the cursor position.
        PUSH HL           ; Save it.

        CALL L3C0D        ; Move to the start of the word to the left.
        CALL L3C0D        ; Move to the start of the word to the left.
        CALL L3C45        ; Move to the start of the next word.

        CALL L3AD8        ; Fetch the address of the start of the next word.
        PUSH HL           ; Save it.

        LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        LD   B,A          ;
        LD   A,$20        ; Column 32.
        SUB  B            ; A=Number of characters to end of the row.

        LD   B,$00        ;
        LD   C,A          ; BC=Number of characters to end of the row.

        POP  HL           ; Fetch the address of the start of the next word.
        POP  DE           ; Fetch the address of the cursor position.

        CP   $20          ; Is the cursor in column 0?
        JR   NC,L3E50     ; Jump ahead if so.

;The cursor is not in column 0

        PUSH HL           ; ????
        PUSH BC           ;
        LDIR              ; Shift all bytes ????
        POP  BC           ;
        POP  HL           ;

;Fill until the end of the row with spaces

        LD   B,C          ; Fetch the number of characters until the end of the row.
        PUSH BC           ; Save it.

L3E3E:  LD   (HL),$20     ; Insert a space.
        INC  HL           ;
        DJNZ L3E3E        ; Repeat until the end of the row.

        POP  BC           ; Fetch the number of characters until the end of the row.
        POP  HL           ; Fetch the original cursor position.
        LD   (ED_COL),HL  ; $5B6B. Restore the cursor position.

L3E48:  PUSH BC           ; ???? move cursor to end of row?
        CALL L3B23        ; Move the cursor right one character via the CURSOR-RIGHT key handler.
        POP  BC           ;
        DJNZ L3E48        ; ????

        RET               ;

;The cursor is in column 0

L3E50:  POP  HL           ; Fetch the original cursor position.
        LD   (ED_COL),HL  ; $5B6B. Restore the cursor position.
        RET               ;

; ------------------------------------------------
; Variable Editing Mode: ENTER Key Handler Routine
; ------------------------------------------------
; This routine handles ENTER being pressed. It performs different actions based on the current editing
; mode (Insert, Overtype, Indent).
;
; Insert   - A row consisting of all characters following the cursor is created below the row containing the cursor.
;            The cursor is placed at the start of this new row. If the cursor was on column 31 then no characters
;            are moved to the row below. If the cursor is on column 30 or bfore then the characters from that column
;            are moved to the row below. The move procedure is slightly inefficient since it always moves 32 characters
;            not matter how many characters follow the cursor on the current row. Any surplus characters introduced at
;            the start of the following row are then deleted.
; Overtype - The cursor is moved to the start of the row below.
; Indent   - This is similar to the Insert mode except that the characters shifted to the row below begin at the
;            active indentation column. The characters forming the indentation are copies of the characters in these
;            positions from the row below [???? is this a bug?].

L3E55:  LD   A,(EV_FLGS)  ; $5B76.
        AND  $03          ; Fetch the variable edit mode.
        JR   NZ,L3E65     ; Jump if Insert or Indent mode.

;Overtype mode

        LD   A,(ED_IDNT)  ; $5B6D. Fetch the indentation column number. [Inefficient since for Overtype mode the indentation column is always 0]
        LD   (ED_COL),A   ; $5B6B. Store this as the new cursor column number.
        JP   L3B48        ; Jump to move down one row.

;Insert or Indent mode

L3E65:  LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        SET  6,(HL)       ; Signal not to update the display file while processing the entered line.

        LD   A,(ED_ROW)   ; $5B6C. Fetch the cursor row position.
        CP   $15          ; On row 21?
        CALL Z,L3953      ; If so then ???? scroll down screen buffer ????

        CALL L3A24        ; ???? copy new content into screen buffer ????

        LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        CP   $1F          ; At column 31?
        JR   Z,L3E99      ; Jump if so.

;The cursor is before column 31

        LD   DE,($FF24)   ; Fetch the address of the Screen Buffer.
        LD   HL,$02A0     ; 21 rows of 32 columns.
        ADD  HL,DE        ; Point to the start of row 22.
        PUSH HL           ; Save the address of row 22 within the Screen Buffer.

        CALL L3AD8        ; Fetch the address of the cursor position into HL.

        POP  DE           ; Fetch the address of row 22 within the Screen Buffer.
        EX   DE,HL        ; DE=Address of the cursor, HL=Address of row 22.

        CALL L285F        ; Determine number of characters after the cursor that need shifting. Return the result in BC.
        DEC  DE           ; DE=Address of column 31 of row 21.

        LD   HL,$0020     ;
        ADD  HL,DE        ; Point to column 31 of row 22.
        EX   DE,HL        ; DE=Address of column 31 of row 22, HL=Address of column 31 of row 21.

        LD   A,B          ; Are there any characters to move?
        OR   C            ;
        JR   Z,L3E99      ; Jump ahead if there are none.

        LDDR              ; Move all characters down one row.

;Joins here when the cursor is at column 31, i.e. do not shift any characters down a row

L3E99:  LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        CALL L3D17        ; Delete a row of characters following the cursor, i.e. 32 characters.
        LD   HL,ED_ROW    ; $5B6C. Point to the cursor row position.
        INC  (HL)         ; Advance to the next row.
        CALL L3B5E        ; Generate position offset for the new cursor row.
        CALL L3CEF        ; Delete all characters back to the start of the row via the DELETE-TO-START-OF-ROW key handler routine.
                          ;???? does this work when in Indent mode?

        LD   A,(ED_IDNT)  ; $5B6D. Fetch the indentation column.
        LD   (ED_COL),A   ; $5B6B. Store the new cursor column position.
        JP   L301B        ; Jump to copy the Screen Buffer to the display file.

; ----------------------------------------------------------
; Variable Editing Mode: Find/Create String Variable to Edit
; ----------------------------------------------------------
; This routine locates the string variable specified, creating it if it does not exist.

L3EB2:  LD   HL,$EC20     ; The second row of the Screen Buffer.
        LD   ($FF24),HL   ; Store the ???? next available ???? address within the Screen Buffer.

        LD   HL,(KPARAM1) ; $5B6D. Fetch the address of the parameter following the EDITAR command.
        CALL L3FE1        ; Is it an existing simple string variable?
        JR   NC,L3EDA     ; Jump if it is.

;No such variable exists in the variables area so create a new entry.

        LD   A,(HL)       ; Fetch the name as typed (lowercase or uppercase).
        PUSH AF           ; Save the name.

        LD   HL,($5C4B)   ; VARS. Point to the start of the variables area.

        LD   BC,$0003     ; The null variable is stored using 3 bytes (1 byte for the name, 2 bytes for the length).
        CALL L29A5        ; Create room for the variable.

        POP  AF           ; Retrieve the name of the variable as typed.

        INC  HL           ; Point to the first byte of the created space.

        LD   D,H          ; Keep a copy of the start address of the variable entry.
        LD   E,L          ;

        AND  $1F          ; Keep the letter offset bits.
        OR   $40          ; Convert to the ASCII range for uppercase letters.
        LD   (HL),A       ; Store the name of the variable in the variables area.
        INC  HL           ;
        LD   (HL),$00     ; Store the length as 0, i.e. a null string.
        INC  HL           ;
        LD   (HL),$00     ;

;Joins here when the variable already exists in the variables area.

L3EDA:  EX   DE,HL        ; Fetch the address of the variable in the variables area into HL.

        INC  HL           ; Point to the low byte of the length field.
        LD   A,(HL)       ; Fetch the low byte.
        LD   (EV_LEN),A   ; $5B74. Save the low byte.

        INC  HL           ; Point to the high byte of the length field.
        LD   A,(HL)       ; Fetch the high byte.
        INC  HL           ; Point to the string variable's content.
        LD   (EV_LEN+1),A ; $5B75. Save the high byte.

        LD   (EV_ADDR),HL ; $5B72. Save the address of the variable's content.
        LD   (EV_XXXX),HL ; $5B70. ????

        LD   HL,$0000     ;
        LD   (ED_COL),HL  ; $5B6B. Set the cursor at row 0, column 0.
        LD   (ED_POS),HL  ; $5B92. Set the cursor offset position to 0.

        LD   HL,$FFEA     ; ????
        LD   (ED_XXXX),HL ; $5B6E.

        LD   HL,ED_IDNT   ; $5B6D. The indentation column system variable.
        LD   (HL),$00     ; Set the indentation at column 0.

        LD   A,$05        ; Select Word Wrap and Insert mode.
        LD   (EV_FLGS),A  ; $5B76. Set the string variable editing flags.

;Insert an 'Enter' character at the end of the variable's content.

        LD   HL,(EV_LEN)  ; $5B74. Fetch the length of the variable.
        LD   DE,(EV_ADDR) ; $5B72. Fetch the start address of the variable's content.
        ADD  HL,DE        ; Point to the location after the variable's content.
        CALL L29A2        ; Create room for 1 byte at HL.
        INC  HL           ; Point to the first byte of the created space.
        LD   (HL),$0D     ; Insert an 'Enter'.

        LD   HL,(EV_LEN)  ; $5B74. Fetch the length of the variable.
        INC  HL           ; Increment the length.
        LD   (EV_LEN),HL  ; $5B74. Store the new length.

        LD   HL,ED_FLGS   ; $5BFF.
        SET  4,(HL)       ; Signal variable editing mode.
        RES  3,(HL)       ; Signal using the main edit screen area.

        LD   HL,FLAGS3    ; $5B66.
        RES  0,(HL)       ; Signal Editor mode.
        RET               ;

; -----------------------------------------------
; Variable Editing Mode: EDIT Key Handler Routine
; -----------------------------------------------
; This is executed when the EDIT key is pressed.
; The EDIT key is used to exit the string variable editing mode and return to the lower screen area
; editing mode.

; ???? What does this routine do?

L3F27:  LD   HL,ED_FLGS   ; $5BFF.
        SET  3,(HL)       ; Signal using the lower edit screen area.
        RES  4,(HL)       ; Signal BASIC editing mode (which causes the call to $3D65 not to display the Screen Buffer).

        CALL L3D65        ; Move to the end of the last row.

	LD   HL,EV_FLGS   ; $5B76. String variable editing flags.
        SET  6,(HL)       ; Signal not to update the display file during the ???? operation.

        LD   A,$15        ; Row 21.
        LD   (ED_ROW),A   ; $5B6C. Set the cursor to the start of row 21.

        LD   B,$16        ; 22 rows.

L3F3D:  PUSH BC           ; ????
        CALL L3B48        ; Move the cursor down 1 row.
        POP  BC           ;
        DJNZ L3F3D        ; Repeat for all rows.

        CALL L1EAF        ; Use Normal RAM Configuration (physical RAM bank 0).

        LD   HL,(EV_ADDR) ; $5B72. ????
        LD   DE,(EV_LEN)  ; $5B74.
        ADD  HL,DE        ;
        LD   BC,$0000     ;

L3F52:  DEC  HL           ;
        LD   A,(HL)       ;
        CP   $0D          ;
        JR   NZ,L3F5F     ;

        INC  BC           ;
        DEC  DE           ;
        LD   A,D          ;
        OR   E            ;
        JR   NZ,L3F52     ;

        DEC  HL           ;

L3F5F:  PUSH DE           ;

        INC  HL           ;
        RST  28H          ;
        DEFW RECLAIM_2    ; $19E8.
        POP  DE           ;
        LD   HL,(EV_ADDR) ; $5B72.
        DEC  HL           ;
        LD   (HL),D       ;
        DEC  HL           ;
        LD   (HL),E       ;

        CALL L1ED4        ; Use Workspace RAM configuration (physical RAM bank 7).

        POP  HL           ;
        RST  28H          ;
        DEFW CLS          ; $0D6B.
        RET               ;

; -----------------------------------------------------------
; Variable Editing Mode: WORD-WRAP-TOGGLE Key Handler Routine
; -----------------------------------------------------------
; The SHIFT-TOGGLE key toggles word-wrap mode on and off.

L3F74:  LD   HL,EV_FLGS   ; $5B76.
        LD   A,$04        ;
        XOR  (HL)         ; Toggle the Word Wrap mode.
        LD   (HL),A       ;
        RET               ;

; -----------------------------------------------------
; Variable Editing Mode: CYCLE-MODE Key Handler Routine
; -----------------------------------------------------
; The TOGGLE key cycles through the editing modes (Insert, Overtype and Indent).
; The indentation column is set to 0 for Insert and Overtype and as per the current
; cursor location when Indent mode is selected (but capped at column 26 if the
; cursor location is greater).

L3F7C:  LD   HL,EV_FLGS   ; $5B76.
        LD   A,(HL)       ; Fetch the variable editing flags.
        AND  $03          ; Mask off the mode bits.
        INC  A            ; Advance to the next mode
        CP   $03          ; Cycled through all modes?
        JR   NZ,L3F88     ; Jump ahead if not.

        XOR  A            ; Reset back to the first mode.

L3F88:  LD   B,A          ; B=New mode.
        LD   A,$FC        ; Mask for the other bits.
        AND  (HL)         ; Save the other bits.
        OR   B            ; Add the new mode.
        LD   (HL),A       ; Save the new editor flags.

        AND  $03          ; Keep only the new mode.
        CP   $02          ; Is it Indent?
        LD   A,$00        ; Assume no indentation, i.e. column 0.
        JR   NZ,L3F9F     ; Jump ahead if not.

;Indent mode so set the indentation column to the current cursor position

        LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        CP   $1A          ; Is it below column 26?
        JR   C,L3F9F      ; Jump ahead if it is.

        LD   A,$1A        ; Cap the indentation column 26.

L3F9F:  LD   (ED_IDNT),A  ; $5B6D. Store the indentation column.
        RET               ;

; ---------------------------------------
; Variable Editing Mode: Insert Character ???? in what mode?
; ---------------------------------------
; A key has been pressed and the editor is in the string variable editing mode.
; The cursor is not within a word and the editor is not in insert mode.
; If the row is full and the character in column 31 is not a space then the
; character is not inserted.
; Entry: A=Key code.
;        C=Key code.
; Exit : Carry flag reset if the the key was not handled.

L3FA3:  LD   A,(ED_COL)   ; $5B6B. Fetch the cursor column position.
        LD   B,A          ;
        LD   A,$1F        ; Is the cursor at column 31?
        SUB  B            ;
        JR   Z,L3FD6      ; Jump if at column 31.

;The cursor is before column 31 and hence all characters after it on this row may require
;shifting to the right before inserting the new key code

        PUSH BC           ; Save the cursor column position.

        LD   A,$1F        ; Column 31.
        LD   (ED_COL),A   ; $5B6B. Set the cursor position to column 31.
        CALL L3AD8        ; Fetch the address of the column position 31 into HL.

        POP  BC           ; Fetch the previous cursor column position.
        LD   A,B          ;
        LD   (ED_COL),A   ; $5B6B. Restore the previous cursor column position.

        LD   A,(HL)       ; Fetch the character at column position 31.
        CP   $20          ; Was it a space?
        RET  NZ           ; Return if not back to the Editor with the carry flag reset
                          ; to indicate that the character could not be inserted.

;The character in column 31 is a space. All characters after the cursor will be shifted to the
;right, before inserting the new character

        PUSH HL           ; Save the address of column 31.

        PUSH BC           ;
        CALL L3AD8        ; Fetch the address of the cursor position into HL.
        POP  BC           ;

        EX   DE,HL        ; DE=Location of the cursor position.

        POP  HL           ; Fetch the address of column 31.
        PUSH HL           ;

        SBC  HL,DE        ; HL=Number of characters from the cursor position to column 31.

        LD   A,C          ; Fetch the key code.

        LD   B,H          ; BC=Number of characters to shift.
        LD   C,L          ;
        POP  DE           ; Address of column 31.
        LD   H,D          ;
        LD   L,E          ;
        DEC  HL           ; HL=Address of column 30.
        LDDR              ; Shift characters to the right.

        LD   C,A          ; Fetch the key code.
        JP   L3DBB        ; Jump to insert the character.

;The cursor is at column 31 so the new key code can be inserted

L3FD6:  PUSH BC           ; Save the cursor column position.
        CALL L3AD8        ; Fetch the character at the cursor position.
        POP  BC           ; Fetch the cursor column position.

        CP   $20          ; Is it a space? [Redundant check since $3AD8 performs this also]
        JP   Z,L3DBB      ; Jump if so to insert the character.

        RET               ; Return back to the Editor with the carry flag reset to indicate that the
                          ; character could not be inserted.

; -------------------------------------------------
; Find Simple String Variable Within Variables Area
; -------------------------------------------------
; Entry: HL=Address of the parameter following an EDITAR command.
; Exit : Carry flag set if the variable was not found.

L3FE1:  PUSH HL           ; Save the parameter address.

        LD   B,(HL)       ; Fetch the name of the variable.
        RES  5,B          ; Convert to uppercase.

        LD   HL,($5C4B)   ; VARS. Point to the start of the variables area.

L3FE8:  LD   A,B          ; Fetch the variable name.
        CP   (HL)         ; Does it match?
        JR   Z,L3FFA      ; Jump if it does. The carry flag will be reset.

        LD   A,$80        ; The 'end of variables' marker.
        CP   (HL)         ; Has the end of variables area marker been found?
        SCF               ;
        JR   Z,L3FFB      ; Jump if so, with the carry flag set to indicate that the variable was not found.

        PUSH BC           ; Save the variable name.

        RST  28H          ;
        DEFW NEXT_ONE     ; $19B8. Find the address of the next variable, into DE.

        POP  BC           ; Fetch the variable name.

        EX   DE,HL        ; Transfer the address of the next variable in the variables area to HL
        JR   L3FE8        ; and jump back to test whether this variable matches.

;The variable was found within the variables area.

L3FFA:  EX   DE,HL        ; Transfer the address of the variable in the variables area to DE.

;Joins here when the variable was not found within the variables area.

L3FFB:  POP  HL           ; Retrieve the parameter address.
        RET               ;


; ============
; UNUSED SPACE
; ============

L3FFD:  DEFB %10011001    ; Remains of the copyright symbol from ROM 1.
        DEFB %01000010    ;
        DEFB %00111100    ;

        END


; ==============================
; REFERENCE INFORMATION - PART 2
; ==============================

; ===========================
; Standard Error Report Codes
; ===========================

; 0 - OK                      Successful completion, or jump to a line number bigger than any existing.
; 1 - NEXT without FOR        The control variable does not exist (it has not been set up by a FOR statement),
;                             but there is an ordinary variable with the same name.
; 2 - Variable not found      For a simple variable, this will happen if the variable is used before it has been assigned
;                             to by a LET, READ or INPUT statement, loaded from disk (or tape), or set up in a FOR statement.
;                             For a subscripted variable, it will happen if the variable is used before it has been
;                             dimensioned in a DIM statement, or loaded from disk (or tape).
; 3 - Subscript wrong         A subscript is beyond the dimension of the array or there are the wrong number of subscripts.
; 4 - Out of memory           There is not enough room in the computer for what you are trying to do.
; 5 - Out of screen           An INPUT statement has tried to generate more than 23 lines in the lower half of the screen.
;                             Also occurs with 'PRINT AT 22,xx'.
; 6 - Number too big          Calculations have yielded a number greater than approximately 10^38.
; 7 - RETURN without GO SUB   There has been one more RETURN than there were GO SUBs.
; 8 - End of file             Input returned unacceptable character code.
; 9 - STOP statement          After this, CONTINUE will not repeat the STOP but carries on with the statement after.
; A - Invalid argument        The argument for a function is unsuitable.
; B - Integer out of range    When an integer is required, the floating point argument is rounded to the nearest integer.
;                             If this is outside a suitable range, then this error results.
; C - Nonsense in BASIC       The text of the (string) argument does not form a valid expression.
; D - BREAK - CONT repeats    BREAK was pressed during some peripheral operation.
; E - Out of DATA             You have tried to READ past the end of the DATA list.
; F - Invalid file name       SAVE with filename empty or longer than 10 characters.
; G - No room for line        There is not enough room left in memory to accommodate the new program line.
; H - STOP in INPUT           Some INPUT data started with STOP.
; I - FOR without NEXT        A FOR loop was to be executed no times (e.g. FOR n=1 TO 0) and corresponding NEXT statement could not be found.
; J - Invalid I/O device      Attempting to input characters from or output characters to a device that doesn't support it.
; K - Invalid colour          The number specified is not an appropriate value.
; L - BREAK into program      BREAK pressed. This is detected between two statements.
; M - RAMTOP no good          The number specified for RAMTOP is either too big or too small.
; N - Statement lost          Jump to a statement that no longer exists.
; O - Invalid Stream          Trying to input from or output to a stream that isn't open or that is out of range (0...15),
;                             or trying to open a stream that is out of range.
; P - FN without DEF          User-defined function used without a corresponding DEF in the program.
; Q - Parameter error         Wrong number of arguments, or one of them is the wrong type.
; R - Tape loading error      A file on tape was found but for some reason could not be read in, or would not verify.


; =========================
; Standard System Variables
; =========================
; These occupy addresses $5C00-$5CB5.
;
; KSTATE   $5C00   8   IY-$3A   Used in reading the keyboard.
; LASTK    $5C08   1   IY-$32   Stores newly pressed key.
; REPDEL   $5C09   1   IY-$31   Time (in 50ths of a second) that a key must be held down before it repeats. This starts off at 35.
; REPPER   $5C0A   1   IY-$30   Delay (in 50ths of a second) between successive repeats of a key held down - initially 5.
; DEFADD   $5C0B   2   IY-$2F   Address of arguments of user defined function (if one is being evaluated), otherwise 0.
; K_DATA   $5C0D   1   IY-$2D   Stores second byte of colour controls entered from keyboard.
; TVDATA   $5C0E   2   IY-$2C   Stores bytes of colour, AT and TAB controls going to TV.
; STRMS    $5C10  38   IY-$2A   Addresses of channels attached to streams.
; CHARS    $5C36   2   IY-$04   256 less than address of character set, which starts with ' ' and carries on to '(c)'.
; RASP     $5C38   1   IY-$02   Length of warning buzz.
; PIP      $5C39   1   IY-$01   Length of keyboard click.
; ERR_NR   $5C3A   1   IY+$00   1 less than the report code. Starts off at 255 (for -1) so 'PEEK 23610' gives 255.
; FLAGS    $5C3B   1   IY+$01   Various flags to control the BASIC system:
;                                 Bit 0: 1=Suppress leading space.
;                                 Bit 1: 1=Using printer, 0=Using screen.
;                                 Bit 2: 1=Print in L-Mode, 0=Print in K-Mode.
;                                 Bit 3: 1=L-Mode, 0=K-Mode.
;                                 Bit 4: 1=128K Mode, 0=48K Mode. [Always 0 on 48K Spectrum]
;                                 Bit 5: 1=New key press code available in LAST_K.
;                                 Bit 6: 1=Numeric variable, 0=String variable.
;                                 Bit 7: 1=Line execution, 0=Syntax checking.
; TVFLAG   $5C3C   1   IY+$02   Flags associated with the TV:
;                                 Bit 0  : 1=Using lower editing area, 0=Using main screen.
;                                 Bit 1-2: Not used (always 0).
;                                 Bit 3  : 1=Mode might have changed.
;                                 Bit 4  : 1=Automatic listing in main screen, 0=Ordinary listing in main screen.
;                                 Bit 5  : 1=Lower screen requires clearing after a key press.
;                                 Bit 6-7: 1=Tape Loader option selected. [Always 0 on 48K Spectrum]
; ERR_SP   $5C3D   2   IY+$03   Address of item on machine stack to be used as error return.
; LISTSP   $5C3F   2   IY+$05   Address of return address from automatic listing.
; MODE     $5C41   1   IY+$07   Specifies cursor type:
;                                 $00='L' or 'C'.
;                                 $01='E'.
;                                 $02='G'.
;                                 $04='K'.
; NEWPPC   $5C42   2   IY+$08   Line to be jumped to.
; NSPPC    $5C44   1   IY+$0A   Statement number in line to be jumped to.
; PPC      $5C45   2   IY+$0B   Line number of statement currently being executed.
; SUBPPC   $5C47   1   IY+$0D   Number within line of statement currently being executed.
; BORDCR   $5C48   1   IY+$0E   Border colour multiplied by 8; also contains the attributes normally used for the lower half
;                               of the screen.
; E_PPC    $5C49   2   IY+$0F   Number of current line (with program cursor).
; VARS     $5C4B   2   IY+$11   Address of variables.
; DEST     $5C4D   2   IY+$13   Address of variable in assignment.
; CHANS    $5C4F   2   IY+$15   Address of channel data.
; CURCHL   $5C51   2   IY+$17   Address of information currently being used for input and output.
; PROG     $5C53   2   IY+$19   Address of BASIC program.
; NXTLIN   $5C55   2   IY+$1B   Address of next line in program.
; DATADD   $5C57   2   IY+$1D   Address of terminator of last DATA item.
; E_LINE   $5C59   2   IY+$1F   Address of command being typed in.
; K_CUR    $5C5B   2   IY+$21   Address of cursor.
; CH_ADD   $5C5D   2   IY+$23   Address of the next character to be interpreted - the character after the argument of PEEK,
;                               or the NEWLINE at the end of a POKE statement.
; X_PTR    $5C5F   2   IY+$25   Address of the character after the '?' marker.
; WORKSP   $5C61   2   IY+$27   Address of temporary work space.
; STKBOT   $5C63   2   IY+$29   Address of bottom of calculator stack.
; STKEND   $5C65   2   IY+$2B   Address of start of spare space.
; BREG     $5C67   1   IY+$2D   Calculator's B register.
; MEM      $5C68   2   IY+$2E   Address of area used for calculator's memory (usually MEMBOT, but not always).
; FLAGS2   $5C6A   1   IY+$30   Flags:
;                                 Bit 0  : 1=Screen requires clearing.
;                                 Bit 1  : 1=Printer buffer contains data.
;                                 Bit 2  : 1=In quotes.
;                                 Bit 3  : 1=CAPS LOCK on.
;                                 Bit 4  : 1=Using channel 'K'.
;                                 Bit 5-7: Not used (always 0).
; DF_SZ    $5C6B   1   IY+$31   The number of lines (including one blank line) in the lower part of the screen.
; S_TOP    $5C6C   2   IY+$32   The number of the top program line in automatic listings.
; OLDPPC   $5C6E   2   IY+$34   Line number to which CONTINUE jumps.
; OSPPC    $5C70   1   IY+$36   Number within line of statement to which CONTINUE jumps.
; FLAGX    $5C71   1   IY+$37   Flags:
;                                 Bit 0  : 1=Simple string complete so delete old copy.
;                                 Bit 1  : 1=Indicates new variable, 0=Variable exists.
;                                 Bit 2-4: Not used (always 0).
;                                 Bit 5  : 1=INPUT mode.
;                                 Bit 6  : 1=Numeric variable, 0=String variable. Holds nature of existing variable.
;                                 Bit 7  : 1=Using INPUT LINE.
; STRLEN   $5C72   2   IY+$38   Length of string type destination in assignment.
; T_ADDR   $5C74   2   IY+$3A   Address of next item in syntax table.
; SEED     $5C76   2   IY+$3C   The seed for RND. Set by RANDOMIZE.
; FRAMES   $5C78   3   IY+$3E   3 byte (least significant byte first), frame counter incremented every 20ms.
; UDG      $5C7B   2   IY+$41   Address of first user-defined graphic. Can be changed to save space by having fewer
;                               user-defined characters.
; COORDS   $5C7D   1   IY+$43   X-coordinate of last point plotted.
;          $5C7E   1   IY+$44   Y-coordinate of last point plotted.
; P_POSN   $5C7F   1   IY+$45   33-column number of printer position.
; PRCC     $5C80   2   IY+$46   Full address of next position for LPRINT to print at (in ZX Printer buffer).
;                               Legal values $5B00 - $5B1F. [Not used in 128K mode]
; ECHO_E   $5C82   2   IY+$48   33-column number and 24-line number (in lower half) of end of input buffer.
; DF_CC    $5C84   2   IY+$4A   Address in display file of PRINT position.
; DF_CCL   $5C86   2   IY+$4C   Like DF CC for lower part of screen.
; S_POSN   $5C88   1   IY+$4E   33-column number for PRINT position.
;          $5C89   1   IY+$4F   24-line number for PRINT position.
; SPOSNL   $5C8A   2   IY+$50   Like S_POSN for lower part.
; SCR_CT   $5C8C   1   IY+$52   Counts scrolls - it is always 1 more than the number of scrolls that will be done before
;                               stopping with 'scroll?'.
; ATTR_P   $5C8D   1   IY+$53   Permanent current colours, etc, as set up by colour statements.
; MASK_P   $5C8E   1   IY+$54   Used for transparent colours, etc. Any bit that is 1 shows that the corresponding attribute
;                               bit is taken not from ATTR_P, but from what is already on the screen.
; ATTR_T   $5C8F   1   IY+$55   Temporary current colours (as set up by colour items).
; MASK_T   $5C90   1   IY+$56   Like MASK_P, but temporary.
; P_FLAG   $5C91   1   IY+$57   Flags:
;                                 Bit 0: 1=OVER 1, 0=OVER 0.
;                                 Bit 1: Not used (always 0).
;                                 Bit 2: 1=INVERSE 1, 0=INVERSE 0.
;                                 Bit 3: Not used (always 0).
;                                 Bit 4: 1=Using INK 9.
;                                 Bit 5: Not used (always 0).
;                                 Bit 6: 1=Using PAPER 9.
;                                 Bit 7: Not used (always 0).
; MEMBOT   $5C92  30   IY+$58   Calculator's memory area - used to store numbers that cannot conveniently be put on the
;                               calculator stack.
;          $5CB0   2   IY+$76   Not used on standard Spectrum. [Used by ZX Interface 1 Edition 2 for printer WIDTH]
; RAMTOP   $5CB2   2   IY+$78   Address of last byte of BASIC system area.
; P_RAMT   $5CB4   2   IY+$7A   Address of last byte of physical RAM.


; ==========
; Memory Map
; ==========
; The conventional memory, i.e. when RAM banks 5, 2 and 0 are paged in, is used as follows:
;
; +---------+-----------+------------+--------------+-------------+--
; | BASIC   |  Display  | Attributes |  New System  |   System    | 
; |  ROM    |   File    |    File    |  Variables   |  Variables  | 
; +---------+-----------+------------+--------------+-------------+--
; ^         ^           ^            ^              ^             ^
; $0000   $4000       $5800        $5B00          $5C00         $5CB6 = CHANS 
;
;
;  --+----------+---+---------+-----------+---+------------+--+---+--
;    | Channel  |$80|  BASIC  | Variables |$80| Edit Line  |NL|$80|
;    |   Info   |   | Program |   Area    |   | or Command |  |   |
;  --+----------+---+---------+-----------+---+------------+--+---+--
;    ^              ^         ^               ^                   ^
;  CHANS           PROG      VARS           E_LINE              WORKSP
;
;
;                             ------>         <-------  <------
;  --+-------+--+------------+-------+-------+---------+-------+-+---+------+
;    | INPUT |NL| Temporary  | Calc. | Spare | Machine | GOSUB |?|$3E| UDGs |
;    | data  |  | Work Space | Stack |       |  Stack  | Stack | |   |      |
;  --+-------+--+------------+-------+-------+---------+-------+-+---+------+
;    ^                       ^       ^       ^                   ^   ^      ^
;  WORKSP                  STKBOT  STKEND   SP               RAMTOP UDG  P_RAMT


; ===================
; Extending 128 BASIC
; ===================
; Full details on the mechanism and an example program with source code listing is available for download at www.fruitcake.plus.com.
;
; The new system variable RAMRST normally contains a RST $08 instruction and is used with the following byte in RAMERR to allow
; 128 BASIC mode to produce a standard Spectrum error report via ROM 1. Replacing the RST $08 instruction with a JP instruction
; allows control to be passed to a user routine when certain 128 BASIC errors occur. The low byte of the jump destination
; address is held in the RAMERR system variable, and so this will hold the error code value ranging from $00 to $FF. The high
; byte of the destination address will be taken from system variable BAUD, and so this must be requisitioned for use by
; the extended BASIC parser. This means that whilst the extended BASIC mechanism is active, the Spectrum 128 RS232 commands
; cannot be used. This limitation can be overcome by temporarily disabling the paging mechanism by restoring the RST $08 instruction
; in RAMRST and restoring the baud rate constant in BAUD, then executing the required RS232 commands. Afterwards, the extended
; BASIC parser can be re-enabled by resetting the BAUD and RAMRST system variables.
;
; When an error occurs, RAMERR will be set by ROM 0 before calling RAMRST. With a JP instruction installed at RAMRST, the
; destination address could in theory range from any address within a page of memory (256 bytes). In practice, ROM 0
; only uses the RAMRST routine for 13 error codes, and then only for certain situations. Most of these errors are produced
; for very obscure scenarios but fortunately ROM 0 will produce error "C Nonsense in BASIC" when it cannot identify the first
; keyword of a BASIC statement. This will cause the extended BASIC mechanism to be invoked and it can then have a go at parsing
; the unknown word. Since all keywords in 128 BASIC mode have to be typed in letter by letter, the extended BASIC parser can support
; meaningful command names and is not limited to extensions of standard keywords as is the case with the mechanism offer by the
; ZX Interface 1.


; ===================
; Screen File Formats
; ===================
; The two screens available on the Spectrum 128, the normal screen in RAM bank 5 ($4000-$5AFF) and the shadow screen in
; RAM bank 7 ($C000-$FFFF), both use the same file format.
;
; ------------
; Display File
; ------------
; The display file consists of 3 areas, each consisting of 8 characters rows, with each row consisting of 8 pixel lines.
; Each pixel line consists of 32 cell columns, with each cell consisting of a byte that represents 8 pixels.
;
; The address of a particular cell is formed as follows:
;
;      +---+---+---+---+---+---+---+---+  +---+---+---+---+---+---+---+---+ 
;      | s | 1 | 0 | a | a | l | l | l |  | r | r | r | c | c | c | c | c |
;      +---+---+---+---+---+---+---+---+  +---+---+---+---+---+---+---+---+ 
; Bit:  15  14  13  12  11  10   9   8      7   6   5   4   3   2   1   0
;
; where: s     = Screen (0-1: 0=Normal screen, 1=Shadow Screen)
;        aa    = Area   (0-2)
;        rrr   = Row    (0-7)
;        lll   = Line   (0-7)
;        ccccc = Column (0-31)
;
; An area value of 3 denotes the attributes file, which consists of a different format.
;
; ---------------
; Attributes File
; ---------------
; The attributes file consists of 24 characters rows, with each row consisting of 32 cell columns.
; Each cell consisting of a byte that holds the colour information.
;
; The address of a particular cell is formed as follows:
;
;      +---+---+---+---+---+---+---+---+  +---+---+---+---+---+---+---+---+ 
;      | s | 1 | 0 | 1 | 1 | 0 | r | r |  | r | r | r | c | c | c | c | c |
;      +---+---+---+---+---+---+---+---+  +---+---+---+---+---+---+---+---+ 
; Bit:  15  14  13  12  11  10   9   8      7   6   5   4   3   2   1   0
;
; where: s     = Screen (0-1: 0=Normal screen, 1=Shadow Screen) 
;        rrrrr = Row    (0-23)
;        ccccc = Column (0-31)
;
;
; Each cell holds a byte of colour information:
;
;      +---+---+---+---+---+---+---+---+ 
;      | f | b | p | p | p | i | i | i |
;      +---+---+---+---+---+---+---+---+ 
; Bit:   7   6   5   4   3   2   1   0
;
; where: f   = Flash  (0-1: 0=Off, 1=On)
;        b   = Bright (0-1: 0=Off, 1=On)
;        ppp = Paper  (0-7: 0=Black, 1=Blue, 2=Red, 3=Magenta, 4=Green, 5=Cyan, 6=Yellow, 7=White)
;        iii = Ink    (0-7: 0=Black, 1=Blue, 2=Red, 3=Magenta, 4=Green, 5=Cyan, 6=Yellow, 7=White)
;
; -----------------------------------------------------------
; Address Conversion Between Display File and Attributes File
; -----------------------------------------------------------
; The address of the attribute cell corresponding to an address in the display file can be constructed by moving bits 11 to 12 (the area value)
; to bit positions 8 to 9, setting bit 10 to 0 and setting bits 11 to 12 to 1.
;
; The address of the display file character cell corresponding to an address in the attributes file can be constructed by moving bits 8 to 9 (the row value)
; to bit positions 11 to 12, and then setting bits 8 to 9 to 0.


; ==================
; Standard I/O Ports
; ==================

; --------
; Port $FE
; --------
; This controls the cassette interface, the speaker, the border colour and
; is used to read the keyboard.
;
; OUTPUT:
;
; Bit 0-2: Border colour  (0=Black, 1=Blue, 2=Red, 3=Magenta, 4=Green, 5=Cyan, 6=Yellow, 7=White).
; Bit 3  : MIC output     (1=Off, 0=On).
; Bit 4  : Speaker output (1=On, 0=Off).
; Bit 5-7: Not used.
;
; INPUT:
;
; Upper byte selects keyboard row to read.
;
;          Bit0  Bit1  Bit2  Bit3  Bit4    Bit4  Bit3  Bit2  Bit1  Bit0
;          ----  ----  ----  ----  ----    ----  ----  ----  ----  ----
; $F7FE =    1     2     3     4     5       6     7     8     9     0   = $EFFE
; $FBFE =    Q     W     E     R     T       Y     U     I     O     P   = $DFFE
; $FDFE =    A     S     D     F     G       H     J     K     L   ENTER = $BFFE
; $FEFE =  SHIFT   Z     X     C     V       B     N     M    SYM  SPACE = $7FFE
;
; Bit 0-4 : Key states (corresponding bit is 0 if the key is pressed).
; Bit 5   : Not used (always 1).
; Bit 6   : EAR input.
; Bit 7   : Not used (always 1).


; ======================
; Cassette Header Format
; ======================
;
; A file consists of a header block followed by a data block. The header block consists of 17 bytes and these describe the size
; and type of data that the data block contains.
;
; The header bytes have the following meaning:
;   Byte  $00    : File type - $00=Program, $01=Numeric array, $02=Character array, $03=Code/Screen$.
;   Bytes $01-$0A: File name, padding with trailing spaces.
;   Bytes $0B-$0C: Length of program/code block/screen$/array ($1B00 for screen$).
;   Bytes $0D-$0E: For a program, it holds the auto-run line number ($80 in byte $0E if no auto-run).
;                  For code block/screen$ it holds the start address ($4000 for screen$).
;                  For an array, it holds the variable name in byte $0E.
;   Bytes $0F-$10: Offset to the variables (i.e. length of program) if a program.


; ================================================
; AY-3-8912 Programmable Sound Generator Registers
; ================================================
; This is controlled through output I/O port $FFFD. It is driven from a 1.77345MHz clock.
;
; -----------------
; Registers 0 and 1 (Channel A Tone Generator)
; -----------------
; Forms a 12 bit pitch control for sound channel A. The basic unit of tone is the clock
; frequency divided by 16, i.e. 110.841KHz. With a 12 bit counter range, 4095 different
; frequencies from 27.067Hz to 110.841KHz (in increments of 27.067Hz) can be generated.
;
;   Bits 0-7  : Contents of register 0.
;   Bits 8-11 : Contents of lower nibble of register 1.
;   Bits 12-15: Not used.
;
; -----------------
; Registers 2 and 3 (Channel B Tone Generator)
; -----------------
; Forms a 12 bit pitch control for sound channel B.
;
;   Bits 0-7  : Contents of register 2.
;   Bits 8-11 : Contents of lower nibble of register 3.
;   Bits 12-15: Not used.
;
; -----------------
; Registers 4 and 5 (Channel C Tone Generator)
; -----------------
; Forms a 12 bit pitch control for sound channel C.
;
;   Bits 0-7  : Contents of register 4.
;   Bits 8-11 : Contents of lower nibble of register 5.
;   Bits 12-15: Not used.
;
; ----------
; Register 6 (Noise Generator)
; ----------
; The frequency of the noise is obtained in the PSG by first counting down the input
; clock by 16 (i.e. 110.841KHz), then by further counting down the result by the programmed
; 5 bit noise period value held in bits 0-4 of register 6. With a 5 bit counter range, 31 different
; frequencies from 3.576KHz to 110.841KHz (in increments of 3.576KHz) can be generated.
;
; ----------
; Register 7 (Mixer - I/O Enable)
; ----------
; This controls the enable status of the noise and tone mixers for the three channels,
; and also controls the I/O port used to drive the RS232 and Keypad sockets.
;
; Bit 0: Channel A Tone Enable (0=enabled).
; Bit 1: Channel B Tone Enable (0=enabled).
; Bit 2: Channel C Tone Enable (0=enabled).
; Bit 3: Channel A Noise Enable (0=enabled).
; Bit 4: Channel B Noise Enable (0=enabled).
; Bit 5: Channel C Noise Enable (0=enabled).
; Bit 6: I/O Port Enable (0=input, 1=output).
; Bit 7: Not used.
;
; ----------
; Register 8 (Channel A Volume)
; ----------
; This controls the volume of channel A.
;
; Bits 0-4: Channel A volume level.
; Bit 5   : 1=Use envelope defined by register 13 and ignore the volume setting.
; Bits 6-7: Not used.
;
; ----------
; Register 9 (Channel B Volume)
; ----------
; This controls the volume of channel B.
;
; Bits 0-4: Channel B volume level.
; Bit 5   : 1=Use envelope defined by register 13 and ignore the volume setting.
; Bits 6-7: Not used.
;
; -----------
; Register 10 (Channel C Volume)
; -----------
; This controls the volume of channel C.
;
; Bits 0-4: Channel C volume level.
; Bit 5   : 1=Use envelope defined by register 13 and ignore the volume setting.
; Bits 6-7: Not used.
;
; ------------------
; Register 11 and 12 (Envelope Period)
; ------------------
; These registers allow the frequency of the envelope to be selected.
; The frequency of the envelope is obtained in the PSG by first counting down
; the input clock by 256 (6.927KHz), then further counting down the result by the programmed
; 16 bit envelope period value. With a 16 bit counter range, 65535 different
; frequencies from 1.691Hz to 110.841KHz (in increments of 1.691Hz) can be generated.
;
; Bits 0-7 : Contents of register 11.
; Bits 8-15: Contents of register 12.
;
; -----------
; Register 13 (Envelope Shape)
; -----------
; This register allows the shape of the envelope to be selected.
; The envelope generator further counts down the envelope frequency by 16, producing
; a 16-state per cycle envelope pattern. The particular shape and cycle pattern of any
; desired envelope is accomplished by controlling the count pattern of the 4 bit counter
; and by defining a single cycle or repeat cycle pattern.
;
; Bit 0   : Hold.
; Bit 1   : Alternate.
; Bit 2   : Attack.
; Bit 3   : Continue.
; Bits 4-7: Not used.
;
; These control bits can produce the following envelope waveforms:
;
; Bit: 3 2 1 0
;      -------
;
;      0 0 X X  \                         Single decay then off.
;                \______________________  Used by W0 PLAY command.
;
;
;      0 1 X X   /|                       Single attack then off.
;               / |_____________________  Used by W1 PLAY command.
;
;
;      1 0 0 0  \ |\ |\ |\ |\ |\ |\ |\ |  Repeated decay.
;                \| \| \| \| \| \| \| \|  Used by W4 PLAY command.
;
;
;      1 0 0 1  \                         Single decay then off.
;                \______________________  Not used PLAY command (use W0 instead).
;
;
;      1 0 1 0  \  /\  /\  /\  /\  /\  /  Repeated decay-attack.
;                \/  \/  \/  \/  \/  \/   Used by W7 PLAY command.
;
;                  _____________________
;      1 0 1 1  \ |                       Single decay then hold.
;                \|                       Used by W2 PLAY command.
;
;
;      1 1 0 0   /| /| /| /| /| /| /| /|  Repeated attack.
;               / |/ |/ |/ |/ |/ |/ |/ |  Used by W5 PLAY command.
;
;                 ______________________
;      1 1 0 1   /                        Single attack then hold.
;               /                         Used by W3 PLAY command.
;
;
;      1 1 1 0   /\  /\  /\  /\  /\  /\   Repeated attack-decay.
;               /  \/  \/  \/  \/  \/  \  Used by W6 PLAY command.
;
;
;      1 1 1 1   /|                       Single attack then off.
;               / |_____________________  Not used by PLAY command (use W1 instead).
;
;
;           -->|  |<--  Envelope Period
;
; -----------
; Register 14 (I/O Port)
; -----------
; This controls the RS232 and Keypad sockets.
; Once the register has been selected, it can be read via port $FFFD and written via port $BFFD. The state of port $BFFD can also be read back.
;
; Bit 0: KEYPAD CTS (out) - 0=Spectrum ready to receive, 1=Busy
; Bit 1: KEYPAD RXD (out) - 0=Transmit high bit,         1=Transmit low bit
; Bit 2: RS232  CTS (out) - 0=Spectrum ready to receive, 1=Busy
; Bit 3: RS232  RXD (out) - 0=Transmit high bit,         1=Transmit low bit
; Bit 4: KEYPAD DTR (in)  - 0=Keypad ready for data,     1=Busy
; Bit 5: KEYPAD TXD (in)  - 0=Receive high bit,          1=Receive low bit
; Bit 6: RS232  DTR (in)  - 0=Device ready for data,     1=Busy
; Bit 7: RS232  TXD (in)  - 0=Receive high bit,          1=Receive low bit
;
; The RS232 port also doubles up as a MIDI port, with communications to MIDI devices occurring at 31250 baud.
; Commands and data can be sent to MIDI devices. Command bytes have the most significant bit set, whereas data bytes have it reset.


; ===============
; Socket Pin Outs
; ===============

; -----------------
; RS232/MIDI Socket
; -----------------
; The RS232/MIDI socket is controlled by register 14 of the AY-3-8912 sound generator.
;    _____________
;  _|             |
; |               | Front View
; |_  6 5 4 3 2 1 |
;   |_|_|_|_|_|_|_|
;
; Pin   Signal
; ---   ------
; 1     0V
; 2     TXD - In  (Bit 7)
; 3     RXD - Out (Bit 3)
; 4     DTR - In  (Bit 6)
; 5     CTS - Out (Bit 2)
; 6     12V

; -------------
; Keypad Socket
; -------------
; The keypad socket is controlled by register 14 of the AY-3-8912 sound generator.
; Only bits 0 and 5 are used for communications with the keypad (pins 2 and 5).
; Writing a 1 to bit 0 (pin 2) will eventually force the keypad to reset.
; Summary information about the keypad and its communications protocol can be found in the Spectrum 128 Service Manual and
; detailed description can be found at www.fruitcake.plus.com.
;    _____________
;  _|             |
; |               | Front View
; |_  6 5 4 3 2 1 |
;   |_|_|_|_|_|_|_|
;
; Pin   Signal
; ---   ------
; 1     0V
; 2     OUT - Out (Bit 0)
; 3     n/u - In  (Bit 4)
; 4     n/u - Out (Bit 1)
; 5     IN  - In  (Bit 5)
; 6     12V
;
; n/u = Not used for keypad communications.
;
; The keypad socket was later used by Amstrad to support a lightgun. There are no routines within the ROMs to handle communications
; to the lightgun so each game has to implement its own control software. Only bits 4 and 5 are used for communications with the lightgun (pins 3 and 5).
; The connections to the lightgun are as follows:
;
; Pin   Signal
; ---   ------
; 1     0V
; 2     n/u     - Out (Bit 0)
; 3     SENSOR  - In  (Bit 4)
; 4     n/u     - Out (Bit 1)
; 5     TRIGGER - In  (Bit 5)
; 6     12V
;
; n/u = Not used for lightgun communications.

; --------------
; Monitor Socket
; --------------
;
;         *******
;      ***       ***
;    **             **
;   * --7--     --6-- *
;  *         |         *
; *  --3--   8   --1--  *  Front View
; *          |          *
; *      /       \      *
;  *    5    |    4    *
;   *  /     2     \  *
;    **      |      **
;      ***       ***
;         *******
;
; The Investronica 2.1 PCB has the following pinout:
;
; Pin   Signal           Level
; ---   ------           -----
; 1     n/u              n/u
; 2     0 Volts          0V
; 3     Composite PAL    1.2V pk-pk (75 Ohms)
; 4     Composite Sync   TTL
; 5     Bright Output    TTL
; 6     Green            TTL
; 7     Red              TTL
; 8     Blue             TTL
;
; The Spanish Spectrum 128 User Manual states the pinout as follows:
;
; Pin   Signal           Level
; ---   ------           -----
; 1     Composite PAL    1.2V pk-pk (75 Ohms)
; 2     0 Volts          0V
; 3     Bright Output    TTL
; 4     Composite Sync   TTL
; 5     Vertical Sync    TTL
; 6     Green            TTL
; 7     Red              TTL
; 8     Blue             TTL
;
; n/u = Not used.
;
; A detailed description of the monitor socket and circuitry, and how to construct a suitable RGB SCART cable
; can be found at www.fruitcake.plus.com.

; --------------
; Edge Connector
; --------------
;
; Pin   Side A   Side B
; ---   ------   ------
; 1     A15      A14
; 2     A13      A12
; 3     D7       +5V
; 4     n/u      +9V
; 5     Slot     Slot
; 6     D0       0V
; 7     D1       0V
; 8     D2       /CLK
; 9     D6       A0
; 10    D5       A1
; 11    D3       A2
; 12    D4       A3
; 13    /INT     /IORQULA
; 14    /NMI     0V  (On 48K Spectrum = VIDEO 0V)
; 15    /HALT    n/u (On 48K Spectrum = VIDEO)
; 16    /MREQ    n/u (On 48K Spectrum = /Y)
; 17    /IORQ    n/u (On 48K Spectrum = V)
; 18    /RD      n/u (On 48K Spectrum = U)
; 19    /WR      /BUSREQ
; 20    -5V      /RESET
; 21    /WAIT    A7
; 22    +12V     A6
; 23    -12V     A5
; 24    /M1      A4
; 25    /RFSH    /ROMCS
; 26    A8       /BUSACK
; 27    A10      A9
; 28    n/u      A11
;
; Side A=Component Side, Side B=Underside.
; n/u = Not used.


; ==================================
; ROM 0 Similarities to Spectrum 128
; ==================================
; The following shows a comparision of the Spanish 128 ROM 0 to the Spectrum 128 ROM 0,
; showing which sections are identical between the two models.
;
; Spanish 128   Spectrum 128
; -----------   ------------
; $0000-$0000   $0000-$0000
; $0001-$0003   $0009-$000B
;     ...
; $000E-$01C6   $000E-$01C2
; $01C7-$01D1   $01C3-$01CA
; $01D2-$020C   $01D7-$0211
; $020D-$0236   $0216-$023F
; $0237-$023A   $0243-$0248
;     ...
; $0241-$0261   $0268-$0288
;     ...
; $0268-$0272   $0289-$0293
; $0273-$0278   $029E-$02A3
;     ...
; $027C-$0297   $02BA-$02D5
; $0298-$029A   $02DC-$02DE
; $029B-$0398   $02FC-$03FA
; $039A-$03BB   $040D-$042C
; $03BC-$0405   $0442-$048B
;     ...
; $0537-$0C72   $057D-$0CB8
;     ...
; $0C76-$0E09   $0CB9-$0E4C
; $0E0A-$1047   $0E58-$1095
;     ...
; $1072-$150A   $1096-$152E
; $150B-$15A4   $2174-$220D
; $15A5-$15AB   $2213-$2219
;     ...
; $15AF-$15CB   $221A-$2236
;     ...
; $15DD-$15E0   $223A-$223D
;     ...
; $1636-$163E   $228E-$2296
; $163F-$167A   $22AB-$22E6
;     ...
; $167D-$16C9   $22E9-$2335
; $16CA-$1ADE   $16DC-$1AF0
; $1ADF-$1AF4   $1B2E-$1B43
;     ...
; $1AFD-$1AFF   $1B44-$1B46
; $1B00-$1F3F   $1B71-$1FB0
;     ...
; $1F41-$1560   $1FB1-$1FD0
; $1F61-$1F7A   $1FD2-$1FEB
; $1F7B-$2100   $1FED-$2173
;     ...
; $285F-$2866   $2342-$2349
;     ...
; $2959-$2989   $3A3C-$3A6C
;     ...
; $29A2-$29C6   $234A-$236E
;     ...
; $2D22-$2D35   $2513-$2526
;     ...
; $2EC3-$2EF2   $2388-$23B7
; $2EF3-$2F07   $236F-$2383
;     ...
; $301B-$30D7   $23CB-$2487
; $30D8-$30E7   $2527-$2536
;     ...
; $3168-$317A   $23B8-$23CA
; $317B-$31EB   $2488-$24FA
;     ...
; $31F4-$3205   $2501-$2512
;     ...
; $33EC-$33F1   $3888-$388D
; $33F2-$3463   $3893-$3904
;     ...
; $3467-$346D   $3907-$390D
; $346E-$3502   $390E-$399F
;     ...
; $3506-$3507   $39BC-$39BD
; $3508-$354D   $39C5-$3A0A
;     ...
; $3550-$3580   $3A0B-$3A3B
;     ...

