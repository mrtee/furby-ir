	list	p=12f683

		
include "p12f683.inc"

    __config (_FCMEN_OFF & _IESO_OFF & _BOD_NSLEEP & _CPD_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_OFF & _WDT_OFF & _INTOSCIO)

;4 MHz-nél egy utasítás ciklus 0,000001 sec (1 usec)
;az IR impulzus időtartama 150-200 usec kell legyen,
;ez 150-200 utasítás ciklus
;csomag mérete 9-36 ms (1-4 ms/bit)
;csomagok közti várakozás 6x80 ms
;
;GP0 GOMB0
;GP1 GOMB1
;GP2 GOMB2
;GP3 RESET
;GP4 GOMB3
;GP5 IR-LED


cblock	0x70
tmp1
byyte
rolbyte
bitcount
impcount
endc	


	org	0

main
    clrf	GPIO
    bsf		STATUS,RP0
    movlw	b'11011111'	;GP5 output
    movwf	TRISIO
    clrf	ANSEL
    clrf	OPTION_REG	;PULL-ups, Timer0 off
    bcf		STATUS,RP0
    movlw	b'00000111'
    movwf	CMCON0		;GP2 i/o mode
    movlw	b'00000001'	;1 ms WDT, WDT on
    movwf	WDTCON

    

byteki2
    movf	GPIO,w
    movwf	byyte
;
;    nop
;    nop
;    clrf	byyte		;hello
;

    btfsc	byyte,4
    bsf		byyte,3
    movlw	b'00001111'
    andwf	byyte,f
    swapf	byyte,w
    xorlw	b'11110000'
    iorwf	byyte,f
				; küldendő byyte kész
    movlw	0x06		; 6 csomag
    movwf	impcount

csomagciklus    
    movf	byyte,w

;    movlw	0xf0

    movwf	rolbyte
				; rolbyte kész
    bsf		STATUS,C
    call	bitki2		; START bit

    movlw	0x08		; 8 bit
    movwf	bitcount

egybit				; 8 bitet elküld
    rrf		rolbyte,f
    call	bitki2

    decfsz	bitcount,f
    goto	egybit    
				; csomagok között vár
    movlw	b'00001100'	;66 ms WDT
    movwf	WDTCON
    bsf		WDTCON,0	;WDT on
    sleep
    movlw	b'00001000'	;17 ms WDT
    movwf	WDTCON
    bsf		WDTCON,0	;WDT on
    sleep
    clrf	WDTCON		;1 ms
    bsf		WDTCON,0	;WDT on

    decfsz	impcount,f
    goto	csomagciklus
    
    bcf		WDTCON,0
    sleep
;	vége is


bitki2

    clrwdt
    call	impul
    sleep
    clrwdt
    btfsc	STATUS,C
    call	impul
    sleep
    return

impul
    bsf		GPIO,5		;IR-LED on
    movlw	d'55'		;~170 usec
    movwf	tmp1

ido170
    decfsz	tmp1,f		;cikl 3
    goto	ido170		;1

    bcf		GPIO,5		;IR-LED off
    return

end


