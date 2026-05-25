

.386
.model flat, stdcall
.stack 4096

ExitProcess PROTO, dwExitCode:DWORD
include Irvine32.inc


PlaySoundA PROTO, pszSound:PTR BYTE, hmod:DWORD, dwFlags:DWORD
; Define the necessary flags in your constant/data section if not already present:
SND_ASYNC    = 0001h 
SND_FILENAME = 00020000h
SND_LOOP     = 0008h

; --- Windows API Declaration ---
Beep PROTO, dwFreq:DWORD, dwDuration:DWORD
Sound PROTO, frequency:DWORD
Mute PROTO
MuteCustom PROTO ; FIX: For low-level speaker mute

; --- Constant Definitions (Standard MASM format) ---
MAX_SCORES      EQU 10
MAX_NAME_LEN    EQU 30
TAB             EQU 9

; --- Game Board Constants (Iteration 3) ---
BOARD_SIZE      EQU 20
TILE_ROAD       EQU 1
TILE_BUILDING   EQU 0

; --- Game Modes Constants (NEW) ---
; Removed MODE_CAREER, MODE_TIME, MODE_ENDLESS. Using literal values 0, 1, 2 instead.
CAREER_WIN_SCORE EQU 100
TIME_MODE_LIMIT EQU 120 ; seconds



; --- Data Section ---
.data
; Menu strings
menuTitle BYTE "RUSH HOUR - The Taxi Game", 0
menuOpt1  BYTE "1. Start a New Game", 0
menuOpt2  BYTE "2. Continue the Game (Placeholder)", 0
menuOpt3  BYTE "3. Select Game Mode", 0 ; <-- UPDATED MENU OPTION
menuOpt4  BYTE "4. View the Leader Board", 0
menuOpt5  BYTE "5. Read the Instructions", 0
menuOpt6  BYTE "6. Exit", 0
menuPrompt BYTE "Enter your choice (1-6): ", 0
errorMsg  BYTE "Invalid choice. Please try again.", 0

; --- Visual Assets (Extended ASCII / "PC Emojis") ---
BUILDING_CHAR   EQU 178      ; ? (Textured Block)
ROAD_CHAR       EQU 250      ; ? (Middle Dot)

PERSON_CHAR     EQU 2        ; ? (Smiley Face)
OBSTACLE_CHAR   EQU 5        ; ? (Tree/Bush)
NPC_CAR_CHAR    EQU 219      ; ? (Solid Block)
BONUS_CHAR      EQU 36       ; $ 
; --- Visual Assets ---
; ...
DESTINATION_CHAR EQU 219      ;
; --- Color Definitions ---
; ...
DEST_COLOR      EQU lightGreen + (black * 16) ; FIX: Use LightGreen for visibility

; --- Color Definitions (Night City Theme) ---
; Roads: Dark Gray dots on Black
ROAD_COLOR      EQU gray + (black * 16)       

; Buildings: Light Gray texture on Dark Gray background
BUILDING_COLOR  EQU lightGray + (gray * 16)   

; Entities
PERSON_COLOR    EQU lightCyan + (black * 16)  ; Bright Cyan
DEST_COLOR      EQU lightGreen + (black * 16) ; Bright Green
NPC_CAR_COLOR   EQU lightRed + (black * 16)   ; Bright Red
BONUS_COLOR     EQU yellow + (black * 16)     ; Bright Yellow
OBSTACLE_COLOR  EQU green + (black * 16)      ; Green Trees
PASSENGER_COLOR EQU yellow + (black * 16)     ; Yellow Passengers

; ... (Keep your MAX constants: MAX_STATIC_OBJS, etc.) ...

; --- Data Section ---
.data
; ... (Keep existing variables) ...

; --- Visual Menu Assets (FIXED) ---
menuBorder   BYTE "====================================================", 0
menuTitleArt BYTE "       R  U  S  H     H  O  U  R     T  A  X  I    ", 0

; Taxi ASCII Art (Simplified to prevent distortion)
taxiArt1     BYTE "      _______      ", 0
taxiArt2     BYTE "     /  _ _  \     ", 0
taxiArt3     BYTE "   _|___|_|___|_   ", 0
taxiArt4     BYTE "  /  o       o  \  ", 0
taxiArt5     BYTE "  \_____________/  ", 0
taxiArt6     BYTE "    O         O    ", 0

; Styled Options
txtOption1   BYTE ". Start a New Game", 0
txtOption2   BYTE ". Continue the Game (Placeholder)", 0
txtOption3   BYTE ". Select Game Mode", 0
txtOption4   BYTE ". View the Leader Board", 0
txtOption5   BYTE ". Read the Instructions", 0
txtOption6   BYTE ". Exit", 0

num1 BYTE "1", 0
num2 BYTE "2", 0
num3 BYTE "3", 0
num4 BYTE "4", 0
num5 BYTE "5", 0
num6 BYTE "6", 0
; ... (Rest of your data) ...

; Instructions strings
instTitle BYTE "Game Instructions", 0
instBody1 BYTE "You are a taxi driver. Pick up passengers (P) and drop them", 0
instBody2 BYTE "at their destinations (GREEN) to earn points (+10).", 0
instBody3 BYTE "Avoid hitting people (-5), obstacles, and other cars.", 0
instBody4 BYTE "Press 'Q' to return to the Main Menu.", 0
newLine   BYTE 0dh, 0ah, 0

; Game State Variable
gameState       DWORD 0 ; 0=Menu, 1=Instructions, 2=Setup, 3=ModeSelect (NEW), 4=Leaderboard, 5=GameRun, 6=Paused, 7=GameOver (NEW), 8=GameWin (NEW), 99=Exit
game_initialized DWORD 0

; --- Game Modes Data (NEW) ---
gameMode        DWORD 0 ; Current mode (0=Career, 1=Time, 2=Endless)
timeLimit       DWORD TIME_MODE_LIMIT
timerTick       DWORD 0           ; Counter for timer update rate (approx 50 ticks/second)
modeMsg         BYTE "Mode: ", 0
modeNameCareer  BYTE "Career", 0
modeNameTime    BYTE "Time Attack", 0
modeNameEndless BYTE "Endless", 0
modeMenuTitle   BYTE "SELECT GAME MODE", 0
modeOpt1        BYTE "1. Career Mode (Goal: Achieve 100 points)", 0
modeOpt2        BYTE "2. Time Mode (Goal: Max score in 120 seconds)", 0
modeOpt3        BYTE "3. Endless Mode (Max score, unlimited time)", 0
modePrompt      BYTE "Enter mode choice (1-3): ", 0
gameOverMsg     BYTE "GAME OVER! Time expired. Final ", 0
winMsg          BYTE "CAREER COMPLETE! Final ", 0
; --- Data Section Update (Add Filename) ---
.data
WavFileName BYTE "merx-market-song-33936.wav", 0 ; Path to your WAV fil



; --- Leaderboard Data (Iteration 2) ---
highScores      DWORD MAX_SCORES DUP(0)
playerNames     BYTE (MAX_NAME_LEN * MAX_SCORES) DUP(?)
scoresRead      DWORD 0

; File I/O strings
fileName        BYTE "highscores.txt", 0
fileHandle      DWORD ?
noScoresMsg     BYTE "Leaderboard is empty.", 0
leaderTitle     BYTE "--- TOP 10 RUSH HOUR DRIVERS ---", 0
tempBuffer      BYTE 30 DUP(?)
fileCreationMsg BYTE "File not found. Creating empty highscores.txt...", 0
fileWriteErrorMsg BYTE "Error: Failed to write to highscores.txt", 0

; --- Game Board Data (Iteration 3) ---
gameBoard       BYTE (BOARD_SIZE * BOARD_SIZE) DUP(?)
boardInitMsg    BYTE "Initializing game board (Roads: White, Buildings: Black)...", 0
; --- Save/Load Data (NEW) ---
saveFileName    BYTE "savegame.dat", 0
saveMsg         BYTE "Game Saved Successfully!", 0
loadErrMsg      BYTE "No saved game found.", 0

; We need to save these variables to resume correctly
; (The arrays gameBoard, PassengerData, etc. will also be saved)

; --- Taxi Selection Data (Iteration 3) ---
taxiPrompt      BYTE "Select your taxi color:", 0
taxiOptRed      BYTE "R - Red Taxi (Slower, less obstacle penalty)", 0
taxiOptYellow   BYTE "Y - Yellow Taxi (Faster, higher obstacle penalty)", 0
taxiOptRandom   BYTE "A - Assign Randomly", 0
namePrompt      BYTE "Enter your driver name (max 15 chars): ", 0
nameInputBuffer BYTE 50 DUP(?)
selectedTaxi    BYTE ?
playerColor     BYTE ?              ; Set in TaxiSelection
playerChar      BYTE 219            ; Block character

; --- Player State Data (Iteration 4) ---
playerX         DWORD 0
playerY         DWORD 0
score           DWORD 0
scoreMsg        BYTE "Score: ", 0
pausedMsg BYTE "GAME PAUSED. Press 'P' to Resume, 'S' to Save, 'Q' to Quit.", 0
droppedPassengers DWORD 0           ; Counter for speed increase

; --- Passenger Constants & Data (Iteration 5) ---
MAX_PASSENGERS  EQU 5
PASSENGER_CHAR  EQU 'P'
PASSENGER_COLOR EQU yellow + (black * 16)

PassengerData   BYTE MAX_PASSENGERS DUP(0) ; 0=waiting, 1=picked up, 2=delivered
PassengerX      BYTE MAX_PASSENGERS DUP(0)
PassengerY      BYTE MAX_PASSENGERS DUP(0)

DestX           DWORD 0
DestY           DWORD 0
isCarrying      DWORD 0

; --- Obstacle & Character Data ---
NPC_CAR_CHAR    EQU 219               ; Block character for NPC cars

MAX_STATIC_OBJS EQU 10
StaticX         BYTE MAX_STATIC_OBJS DUP(0)
StaticY         BYTE MAX_STATIC_OBJS DUP(0)
StaticType      BYTE MAX_STATIC_OBJS DUP(0) ; 1=Person, 2=Obstacle (Tree/Box)

; --- NPC Car Data ---
MAX_NPC_CARS    EQU 3
NPC_CarX        BYTE MAX_NPC_CARS DUP(0)
NPC_CarY        BYTE MAX_NPC_CARS DUP(0)
NPC_CAR_COLOR   EQU 12 + (black * 16) ; Light Red/Purple (not Red or Yellow)
NPC_CarDir      BYTE MAX_NPC_CARS DUP(0) ; 0=Up, 1=Down, 2=Left, 3=Right

; --- Bonus Item Data ---
MAX_BONUS_ITEMS EQU 3
BONUS_CHAR      EQU '$'
BONUS_COLOR     EQU yellow + (black * 16) ; FIX: Replaced undefined brightYellow with defined yellow
BonusX          BYTE MAX_BONUS_ITEMS DUP(0)
BonusY          BYTE MAX_BONUS_ITEMS DUP(0)

; --- Audio Constants ---
FREQ_CRASH_HIGH  EQU 500
DUR_CRASH_SHORT  EQU 150

FREQ_PICKUP      EQU 800
DUR_PICKUP       EQU 200

FREQ_DROP_SUCCESS EQU 1200
DUR_DROP_SUCCESS EQU 300

FREQ_PAUSE_LOW   EQU 200
DUR_PAUSE_SHORT  EQU 50

FREQ_PAUSE_HIGH  EQU 400
DUR_PAUSE_LONG   EQU 100

; --- Game Mode and Stats Variables ---
currentMode     DWORD 0     ; 0=Career, 1=Time, 2=Endless
droppedCount    DWORD 0     ; Tracks successful drop-offs for speed increase
timeLeft        DWORD 120   ; Time limit (initially 120)

; --- Strings for Score Panel ---
modeNameStr     BYTE "Mode: ", 0
timeMsg         BYTE "Time: ", 0

; --- Code Section ---
.code

; =======================================================
; Procedures from Iteration 1 & 2 (Menu & Leaderboard)
; =======================================================

; DisplayMenu, Abs, DisplayInstructions, HandleMenuInput: (Unchanged)
;-----------------------------------------------------
;-----------------------------------------------------
DisplayMenu PROC
; Displays the menu with fixed coordinates to prevent distortion.
;-----------------------------------------------------
    CALL Clrscr 

    ; --- Draw Header (Cyan) ---
    MOV EAX, lightCyan + (black * 16)
    CALL SetTextColor
    
    MOV DH, 2 ; Row 2
    MOV DL, 15 ; Center X
    CALL Gotoxy
    MOV EDX, OFFSET menuBorder
    CALL WriteString

    ; --- Draw Title (Light Red) ---
    MOV EAX, lightRed + (black * 16)
    CALL SetTextColor
    
    MOV DH, 3 ; Row 3
    MOV DL, 15
    CALL Gotoxy
    MOV EDX, OFFSET menuTitleArt
    CALL WriteString

    ; --- Draw Header Bottom (Cyan) ---
    MOV EAX, lightCyan + (black * 16)
    CALL SetTextColor
    
    MOV DH, 4 ; Row 4
    MOV DL, 15
    CALL Gotoxy
    MOV EDX, OFFSET menuBorder
    CALL WriteString

    ; --- Draw Taxi Art (Yellow) - FIXED POSITIONS ---
    MOV EAX, yellow + (black * 16)
    CALL SetTextColor
    
    ; Draw lines manually to ensure they stack perfectly
    MOV DL, 25 ; Center the car (Column 25)

    MOV DH, 6  ; Row 6
    CALL Gotoxy
    MOV EDX, OFFSET taxiArt1
    CALL WriteString
    
    MOV DH, 7  ; Row 7
    MOV DL, 25
    CALL Gotoxy
    MOV EDX, OFFSET taxiArt2
    CALL WriteString
    
    MOV DH, 8  ; Row 8
    MOV DL, 25
    CALL Gotoxy
    MOV EDX, OFFSET taxiArt3
    CALL WriteString
    
    MOV DH, 9  ; Row 9
    MOV DL, 25
    CALL Gotoxy
    MOV EDX, OFFSET taxiArt4
    CALL WriteString

    MOV DH, 10 ; Row 10
    MOV DL, 25
    CALL Gotoxy
    MOV EDX, OFFSET taxiArt5
    CALL WriteString
    
    MOV DH, 11 ; Row 11
    MOV DL, 25
    CALL Gotoxy
    MOV EDX, OFFSET taxiArt6
    CALL WriteString

    ; --- Draw Options (White with Green Numbers) ---
    ; Start drawing options at Row 14 so they don't overlap the car
    
    ; Option 1
    MOV DH, 14
    MOV DL, 20
    CALL Gotoxy
    MOV EAX, lightGreen + (black * 16) 
    CALL SetTextColor
    MOV EDX, OFFSET num1
    CALL WriteString
    MOV EAX, white + (black * 16)      
    CALL SetTextColor
    MOV EDX, OFFSET txtOption1
    CALL WriteString

    ; Option 2
    MOV DH, 15
    MOV DL, 20
    CALL Gotoxy
    MOV EAX, lightGreen + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET num2
    CALL WriteString
    MOV EAX, gray + (black * 16)       
    CALL SetTextColor
    MOV EDX, OFFSET txtOption2
    CALL WriteString

    ; Option 3
    MOV DH, 16
    MOV DL, 20
    CALL Gotoxy
    MOV EAX, lightGreen + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET num3
    CALL WriteString
    MOV EAX, white + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET txtOption3
    CALL WriteString

    ; Option 4
    MOV DH, 17
    MOV DL, 20
    CALL Gotoxy
    MOV EAX, lightGreen + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET num4
    CALL WriteString
    MOV EAX, white + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET txtOption4
    CALL WriteString

    ; Option 5
    MOV DH, 18
    MOV DL, 20
    CALL Gotoxy
    MOV EAX, lightGreen + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET num5
    CALL WriteString
    MOV EAX, white + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET txtOption5
    CALL WriteString

    ; Option 6
    MOV DH, 19
    MOV DL, 20
    CALL Gotoxy
    MOV EAX, lightRed + (black * 16)   
    CALL SetTextColor
    MOV EDX, OFFSET num6
    CALL WriteString
    MOV EAX, white + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET txtOption6
    CALL WriteString

    ; --- Draw Prompt ---
    MOV DH, 22
    MOV DL, 20
    CALL Gotoxy
    MOV EAX, cyan + (black * 16)
    CALL SetTextColor
    MOV EDX, OFFSET menuPrompt
    CALL WriteString
    
    ; Reset color to white for input
    MOV EAX, white + (black * 16)
    CALL SetTextColor

    RET
DisplayMenu ENDP
Abs PROC
    CMP EAX, 0
    JGE abs_done
    NEG EAX
abs_done:
    RET
Abs ENDP



DisplayInstructions PROC
    CALL Clrscr
    MOV EDX, OFFSET instTitle
    CALL WriteString
    CALL Crlf
    CALL Crlf
    MOV EDX, OFFSET instBody1
    CALL WriteString
    CALL Crlf
    MOV EDX, OFFSET instBody2
    CALL WriteString
    CALL Crlf
    MOV EDX, OFFSET instBody3
    CALL WriteString
    CALL Crlf
    CALL Crlf
    MOV EDX, OFFSET instBody4
    CALL WriteString
    CALL Crlf
    CALL Crlf
    .WHILE TRUE
        CALL ReadChar
        MOV AL, AL
        CMP AL, 'Q'
        JE  exitInst
        CMP AL, 'q'
        JE  exitInst
    .ENDW
exitInst:
    MOV gameState, 0
    RET
DisplayInstructions ENDP

;-----------------------------------------------------
SaveGame PROC
; Saves player state, score, and board configuration to file.
;-----------------------------------------------------
    PUSHAD
    
    MOV EDX, OFFSET saveFileName
    CALL CreateOutputFile
    MOV fileHandle, EAX
    
    CMP EAX, INVALID_HANDLE_VALUE
    JE save_fail

    ; 1. Save Player Variables (One by one)
    MOV EAX, fileHandle
    MOV EDX, OFFSET playerX
    MOV ECX, 4 ; 4 bytes for DWORD
    CALL WriteToFile
    
    MOV EDX, OFFSET playerY
    MOV ECX, 4
    CALL WriteToFile
    
    MOV EDX, OFFSET score
    MOV ECX, 4
    CALL WriteToFile
    
    MOV EDX, OFFSET currentMode
    MOV ECX, 4
    CALL WriteToFile
    
    MOV EDX, OFFSET timeLeft
    MOV ECX, 4
    CALL WriteToFile
    
    MOV EDX, OFFSET droppedCount
    MOV ECX, 4
    CALL WriteToFile
    
    MOV EDX, OFFSET isCarrying
    MOV ECX, 4
    CALL WriteToFile
    
    MOV EDX, OFFSET DestX
    MOV ECX, 4
    CALL WriteToFile
    
    MOV EDX, OFFSET DestY
    MOV ECX, 4
    CALL WriteToFile

    ; 2. Save Arrays (Bulk write)
    ; Save GameBoard (400 bytes) - Keeps walls/roads static
    MOV EDX, OFFSET gameBoard
    MOV ECX, BOARD_SIZE * BOARD_SIZE
    CALL WriteToFile
    
    ; Save Passenger Data
    MOV EDX, OFFSET PassengerData
    MOV ECX, MAX_PASSENGERS
    CALL WriteToFile
    
    MOV EDX, OFFSET PassengerX
    MOV ECX, MAX_PASSENGERS
    CALL WriteToFile
    
    MOV EDX, OFFSET PassengerY
    MOV ECX, MAX_PASSENGERS
    CALL WriteToFile

    ; Save Static Obstacles
    MOV EDX, OFFSET StaticX
    MOV ECX, MAX_STATIC_OBJS
    CALL WriteToFile
    MOV EDX, OFFSET StaticY
    MOV ECX, MAX_STATIC_OBJS
    CALL WriteToFile

    CALL CloseFile
    
    ; Feedback
    MOV DH, 10
    MOV DL, 20
    CALL Gotoxy
    MOV EDX, OFFSET saveMsg
    CALL WriteString
    MOV EAX, 1000
    CALL Delay

save_fail:
    POPAD
    RET
SaveGame ENDP

;-----------------------------------------------------
LoadGame PROC
; Loads game state from file. Returns EAX=1 if success, 0 if fail.
;-----------------------------------------------------
    PUSHAD
    
    MOV EDX, OFFSET saveFileName
    CALL OpenInputFile
    MOV fileHandle, EAX
    
    CMP EAX, INVALID_HANDLE_VALUE
    JE load_fail

    ; 1. Read Player Variables
    MOV EAX, fileHandle
    MOV EDX, OFFSET playerX
    MOV ECX, 4 
    CALL ReadFromFile
    
    MOV EDX, OFFSET playerY
    MOV ECX, 4
    CALL ReadFromFile
    
    MOV EDX, OFFSET score
    MOV ECX, 4
    CALL ReadFromFile
    
    MOV EDX, OFFSET currentMode
    MOV ECX, 4
    CALL ReadFromFile
    
    MOV EDX, OFFSET timeLeft
    MOV ECX, 4
    CALL ReadFromFile
    
    MOV EDX, OFFSET droppedCount
    MOV ECX, 4
    CALL ReadFromFile
    
    MOV EDX, OFFSET isCarrying
    MOV ECX, 4
    CALL ReadFromFile
    
    MOV EDX, OFFSET DestX
    MOV ECX, 4
    CALL ReadFromFile
    
    MOV EDX, OFFSET DestY
    MOV ECX, 4
    CALL ReadFromFile

    ; 2. Read Arrays
    MOV EDX, OFFSET gameBoard
    MOV ECX, BOARD_SIZE * BOARD_SIZE
    CALL ReadFromFile
    
    MOV EDX, OFFSET PassengerData
    MOV ECX, MAX_PASSENGERS
    CALL ReadFromFile
    
    MOV EDX, OFFSET PassengerX
    MOV ECX, MAX_PASSENGERS
    CALL ReadFromFile
    
    MOV EDX, OFFSET PassengerY
    MOV ECX, MAX_PASSENGERS
    CALL ReadFromFile
    
    MOV EDX, OFFSET StaticX
    MOV ECX, MAX_STATIC_OBJS
    CALL ReadFromFile
    MOV EDX, OFFSET StaticY
    MOV ECX, MAX_STATIC_OBJS
    CALL ReadFromFile

    CALL CloseFile
    
    ; Success flag
    POPAD
    MOV EAX, 1 
    RET

load_fail:
    ; Display Error
    CALL Clrscr
    MOV EDX, OFFSET loadErrMsg
    CALL WriteString
    MOV EAX, 2000
    CALL Delay
    POPAD
    MOV EAX, 0
    RET
LoadGame ENDP

HandleMenuInput PROC
    CALL ReadChar
    SUB AL, '0'
    MOVZX EAX, AL
    CMP EAX, 1
    JL  invalidInput
    CMP EAX, 6
    JG  invalidInput
    
    CMP EAX, 1
    JE  setNewGame

    CMP EAX, 2 ; <--- FIX: Enable Option 2
    JE  setContinueGame
    
    CMP EAX, 3 ; <--- NEW: Mode Selection
    JE  setModeSelection

    CMP EAX, 4
    JE  setLeaderboard
    CMP EAX, 5
    JE  setInstructions
    CMP EAX, 6
    JE  setExit
    
    JMP invalidInput

setContinueGame:
    MOV gameState, 9 ; State 9 = Attempt Load
    JMP inputDone
setNewGame:
    MOV gameState, 2
    JMP inputDone

setModeSelection: ; <--- NEW
    MOV gameState, 3
    JMP inputDone

setLeaderboard:
    MOV gameState, 4
    JMP inputDone

setInstructions:
    MOV gameState, 1
    JMP inputDone

setExit:
    MOV gameState, 99
    JMP inputDone

invalidInput:
    CALL Crlf
    MOV EDX, OFFSET errorMsg
    CALL WriteString
    CALL Crlf
    MOV EAX, 100
    CALL Delay
    JMP inputDone

inputDone:
    RET
HandleMenuInput ENDP


WriteLeaderboard PROC
    PUSHAD
    
    MOV EDX, OFFSET fileName
    CALL CreateOutputFile
    MOV fileHandle, EAX
    
    CMP EAX, 0
    JE  fileWriteError

    MOV ESI, OFFSET playerNames
    MOV EDI, OFFSET highScores
    MOV ECX, scoresRead

writeLoop:
    PUSH ECX
    
    MOV EDX, ESI
    CALL WriteString
    CALL Crlf

    MOV EAX, [EDI]
    CALL WriteInt
    CALL Crlf

    ADD ESI, MAX_NAME_LEN
    ADD EDI, 4

    POP ECX
    LOOP writeLoop

    CALL CloseFile
    JMP done

fileWriteError:
    CALL Crlf
    MOV EDX, OFFSET fileWriteErrorMsg
    CALL WriteString
    CALL Crlf

done:
    POPAD
    RET
WriteLeaderboard ENDP

CheckAndUpdateLeaderboard PROC
    PUSHAD
    
    ; --- 1. Read existing high scores from file ---
    CALL ReadLeaderboard ; Fills highScores[] and playerNames[] arrays.
    
    CMP score, 0
    JLE finished_check ; Skip if score is 0 or negative

    ; --- 2. Check if current score qualifies for Top 10 ---
    MOV EAX, score
    MOV EBX, MAX_SCORES
    DEC EBX ; Start comparison from the last (lowest) element (index 9)
    
check_score_loop:
    CMP EBX, 0
    JL  finished_check ; Check score failure
    
    MOV EDI, EBX        ; EDI = current array index (0-9)
    MOV ESI, [highScores + EDI * 4] ; Load score at index EDI
    
    CMP EAX, ESI        ; Compare Current Score (EAX) to High Score (ESI)
    JG  insert_score    ; If current score is GREATER, we insert it
    
    DEC EBX
    JMP check_score_loop
insert_score:
    ; --- 3. Shift scores down to make room for new score at index EBX ---
    ; EBX holds the index where the new score will be inserted.
    
    PUSH EAX ; Save current score (EAX)
    
    MOV ECX, MAX_SCORES ; Counter (10 elements)
    MOV ESI, MAX_SCORES - 1 ; Start from the lowest element (index 9)
    
shift_loop:
    CMP ESI, EBX
    JLE start_insertion ; Stop shifting if index matches insertion point
    
    ; Shift score down (Score[i] = Score[i-1])
    MOV EAX, [highScores + ESI * 4 - 4] ; Load previous score
    MOV [highScores + ESI * 4], EAX      ; Save to current index
    
    ; Shift name down (Name[i] = Name[i-1])
    PUSH ESI ; Save index
    MOV ESI, OFFSET playerNames
    CALL ShiftNameDown ; Copy name block
    POP ESI
    
    DEC ESI
    JMP shift_loop

start_insertion:
    POP EAX ; Restore current score
    
    ; --- 4. Insert New Score and Name ---
    MOV [highScores + EBX * 4], EAX
    
    ; Insert Name: Copy nameInputBuffer to playerNames[EBX]
    PUSH EAX
    MOV EAX, EBX
    CALL CopyNameBlock
    POP EAX

    ; --- 5. Overwrite the highscores.txt file ---
    CALL WriteLeaderboard

finished_check:
    POPAD
    RET
CheckAndUpdateLeaderboard ENDP

ShiftNameDown PROC
; Shifts playerNames[ESI] down from playerNames[ESI-1]
; Assumes ESI holds the index (0-9) to copy TO.
    PUSHAD
    
    MOV EDI, ESI ; EDI = Destination index
    
    ; Calculate Destination Offset (EDI)
    MOV EAX, MAX_NAME_LEN
    MUL EDI
    MOV EDI, EAX ; EDI = Offset of Destination Name Block
    ADD EDI, OFFSET playerNames
    
    ; Calculate Source Offset (ESI) - from index (original index - 1)
    DEC EAX
    MOV ESI, EAX ; ESI = Offset of Source Name Block
    ADD ESI, OFFSET playerNames

    MOV ECX, MAX_NAME_LEN
    CLD ; Set direction flag forward
    REP MOVSB
    
    POPAD
    RET
ShiftNameDown ENDP

CopyNameBlock PROC
; Copies nameInputBuffer (current player name) to playerNames[EAX]
; Assumes EAX holds the index (0-9).
    PUSHAD
    
    MOV EBX, EAX ; EBX = Index
    MOV EAX, MAX_NAME_LEN
    MUL EBX
    MOV EDI, EAX ; EDI = Offset of Destination Name Block
    ADD EDI, OFFSET playerNames ; Destination
    
    MOV ESI, OFFSET nameInputBuffer ; Source
    MOV ECX, MAX_NAME_LEN
    CLD
    REP MOVSB
    
    POPAD
    RET
CopyNameBlock ENDP

DisplayLeaderboard PROC
    PUSHAD
    
    CALL Clrscr
    MOV EDX, OFFSET leaderTitle
    CALL WriteString
    CALL Crlf
    CALL Crlf

    CMP scoresRead, 0
    JE  noScoresFound

    MOV ESI, OFFSET playerNames
    MOV EDI, OFFSET highScores
    MOV ECX, scoresRead
    MOV EBX, 1

displayLoop:
    PUSH ECX
    
    MOV EAX, EBX
    CALL WriteDec
    MOV AL, '.'
    CALL WriteChar

    MOV EDX, ESI
    CALL WriteString

    MOV AL, TAB
    CALL WriteChar

    MOV EAX, [EDI]
    CALL WriteDec
    CALL Crlf

    ADD ESI, MAX_NAME_LEN
    ADD EDI, 4
    INC EBX

    POP ECX
    LOOP displayLoop

    JMP displayDone

noScoresFound:
    MOV EDX, OFFSET noScoresMsg
    CALL WriteString
    CALL Crlf

displayDone:
    CALL Crlf
    MOV EDX, OFFSET instBody4
    CALL WriteString
    CALL Crlf
    
    .WHILE TRUE
        CALL ReadChar
        MOV AL, AL
        CMP AL, 'Q'
        JE  exitLeaderboard
        CMP AL, 'q'
        JE  exitLeaderboard
    .ENDW

exitLeaderboard:
    MOV gameState, 0
    POPAD
    RET
DisplayLeaderboard ENDP

; =======================================================
; Game Mode Selection (NEW State 3)
; =======================================================
DisplayModeMenu PROC
    PUSHAD
    CALL Clrscr
    MOV EDX, OFFSET modeMenuTitle
    CALL WriteString
    CALL Crlf
    CALL Crlf
    MOV EDX, OFFSET modeOpt1
    CALL WriteString
    CALL Crlf
    MOV EDX, OFFSET modeOpt2
    CALL WriteString
    CALL Crlf
    MOV EDX, OFFSET modeOpt3
    CALL WriteString
    CALL Crlf
    CALL Crlf
    MOV EDX, OFFSET modePrompt
    CALL WriteString
    POPAD
    RET
DisplayModeMenu ENDP

HandleModeInput PROC
    PUSHAD
    CALL ReadChar
    SUB AL, '0'
    MOVZX EAX, AL
    
    CMP EAX, 1
    JL  invalidModeInput
    CMP EAX, 3
    JG  invalidModeInput
    
    ; Set gameMode (0, 1, or 2)
    DEC EAX ; EAX is now 0, 1, or 2
    MOV gameMode, EAX
    
    ; Return to main menu (State 0)
    MOV gameState, 0
    JMP modeInputDone

invalidModeInput:
    CALL Crlf
    MOV EDX, OFFSET errorMsg
    CALL WriteString
    CALL Crlf
    MOV EAX, 100
    CALL Delay
    
modeInputDone:
    POPAD
    RET
HandleModeInput ENDP


; =======================================================
; Procedures from Iteration 5-7 (Audio, Board Drawing, Logic)
; =======================================================

; --- Audio Procedures ---
PlayCrashSound PROC
    PUSHAD
    MOV EAX, FREQ_CRASH_HIGH
    MOV EBX, DUR_CRASH_SHORT
    INVOKE Beep, EAX, EBX
    POPAD
    RET
PlayCrashSound ENDP

PlayPickupSound PROC
    PUSHAD
    MOV EAX, FREQ_PICKUP
    MOV EBX, DUR_PICKUP
    INVOKE Beep, EAX, EBX
    POPAD
    RET
PlayPickupSound ENDP

PlayDropSound PROC
    PUSHAD
    MOV EAX, FREQ_DROP_SUCCESS
    MOV EBX, DUR_DROP_SUCCESS
    INVOKE Beep, EAX, EBX
    POPAD
    RET
PlayDropSound ENDP

PlayPauseSound PROC
    PUSHAD
    MOV EAX, FREQ_PAUSE_LOW
    MOV EBX, DUR_PAUSE_SHORT
    INVOKE Beep, EAX, EBX
    POPAD
    RET
PlayPauseSound ENDP

PlayResumeSound PROC
    PUSHAD
    MOV EAX, FREQ_PAUSE_HIGH
    MOV EBX, DUR_PAUSE_LONG
    INVOKE Beep, EAX, EBX
    POPAD
    RET
PlayResumeSound ENDP


PlayBackgroundMusic PROC
; Plays the .wav file continuously in the background.
;-----------------------------------------------------
    PUSHAD
    
    ; Load filename address into pszSound parameter
    MOV EAX, OFFSET WavFileName ; pszSound: Pointer to filename
    
    ; Use the INVOKE directive to call PlaySoundA
    INVOKE PlaySoundA, 
           EAX,                ; pszSound (Pointer to WAV file name)
           NULL,               ; hmod (NULL handles default process)
           SND_FILENAME OR SND_ASYNC OR SND_LOOP ; dwFlags
           
    ; The background music will now loop asynchronously, so we don't need the Delay.
    
    POPAD
    RET
PlayBackgroundMusic ENDP

PlayEndGameSound PROC ; <--- NEW
; Distinct sound for game ending (low, sustained tones)
    PUSHAD
    MOV EAX, 100 ; Low frequency
    MOV EBX, 500 ; Long duration
    INVOKE Beep, EAX, EBX
    MOV EAX, 50 ; Even lower frequency
    MOV EBX, 500
    INVOKE Beep, EAX, EBX
    POPAD
    RET
PlayEndGameSound ENDP

MuteCustom PROC
; Low-level hardware method to stop the PC speaker (replaces Mute)
    PUSH AX
    PUSH DX

    ; Read control register 61h
    MOV AL, 0B6h ; Address of control register (61h)
    IN AL, 61h   ; Read current value into AL
    
    ; Turn off bit 1 and bit 0 (speaker control bits)
    AND AL, 11111100b
    
    ; Write the new value back to turn the speaker off
    MOV DX, 61h
    OUT DX, AL
    
    POP DX
    POP AX
    RET
MuteCustom ENDP

; --- Board/Element Drawing Procedures ---

DrawPassenger PROC
; Draws the passenger at X (BL) and Y (DL).
; Input: BL = X coordinate, DL = Y coordinate
    PUSHAD
    
    MOV DH, DL ; Set DH = Y coordinate
    MOV DL, BL ; Set DL = X coordinate
    ADD DH, 2  ; Apply offset (Y+2 for board top)
    CALL Gotoxy
    
    MOV AL, PASSENGER_COLOR
    CALL SetTextColor
    MOV AL, PASSENGER_CHAR
    CALL WriteChar
    
    POPAD
    RET
DrawPassenger ENDP

DrawPlayer PROC
    PUSHAD
    MOV EAX, playerY
    MOV DH, AL
    MOV EAX, playerX
    MOV DL, AL
    ADD DH, 2
    CALL Gotoxy
    MOV AL, playerColor
    CALL SetTextColor
    MOV AL, playerChar
    CALL WriteChar
    POPAD
    RET
DrawPlayer ENDP

;-----------------------------------------------------
ClearPlayer PROC
; Clears player position by restoring the ROAD texture.
;-----------------------------------------------------
    PUSHAD
    MOV EAX, playerY
    MOV DH, AL
    MOV EAX, playerX
    MOV DL, AL
    ADD DH, 2
    CALL Gotoxy
    
    ; Restore Asphalt Visual
    MOV EAX, ROAD_COLOR
    CALL SetTextColor
    MOV AL, ROAD_CHAR 
    CALL WriteChar
    
    POPAD
    RET
ClearPlayer ENDP

RedrawStaticObject PROC
; Redraws the static object at index EDI.
; Input: EDI = index of the object (0-9)
    PUSHAD
    
    ; Index is in EDI
    MOV AL, [StaticType + EDI]
    
    ; Determine Char/Color based on Type
    CMP AL, 1 ; Type 1: Person
    JE redraw_person
    
    ; Redraw Obstacle (Type 2: Tree/Box)
    MOV AL, white + (black * 16) ; White char on Black BG
    CALL SetTextColor
    MOV AL, OBSTACLE_CHAR
    JMP draw_static_obj
    
redraw_person:
    MOV AL, PERSON_COLOR
    CALL SetTextColor
    MOV AL, PERSON_CHAR
    
draw_static_obj:
    ; Get Coordinates (StaticX[EDI], StaticY[EDI])
    MOVZX EBX, BYTE PTR [StaticX + EDI]
    MOVZX EDX, BYTE PTR [StaticY + EDI]

    MOV DH, DL ; DH = Y
    MOV DL, BL ; DL = X
    ADD DH, 2
    CALL Gotoxy
    CALL WriteChar
    
    POPAD
    RET
RedrawStaticObject ENDP

DrawDestination PROC
    ; Draws the destination marker at DestX/DestY.
    PUSHAD
    
    CMP isCarrying, 0
    JE dest_done            ; Only draw if we are carrying a passenger

    ; Load Destination Coordinates (DWORDs)
    MOV EAX, DestY
    MOV DH, AL              ; DH = Y coordinate
    MOV EAX, DestX
    MOV DL, AL              ; DL = X coordinate
    ADD DH, 2               ; Apply offset (Match your board offset)

    CALL Gotoxy
    
    ; --- FIX: Bright Green for visibility ---
    MOV EAX, lightGreen + (black * 16) 
    CALL SetTextColor
    
    MOV AL, DESTINATION_CHAR  ; Using your defined char (15 or 'D')
    CALL WriteChar

dest_done:
    POPAD
    RET
DrawDestination ENDP
;-----------------------------------------------------
ClearDestination PROC
; Clears destination by restoring the ROAD texture.
;-----------------------------------------------------
    PUSHAD
    
    MOV EAX, DestY
    MOV DH, AL
    MOV EAX, DestX
    MOV DL, AL
    ADD DH, 2
    CALL Gotoxy
    
    MOV EAX, ROAD_COLOR
    CALL SetTextColor
    MOV AL, ROAD_CHAR 
    CALL WriteChar
    
    POPAD
    RET
ClearDestination ENDP
;-----------------------------------------------------
DrawScore PROC
; Displays the score. Uses WriteInt to handle negative values correctly.
;-----------------------------------------------------
    PUSHAD
    
    ; 1. Move to Score position (Row 0, Col 55)
    MOV DH, 0 
    MOV DL, 55 
    CALL Gotoxy
    
    ; 2. Clear previous score (overwrite with spaces)
    MOV AL, ' '
    MOV ECX, 15 
    PUSH EDX 
score_clear_loop:
    CALL WriteChar
    LOOP score_clear_loop
    POP EDX 
    
    ; 3. Move back to start
    MOV DH, 0 
    MOV DL, 55 
    CALL Gotoxy
    
    ; 4. Display Label
    MOV EDX, OFFSET scoreMsg
    CALL WriteString
    
    ; 5. Display Score (FIX: Use WriteInt for signed numbers)
    MOV EAX, score 
    CALL WriteInt  
    
    POPAD
    RET
DrawScore ENDP
DrawDriverName PROC
    PUSHAD
    
    MOV DH, 1 ; Row 1
    MOV DL, 55 ; Column 55
    CALL Gotoxy
    
    MOV EDX, OFFSET nameInputBuffer
    CALL WriteString
    
    POPAD
    RET
DrawDriverName ENDP

DrawMode PROC ; <--- NEW
    PUSHAD
    MOV DH, 2 ; Row 2 (below name/score)
    MOV DL, 55 ; Col 55
    CALL Gotoxy
    MOV EDX, OFFSET modeMsg
    CALL WriteString
    
    MOV EAX, gameMode
    CMP EAX, 0 ; MODE_CAREER
    JE mode_career
    CMP EAX, 1 ; MODE_TIME
    JE mode_time
    CMP EAX, 2 ; MODE_ENDLESS
    JE mode_endless
    
mode_career:
    MOV EDX, OFFSET modeNameCareer
    JMP mode_draw_string
mode_time:
    MOV EDX, OFFSET modeNameTime
    JMP mode_draw_string
mode_endless:
    MOV EDX, OFFSET modeNameEndless
    
mode_draw_string:
    CALL WriteString
    POPAD
    RET
DrawMode ENDP

DrawTime PROC ; <--- NEW
; Displays Time Left only if in TIME_MODE
    PUSHAD
    
    MOV EAX, gameMode
    CMP EAX, 1 ; MODE_TIME
    JNE time_draw_done ; Skip if not Time Mode

    MOV DH, 3 ; Row 3
    MOV DL, 55 ; Col 55
    CALL Gotoxy
    
    ; Clear old time value
    MOV AL, ' '
    MOV ECX, 15
    PUSH EDX
time_clear_loop:
    CALL WriteChar
    LOOP time_clear_loop
    POP EDX
    
    MOV DH, 3
    MOV DL, 55
    CALL Gotoxy
    
    MOV EDX, OFFSET timeMsg
    CALL WriteString
    
    MOV EAX, timeLeft
    CALL WriteDec
    
time_draw_done:
    POPAD
    RET
DrawTime ENDP

DisplayGameOver PROC ; <--- NEW
    PUSHAD
    CALL Clrscr
    
    MOV EDX, OFFSET gameOverMsg
    CALL WriteString
    
    MOV EDX, OFFSET scoreMsg
    CALL WriteString
    MOV EAX, score
    CALL WriteDec
    CALL Crlf
    
    MOV EDX, OFFSET instBody4 ; "Press 'Q' to return to the Main Menu."
    CALL WriteString
    
    CALL CheckAndUpdateLeaderboard ; Save high score
    
wait_for_quit:
    CALL ReadChar
    CMP AL, 'Q'
    JE  exit_game_over
    CMP AL, 'q'
    JE  exit_game_over
    JMP wait_for_quit
    
exit_game_over:
    MOV gameState, 0
    POPAD
    RET
DisplayGameOver ENDP

DisplayGameWin PROC ; <--- NEW
; Only called by Career Mode Win
    PUSHAD
    CALL Clrscr
    
    MOV EDX, OFFSET winMsg
    CALL WriteString
    
    MOV EDX, OFFSET scoreMsg
    CALL WriteString
    MOV EAX, score
    CALL WriteDec
    CALL Crlf
    
    MOV EDX, OFFSET instBody4
    CALL WriteString
    
    CALL CheckAndUpdateLeaderboard ; Save high score
    
wait_for_quit_win:
    CALL ReadChar
    CMP AL, 'Q'
    JE  exit_game_win
    CMP AL, 'q'
    JE  exit_game_win
    JMP wait_for_quit_win
    
exit_game_win:
    MOV gameState, 0
    POPAD
    RET
DisplayGameWin ENDP


; --- Element Placement Procedures ---

PlacePassengers PROC
    PUSHAD
    
    ; Calculate passenger count (3 to 5)
    MOV EAX, 3
    CALL RandomRange
    ADD EAX, 3
    MOV ECX, EAX ; ECX = Passenger count for the loop
    
    MOV ESI, OFFSET PassengerData
    
passenger_loop:
    ; 1. Find a random, valid road tile (X, Y)
find_spot:
    MOV EAX, BOARD_SIZE
    CALL RandomRange
    MOV EBX, EAX ; EBX = Candidate X
    
    MOV EAX, BOARD_SIZE
    CALL RandomRange
    MOV EDX, EAX ; EDX = Candidate Y

    ; Check if (X, Y) is TILE_ROAD: Index calculation
    PUSH EBX
    PUSH EDX

    MOV EAX, EDX
    MOV EBP, BOARD_SIZE
    MUL EBP
    ADD EAX, EBX
    
    MOV ESI, OFFSET gameBoard
    ADD ESI, EAX
    MOV AL, [ESI]
    
    POP EDX
    POP EBX

    CMP AL, TILE_ROAD ; Ensure tile is explicitly TILE_ROAD (1)
    JNE find_spot ; If not a road, try again.

    ; Check if occupied by taxi
    CMP EBX, playerX
    JNE check_passengers
    CMP EDX, playerY
    JE find_spot

check_passengers:
    ; 2. Assign the spot and set status (Index = ECX - 1)
    PUSH ECX
    DEC ECX
    
    MOV BYTE PTR [PassengerData + ECX], 0 ; Status 0: Waiting
    
    MOV AL, BL
    MOV BYTE PTR [PassengerX + ECX], AL
    
    MOV AL, DL
    MOV BYTE PTR [PassengerY + ECX], AL
    
    INC ECX
    POP ECX
    
    ; Draw the passenger ('P')
    MOV AL, BL ; X
    MOV BL, AL
    MOV AL, DL ; Y
    MOV DL, AL
    CALL DrawPassenger
    
    LOOP passenger_loop
    
    POPAD
    RET
PlacePassengers ENDP

;-----------------------------------------------------
DrawScorePanel PROC
; Displays Name, Score, Mode, and Time on the right side.
;-----------------------------------------------------
    PUSHAD
    
    ; 1. Draw Driver Name
    MOV DH, 0       ; Row 0
    MOV DL, 25      ; Col 25
    CALL Gotoxy
    MOV EDX, OFFSET nameInputBuffer
    CALL WriteString
    
    ; 2. Draw Score
    MOV DH, 1       ; Row 1
    MOV DL, 25
    CALL Gotoxy
    MOV EDX, OFFSET scoreMsg
    CALL WriteString
    MOV EAX, score
    CALL WriteInt   ; Use WriteInt to handle negative scores correctly
    
    ; 3. Draw Current Mode
    MOV DH, 2       ; Row 2
    MOV DL, 25
    CALL Gotoxy
    MOV EDX, OFFSET modeNameStr
    CALL WriteString
    MOV EAX, currentMode
    CALL WriteDec
    
    ; 4. Draw Time (Only if in Time Mode, which is Mode 1)
    CMP currentMode, 1
    JNE skip_time_draw
    
    MOV DH, 3       ; Row 3
    MOV DL, 25
    CALL Gotoxy
    MOV EDX, OFFSET timeMsg
    CALL WriteString
    MOV EAX, timeLeft
    CALL WriteDec
    
    ; Clear trailing digits if time shrinks (e.g., 100 -> 99)
    MOV AL, ' '
    CALL WriteChar 
    
skip_time_draw:
    POPAD
    RET
DrawScorePanel ENDP

;-----------------------------------------------------
PlaceStaticObstacles PROC
; Randomly places 10 static obstacles/persons, avoiding the start area.
;-----------------------------------------------------
    PUSHAD
    
    MOV ECX, MAX_STATIC_OBJS 
    MOV ESI, OFFSET StaticType
    
static_loop:
    ; 1. Determine Type 
    MOV EAX, 2
    CALL RandomRange
    INC EAX 
    MOV [ESI], AL 
    
find_static_spot:
    ; 2. Find a random spot
    MOV EAX, BOARD_SIZE 
    CALL RandomRange
    MOV EBX, EAX ; Candidate X
    
    MOV EAX, BOARD_SIZE
    CALL RandomRange
    MOV EDX, EAX ; Candidate Y

    ; --- FIX: SAFE ZONE CHECK ---
    ; If X < 3 AND Y < 3, try again (Keep top-left clear)
    CMP EBX, 3
    JGE check_road_static
    CMP EDX, 3
    JL  find_static_spot
    ; ----------------------------

check_road_static:
    ; Check if TILE_ROAD
    PUSH EBX 
    PUSH EDX 
    MOV EAX, EDX
    MOV EDI, BOARD_SIZE
    MUL EDI 
    ADD EAX, EBX 
    MOV EDI, OFFSET gameBoard
    ADD EDI, EAX
    MOV AL, [EDI]
    POP EDX 
    POP EBX 

    CMP AL, TILE_BUILDING
    JE find_static_spot 
    
    ; 3. Assign and Draw
    PUSH ECX
    DEC ECX
    MOV AL, BL 
    MOV BYTE PTR [StaticX + ECX], AL
    MOV AL, DL 
    MOV BYTE PTR [StaticY + ECX], AL
    INC ECX
    POP ECX
    
    ; Draw logic (same as before)
    MOV AL, [ESI]
    CMP AL, 1 
    JE draw_person
    
    MOV AL, white + (black * 16)
    CALL SetTextColor
    MOV AL, OBSTACLE_CHAR
    JMP draw_obj
    
draw_person:
    MOV AL, PERSON_COLOR
    CALL SetTextColor
    MOV AL, PERSON_CHAR
    
draw_obj:
    PUSH EBX
    PUSH EDX
    MOV DH, DL
    MOV DL, BL
    ADD DH, 2
    CALL Gotoxy
    CALL WriteChar
    POP EDX
    POP EBX
    
    INC ESI 
    
    DEC ECX
    JNZ static_loop
    
    POPAD
    RET
PlaceStaticObstacles ENDP
;-----------------------------------------------------
;-----------------------------------------------------
PlaceNPCs PROC
; Randomly places NPC cars, avoiding the start area.
; FIXED: Replaced LOOP with DEC/JNZ to fix "jump too far" error.
;-----------------------------------------------------
    PUSHAD
    MOV ECX, MAX_NPC_CARS
    
npc_loop:
    PUSH ECX

find_npc_spot:
    MOV EAX, BOARD_SIZE 
    CALL RandomRange
    MOV EBX, EAX 
    MOV EAX, BOARD_SIZE
    CALL RandomRange
    MOV EDX, EAX 

    ; --- SAFE ZONE CHECK ---
    CMP EBX, 3
    JGE check_road_npc
    CMP EDX, 3
    JL  find_npc_spot

check_road_npc:
    PUSH EBX 
    PUSH EDX 
    MOV EAX, EDX
    MOV EBP, BOARD_SIZE
    MUL EBP 
    ADD EAX, EBX 
    MOV ESI, OFFSET gameBoard
    ADD ESI, EAX
    MOV AL, [ESI]
    POP EDX 
    POP EBX 

    CMP AL, TILE_ROAD
    JNE find_npc_spot 
    
    ; Assign and Draw
    DEC ECX
    MOV AL, BL
    MOV BYTE PTR [NPC_CarX + ECX], AL
    MOV AL, DL
    MOV BYTE PTR [NPC_CarY + ECX], AL
    
    MOV EAX, 4
    CALL RandomRange
    MOV [NPC_CarDir + ECX], AL
    INC ECX

    PUSH EBX 
    PUSH EDX 
    MOV DH, DL
    MOV DL, BL
    ADD DH, 2
    CALL Gotoxy
    MOV AL, NPC_CAR_COLOR
    CALL SetTextColor
    MOV AL, NPC_CAR_CHAR
    CALL WriteChar
    POP EDX
    POP EBX
    
    POP ECX
    
    ; --- FIX: Manual Loop Control ---
    DEC ECX
    JNZ npc_loop 
    ; --------------------------------
    
    POPAD
    RET
PlaceNPCs ENDP

;-----------------------------------------------------
PlaceBonusItems PROC
; Randomly places bonuses, avoiding start area.
;-----------------------------------------------------
    PUSHAD
    MOV ECX, MAX_BONUS_ITEMS
    
bonus_loop:
    PUSH ECX

find_bonus_spot:
    MOV EAX, BOARD_SIZE 
    CALL RandomRange
    MOV EBX, EAX 
    MOV EAX, BOARD_SIZE
    CALL RandomRange
    MOV EDX, EAX 

    ; --- FIX: SAFE ZONE CHECK ---
    CMP EBX, 3
    JGE check_road_bonus
    CMP EDX, 3
    JL  find_bonus_spot
    ; ----------------------------

check_road_bonus:
    PUSH EBX 
    PUSH EDX 
    MOV EAX, EDX
    MOV EBP, BOARD_SIZE
    MUL EBP 
    ADD EAX, EBX 
    MOV ESI, OFFSET gameBoard
    ADD ESI, EAX
    MOV AL, [ESI]
    POP EDX 
    POP EBX 

    CMP AL, TILE_ROAD
    JNE find_bonus_spot 
    
    DEC ECX
    MOV AL, BL
    MOV BYTE PTR [BonusX + ECX], AL
    MOV AL, DL
    MOV BYTE PTR [BonusY + ECX], AL
    INC ECX

    PUSH EBX 
    PUSH EDX 
    MOV DH, DL
    MOV DL, BL
    ADD DH, 2
    CALL Gotoxy
    MOV AL, BONUS_COLOR
    CALL SetTextColor
    MOV AL, BONUS_CHAR
    CALL WriteChar
    POP EDX
    POP EBX
    
    POP ECX
    LOOP bonus_loop
    
    POPAD
    RET
PlaceBonusItems ENDP
; --- Board and Setup Procedures ---
;-----------------------------------------------------
;-----------------------------------------------------
InitBoardData PROC
; Fills the 20x20 gameBoard array, guaranteeing the starting area is road.
;-----------------------------------------------------
    PUSHAD
    
    MOV EDI, OFFSET gameBoard

    XOR EAX, EAX ; EAX = row
rows_loop:
    XOR EBX, EBX ; EBX = col

cols_loop:
    ; --- CRITICAL FIX: Ensure Column 0 is ALWAYS a road ---
    CMP EBX, 0
    JE set_road_default 

    ; Apply grid logic
    MOV ECX, EAX ; ECX = row
    AND ECX, 3   ; ECX = row % 4
    CMP ECX, 0
    JE set_road_default

    MOV ECX, EBX ; ECX = col
    AND ECX, 3   ; ECX = col % 4
    CMP ECX, 0
    JE set_road_default

    MOV BYTE PTR [EDI], TILE_BUILDING
    JMP after_put

set_road_default:
    MOV BYTE PTR [EDI], TILE_ROAD

after_put:
    ; --- Check and Override Start Area (Retain initial 2x2 override for safety) ---
    
    ; If Row < 2 AND Col < 2, force TILE_ROAD (2x2 area: (0,0), (0,1), (1,0), (1,1))
    CMP EAX, 2 
    JGE end_override 

    CMP EBX, 2
    JGE end_override 

    MOV BYTE PTR [EDI], TILE_ROAD
    
end_override:
    INC EDI
    INC EBX
    CMP EBX, BOARD_SIZE
    JB cols_loop

    INC EAX
    CMP EAX, BOARD_SIZE
    JB rows_loop

    POPAD
    RET
InitBoardData ENDP

;-----------------------------------------------------
HideCursor PROC
; Hides the console cursor to prevent flickering.
;-----------------------------------------------------
    .data
    consoleHandle DWORD ?
    cursorInfo CONSOLE_CURSOR_INFO <>
    .code
    PUSHAD
    
    ; Get output handle
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    MOV consoleHandle, EAX
    
    ; Get current cursor info
    INVOKE GetConsoleCursorInfo, consoleHandle, ADDR cursorInfo
    
    ; Set visible = 0 (false)
    MOV cursorInfo.bVisible, 0
    
    ; Set new info
    INVOKE SetConsoleCursorInfo, consoleHandle, ADDR cursorInfo
    
    POPAD
    RET
HideCursor ENDP

;-----------------------------------------------------
ReadLeaderboard PROC
; Safely reads highscores.txt. Creates it if missing.
;-----------------------------------------------------
    PUSHAD
    
    MOV scoresRead, 0

    ; Open File
    MOV EDX, OFFSET fileName
    CALL OpenInputFile
    MOV fileHandle, EAX

    CMP EAX, INVALID_HANDLE_VALUE ; Check for error
    JE  fileNotFound

    ; File found, read data
    MOV ECX, MAX_SCORES 
    MOV ESI, 0 ; Index for playerNames (byte offset)
    MOV EDI, 0 ; Index for highScores (array index)

readLoop:
    PUSH ECX
    
    ; 1. Read Name
    ; Calculate address: OFFSET playerNames + (EDI * MAX_NAME_LEN)
    MOV EAX, MAX_NAME_LEN
    MUL EDI
    ADD EAX, OFFSET playerNames
    MOV EDX, EAX        ; EDX = Buffer address for name
    MOV ECX, MAX_NAME_LEN
    CALL ReadString
    
    ; Check if read failed (End of File)
    CMP EAX, 0
    JE  close_file_early

    ; 2. Read Score String
    MOV EDX, OFFSET tempBuffer
    MOV ECX, 10
    CALL ReadString
    
    ; 3. Parse Score
    MOV EDX, OFFSET tempBuffer
    CALL ParseDecimal32 ; Returns value in EAX
    MOV [highScores + EDI * 4], EAX ; Store in DWORD array

    INC scoresRead
    INC EDI
    
    POP ECX
    LOOP readLoop

    JMP close_file_normal

close_file_early:
    POP ECX ; Clean stack from loop
    
close_file_normal:
    MOV EAX, fileHandle
    CALL CloseFile
    JMP done

fileNotFound:
    ; Create empty file if it doesn't exist
    MOV EDX, OFFSET fileName
    CALL CreateOutputFile
    CALL CloseFile
    MOV scoresRead, 0

done:
    POPAD
    RET
ReadLeaderboard ENDP

;-----------------------------------------------------


;-----------------------------------------------------
DrawBoard PROC
; Draws the visually upgraded board (Textured Buildings, Asphalt Roads).
;-----------------------------------------------------
    PUSHAD
    
    CALL Clrscr
    
    ; Draw Initialization Message
    MOV DH, 0 
    MOV DL, 0 
    CALL Gotoxy
    MOV EDX, OFFSET boardInitMsg
    CALL WriteString
    CALL Crlf
    
    ; Draw Grid
    MOV DH, 2 
    MOV DL, 0 
    MOV ESI, OFFSET gameBoard
    MOV ECX, BOARD_SIZE * BOARD_SIZE 
    
drawLoop:
    PUSH ECX
    CALL Gotoxy
    
    MOV AL, [ESI]
    CMP AL, TILE_ROAD
    JE  drawRoad

    ; --- Draw BUILDING (Concrete Texture) ---
    MOV EAX, BUILDING_COLOR 
    CALL SetTextColor
    MOV AL, BUILDING_CHAR 
    CALL WriteChar
    JMP nextCoord

drawRoad:
    ; --- Draw ROAD (Asphalt Texture) ---
    MOV EAX, ROAD_COLOR
    CALL SetTextColor
    MOV AL, ROAD_CHAR 
    CALL WriteChar
    
nextCoord:
    INC DL
    CMP DL, BOARD_SIZE
    JNE continueRow
    
    MOV DL, 0
    INC DH

continueRow:
    INC ESI
    POP ECX
    LOOP drawLoop

    ; Reset color to standard console white for UI
    MOV EAX, white + (black * 16)
    CALL SetTextColor
    CALL DrawDestination
    POPAD
    RET
DrawBoard ENDP
TaxiSelection PROC
    PUSHAD
    
taxiScreen:
    CALL Clrscr
    
    MOV EDX, OFFSET taxiPrompt
    CALL WriteString
    CALL Crlf
    MOV EDX, OFFSET taxiOptRed
    CALL WriteString
    CALL Crlf
    MOV EDX, OFFSET taxiOptYellow
    CALL WriteString
    CALL Crlf
    MOV EDX, OFFSET taxiOptRandom
    CALL WriteString
    CALL Crlf
    CALL Crlf
    
    MOV EDX, OFFSET menuPrompt
    CALL WriteString
    CALL ReadChar
    
    ; Manual UCase conversion
    CMP AL, 'a'
    JL  checkUpper
    CMP AL, 'z'
    JG  checkUpper
    SUB AL, 32
    
checkUpper:
    MOV selectedTaxi, AL
    
    CMP AL, 'R'
    JE  setRed
    CMP AL, 'Y'
    JE  setYellow
    CMP AL, 'A'
    JE  randomSelect

    CALL Crlf
    MOV EDX, OFFSET errorMsg
    CALL WriteString
    MOV EAX, 100
    CALL Delay
    JMP taxiScreen

randomSelect:
    MOV EAX, 2
    CALL RandomRange
    
    CMP EAX, 0
    JE  setRed
    JMP setYellow
    
setRed:
    MOV selectedTaxi, 'R'
    MOV playerColor, red + (black * 16)
    JMP getName
    
setYellow:
    MOV selectedTaxi, 'Y'
    MOV playerColor, yellow + (black * 16)
    JMP getName
    
getName:
    CALL Clrscr
    MOV EDX, OFFSET namePrompt
    CALL WriteString
    
    MOV EDX, OFFSET nameInputBuffer
    MOV ECX, 15
    CALL ReadString

    CMP AL, 0
    JE  taxiScreen

    MOV gameState, 5
    POPAD
    RET
TaxiSelection ENDP

; --- Game Logic Procedures ---

CheckPickupDropoff PROC
    PUSHAD
    
    CMP isCarrying, 1
    JNE check_pickup
    
    ; --- DROP-OFF LOGIC ---
    MOV EAX, playerX
    CMP EAX, DestX
    JNE end_check
    
    MOV EAX, playerY
    CMP EAX, DestY
    JNE end_check
    
    ADD score, 10
    MOV isCarrying, 0
    INC droppedPassengers ; <-- NEW: Track successful drop-offs for speed increase
    
    CALL PlayDropSound
    CALL ClearDestination
    CALL DrawScore
    
    ; Re-spawn new passengers to maintain 3-5 requirement
    CALL PlacePassengers
    
    JMP end_check
    
check_pickup:
    ; --- PICKUP LOGIC (Only runs if not carrying) ---
    
    ; Check if 'P' key was pressed next to a waiting passenger
    
    MOV ECX, MAX_PASSENGERS
    MOV ESI, 0 ; Index counter
    
pickup_loop_start:
    CMP ESI, ECX
    JGE end_check
    
    MOV AL, [PassengerData + ESI]
    CMP AL, 0
    JNE pickup_loop_continue ; Skip if not waiting (Status 0)

    ; 1. Calculate Manhattan Distance (Strict Adjacency = 1)
    MOV EAX, playerX
    MOVZX EBX, BYTE PTR [PassengerX + ESI]
    SUB EAX, EBX
    CALL Abs
    MOV EBP, EAX ; EBP = |Delta X|

    MOV EAX, playerY
    MOVZX EBX, BYTE PTR [PassengerY + ESI]
    SUB EAX, EBX
    CALL Abs
    
    ADD EAX, EBP ; EAX = Total Manhattan Distance
    
    CMP EAX, 1
    JNE pickup_loop_continue ; Only strictly adjacent (Dist=1) is allowed.

    ; --- SUCCESSFUL PICKUP ---
    MOV BYTE PTR [PassengerData + ESI], 1 ; Status 1: Picked Up
    MOV isCarrying, 1
    
    CALL PlayPickupSound
    
    ; Clear the passenger marker immediately
    MOVZX EBX, BYTE PTR [PassengerX + ESI] ; X coord
    MOVZX EDX, BYTE PTR [PassengerY + ESI] ; Y coord
    
    PUSH EBX
    PUSH EDX
    
    ; Clear the passenger marker spot
    MOV DH, DL
    MOV DL, BL
    ADD DH, 2
    CALL Gotoxy
    
    MOV AL, white + (black * 16)
    CALL SetTextColor
    MOV AL, 219 ; Draw road tile (clears the passenger)
    CALL WriteChar
    
    POP EDX
    POP EBX
    
generate_dest:
    ; Find a random destination (X, Y)
    MOV EAX, BOARD_SIZE
    CALL RandomRange
    MOV DestX, EAX
    
    MOV EAX, BOARD_SIZE
    CALL RandomRange
    MOV DestY, EAX
    
    ; Check 1: Destination is not same as pickup spot
    MOVZX EAX, BYTE PTR [PassengerX + ESI]
    CMP EAX, DestX
    JNE check_dest_tile
    
    MOVZX EAX, BYTE PTR [PassengerY + ESI]
    CMP EAX, DestY
    JE  generate_dest
    
check_dest_tile:
    ; Check 2: Destination is TILE_ROAD
    MOV EAX, DestY
    MOV EDX, 0
    MOV EBX, BOARD_SIZE
    MUL EBX
    ADD EAX, DestX
    
    MOV EDI, OFFSET gameBoard
    ADD EDI, EAX
    MOV AL, [EDI]
    
    CMP AL, TILE_BUILDING
    JE generate_dest
    
    CALL DrawDestination
    
    JMP end_check ; PICKUP SUCCESSFUL - EXIT PROC

pickup_loop_continue:
    INC ESI ; Next index
    JMP pickup_loop_start
    
end_check:
    POPAD
    RET
CheckPickupDropoff ENDP

MovePlayer PROC
; Handles player movement, boundary checks, and collision detection
    PUSHAD

    MOV EBX, playerX ; Save old X
    MOV ECX, playerY ; Save old Y
    
    ; EAX holds the scan code from ReadKey

    ; --- 1. Determine New Potential Position (Boundary Checks) ---
    CMP EAX, 4800h ; Up Arrow
    JNE check_down
    CMP playerY, 0
    JE  end_move
    DEC playerY
    JMP check_collision_all

check_down:
    CMP EAX, 5000h ; Down Arrow
    JNE check_right
    CMP playerY, BOARD_SIZE - 1
    JE  end_move
    INC playerY
    JMP check_collision_all

check_right:
    CMP EAX, 4D00h ; Right Arrow
    JNE check_left
    CMP playerX, BOARD_SIZE - 1
    JE  end_move
    INC playerX
    JMP check_collision_all

check_left:
    CMP EAX, 4B00h ; Left Arrow
    JNE end_move
    CMP playerX, 0
    JE  end_move
    DEC playerX

check_collision_all:
    ; --- 2. Check Building Collision (Impassable Terrain) ---
    MOV EAX, playerY
    MOV EDX, 0
    MOV EDI, BOARD_SIZE
    MUL EDI
    ADD EAX, playerX
    
    MOV ESI, OFFSET gameBoard
    ADD ESI, EAX
    MOV AL, [ESI]
    
    CMP AL, TILE_BUILDING
    JE  revert_collision_common ; Building hit reverts move
    
    ; --- 3. Check Waiting Passenger Collision (Prevent moving onto waiting 'P') ---
    MOV EAX, playerY ; Y coord (New Potential Spot)
    MOV EBX, playerX ; X coord (New Potential Spot)
    
    MOV ESI, 0 ; Passenger Index counter
passenger_collision_loop:
    CMP ESI, MAX_PASSENGERS
    JGE check_static_collision

    MOV AL, [PassengerData + ESI]
    CMP AL, 0 ; Only check waiting passengers (Status 0)
    JNE passenger_collision_continue
    
    ; Check if new position (EAX, EBX) matches passenger position
    MOVZX EDX, BYTE PTR [PassengerY + ESI]
    CMP EAX, EDX
    JNE passenger_collision_continue
    
    MOVZX EDX, BYTE PTR [PassengerX + ESI]
    CMP EBX, EDX
    JE  revert_collision_common ; Passenger hit reverts move
    
passenger_collision_continue:
    INC ESI
    JMP passenger_collision_loop


check_static_collision:
    ; --- 4. Check Static Obstacle/Person Collision (Scoring Logic) ---
    MOV ESI, 0 ; Static Index counter
static_collision_loop:
    CMP ESI, MAX_STATIC_OBJS
    JGE check_npc_collision ; All static checks passed

    MOV EAX, playerY
    MOV EBX, playerX
    
    ; Check if new position (EAX, EBX) matches static object position
    MOVZX EDX, BYTE PTR [StaticY + ESI]
    CMP EAX, EDX
    JNE static_collision_continue
    
    MOVZX EDX, BYTE PTR [StaticX + ESI]
    CMP EBX, EDX
    JNE static_collision_continue
    
    ; Static Collision detected!
    MOV AL, [StaticType + ESI]
    
    MOV EDI, ESI ; Store the index of the hit object in EDI
    
    CMP AL, 1 ; Type 1: Person
    JE handle_person_hit
    
    CMP AL, 2 ; Type 2: Obstacle (Tree/Box)
    JE handle_obstacle_hit
    
    JMP static_collision_continue

handle_person_hit:
    SUB score, 5 ; Person: -5 points
    JMP handle_collision_cleanup
    
handle_obstacle_hit:
    ; Determine penalty based on taxi type
    MOV AL, selectedTaxi
    CMP AL, 'R'
    JE red_taxi_obstacle_hit
    
    SUB score, 4 ; Yellow Taxi: Hits obstacle (-4 points)
    JMP handle_collision_cleanup
    
red_taxi_obstacle_hit:
    SUB score, 2 ; Red Taxi: Hits obstacle (-2 points)

handle_collision_cleanup:
    CALL PlayCrashSound ; Sound
    
    ; Redraw the obstacle/person at the collision spot
    CALL RedrawStaticObject
    
    ; Update score display
    CALL DrawScore
    
    JMP revert_collision_common
static_collision_continue:
    INC ESI
    JMP static_collision_loop

check_npc_collision:
    ; --- 5. NEW: Check NPC Car Collision ---
    MOV EAX, playerY
    MOV EBX, playerX
    MOV ESI, 0 ; NPC Index counter
npc_collision_loop:
    CMP ESI, MAX_NPC_CARS
    JGE check_bonus_collision ; All NPC checks passed

    ; Check if new position matches NPC position
    MOVZX EDX, BYTE PTR [NPC_CarY + ESI]
    CMP EAX, EDX
    JNE npc_collision_continue
    
    MOVZX EDX, BYTE PTR [NPC_CarX + ESI]
    CMP EBX, EDX
    JNE npc_collision_continue
    
    ; NPC Car Collision detected!
    CALL PlayCrashSound
    
    ; Determine penalty based on taxi type
    MOV AL, selectedTaxi
    CMP AL, 'R'
    JE red_taxi_npc_hit
    
    SUB score, 2 ; Yellow Taxi: Hits car (-2 points)
    JMP npc_collision_revert
    
red_taxi_npc_hit:
    SUB score, 3 ; Red Taxi: Hits car (-3 points)

npc_collision_revert:
    CALL DrawScore ; Update score display
    
    ; NPC does not stop or revert, only player reverts.
    JMP revert_collision_common
    
npc_collision_continue:
    INC ESI
    JMP npc_collision_loop

check_bonus_collision:
    ; --- 6. NEW: Check Bonus Item Collision ---
    MOV EAX, playerY
    MOV EBX, playerX
    MOV ESI, 0 ; Bonus Index counter
bonus_collision_loop:
    CMP ESI, MAX_BONUS_ITEMS
    JGE end_move ; All checks passed - Move is safe!

    ; Check if new position matches Bonus Item position
    MOVZX EDX, BYTE PTR [BonusY + ESI]
    CMP EAX, EDX
    JNE bonus_collision_continue
    
    MOVZX EDX, BYTE PTR [BonusX + ESI]
    CMP EBX, EDX
    JNE bonus_collision_continue
    
    ; Bonus Item Collected!
    ADD score, 10
    CALL PlayPickupSound
    CALL DrawScore
    
    ; Clear the bonus item marker from the map
    PUSH EBX ; Save playerX
    PUSH EAX ; Save playerY
    
    MOV DH, AL ; Y
    MOV DL, BL ; X
    ADD DH, 2
    CALL Gotoxy
    
    MOV AL, white + (black * 16)
    CALL SetTextColor
    MOV AL, 219 ; Draw road tile (clears the bonus item)
    CALL WriteChar
    
    POP EAX ; Restore playerY
    POP EBX ; Restore playerX
    
    ; Remove bonus item from active list (Move it off the map)
    MOV BYTE PTR [BonusX + ESI], 255
    MOV BYTE PTR [BonusY + ESI], 255
    
    ; Continue move (no revert needed)
    JMP bonus_collision_continue

bonus_collision_continue:
    INC ESI
    JMP bonus_collision_loop
    
revert_collision_common:
    ; Revert position (EBX, ECX hold the original, safe coordinates)
    MOV playerX, EBX
    MOV playerY, ECX
    
end_move:
    POPAD
    RET
MovePlayer ENDP

MoveNPCs PROC
; Moves all NPCs one step in their fixed path direction.
    PUSHAD
    
    MOV ECX, MAX_NPC_CARS
    MOV EBX, 0         ; EBX = Current NPC Index (0 to 2)
    
npc_move_loop:
    
    ; Load current position and direction
    MOV AL, [NPC_CarDir + EBX] ; AL = Direction
    MOV DL, [NPC_CarY + EBX]   ; DL = Current Y
    MOV DH, [NPC_CarX + EBX]   ; DH = Current X
    
    ; 1. Clear old position (Draw road tile)
    PUSH EBX ; Save index
    PUSH EDX ; Save coordinates (X in DH, Y in DL)
    
    MOV EAX, white + (black * 16)
    CALL SetTextColor
    MOV AL, 219
    MOV DH, DL    ; Y coord
    MOV DL, DH    ; X coord (swap DH/DL for Gotoxy format)
    ADD DH, 2
    CALL Gotoxy
    CALL WriteChar
    
    POP EDX
    POP EBX

    ; 2. Calculate new position based on direction (AL)
    CMP AL, 0 ; Up
    JE move_up_npc
    CMP AL, 1 ; Down
    JE move_down_npc
    CMP AL, 2 ; Left
    JE move_left_npc
    CMP AL, 3 ; Right
    JE move_right_npc
    JMP next_npc_check_internal ; Should not happen

move_up_npc:
    DEC DL
    JMP check_npc_bounds

move_down_npc:
    INC DL
    JMP check_npc_bounds

move_left_npc:
    DEC DH
    JMP check_npc_bounds

move_right_npc:
    INC DH
    JMP check_npc_bounds

check_npc_bounds:
    
    ; --- 3. Check Boundary Limits (0 and BOARD_SIZE - 1) ---
    
    CMP DH, 0
    JL reverse_move
    CMP DH, BOARD_SIZE - 1
    JG reverse_move
    CMP DL, 0
    JL reverse_move
    CMP DL, BOARD_SIZE - 1
    JG reverse_move
    
    JMP npc_check_obstacle

reverse_move:
    ; The move was illegal (boundary hit). Reverse the coordinate change, then flip direction.
    MOV AL, [NPC_CarDir + EBX]
    CMP AL, 0 ; Was it Up (0)?
    JE redo_down
    CMP AL, 1 ; Was it Down (1)?
    JE redo_up
    CMP AL, 2 ; Was it Left (2)?
    JE redo_right
    CMP AL, 3 ; Was it Right (3)?
    JE redo_left
    JMP npc_update_dir

    ; --- Reverse Move Calculation Blocks (Step back one unit) ---
redo_up:    DEC DL  ; Revert Down move (DL++)
            JMP npc_update_dir
redo_down:  INC DL  ; Revert Up move (DL--)
            JMP npc_update_dir
redo_left:  INC DH  ; Revert Left move (DH--)
            JMP npc_update_dir
redo_right: DEC DH  ; Revert Right move (DH++)
            JMP npc_update_dir
    
npc_update_dir:
    ; Flip direction (0<->1 for Y, 2<->3 for X)
    MOV AL, [NPC_CarDir + EBX]
    XOR AL, 1
    MOV [NPC_CarDir + EBX], AL
    
    JMP npc_boundary_ok
    
npc_check_obstacle:
    ; 4. Check Building Collision
    
    ; Calculate Array Index (EAX = Y * BOARD_SIZE + X)
    MOVZX EAX, DL        ; EAX = New Y
    MOV EDX, 0           ; Clear EDX
    MOV EDI, BOARD_SIZE
    MUL EDI              ; EAX = Y * BOARD_SIZE
    
    MOVZX ESI, DH        ; ESI = New X
    ADD EAX, ESI         ; EAX = Final Array Index
    
    MOV EDI, OFFSET gameBoard
    ADD EDI, EAX
    MOV AL, [EDI]
    
    CMP AL, TILE_BUILDING
    JE reverse_move ; Hit a building, reverse direction and step back

npc_boundary_ok:
    ; 5. Update and Draw new position
    MOV AL, DH ; New X
    MOV [NPC_CarX + EBX], AL
    MOV AL, DL ; New Y
    MOV [NPC_CarY + EBX], AL
    
    MOV AL, NPC_CAR_COLOR
    CALL SetTextColor
    MOV AL, NPC_CAR_CHAR
    
    ; Draw at (DH, DL) - remember to adjust Y by 2
    MOV DH, DL
    MOV DL, DH
    ADD DH, 2
    CALL Gotoxy
    CALL WriteChar

next_npc_check_internal:
    INC EBX ; Increment array index
    DEC ECX
    JNZ npc_move_loop
    
    POPAD
    RET
MoveNPCs ENDP



; Add this procedure to your .code section:
;-----------------------------------------------------
StopBackgroundMusic PROC
; Stops any currently looping background music.
;-----------------------------------------------------
    PUSHAD
    
    ; Stop the music by calling PlaySoundA with NULL for the filename
    INVOKE PlaySoundA, 
           NULL,               ; pszSound: NULL to stop current sound
           NULL,               ; hmod
           NULL                ; dwFlags (0 is safest for stopping)
           
    POPAD
    RET
StopBackgroundMusic ENDP

; =======================================================
; Main Program
; =======================================================

main PROC
    CALL PlayBackgroundMusic
    CALL Randomize
    MOV gameState, 0

    .WHILE gameState != 99

        ; --- State 0: Main Menu ---
        CMP gameState, 0
        JNE checkInstructions
        CALL DisplayMenu
        CALL HandleMenuInput
        JMP nextState

        ; --- State 1: Instructions ---
checkInstructions:
        CMP gameState, 1
        JNE checkModeSelect ; Jumps to NEW Mode Select
        CALL DisplayInstructions
        JMP nextState
        
        ; --- State 3: Mode Selection (NEW) ---
checkModeSelect:
        CMP gameState, 3
        JNE checkLeaderboard
        CALL DisplayModeMenu
        CALL HandleModeInput
        JMP nextState

        ; --- State 4: Leaderboard ---
checkLeaderboard:
        CMP gameState, 4
        JNE checkNewGame
        CALL ReadLeaderboard
        CALL DisplayLeaderboard
        JMP nextState
        
        ; --- State 2: New Game Setup (Taxi Selection) ---
checkNewGame:
        CMP gameState, 2
        JNE checkGameRunning
        CALL TaxiSelection
        JMP nextState
        
        ; --- State 5: GAME_RUNNING (The Game Loop) ---
checkGameRunning:
        ; --- Game Initialization ---
        CMP game_initialized, 0
        JNE gameLoop
        CALL HideCursor
        
        CALL InitBoardData
        CALL DrawBoard ; Prints message, clears screen.
        
        
        ; Reset player state for new game
        MOV playerX, 0
        MOV playerY, 0
        MOV score, 0
        MOV isCarrying, 0
        MOV droppedPassengers, 0
        MOV timerTick, 0 ; <-- NEW: Reset timer tick
        
        ; NEW: Initialize state based on game mode
        MOV EAX, gameMode
        CMP EAX, 1 ; MODE_TIME = 1
        JNE init_endless_career
        
        ; TIME MODE INIT: Set time limit
        MOV EAX, timeLimit
        MOV timeLeft, EAX
        
        JMP init_mode_done
        
init_endless_career:
        ; CAREER/ENDLESS MODE INIT: Effectively infinite time for timer display logic
        MOV timeLeft, 9999
        
init_mode_done:
        
        CALL PlacePassengers
        CALL PlaceStaticObstacles
        CALL PlaceNPCs
        CALL PlaceBonusItems
        CALL PlayBackgroundMusic
        ; NEW FIX: Start BGM here when the game is fully initialized
       

        ; Reset player position to start 
        MOV playerX, 0
        MOV playerY, 0
        MOV score, 0

        CALL DrawPlayer
        
        ; Draw status info
        CALL DrawScore
        CALL DrawDriverName
        CALL DrawMode ; <--- NEW: Draw mode name
        CALL DrawTime ; <--- NEW: Draw initial time
        
        MOV game_initialized, 1 ; Set flag
       
        JMP gameLoop
gameLoop:
        ; Non-blocking check for P key, Q key, Spacebar, or arrow key
        
        CALL ReadKey

        CMP AL, 1Bh 
        JE  game_quit
        
        ; 1. Check for Pause/Quit keys
        CMP AL, 'P'
        JE  set_pause
        CMP AL, 'p'
        JE  set_pause
        
        CMP AL, 'Q'
        JE  game_quit
        
        ; 2. Check for Spacebar (Pickup/Dropoff)
        CMP AL, ' '
        JNE check_move
        
        CALL CheckPickupDropoff
        JMP gameLoopEnd

check_move:
        ; 3. Handle Movement if it was an arrow key (AL=0)
        CMP AL, 0
        JNE gameLoopEnd
        
        CALL ClearPlayer
        CALL MovePlayer
        CALL DrawPlayer
        
        JMP gameLoopEnd

set_pause:
        CALL PlayPauseSound
        MOV gameState, 6
        JMP gameLoopEnd
        
game_quit:
        CALL StopBackgroundMusic
        MOV gameState, 0 ; Return to menu
        JMP nextState

gameLoopEnd:
        
        
        ; --- NPC Movement and Speed Control ---
        CALL MoveNPCs
        CALL DrawDestination
        ; --- NEW: Mode Specific Logic (Timer and Win/Loss Check) ---
        
        ; Timer Tick: Runs only in TIME_MODE
        MOV EAX, gameMode
        CMP EAX, 1 ; MODE_TIME = 1
        JNE check_career_win ; Skip timer check if not Time Mode
        
        INC timerTick
        
        MOV EAX, timerTick
        MOV EDX, 0
        MOV ESI, 50 ; Update timer every 50 ticks (approx 0.5s at 10ms delay)
        DIV ESI
        CMP EDX, 0 ; If remainder is 0 (i.e., 50th tick)
        JNE check_career_win
        
        ; Time to decrement timer
        CMP timeLeft, 0
        JE time_mode_game_over
        
        DEC timeLeft
        CALL DrawTime
        
        JMP check_career_win

time_mode_game_over: ; <--- NEW
        CALL PlayEndGameSound
        MOV EAX, 7 ; Game Over State
        MOV gameState, EAX
        JMP gameLoopEnd_no_delay
        
check_career_win: ; <--- NEW
        ; Career Mode Win Condition: 100 Points
        MOV EAX, gameMode
        CMP EAX, 0 ; MODE_CAREER = 0
        JNE check_delay_speed
        
        CMP score, CAREER_WIN_SCORE
        JL check_delay_speed
        
        ; Career Mode Win!
        CALL PlayEndGameSound
        MOV EAX, 8 ; Game Win State
        MOV gameState, EAX
        JMP gameLoopEnd_no_delay
        
        ; --- Speed control logic (unchanged) ---
        
check_delay_speed:
        ; 1. Set Base Speed (EAX = Delay in ms)
        MOV AL, selectedTaxi
        CMP AL, 'Y'
        JE set_yellow_base_delay ; If Yellow
        MOV EAX, 10 ; Red Taxi base delay: 10ms
        JMP calculate_speed_increase

set_yellow_base_delay:
        MOV EAX, 5 ; Yellow Taxi base delay: 5ms

calculate_speed_increase:
        ; Determine speed decrease amount (1ms per 2 successful drops)
        
        PUSH EAX ; Save base delay
        
        MOV EAX, droppedPassengers
        MOV EDX, 0
        MOV ESI, 2
        DIV ESI ; EAX = Reduction factor (1 for 2 drops, 2 for 4 drops, etc.)
        
        MOV ESI, EAX ; ESI = Reduction factor
        
        POP EAX ; Restore base delay to EAX
        
        ; EAX = Base Delay, ESI = Reduction Factor
        SUB EAX, ESI
        
        ; Clamp minimum delay to 1ms
        CMP EAX, 1
        JGE final_delay_set
        MOV EAX, 1 ; Min delay is 1ms

final_delay_set:
        
        CALL Delay
        JMP checkGameRunning

gameLoopEnd_no_delay: ; Jump target to bypass Delay when transitioning to Game Over
        JMP checkGameRunning
        

        ; --- State 6: PAUSED ---
checkLoadGame:
    CMP gameState, 9
    JNE checkNewGame
    
    CALL LoadGame
    CMP EAX, 1 ; Check success
    JE  load_success
    
    ; If load failed, go back to menu
    MOV gameState, 0
    JMP nextState
    
load_success:
    ; If load success, jump straight to running WITHOUT initialization
    MOV gameState, 5
    MOV game_initialized, 1 ; Prevents re-initialization of board/vars
    
    ; We need to manually restore the visuals once
    CALL DrawBoard
    CALL DrawPlayer
    CALL DrawScorePanel
    CALL DrawDestination ; In case one was active
    
    JMP nextState

    ; ... (State 2 New Game) ...

    ; --- State 6: PAUSED ---
checkPaused:
    CMP gameState, 6
    JNE nextState
    
    CALL Clrscr 
    MOV EDX, OFFSET pausedMsg
    CALL WriteString
    CALL Crlf

pause_wait_loop:
    CALL ReadChar
    
    CMP AL, 'P'
    JE  resume_game
    CMP AL, 'p'
    JE  resume_game
    
    CMP AL, 'S' ; <--- NEW: Save Game
    JE  save_current_game
    CMP AL, 's'
    JE  save_current_game
    
    CMP AL, 'Q'
    JE  return_to_menu_from_pause

    JMP pause_wait_loop

save_current_game:
    CALL SaveGame
    JMP checkPaused ; Refresh pause screen (shows saved msg)

resume_game:
    MOV gameState, 5
    ; Restore visuals
    CALL DrawBoard
    CALL DrawPlayer
    CALL DrawScorePanel
    CALL DrawDestination
    
    JMP nextState 

return_to_menu_from_pause:
    CALL StopBackgroundMusic
    MOV gameState, 0
    JMP nextState





        ; --- State 7: GAME_OVER (NEW) ---
checkGameOver:
        CMP gameState, 7
        JNE checkGameWin
        CALL DisplayGameOver
        JMP nextState

        ; --- State 8: GAME_WIN (NEW) ---
checkGameWin:
        CMP gameState, 8
        JNE nextState_end
        CALL DisplayGameWin
        JMP nextState

nextState_end:
        JMP nextState


nextState:
    .ENDW

    CALL CheckAndUpdateLeaderboard
    
    MOV EAX, 0
    CALL ExitProcess
main ENDP
END main



