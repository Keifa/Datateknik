
	.data
outBuf:		.skip	64
outBufOffset:	.quad 0
endLine:	.asciz "\n"

	.text
	.global inImage
inImage: # NOT DONE
	ret

	.global getInt
getInt: # NOT DONE
	ret

	.global getText
getText: # NOT DONE
	ret

	.global getChar
getChar: # NOT DONE
	ret

	.global getInPos
getInPos: # NOT DONE
	ret

	.global setInPos
setInPos: # NOT DONE
	ret

	.global outImage
outImage: # NOT DONE
	pushq	$0
	
	movq	$outBuf, %rdi
	call	puts

	movq	$0, outBuf
	movq	$0, outBufOffset
	
	popq	%rax
	ret

	.global putInt
putInt: # NOT DONE
	ret

	.global putText
putText: # NOT DONE
	pushq	$0
	pushq 	%rax

	movq	%rdi, %rax

	checkBuffer:
		cmpq	$63, outBufOffset
		jle		flushBuffer
		
	ptLoop:
		movq	(%rcx, outBufOffset, 1), %r8
		movq	%rax, (outBuf, outBufOffset, 1)
		incq	outBufOffset
		cmpq	%r8, $'\0'
		je 		ptExit
		jmp		checkBuffer
	
	flushBuffer:
		movq	$'\0', (outBuf, outBufOffset, 1)
		call 	outImage
		call	ptLoop

	ptExit:
		popq	%rax
		popq	%rax
		ret

	.global putChar
putChar: # NOT DONE
	ret

	.global getOutPos
getOutPos: # NOT DONE
	ret

	.global setOutPos
setOutPos: # NOT DONE
	ret