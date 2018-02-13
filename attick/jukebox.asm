; Jukebox.exe Shamelessly stolen from Hannes Seifert, part of the gread DOS game "The clue!"
; (c) Neo Software Productions, 1994

HSCData		struc ;	(sizeof=0x12)
field_0		dw ?
field_2		dw ?
field_4		dw ?
field_6		dw ?
field_8		dw ?
field_A		dw ?
field_C		dw ?
field_E		dw ?
field_10	dw ?
HSCData		ends

; Currently doesn't work under TINY model (.com)...

.286
ifdef __TINY__
CS_OR_DATA equ cs
.model tiny
else
CS_OR_DATA equ _DATA
.model small
.stack 256
endif

.code
IFDEF __TINY__
org 100h
ENDIF

start:
		mov	ax, CS_OR_DATA
		mov	ds, ax
		call	DetectSB
		cmp	ax, 0FFFFh
		jnz	short loc_1006D
		pusha
		mov	dx, 4639h
		mov	ax, 0B800h
		mov	es, ax
		assume es:nothing
		mov	ah, 3
		mov	bh, 0
		push	dx
		int	10h		; - VIDEO - READ CURSOR	POSITION
					; BH = page number
					; Return: DH,DL	= row,column, CH = cursor start	line, CL = cursor end line
		mov	al, dl
		xor	ah, ah
		shl	ax, 1
		mov	di, ax
		mov	al, dh
		shl	ax, 5
		mov	bx, ax
		shl	bx, 2
		add	di, ax
		add	di, bx
		pop	dx
		mov	si, dx

loc_10046:				; CODE XREF: Main+43j Main+53j ...
		lodsb
		cmp	al, '$'
		jz	short loc_10069
		cmp	al, 0Ah
		jnz	short loc_10055
		add	di, 160
		jmp	short loc_10046
; ---------------------------------------------------------------------------

loc_10055:				; CODE XREF: Main+3Dj
		cmp	al, 0Dh
		jnz	short loc_10065
		mov	bl, 160
		mov	ax, di
		div	bl
		mul	bl
		mov	di, ax
		jmp	short loc_10046
; ---------------------------------------------------------------------------

loc_10065:				; CODE XREF: Main+47j
		stosb
		inc	di
		jmp	short loc_10046
; ---------------------------------------------------------------------------

loc_10069:				; CODE XREF: Main+39j
		popa
		jmp	loc_10120
; ---------------------------------------------------------------------------

loc_1006D:				; CODE XREF: Main+Bj
		mov	ax, 3
		int	10h		; - VIDEO - SET	VIDEO MODE
					; AL = mode
		mov	ax, 0B800h
		mov	es, ax
		mov	bx, 3C3h
		mov	cx, 78

loc_1007D:				; CODE XREF: Main+74j
		mov	byte ptr es:[bx], 0Fh
		add	bx, 2
		loop	loc_1007D

loc_10086:				; CODE XREF: Main+A0j Main+A8j ...
		call	IntroText

loc_10089:				; CODE XREF: Main+87j Main+8Bj
		mov	ah, 1
		int	16h		; KEYBOARD - CHECK BUFFER, DO NOT CLEAR
					; Return: ZF clear if character	in buffer
					; AH = scan code, AL = character
					; ZF set if no character in buffer
		jnz	short loc_1009D
		mov	ah, 2
		int	16h		; KEYBOARD - GET SHIFT STATUS
					; AL = shift status bits
		and	al, 1
		cmp	al, 1
		jnz	short loc_10089
		int	1Ch		; CLOCK	TICK
		jmp	short loc_10089
; ---------------------------------------------------------------------------

loc_1009D:				; CODE XREF: Main+7Dj
		xor	ax, ax
		int	16h		; KEYBOARD - READ CHAR FROM BUFFER, WAIT IF EMPTY
					; Return: AH = scan code, AL = character
		cmp	al, 0
		jnz	short loc_100CF
		cmp	ah, 48h
		jnz	short loc_100BA
		xor	al, al
		cmp	byte ptr asc_10F2F+4444h, al
		jz	short loc_10086
		mov	al, 1
		sub	byte ptr asc_10F2F+4444h, al
		jmp	short loc_10086
; ---------------------------------------------------------------------------

loc_100BA:				; CODE XREF: Main+98j
		cmp	ah, 50h
		jnz	short loc_100CF
		mov	al, 15h
		cmp	byte ptr asc_10F2F+4444h, al
		jz	short loc_10086
		mov	al, 1
		add	byte ptr asc_10F2F+4444h, al
		jmp	short loc_10086
; ---------------------------------------------------------------------------

loc_100CF:				; CODE XREF: Main+93j Main+ADj
		cmp	al, 0Dh
		jnz	short loc_100D8
		call	StartPlay
		jmp	short loc_10086
; ---------------------------------------------------------------------------

loc_100D8:				; CODE XREF: Main+C1j
		cmp	al, 2Eh
		jnz	short loc_100E3
		mov	al, 0FFh
		call	InitPlayer
		jmp	short loc_10086
; ---------------------------------------------------------------------------

loc_100E3:				; CODE XREF: Main+CAj
		cmp	al, 74h
		jnz	short loc_100EF
		mov	al, 0FFh
		xor	byte_15375, al
		jmp	short loc_10086
; ---------------------------------------------------------------------------

loc_100EF:				; CODE XREF: Main+D5j
		cmp	al, 54h
		jnz	short loc_100FB
		mov	al, 0FFh
		xor	byte_15375, al
		jmp	short loc_10086
; ---------------------------------------------------------------------------

loc_100FB:				; CODE XREF: Main+E1j
		cmp	al, 1Bh
		jz	short loc_10110
		xor	al, al
		cmp	al, Flag2
		jz	short loc_1010D
		call	RestoreTimerISR
		mov	Flag2, al

loc_1010D:				; CODE XREF: Main+F5j
		jmp	loc_10086
; ---------------------------------------------------------------------------

loc_10110:				; CODE XREF: Main+EDj
		xor	al, al
		cmp	Flag2, al
		jz	short loc_1011B
		call	RestoreTimerISR

loc_1011B:				; CODE XREF: Main+106j
		mov	ax, 3
		int	10h		; - VIDEO - SET	VIDEO MODE
					; AL = mode

loc_10120:				; CODE XREF: Main+5Aj
		mov	ax, 4C00h
		int	21h		; DOS -	2+ - QUIT WITH EXIT CODE (EXIT)
;Main		endp			; AL = exit code


; =============== S U B	R O U T	I N E =======================================


StartPlay	proc near		; CODE XREF: Main+C3p
		mov	al, byte ptr asc_10F2F+4444h
		call	OpenSndFile	; AL=index
		mov	bx, ds
		mov	si, offset SndBuffer
		call	PlayMusic
		retn
StartPlay	endp


; =============== S U B	R O U T	I N E =======================================


IntroText	proc near		; CODE XREF: Main:loc_10086p
		xor	ax, ax
		mov	al, byte ptr asc_10F2F+4444h
		mov	bl, 76
		mul	bl
		mov	si, (offset asc_10F2F+552h)
		add	si, ax
		mov	di, (offset asc_10D00+142h)
		mov	cx, 5

loc_10148:				; CODE XREF: IntroText+24j
		push	cx
		mov	cx, 76

loc_1014C:				; CODE XREF: IntroText+1Ej
		mov	al, [si]
		mov	[di], al
		inc	di
		inc	si
		loop	loc_1014C
		pop	cx
		add	di, 4
		loop	loc_10148
		xor	ax, ax
		mov	al, byte ptr asc_10F2F+4444h
		mov	bl, 80
		mul	bl
		shl	ax, 3
		mov	si, (offset asc_10F2F+0D0Ah)
		add	si, ax
		mov	di, (offset asc_10F2F+281h)
		mov	cx, 280h

loc_10171:				; CODE XREF: IntroText+43j
		mov	al, [si]
		mov	[di], al
		inc	di
		inc	si
		loop	loc_10171
		pusha
		xor	di, di
		mov	dx, 0
		mov	ax, 0B800h
		mov	es, ax
		mov	si, dx

loc_10186:				; CODE XREF: IntroText+5Fj
					; IntroText+6Fj ...
		lodsb
		cmp	al, '$'
		jz	short loc_101A9
		cmp	al, 0Ah
		jnz	short loc_10195
		add	di, 160
		jmp	short loc_10186
; ---------------------------------------------------------------------------

loc_10195:				; CODE XREF: IntroText+59j
		cmp	al, 0Dh
		jnz	short loc_101A5
		mov	bl, 160
		mov	ax, di
		div	bl
		mul	bl
		mov	di, ax
		jmp	short loc_10186
; ---------------------------------------------------------------------------

loc_101A5:				; CODE XREF: IntroText+63j
		stosb
		inc	di
		jmp	short loc_10186
; ---------------------------------------------------------------------------

loc_101A9:				; CODE XREF: IntroText+55j
		popa
		mov	ah, 2
		mov	bh, 0
		mov	dx, 2500h
		int	10h		; - VIDEO - SET	CURSOR POSITION
					; DH,DL	= row, column (0,0 = upper left)
					; BH = page number
		retn
IntroText	endp


; =============== S U B	R O U T	I N E =======================================


PlayMusic	proc near		; CODE XREF: StartPlay+Bp
		xor	al, al
		cmp	Flag2, al
		jz	short loc_101BF
		call	RestoreTimerISR

loc_101BF:				; CODE XREF: PlayMusic+6j
		xor	ax, ax
		mov	cx, bx
		mov	bx, si
		call	InitPlayer
		mov	al, 0FFh
		mov	Flag2, al
		retn
PlayMusic	endp


; =============== S U B	R O U T	I N E =======================================

; AL=index

OpenSndFile	proc near		; CODE XREF: StartPlay+3p
		pusha
		mov	di, offset SoundList

loc_101D2:				; CODE XREF: OpenSndFile+8j
					; OpenSndFile+10j
		inc	di
		cmp	byte ptr [di], 0
		jnz	short loc_101D2
		cmp	al, 0
		jz	short loc_101E0
		dec	al
		jmp	short loc_101D2
; ---------------------------------------------------------------------------

loc_101E0:				; CODE XREF: OpenSndFile+Cj
		inc	di
		mov	dx, di
		mov	ax, 3D80h
		int	21h		; DOS -	2+ - OPEN DISK FILE WITH HANDLE
					; DS:DX	-> ASCIZ filename
					; AL = access mode
					; 0 - read, 1 -	write, 2 - read	& write
		jb	short loc_10204
		mov	di, offset Handle
		mov	[di], ax
		mov	ah, 3Fh
		mov	bx, [di]
		mov	cx, 14259
		mov	dx, offset SndBuffer
		int	21h		; DOS -	2+ - READ FROM FILE WITH HANDLE
					; BX = file handle, CX = number	of bytes to read
					; DS:DX	-> buffer
		mov	ah, 3Eh
		mov	bx, [di]
		int	21h		; DOS -	2+ - CLOSE A FILE WITH HANDLE
					; BX = file handle
		jmp	short loc_10204
; ---------------------------------------------------------------------------
		nop

loc_10204:				; CODE XREF: OpenSndFile+1Aj
					; OpenSndFile+33j
		popa
		retn
OpenSndFile	endp


; =============== S U B	R O U T	I N E =======================================


Int1CISR	proc far		; DATA XREF: InitPlayer+B7o
		pusha
		push	ds
		mov	ax, CS_OR_DATA
		mov	ds, ax
		mov	si, offset byte_15375
		xor	al, al
		cmp	[si], al
		jz	short loc_10252
		mov	dx, 3DAh

loc_10219:				; CODE XREF: Int1CISR+16j
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jnz	short loc_10219
		mov	dx, 3DAh

loc_10221:				; CODE XREF: Int1CISR+1Ej
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jz	short loc_10221
		mov	dx, 3DAh

loc_10229:				; CODE XREF: Int1CISR+26j
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jz	short loc_10229
		mov	dx, 3DAh

loc_10231:				; CODE XREF: Int1CISR+2Ej
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jnz	short loc_10231
		mov	dx, 3DAh

loc_10239:				; CODE XREF: Int1CISR+36j
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 1
		jnz	short loc_10239
		mov	dx, 3DAh

loc_10241:				; CODE XREF: Int1CISR+3Ej
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 1
		jz	short loc_10241
		mov	dx, 3C0h
		mov	al, 0
		out	dx, al		; EGA: palette register: select	colors for attribute AL:
					; 0: RED
					; 1: GREEN
					; 2: BLUE
					; 3: blue
					; 4: green
					; 5: red
		mov	al, 1
		out	dx, al		; EGA: palette register: select	colors for attribute AL:
					; 0: RED
					; 1: GREEN
					; 2: BLUE
					; 3: blue
					; 4: green
					; 5: red
		mov	al, 20h
		out	dx, al		; EGA: palette register: select	colors for attribute AL:
					; 0: RED
					; 1: GREEN
					; 2: BLUE
					; 3: blue
					; 4: green
					; 5: red

loc_10252:				; CODE XREF: Int1CISR+Ej
		mov	di, offset byte_1564C
		mov	al, 1
		sub	[di], al
		mov	ah, [di]
		cmp	ah, 0
		jnz	short loc_10268
		mov	al, byte_1564E
		mov	[di], al
		call	NewSong

loc_10268:				; CODE XREF: Int1CISR+58j
		call	PlayTick
		call	CheckHscCntr
		mov	si, offset byte_15375
		xor	al, al
		cmp	[si], al
		jz	short loc_10293
		mov	dx, 3DAh

loc_1027A:				; CODE XREF: Int1CISR+77j
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 1
		jnz	short loc_1027A
		mov	dx, 3DAh

loc_10282:				; CODE XREF: Int1CISR+7Fj
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 1
		jz	short loc_10282
		mov	dx, 3C0h
		mov	al, 0
		out	dx, al		; EGA: palette register: select	colors for attribute AL:
					; 0: RED
					; 1: GREEN
					; 2: BLUE
					; 3: blue
					; 4: green
					; 5: red
		mov	al, 0
		out	dx, al		; EGA: palette register: select	colors for attribute AL:
					; 0: RED
					; 1: GREEN
					; 2: BLUE
					; 3: blue
					; 4: green
					; 5: red
		mov	al, 20h
		out	dx, al		; EGA: palette register: select	colors for attribute AL:
					; 0: RED
					; 1: GREEN
					; 2: BLUE
					; 3: blue
					; 4: green
					; 5: red

loc_10293:				; CODE XREF: Int1CISR+6Fj
		pop	ds
		popa
		iret
Int1CISR	endp


; =============== S U B	R O U T	I N E =======================================


CheckHscCntr	proc near		; CODE XREF: Int1CISR+65p
		cmp	byte_15651, 0
		jz	short loc_102A8
		cmp	HscCntr, 63
		jz	short loc_102A8
		inc	HscCntr

loc_102A8:				; CODE XREF: CheckHscCntr+5j
					; CheckHscCntr+Cj
		cmp	byte_15652, 0
		jz	short locret_102BA
		cmp	HscCntr, 0
		jz	short locret_102BA
		dec	HscCntr

locret_102BA:				; CODE XREF: CheckHscCntr+17j
					; CheckHscCntr+1Ej
		retn
CheckHscCntr	endp


; =============== S U B	R O U T	I N E =======================================


NewSong		proc near		; CODE XREF: Int1CISR+5Fp
		mov	si, Song
		add	si, 1587
		mov	bx, Song
		add	bx, 1536
		xor	ax, ax
		mov	al, byte_1564F
		add	bx, ax
		xor	ax, ax
		push	ds
		mov	ds, word_1568E
		mov	al, [bx]
		pop	ds
		mov	bx, 1152
		mul	bx
		add	si, ax
		xor	ax, ax
		mov	al, byte_15650
		mov	bl, 12h
		mul	bl
		add	si, ax
		mov	cx, 9

loc_102F1:				; CODE XREF: NewSong+39j
		call	SomeHSC2
		loop	loc_102F1
		mov	di, offset byte_15650
		mov	al, 1
		add	[di], al
		mov	bl, [di]
		cmp	bl, 40h
		jnz	short locret_1032B
		xor	al, al
		mov	[di], al
		mov	di, offset byte_1564F
		mov	al, 1
		add	[di], al
		mov	si, Song
		add	si, 1536
		xor	bx, bx
		mov	bl, [di]
		push	ds
		mov	ds, word_1568E
		mov	al, [bx+si]
		pop	ds
		cmp	al, 0FFh
		jnz	short locret_1032B
		xor	al, al
		mov	[di], al

locret_1032B:				; CODE XREF: NewSong+47j NewSong+6Aj
		retn
NewSong		endp


; =============== S U B	R O U T	I N E =======================================


SomeHSC2	proc near		; CODE XREF: NewSong:loc_102F1p
		xor	ax, ax
		push	ds
		mov	ds, word_1568E
		mov	al, [si]
		pop	ds
		inc	si
		cmp	al, 80h
		jz	short loc_1033E
		jmp	short loc_10341
; ---------------------------------------------------------------------------
		align 2

loc_1033E:				; CODE XREF: SomeHSC2+Dj
		jmp	loc_104FC
; ---------------------------------------------------------------------------

loc_10341:				; CODE XREF: SomeHSC2+Fj
		cmp	al, 0
		jz	short loc_1034C
		mov	ah, 9
		sub	ah, cl
		call	SomeHSC

loc_1034C:				; CODE XREF: SomeHSC2+17j
		push	ds
		mov	ds, word_1568E
		mov	al, [si]
		pop	ds
		inc	si
		cmp	al, 0
		jnz	short loc_1035C
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_1035C:				; CODE XREF: SomeHSC2+2Bj
		cmp	al, 1
		jnz	short loc_10369
		mov	ah, 3Fh
		mov	byte_15650, ah
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_10369:				; CODE XREF: SomeHSC2+32j
		cmp	al, 2
		jnz	short loc_1037A
		mov	byte_15651, 0FFh
		mov	byte_15652, 0
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_1037A:				; CODE XREF: SomeHSC2+3Fj
		cmp	al, 3
		jnz	short loc_10390
		mov	byte_15652, 0FFh
		mov	byte_15651, 0
		mov	HscCntr, 3Fh
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_10390:				; CODE XREF: SomeHSC2+50j
		cmp	al, 4
		jnz	short loc_1039C
		mov	HscCntr, 0
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_1039C:				; CODE XREF: SomeHSC2+66j
		cmp	al, 5
		jnz	short loc_103A8
		or	byte_15690, 20h
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_103A8:				; CODE XREF: SomeHSC2+72j
		cmp	al, 6
		jnz	short loc_103B4
		and	byte_15690, 0DFh
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_103B4:				; CODE XREF: SomeHSC2+7Ej
		mov	ah, al
		and	ax, 0FF0h
		shr	al, 4
		cmp	al, 1
		jnz	short loc_103D1
		mov	di, offset stru_15600
		mov	bx, 9
		sub	bx, cx
		shl	bx, 1
		inc	ah
		add	[bx+di], ah
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_103D1:				; CODE XREF: SomeHSC2+92j
		cmp	al, 2
		jnz	short loc_103E6
		mov	di, offset stru_15600
		mov	bx, 9
		sub	bx, cx
		shl	bx, 1
		inc	ah
		sub	[bx+di], ah
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_103E6:				; CODE XREF: SomeHSC2+A7j
		cmp	al, 5
		jnz	short loc_10403
		push	bx
		push	cx
		mov	bl, 1
		mov	cl, ah
		shl	bl, cl
		and	byte_15690, 0E0h
		and	bl, 1Fh
		or	byte_15690, bl
		pop	cx
		pop	bx
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_10403:				; CODE XREF: SomeHSC2+BCj
		cmp	al, 6
		jnz	short loc_1045A
		push	bx
		push	di
		push	si
		and	ah, 7
		shl	ah, 1
		mov	bx, 9
		sub	bx, cx
		push	ax
		push	bx
		mov	si, offset byte_15655
		mov	al, [bx+si]
		xor	ah, ah
		mov	bx, 0Ch
		mul	bx
		mov	si, Song
		add	si, ax
		pop	bx
		pop	ax
		push	ds
		mov	ds, word_1568E
		mov	al, [si+8]
		and	al, 1
		or	al, ah
		push	dx
		push	ax
		mov	dx, BasePort
		mov	al, 0C0h
		mov	bx, 9
		sub	bx, cx
		add	al, bl
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		pop	ax
		out	dx, al
		call	Wait2
		pop	dx
		pop	ds
		pop	si
		pop	di
		pop	bx
		jmp	loc_104DA
; ---------------------------------------------------------------------------

loc_1045A:				; CODE XREF: SomeHSC2+D9j
		cmp	al, 0Ah
		jnz	short loc_1046E
		shl	ah, 2
		mov	di, offset byte_15624
		mov	bx, 9
		sub	bx, cx
		mov	[bx+di], ah
		jmp	short loc_104DA
; ---------------------------------------------------------------------------
		align 2

loc_1046E:				; CODE XREF: SomeHSC2+130j
		cmp	al, 0Bh
		jnz	short loc_10483
		shl	ah, 2
		mov	di, offset byte_15624
		mov	bx, 9
		sub	bx, cx
		mov	[bx+di+9], ah
		jmp	short loc_104DA
; ---------------------------------------------------------------------------
		nop

loc_10483:				; CODE XREF: SomeHSC2+144j
		cmp	al, 0Ch
		jnz	short loc_104BE
		shl	ah, 2
		mov	di, offset byte_15624
		mov	bx, 9
		sub	bx, cx
		mov	[bx+di], ah
		push	si
		push	ax
		push	bx
		mov	si, offset byte_15655
		mov	al, [bx+si]
		xor	ah, ah
		mov	bx, 0Ch
		mul	bx
		mov	si, Song
		add	si, ax
		pop	bx
		pop	ax
		push	ds
		mov	ds, word_1568E
		test	byte ptr [si+8], 1
		pop	ds
		pop	si
		jz	short loc_104BB
		mov	[bx+di+9], ah

loc_104BB:				; CODE XREF: SomeHSC2+18Aj
		jmp	short loc_104DA
; ---------------------------------------------------------------------------
		align 2

loc_104BE:				; CODE XREF: SomeHSC2+159j
		cmp	al, 0Dh
		jnz	short loc_104CE
		mov	byte_1564F, ah
		mov	byte_15650, 3Fh
		jmp	short loc_104DA
; ---------------------------------------------------------------------------
		align 2

loc_104CE:				; CODE XREF: SomeHSC2+194j
		cmp	al, 0Fh
		inc	ah
		mov	byte_1564E, ah
		mov	byte_1564C, ah

loc_104DA:				; CODE XREF: SomeHSC2+2Dj SomeHSC2+3Aj ...
		mov	al, byte_15690
		cmp	byte_15691, al
		jz	short locret_104FB
		mov	byte_15691, al
		mov	dx, BasePort
		mov	al, 0BDh
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, byte_15690
		out	dx, al
		call	Wait2

locret_104FB:				; CODE XREF: SomeHSC2+1B5j
		retn
; ---------------------------------------------------------------------------

loc_104FC:				; CODE XREF: SomeHSC2:loc_1033Ej
		push	ds
		mov	ds, word_1568E
		mov	al, [si]
		pop	ds
		and	al, 7Fh
		inc	si
		mov	ah, 9
		sub	ah, cl
		call	PutAXIns
		jmp	short loc_104DA
SomeHSC2	endp


; =============== S U B	R O U T	I N E =======================================


RestoreTimerISR	proc near		; CODE XREF: Main+F7p Main+108p ...
		pusha
		push	ds
		mov	ax, CS_OR_DATA
		mov	ds, ax
		mov	ax, 251Ch
		mov	dx, word ptr OldInt1C
		mov	cx, word ptr OldInt1C+2
		mov	ds, cx
		int	21h		; DOS -	SET INTERRUPT VECTOR
					; AL = interrupt number
					; DS:DX	= new vector to	be used	for specified interrupt
		mov	ax, CS_OR_DATA
		mov	ds, ax
		xor	al, al
		cmp	Flag1, al
		jnz	short loc_10536
		call	InitSB

loc_10536:				; CODE XREF: RestoreTimerISR+21j
		pop	ds
		popa
		retn
RestoreTimerISR	endp


; =============== S U B	R O U T	I N E =======================================


InitPlayer	proc near		; CODE XREF: Main+CEp PlayMusic+11p
		pusha
		push	es
		push	ds
		mov	dx, CS_OR_DATA
		mov	ds, dx
		cmp	al, 0FFh
		jnz	short loc_10550
		mov	byte_15651, al
		mov	byte_15652, 0
		jmp	loc_10615
; ---------------------------------------------------------------------------

loc_10550:				; CODE XREF: InitPlayer+Aj
		mov	Song, bx
		mov	word_1568E, cx
		xor	al, al
		cmp	Flag1, al
		jnz	short loc_10563
		call	InitSB

loc_10563:				; CODE XREF: InitPlayer+25j
		mov	dx, BasePort
		mov	al, 1
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 20h
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 8
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 40h
		out	dx, al
		call	Wait2
		xor	al, al
		cmp	Flag1, al
		jnz	short loc_105BA
		mov	byte_15690, 0
		mov	dx, BasePort
		mov	al, 0BDh
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, byte_15690
		out	dx, al
		call	Wait2
		xor	ax, ax
		mov	cx, 9

loc_105B2:				; CODE XREF: InitPlayer+7Fj
		call	PutAXIns
		add	ax, 257
		loop	loc_105B2

loc_105BA:				; CODE XREF: InitPlayer+58j
		mov	byte_15651, 0
		mov	byte_15652, 0
		mov	HscCntr, 0
		mov	byte_1564C, 1
		xor	al, al
		mov	byte_1564F, al
		mov	byte_15650, al
		mov	al, 2
		mov	byte_1564E, al
		mov	ax, 351Ch
		int	21h		; DOS -	2+ - GET INTERRUPT VECTOR
					; AL = interrupt number
					; Return: ES:BX	= value	of interrupt vector
		mov	word ptr OldInt1C+2, es
		mov	word ptr OldInt1C, bx
		mov	ax, cs
		mov	ds, ax
;		assume ds:code
		mov	ax, 251Ch
		mov	dx, offset cs:Int1CISR
		int	21h		; DOS -	SET INTERRUPT VECTOR
					; AL = interrupt number
					; DS:DX	= new vector to	be used	for specified interrupt
		mov	ax, CS_OR_DATA
		mov	ds, ax
;		assume ds:seg001
		mov	di, offset word_15612
		mov	cx, 12h

loc_10600:				; CODE XREF: InitPlayer+CAj
		mov	byte ptr [di], 0FFh
		loop	loc_10600
		mov	di, offset word_15636
		mov	cx, 12h

loc_1060B:				; CODE XREF: InitPlayer+D5j
		mov	byte ptr [di], 0FFh
		loop	loc_1060B
		mov	byte_15654, 0FFh

loc_10615:				; CODE XREF: InitPlayer+14j
		pop	ds
		pop	es
		assume es:nothing
		popa
		retn
InitPlayer	endp


; =============== S U B	R O U T	I N E =======================================


InitSB		proc near		; CODE XREF: RestoreTimerISR+23p
					; InitPlayer+27p
		mov	dx, BasePort
		mov	al, 1
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0B0h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0B1h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0B2h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0B3h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0B4h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0B5h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0B6h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0B7h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0B8h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 80h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 81h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 82h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 83h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 84h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 85h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 88h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 89h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 8Ah
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 8Bh
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 8Ch
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 8Dh
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 90h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 91h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 92h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 93h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 94h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 95h
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	di, offset stru_15600
		xor	ax, ax
		mov	[di+HSCData.field_0], ax
		mov	[di+HSCData.field_2], ax
		mov	[di+HSCData.field_4], ax
		mov	[di+HSCData.field_6], ax
		mov	[di+HSCData.field_8], ax
		mov	[di+HSCData.field_A], ax
		mov	[di+HSCData.field_C], ax
		mov	[di+HSCData.field_E], ax
		mov	[di+HSCData.field_10], ax
		retn
InitSB		endp


; =============== S U B	R O U T	I N E =======================================


PutAXIns	proc near		; CODE XREF: SomeHSC2+1DFp
					; InitPlayer:loc_105B2p
		pusha
		xor	cx, cx
		mov	di, offset byte_15655
		xor	bx, bx
		mov	bl, ah
		mov	[bx+di], al
		mov	cl, ah
		xor	ah, ah
		mov	bx, 0Ch
		mul	bx
		mov	si, Song
		add	si, ax
		mov	dx, BasePort
		mov	al, 0B0h
		add	al, cl
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		xor	al, al
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0C0h
		add	al, cl
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si+8]
		pop	ds
		out	dx, al
		call	Wait2
		mov	di, offset word_155C4
		rol	cx, 1
		add	di, cx
		ror	cx, 1
		mov	dx, BasePort
		mov	al, 20h
		add	al, [di]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si]
		pop	ds
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 20h
		add	al, [di+1]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si+1]
		pop	ds
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 60h
		add	al, [di]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si+4]
		pop	ds
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 60h
		add	al, [di+1]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si+5]
		pop	ds
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 80h
		add	al, [di]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si+6]
		pop	ds
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 80h
		add	al, [di+1]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si+7]
		pop	ds
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0E0h
		add	al, [di]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si+9]
		pop	ds
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0E0h
		add	al, [di+1]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si+0Ah]
		pop	ds
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 40h
		add	al, [di]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si+2]
		pop	ds
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 40h
		add	al, [di+1]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		push	ds
		mov	ds, word_1568E
		mov	al, [si+3]
		pop	ds
		out	dx, al
		call	Wait2
		mov	di, offset byte_15624
		add	di, cx
		push	ds
		mov	ds, word_1568E
		mov	al, [si+2]
		pop	ds
		mov	[di], al
		push	ds
		mov	ds, word_1568E
		mov	al, [si+3]
		pop	ds
		mov	[di+9],	al
		push	ds
		mov	ds, word_1568E
		mov	al, [si+0Bh]
		pop	ds
		and	al, 0F0h
		shr	al, 4
		mov	di, offset byte_1565E
		add	di, cx
		mov	[di], al
		popa
		retn
PutAXIns	endp


; =============== S U B	R O U T	I N E =======================================


SomeHSC		proc near		; CODE XREF: SomeHSC2+1Dp
		pusha
		cmp	al, 7Fh
		jnz	short loc_10A21
		jmp	short loc_10A6A
; ---------------------------------------------------------------------------
		nop

loc_10A21:				; CODE XREF: SomeHSC+3j
		dec	al
		mov	byte_1564D, al
		xor	cx, cx
		mov	cl, ah
		mov	di, offset word_155C4
		rol	cx, 1
		add	di, cx
		ror	cx, 1
		mov	dx, BasePort
		mov	al, 0B0h
		add	al, cl
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		xor	al, al
		out	dx, al
		call	Wait2
		mov	bx, offset stru_15600
		rol	cx, 1
		mov	di, cx
		ror	cx, 1
		add	di, bx
		mov	si, offset word_154EC
		xor	bx, bx
		mov	bl, byte_1564D
		rol	bx, 1
		mov	ax, [bx+si]
		mov	[di], ax
		mov	word ptr [di+12h], 0FFFFh

loc_10A68:				; CODE XREF: SomeHSC+65j
		popa
		retn
; ---------------------------------------------------------------------------

loc_10A6A:				; CODE XREF: SomeHSC+5j
		mov	al, ah
		xor	ah, ah
		mov	bx, offset stru_15600
		rol	ax, 1
		mov	di, ax
		add	di, bx
		mov	ax, [di]
		and	ah, 0DFh
		mov	[di], ax
		jmp	short loc_10A68
SomeHSC		endp


; =============== S U B	R O U T	I N E =======================================


PlayTick	proc near		; CODE XREF: Int1CISR:loc_10268p
		pusha
		mov	cx, 9
		mov	si, offset stru_15600.field_10
		mov	di, offset byte_1562C

loc_10A8A:				; CODE XREF: PlayTick+48j
		dec	cx
		mov	ax, [si]
		cmp	ax, [si+12h]
		jz	short loc_10A9C
		mov	[si+12h], ax
		push	si
		push	di
		call	SomeHSC3
		pop	di
		pop	si

loc_10A9C:				; CODE XREF: PlayTick+10j
		mov	al, HscCntr
		cmp	al, byte_15654
		jnz	short loc_10ABD
		mov	al, [di]
		cmp	al, [di+12h]
		jnz	short loc_10ABA
		mov	al, [di+9]
		cmp	al, [di+1Bh]
		jz	short loc_10AC4
		mov	[di+1Bh], al
		jmp	short loc_10ABD
; ---------------------------------------------------------------------------
		align 2

loc_10ABA:				; CODE XREF: PlayTick+2Aj
		mov	[di+12h], al

loc_10ABD:				; CODE XREF: PlayTick+23j PlayTick+37j
		push	si
		push	di
		call	SomeHSC4
		pop	di
		pop	si

loc_10AC4:				; CODE XREF: PlayTick+32j
		dec	di
		dec	si
		dec	si
		inc	cx
		loop	loc_10A8A
		mov	al, HscCntr
		mov	byte_15654, al
		popa
		retn
PlayTick	endp


; =============== S U B	R O U T	I N E =======================================


SomeHSC3	proc near		; CODE XREF: PlayTick+17p
		mov	dx, BasePort
		mov	al, 0A0h
		add	al, cl
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	bx, offset stru_15600
		rol	cx, 1
		mov	si, cx
		ror	cx, 1
		mov	al, [bx+si]
		mov	di, offset byte_1565E
		add	di, cx
		add	al, [di]
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 0B0h
		add	al, cl
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, [bx+si+1]
		out	dx, al
		call	Wait2
		retn
SomeHSC3	endp


; =============== S U B	R O U T	I N E =======================================


SomeHSC4	proc near		; CODE XREF: PlayTick+3Fp
		mov	si, offset byte_15624
		add	si, cx
		mov	di, offset word_155C4
		rol	cx, 1
		add	di, cx
		ror	cx, 1
		mov	dx, BasePort
		mov	al, 40h
		add	al, [di]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 3Fh
		sub	al, [si]
		push	dx
		mov	dh, al
		and	dh, 0C0h
		and	ax, 3Fh
		push	dx
		mov	bl, 3Fh
		sub	bl, HscCntr
		xor	bh, bh
		mul	bx
		mov	bx, 3Fh
		div	bx
		pop	dx
		mov	dl, al
		mov	al, 3Fh
		sub	al, dl
		and	al, 3Fh
		or	al, dh
		pop	dx
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 40h
		add	al, [di+1]
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, [si+9]
		push	di
		push	ax
		push	dx
		push	bx
		mov	di, offset byte_15655
		mov	bx, cx
		mov	al, [bx+di]
		xor	ah, ah
		mov	bx, 12
		mul	bx
		mov	di, Song
		add	di, ax
		push	ds
		mov	ds, word_1568E
		test	byte ptr [di+8], 1
		pop	ds
		jnz	short loc_10B9A
		pop	bx
		pop	dx
		pop	ax
		pop	di
		jmp	short loc_10BC8
; ---------------------------------------------------------------------------
		align 2

loc_10B9A:				; CODE XREF: SomeHSC4+81j
		pop	bx
		pop	dx
		pop	ax
		pop	di
		mov	al, 3Fh
		sub	al, [si+9]
		push	dx
		mov	dh, al
		and	dh, 0C0h
		and	ax, 3Fh
		push	dx
		mov	bl, 63
		sub	bl, HscCntr
		xor	bh, bh
		mul	bx
		mov	bx, 63
		div	bx
		pop	dx
		mov	dl, al
		mov	al, 3Fh
		sub	al, dl
		and	al, 3Fh
		or	al, dh
		pop	dx

loc_10BC8:				; CODE XREF: SomeHSC4+87j
		out	dx, al
		call	Wait2
		retn
SomeHSC4	endp


; =============== S U B	R O U T	I N E =======================================


DetectSB	proc near		; CODE XREF: Main+5p
		pusha
		push	ds
		mov	ax, CS_OR_DATA
		mov	ds, ax
		mov	bx, offset SBPorts

loc_10BD7:				; CODE XREF: DetectSB+104j
		mov	dx, [bx]
		mov	BasePort, dx
		inc	dx
		mov	word_155FC, dx
		mov	dx, 3DAh

loc_10BE5:				; CODE XREF: DetectSB+1Bj
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jnz	short loc_10BE5
		mov	dx, 3DAh

loc_10BED:				; CODE XREF: DetectSB+23j
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jz	short loc_10BED
		mov	dx, 3DAh

loc_10BF5:				; CODE XREF: DetectSB+2Bj
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jz	short loc_10BF5
		mov	dx, 3DAh

loc_10BFD:				; CODE XREF: DetectSB+33j
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jnz	short loc_10BFD
		mov	dx, BasePort
		mov	al, 4
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 60h
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 4
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 80h
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		in	al, dx
		and	al, 0E0h
		mov	byte_155FE, al
		mov	dx, BasePort
		mov	al, 2
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 0FFh
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 4
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 21h
		out	dx, al
		call	Wait2
		mov	dx, 3DAh

loc_10C5F:				; CODE XREF: DetectSB+95j
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jnz	short loc_10C5F
		mov	dx, 3DAh

loc_10C67:				; CODE XREF: DetectSB+9Dj
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jz	short loc_10C67
		mov	dx, 3DAh

loc_10C6F:				; CODE XREF: DetectSB+A5j
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jz	short loc_10C6F
		mov	dx, 3DAh

loc_10C77:				; CODE XREF: DetectSB+ADj
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 8
		jnz	short loc_10C77
		mov	dx, BasePort
		in	al, dx
		and	al, 0E0h
		mov	byte_155FF, al
		mov	dx, BasePort
		mov	al, 4
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 60h
		out	dx, al
		call	Wait2
		mov	dx, BasePort
		mov	al, 4
		out	dx, al
		call	Wait1
		mov	dx, word_155FC
		mov	al, 80h
		out	dx, al
		call	Wait2
		cmp	byte_155FE, 0
		jnz	short loc_10CC7
		cmp	byte_155FF, 0C0h
		jnz	short loc_10CC7
		xor	ax, ax

loc_10CBE:				; CODE XREF: DetectSB+10Aj
		pop	ds
		mov	SBPort,	ax
		popa
		mov	ax, SBPort
		retn
; ---------------------------------------------------------------------------

loc_10CC7:				; CODE XREF: DetectSB+E6j DetectSB+EDj
		add	bx, 2
		mov	dx, [bx]
		cmp	dx, 0FFFFh
		jz	short loc_10CD4
		jmp	loc_10BD7
; ---------------------------------------------------------------------------

loc_10CD4:				; CODE XREF: DetectSB+102j
		mov	ax, 0FFFFh
		jmp	short loc_10CBE
DetectSB	endp


; =============== S U B	R O U T	I N E =======================================


Wait1		proc near		; CODE XREF: SomeHSC2+11Ap
					; SomeHSC2+1C1p ...
		pusha
		mov	dx, 3DAh

loc_10CDD:				; CODE XREF: Wait1+7j
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 1
		jnz	short loc_10CDD
		mov	dx, 3DAh

loc_10CE5:				; CODE XREF: Wait1+Fj
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 1
		jz	short loc_10CE5
		popa
		retn
Wait1		endp


; =============== S U B	R O U T	I N E =======================================


Wait2		proc near		; CODE XREF: SomeHSC2+123p
					; SomeHSC2+1CCp ...
		pusha
		mov	dx, 3DAh

loc_10CF0:				; CODE XREF: Wait2+7j
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 1
		jnz	short loc_10CF0
		mov	dx, 3DAh

loc_10CF8:				; CODE XREF: Wait2+Fj
		in	al, dx		; Video	status bits:
					; 0: retrace.  1=display is in vert or horiz retrace.
					; 1: 1=light pen is triggered; 0=armed
					; 2: 1=light pen switch	is open; 0=closed
					; 3: 1=vertical	sync pulse is occurring.
		test	al, 1
		jz	short loc_10CF8
		popa
		retn
Wait2		endp

		align 2

; ===========================================================================
.data
asc_10D00	db 'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ'
		db 'ออออออออออออออปบHSC Adlib Composer Version 3.1 Der Clou!. (W) 199'
		db '4 Hannes Seifert/NEO Project.บศออออออออออออออออออออออออออออออออออ'
		db 'ออออออออออออออออออออออออออออออออออออออออออออผษอออออออออออออออออออ'
		db 'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออปบ    '
		db '                                                                 '
		db '         บบ                                                      '
		db '                        บบ'
		db 10h
aXxxxxxxxxxxxxx	db ' xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
		db 'xxxxxxxxx  '
		db 11h
asc_10F2F	db 'บบ                                                               '
		db '               บบ                                                '
		db '                              บศอออออออออออออออออออออออออออออออออ'
		db 'อออออออออออออออออออออออออออออออออออออออออออออผษออออออออออออออออออ'
		db 'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออปบ   '
		db ' Cursor up and down: Select song. RETURN: Start Song. Right Shift'
		db ': Fast    บบ  forward. ',27h,'.',27h,': Fade out. ',27h,'t',27h,': Show Raste'
		db 'r Time. ',27h,'ESC',27h,'. Quit. Other: Silence. บศออออออออออออออออออออ'
		db 'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผษอออออ'
		db 'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ'
		db 'ออออออออปบ                                                       '
		db '                       บบ                                        '
		db '                                      บบ                         '
		db '                                                     บบ          '
		db '                                                                 '
		db '   บบ                                                            '
		db '                  บบ                                             '
		db '                                 บบ                              '
		db '                                                บบ               '
		db '                                                               บศ'
		db 'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ'
		db 'อออออออออออออผ$                                                  '
		db '                                                                 '
		db '                                       Title Music               '
		db '        (C) 1994 NEO.                    1        Bar 1 Music    '
		db '                   (C) 1994 NEO.                    2        Bar '
		db '2 Music                       (C) 1994 NEO.                    3 '
		db '       Burglary starts...                (C) 1994 NEO.           '
		db '         4        Burglary is running...            (C) 1994 NEO.'
		db '                    5        At Cars and Vans',27h,'                '
		db ' (C) 1994 NEO.                    6        At Pooly',27h,'s         '
		db '               (C) 1994 NEO.                    7        Lonely i'
		db 'n Southampton.            (C) 1994 NEO.                    8     '
		db '   At the Police...                  (C) 1994 NEO.               '
		db '     9        Failed...                         (C) 1994 NEO.    '
		db '               10        Victory...                        (C) 19'
		db '94 NEO.                   11        The Clou!...                 '
		db '     (C) 1994 NEO.                   12        Gludo',27h,'s Theme  '
		db '                   (C) 1994 NEO.                   13        At t'
		db 'he Hotel                      (C) 1994 NEO.                   14 '
		db '       You investigate                   (C) 1994 NEO.           '
		db '        15        At Maloya',27h,'s                       (C) 1994 N'
		db 'EO.                   16        At Parker',27h,'s                   '
		db '    (C) 1994 NEO.                   17        Sabien',27h,'s Theme  '
		db '                  (C) 1994 NEO.                   18        Tools'
		db ' Shop                        (C) 1994 NEO.                   19  '
		db '      The Streets 1                     (C) 1994 NEO.            '
		db '       20        The Streets 2                     (C) 1994 NEO. '
		db '                  21        The Streets 3                     (C)'
		db ' 1994 NEO.                   22                                  '
		db '                                                                 '
		db '                                                           บ Welc'
		db 'ome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' Musicdemo.           '
		db '                    บบ                                           '
		db '                                   บบ                            '
		db '                                                  บบ             '
		db '                                                                 '
		db 'บบ                                                               '
		db '               บบ                                                '
		db '                              บบ                                 '
		db '                                             บบ                  '
		db '                                                   Music 1  บบ We'
		db 'lcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' Musicdemo.         '
		db '                      บบ                                         '
		db '                                     บบ                          '
		db '                                                    บบ           '
		db '                                                                 '
		db '  บบ                                                             '
		db '                 บบ                                              '
		db '                                บบ                               '
		db '                                               บบ                '
		db '                                                     Music 2  บบ '
		db 'Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' Musicdemo.       '
		db '                        บบ                                       '
		db '                                       บบ                        '
		db '                                                      บบ         '
		db '                                                                 '
		db '    บบ                                                           '
		db '                   บบ                                            '
		db '                                  บบ                             '
		db '                                                 บบ              '
		db '                                                       Music 3  บ'
		db 'บ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' Musicdemo.     '
		db '                          บบ                                     '
		db '                                         บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                         Music 4 '
		db ' บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' Musicdemo.   '
		db '                            บบ                                   '
		db '                                           บบ                    '
		db '                                                          บบ     '
		db '                                                                 '
		db '        บบ                                                       '
		db '                       บบ                                        '
		db '                                      บบ                         '
		db '                                                     บบ          '
		db '                                                           Music '
		db '5  บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' Musicdemo. '
		db '                              บบ                                 '
		db '                                             บบ                  '
		db '                                                            บบ   '
		db '                                                                 '
		db '          บบ                                                     '
		db '                         บบ                                      '
		db '                                        บบ                       '
		db '                                                       บบ        '
		db '                                                             Musi'
		db 'c 6  บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' Musicdemo'
		db '.                               บบ                               '
		db '                                               บบ                '
		db '                                                              บบ '
		db '                                                                 '
		db '            บบ                                                   '
		db '                           บบ                                    '
		db '                                          บบ                     '
		db '                                                         บบ      '
		db '                                                               Mu'
		db 'sic 7  บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' Musicde'
		db 'mo.                               บบ                             '
		db '                                                 บบ              '
		db '                                                                บ'
		db 'บ                                                                '
		db '              บบ                                                 '
		db '                             บบ                                  '
		db '                                            บบ                   '
		db '                                                           บบ    '
		db '                                                                 '
		db 'Music 8  บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' Music'
		db 'demo.                               บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '                บบ                                               '
		db '                               บบ                                '
		db '                                              บบ                 '
		db '                                                             บบ  '
		db '                                                                 '
		db '  Music 9  บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' Mus'
		db 'icdemo.                               บบ                         '
		db '                                                     บบ          '
		db '                                                                 '
		db '   บบ                                                            '
		db '                  บบ                                             '
		db '                                 บบ                              '
		db '                                                บบ               '
		db '                                                               บบ'
		db '                                                                 '
		db '    Music 10 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' M'
		db 'usicdemo.                               บบ                       '
		db '                                                       บบ        '
		db '                                                                 '
		db '     บบ                                                          '
		db '                    บบ                                           '
		db '                                   บบ                            '
		db '                                                  บบ             '
		db '                                                                 '
		db 'บบ                                                               '
		db '      Music 11 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 12 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 13 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 14 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 15 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 16 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 17 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 18 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 19 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 20 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 21 บบ Welcome to ',27h,'DER CLOU!',27h,', ',27h,'THE CLUE!',27h,' '
		db 'Musicdemo.                               บบ                      '
		db '                                                        บบ       '
		db '                                                                 '
		db '      บบ                                                         '
		db '                     บบ                                          '
		db '                                    บบ                           '
		db '                                                   บบ            '
		db '                                                                 '
		db ' บบ                                                              '
		db '       Music 22 บSorry, there',27h,'s no Adlib compatible card in th'
		db 'is system.',0Dh,0Ah
		db '$',0
Flag2		db 0			; DATA XREF: Main+F1r Main+FAw ...
byte_15375	db 0			; DATA XREF: Main+D9w Main+E5w ...
Flag1		db 0			; DATA XREF: RestoreTimerISR+1Dr
					; InitPlayer+21r ...
Handle		db 0			; DATA XREF: OpenSndFile+1Co
SoundList	db 0			; DATA XREF: OpenSndFile+1o
		db 0
aSoundsTitle_bk	db 'sounds\title.bk',0
aSoundsBar1_bk	db 'sounds\bar1.bk',0
aSoundsBar2_bk	db 'sounds\bar2.bk',0
aSoundsBruch1_b	db 'sounds\bruch1.bk',0
aSoundsBruch2_b	db 'sounds\bruch2.bk',0
aSoundsCars_bk	db 'sounds\cars.bk',0
aSoundsDealer_b	db 'sounds\dealer.bk',0
aSoundsEnd_bk	db 'sounds\end.bk',0
aSoundsFahndung	db 'sounds\fahndung.bk',0
aSoundsFailed_b	db 'sounds\failed.bk',0
aSoundsOk_bk	db 'sounds\ok.bk',0
aSoundsFinal_bk	db 'sounds\final.bk',0
aSoundsGludo_bk	db 'sounds\gludo.bk',0
aSoundsHotel_bk	db 'sounds\hotel.bk',0
aSoundsInvest_b	db 'sounds\invest.bk',0
aSoundsMaloya_b	db 'sounds\maloya.bk',0
aSoundsParker_b	db 'sounds\parker.bk',0
aSoundsSabien_b	db 'sounds\sabien.bk',0
aSoundsShop_bk	db 'sounds\shop.bk',0
aSoundsStreet1_	db 'sounds\street1.bk',0
aSoundsStreet2_	db 'sounds\street2.bk',0
aSoundsStreet3_	db 'sounds\street3.bk',0
SBPorts		dw 218h, 288h, 318h, 388h, 0FFFFh ; DATA XREF: DetectSB+7o
word_154EC	dw 216Bh, 2181h, 2198h,	21B0h, 21CAh, 21E5h, 2202h, 2220h
					; DATA XREF: SomeHSC+3Bo
		dw 2241h, 2263h, 2287h,	22AEh, 256Bh, 2581h, 2598h, 25B0h
		dw 25CAh, 25E5h, 2602h,	2620h, 2641h, 2663h, 2687h, 26AEh
		dw 296Bh, 2981h, 2998h,	29B0h, 29CAh, 29E5h, 2A02h, 2A20h
		dw 2A41h, 2A63h, 2A87h,	2AAEh, 2D6Bh, 2D81h, 2D98h, 2DB0h
		dw 2DCAh, 2DE5h, 2E02h,	2E20h, 2E41h, 2E63h, 2E87h, 2EAEh
		dw 316Bh, 3181h, 3198h,	31B0h, 31CAh, 31E5h, 3202h, 3220h
		dw 3241h, 3263h, 3287h,	32AEh, 356Bh, 3581h, 3598h, 35B0h
		dw 35CAh, 35E5h, 3602h,	3620h, 3641h, 3663h, 3687h, 36AEh
		dw 396Bh, 3981h, 3998h,	39B0h, 39CAh, 39E5h, 3A02h, 3A20h
		dw 3A41h, 3A63h, 3A87h,	3AAEh, 3D6Bh, 3D81h, 3D98h, 3DB0h
		dw 3DCAh, 3DE5h, 3E02h,	3E20h, 3E41h, 3E63h, 3E87h, 3EAEh
		dw 0Ch dup(0)
word_155C4	dw 3, 104h, 205h, 80Bh,	90Ch, 0A0Dh, 1013h, 1114h, 1215h
					; DATA XREF: PutAXIns+4Eo SomeHSC+11o	...
		db 9 dup(0)
		db 9 dup(0)
		db 9 dup(0)
		db 9 dup(0)
BasePort	dw 0			; DATA XREF: SomeHSC2+10Cr
					; SomeHSC2+1BAr ...
word_155FC	dw 0			; DATA XREF: SomeHSC2+11Dr
					; SomeHSC2+1C4r ...
byte_155FE	db 0			; DATA XREF: DetectSB+64w DetectSB+E1r
byte_155FF	db 0			; DATA XREF: DetectSB+B6w DetectSB+E8r
stru_15600	HSCData	<0>		; DATA XREF: SomeHSC2+94o SomeHSC2+A9o ...
word_15612	dw 9 dup(0FFFFh)	; DATA XREF: InitPlayer+C1o
byte_15624	db 8 dup(0)		; DATA XREF: SomeHSC2+135o
					; SomeHSC2+149o ...
byte_1562C	db 0Ah dup(0)		; DATA XREF: PlayTick+7o
word_15636	dw 9 dup(0)		; DATA XREF: InitPlayer+CCo
OldInt1C	dd 0			; DATA XREF: RestoreTimerISR+Ar
					; InitPlayer+ABw ...
byte_1564C	db 0			; DATA XREF: Int1CISR:loc_10252o
					; SomeHSC2+1AAw ...
byte_1564D	db 0			; DATA XREF: SomeHSC+Aw SomeHSC+40r
byte_1564E	db 0			; DATA XREF: Int1CISR+5Ar
					; SomeHSC2+1A6w ...
byte_1564F	db 0			; DATA XREF: NewSong+12r NewSong+4Do ...
byte_15650	db 0			; DATA XREF: NewSong+2Ar NewSong+3Bo ...
byte_15651	db 0			; DATA XREF: CheckHscCntrr
					; SomeHSC2+41w	...
byte_15652	db 0			; DATA XREF: CheckHscCntr:loc_102A8r
					; SomeHSC2+46w	...
HscCntr		db 0			; DATA XREF: CheckHscCntr+7r
					; CheckHscCntr+Ew ...
byte_15654	db 0FFh			; DATA XREF: InitPlayer+D7w
					; PlayTick+1Fr	...
byte_15655	db 0, 1, 2, 3, 4, 5, 6,	7, 8 ; DATA XREF: SomeHSC2+EAo
					; SomeHSC2+16Bo ...
byte_1565E	db 9 dup(0)		; DATA XREF: PutAXIns+1A7o
					; SomeHSC3+1Bo
		db 0Fh,	0, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 0F6h, 0F7h, 0F8h
		db 0F9h, 0FAh, 0FBh, 0FCh, 0FDh, 0FEh, 0FFh
		db 0, 1, 2, 3, 4, 5, 6,	7, 8, 9, 10, 11, 12, 13, 14, 15
		db 0, 0
SBPort		dw 0			; DATA XREF: DetectSB+F2w DetectSB+F6r
Song		dw 0			; DATA XREF: NewSongr NewSong+8r ...
word_1568E	dw 0			; DATA XREF: NewSong+1Ar NewSong+61r ...
byte_15690	db 0			; DATA XREF: SomeHSC2+74w SomeHSC2+80w ...
byte_15691	db 19h dup(0)		; DATA XREF: SomeHSC2+1B1r
					; SomeHSC2+1B7w
SndBuffer	db 37B6h dup(?)		; DATA XREF: StartPlay+8o
					; OpenSndFile+28o
		end start
