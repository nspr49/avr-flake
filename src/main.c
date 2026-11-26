#include <avr/io.h>

// The AVR128DB48 runs at 4 MHz after reset with factory clock settings.
#define F_CPU 4000000UL
#include <util/delay.h>

int main(void) {
    // PB3 drives the user LED on the AVR128DB48 Curiosity Nano.
    PORTB.DIRSET = PIN3_bm;
    PORTB.DIRSET = PIN4_bm;
    for (;;) {
        PORTB.OUTTGL = PIN3_bm;
        _delay_ms(500);
    }
}
