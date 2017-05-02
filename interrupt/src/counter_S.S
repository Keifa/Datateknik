
.data

/*
input:
	gpio 10	irq: 176
	gpio 9	irq: 175
output:
	gpio 17
	gpio 18
	gpio 27	
	gpio 22	
*/

baseAdress: 
	.word 0x3F200000

gpioAddr:
	.word 0

counter:
	.word 1

printVal:
	.asciz "%x\n"

testPrintUp:
	.asciz "up\n"

testPrintDown:
	.asciz "down\n"

printSetOutput:
	.asciz "SOutput ( %x |= %x ) %x\n"

printSetInput:
	.asciz "SInput ( %x &= %x ) %x\n"
	
.text
/*
** Division
*/
idiv:
	/* r0 innehåller N */
	/* r1 innehåller D */
	mov r2, r1
	mov r1, r0
	mov r0, #0
	b .Lloop_check
	.Lloop:
		add r0, r0, #1
		sub r1, r1, r2
	.Lloop_check:
		cmp r1, r2
		bhs .Lloop
	/* r0 innehåller kvoten */
	/* r1 innehåller resten */
	bx lr

/*
** Avbrottsrutin som kallas när ett interrupt sker. Ska räkna uppåt
*/
.GLOBAL counter_isr_up
counter_isr_up:
	
	PUSH {r4,r5,lr}

	LDR r4, =counter
	LDR r5, [r4]
	ADD r5, #1
	CMP r5, #16
	MOVGE r5, #1
	STR r5, [r4] 

	LDR r0, =printVal
	LDR r1, =counter
	LDR r1, [r1]
	BL printk

	BL handleOutputs

	MOV r0, #1

	POP {r4,r5,pc}

/*
** Avbrottsrutin som kallas när ett avbrott sker. Ska räkna neråt
*/
.GLOBAL counter_isr_down
counter_isr_down:
	
	PUSH {r4,r5,lr}

	LDR r4, =counter
	LDR r5, [r4]
	SUB r5, #1
	CMP r5, #0
	MOVLE r5, #15
	STR r5, [r4] 

	LDR r0, =printVal
	LDR r1, =counter
	LDR r1, [r1]
	BL printk

	BL handleOutputs

	MOV r0, #1

	POP {r4,r5,pc}


/*
 * Sätt upp åtkomst till GPIO-pinnarnas minne
 */
.GLOBAL setup
setup:
	PUSH {lr}

	BL calcGpioAddr
	/*LDR r0, =printVal
	LDR r1, =gpioAddr
	LDR r1, [r1]
	BL printk*/

	/* Set output */
	MOV r0, #17
	BL setOutput
	
	MOV r0, #18
	BL setOutput
	
	MOV r0, #27
	BL setOutput

	MOV r0, #22
	BL setOutput
	
	/* Set input */
	BL setPullCode
	MOV r0, #9
	BL setPinToPullUp
	MOV r0, #10
	BL setPinToPullUp
	
	MOV r0, #9
	BL setInput
	MOV r0, #10
	BL setInput
	
	MOV r0, #17
	BL setOutputHigh

	POP {pc}

/*
** Ta bort åtkomst till GPIO
*/
.GLOBAL setdown
setdown:
	PUSH {r4,r5,r6,r7,lr}

	LDR r4, =gpioAddr
	LDR r4, [r4]

	ADD r5, r4, #148
	ADD r6, r4, #152
	MOV r7, #0

	STR r7, [r5]
	STR r7, [r6]
	BL shortWait	

	POP {r4,r5,r6,r7,pc}

handleOutputs:

	PUSH {r4,r5,lr}

	LDR r5, =counter
	LDR r4, [r5]	
	
	/* Output 1 */
	MOV r0, #17
	AND r4, #1
	CMP r4, #1
	BLEQ setOutputHigh
	BLNE setOutputLow

	/* Output 2 */
	MOV r0, #18
	LDR r4, [r5]
	AND r4, #2
	CMP r4, #2
	BLEQ setOutputHigh
	BLNE setOutputLow

	/* Output 3 */
	MOV r0, #27
	LDR r4, [r5]
	AND r4, #4
	CMP r4, #4
	BLEQ setOutputHigh
	BLNE setOutputLow

	/* Output 4 */
	MOV r0, #22
	LDR r4, [r5]
	AND r4, #8
	CMP r4, #8
	BLEQ setOutputHigh
	BLNE setOutputLow
	
	POP {r4,r5,pc}
	

/* Räkna ut virtuella basminnesaddresen för gpio */
calcGpioAddr:
	/* Pusha på stacken  */
	PUSH {r4,r5,r6,lr}
	
	/* Ladda in adressen för baseAdress i r4 */
	LDR r4, =baseAdress
	/* Flytta värdet i r4  som ligger i r4 till r4 */
	LDR r4, [r4]
	/*  Flytta värdet i r4 till r5 */
	MOV r5, r4
	
	/* Laddar in adressen till konstanten i r6   */
	LDR r6, =#0x00FFFFFF
	/* (addr) & 0x00FFFFFF */
	AND r4, r6
	
	/* r5 >> 4 */
	LSR r5, #4
	
	LDR r6, =#0x0F000000	
	AND r5, r6

	ADD r4, r5
	
	LDR r6, =#0xF0000000
	ADD r4, r6
	
	LDR r5, =gpioAddr
	STR r4, [r5]
	
	MOV r0, r4

	/* Popa från stacken  */
	POP {r4,r5,r6,pc}

/* Sätter outputpin med gpioNr i r0 till high  */
setOutputHigh:
	
	PUSH {r4,r5,r6,r7,lr}
	
	/* Spara input  */
	MOV r5, r0

	/* Hämta gpioadressen  */
	LDR r4, =gpioAddr
	LDR r4, [r4]
	
	/* Dividera r5 med 32  */
	MOV r0, r5
	MOV r1, #32
	BL idiv
	/* Spara kvot  */
	MOV r5, r0
	/* Spara rest  */
	MOV r6, r1
	
	ADD r5, r5, #7
	MOV r7, #4
	MUL r5, r7
	ADD r4, r4, r5

	MOV r5, #1
	LSL r5, r6

	STR r5, [r4]

	POP {r4,r5,r6,r7,pc}

/* Sätter outputpin med gpioNr i r0 till low  */
setOutputLow:
	
	PUSH {r4,r5,r6,r7,lr}
	
	/* Spara input  */
	MOV r5, r0

	/* Hämta gpioadressen  */
	LDR r4, =gpioAddr
	LDR r4, [r4]
	
	/* Dividera r5 med 32  */
	MOV r0, r5
	MOV r1, #32
	BL idiv
	/* Spara kvot  */
	MOV r5, r0
	/* Spara rest  */
	MOV r6, r1
	
	ADD r5, r5, #10
	MOV r7, #4
	MUL r5, r7
	ADD r4, r4, r5

	MOV r5, #1
	LSL r5, r6

	STR r5, [r4]

	POP {r4,r5,r6,r7,pc}
		
	
/*Sätter input*/
setInput:
	PUSH {r4, r5, r6, r7, r8, r9, r10, lr}
	
	/* Dividderar med 10 */
	MOV r1, #10
	BL idiv
	
	/* Sparar kvoten i r5 och resten i r6 */
	MOV r5, r0
	MOV r6, r1
	
	/* Multiplcierar med 4 */
	MOV r7, #4
	MUL r5, r7
	
	/*Adderar gpio adressen */
	LDR r4, =gpioAddr
	LDR r4, [r4]
	ADD r5, r4

	/* Multicplicerar med 3*/
	MOV r7, #3
	MUL r6, r7
	
	/* Leftshift r6 */
	MOV r9, #7
	LSL r9, r6

	/* ~ */
	MVN r9, r9
	
	/* Compare */
	LDR r4, [r5]
	AND r4, r9

	STR r4, [r5]

	POP {r4, r5, r6, r7, r8, r9, r10, pc}


/* Enkel funktion för att vänta en kort stund */
shortWait:
	PUSH {r4,lr}
	
	MOV r4, #0
	BL swLoop
	
	swLoopCheck:
		CMP r4, #150
		BLT swLoop
		BL swEnd
		
	swLoop:
		ADD r4, #1
		SUB r4, #1
		ADD r4, #1
		BL swLoopCheck
		
	swEnd:
		POP {r4,pc}
		
setPullCode:
	PUSH {r4,r5,lr}
	
	/* Hämta gpioadressen  */
	LDR r4, =gpioAddr
	LDR r4, [r4]
	
	ADD r4, #148
	MOV r5, #2
	STR r5, [r4]

	BL shortWait
	
	POP {r4,r5,pc}
	
/* Sätt vilken pin som ska sättas till pull up */
setPinToPullUp:
	PUSH {r4,r5,r6,r7,lr}
	
	/* Spara input */
	MOV r4, r0
	
	/* gpio_addr + 152  */
	LDR r5, =gpioAddr
	LDR r5, [r5]
	ADD r5, #152

	/* 1 << (GPIO_NR % 32) */
	MOV r0, r4
	MOV r1, #32
	BL idiv
	MOV r7, r1
	MOV r6, #1
	LSL r6, r7

	/* *(gpio_addr + 152) = (1 << (GPIO_NR % 32)) */
	STR r6, [r5]

	BL shortWait

	POP {r4,r5,r6,r7,pc}

/* Sätter GPIO pin med nummer GPIO_NR till att vara output. */
setOutput:
	PUSH {r4, r5, r6, r7, r8, r9, r10, lr}
	
	/* Dividderar med 10 */
	MOV r1, #10
	BL idiv
	
	/* Sparar kvoten i r5 och resten i r6 */
	MOV r5, r0
	MOV r6, r1
	
	/* Multiplcierar med 4 */
	MOV r7, #4
	MUL r5, r7
	
	/*Adderar gpio adressen */
	LDR r4, =gpioAddr
	LDR r4, [r4]
	ADD r5, r4

	/* Multicplicerar med 3*/
	MOV r7, #3
	MUL r6, r7
	
	/* Leftshift r6 */
	MOV r9, #1
	LSL r9, r6
	
	/* Compare */
	LDR r4, [r5]
	ORR r4, r9

	STR r4, [r5]

	POP {r4, r5, r6, r7, r8, r9, r10, pc}

