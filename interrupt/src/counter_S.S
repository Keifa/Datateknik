/*
Kristoffer
Sätter pin att vara output
*(gpio_addr + (4 * (GPIO_NR / 10 ))) |= (1 << (((GPIO_NR) % 10) * 3));

Farid
Sätta pin att vara input
*(gpio_addr + (4* ( GPIO_NR / 10))) &= ~(7<< ((GPIO_NR % 10) * 3));

Peter
Sida 4
*/

.data
/*
** Variabler här
input:
	gpio 10	176
	gpio 9	175
output:
	gpio 17	183
	gpio 18	184
	gpio 27 193
	gpio 22	188

*/

baseAdress: 
	.word 0x3F200000

gpioAddr:
	.word 0

printVal:
	.asciz "%x\n"
	
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

	BX lr

/*
** Avbrottsrutin som kallas när ett avbrott sker. Ska räkna neråt
*/
.GLOBAL counter_isr_down
counter_isr_down:

	BX lr

/*
 * Sätt upp åtkomst till GPIO-pinnarnas minne
 */
.GLOBAL setup
setup:
	PUSH {lr}

	BL calcGpioAddr
	MOV r1, r0
	LDR r0, =printVal
	BL printk
	MOV r0, #183
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

	ADD r5. r4, 148
	ADD r6, r4, 152
	MOV r7, #0

	STR r7, [r5]
	STR r7, [r6]
	BL shortWait	

	POP {r4,r5,r6,r7,pc}

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
	/*   */
	AND r4, r6
	
	/* Rightshifta r5 */
	LSR r5, #4
	
	ADD r4, r4, r5
	
	LDR r6, =#0x0F000000
	AND r4, r6
	
	LDR r6, =#0xF0000000
	ADD r4, r4, r6
	
	MOV r0, r4
	
	LDR r5, =gpioAddr
	STR r4, [r5]
	
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

	PUSH {r4, r5, r6, r7, lr}
	
	/* Spara input  */
	MOV r5, r0

	/* Hämta gpioadressen  */
	LDR r4, =gpioAddr
	LDR r4, [r4]
	
	/* Dividera r5 med 10  */
	MOV r0, r5
	MOV r1, #10
	BL idiv
	/* Spara kvot  */
	MOV r5, r0
	/* Spara rest  */
	MOV r6, r1
	
	/* väster delen, (4*(GPIO_NR/10))*/
	MOV r7, #4
	MUL r5, r7
	/* Höger delen, <((GPIO_NR%10)*3) */
	MOV r7, #3
	MUL r6, r7
	/*~  bitwise NOT operator i höger delen */
	NOT r6
	/ *vänster delen, gpio_addr + (4*(GPIO_NR/10)) så r4 är väster delen */
	ADD r4, r4, r5

	/*r5 blir höger delen << */
	MOV r5, #7
	LSL r5, r6

	/*vet inte är det rätt eller inte*/
	/*jag gör vänster delen som pekare och sen kör bitwise AND operator med höger delen*/
	STR r4, [r4]
	AND r4, r5
	POP {r4,r5,r6,r7,pc}

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
	STR #2, [r4]

	BL shortWait
	
	POP {r4,pc}
	
/* Sätt vilken pin som ska sättas till pull up */
setPinToPullUp:
	PUSH {r4,r5,r6,r7,lr}
	
	/* Spara input */
	MOV r4, r0
	
	/* gpio_addr + 152  */
	LDR r5, =gpioAddr
	LDR r5, [r5]
	ADD r5, #152
<<<<<<< HEAD

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
=======
	
	POP {r4,r5,pc}
>>>>>>> 7108637fe13a4cf9b7a21da97774f98ce7a67d0e
