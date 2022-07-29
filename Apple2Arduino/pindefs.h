/* pindefs.h */
/* by Daniel L. Marks */

/*
 * Copyright (c) 2022 Daniel Marks

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
 */

#ifndef _PINDEFS_H
#define _PINDEFS_H

#define CS  10 
#define CS2 9
#define CS3 8

#define MOSI 11
#define MISO 12
#define SCK 13

#define SOFTWARE_SERIAL
#define SOFTWARE_SERIAL_RX A4
#define SOFTWARE_SERIAL_TX A5

#define DISABLE_RXTX_PINS() UCSR0B &= ~(_BV(RXEN0)|_BV(TXEN0)|_BV(RXCIE0)|_BV(UDRIE0))
#define ENABLE_RXTX_PINS() UCSR0B |= (_BV(RXEN0)|_BV(TXEN0)|_BV(RXCIE0)|_BV(UDRIE0))
#define WAIT_TX() while ((UCSR0A & _BV(TXC0) == 0)

#define DATAPORT_MODE_TRANS() DDRD = 0xFF
#define DATAPORT_MODE_RECEIVE() do { PORTD = 0x00; DDRD = 0x00; } while (0)

#define READ_DATAPORT() (PIND)
#define WRITE_DATAPORT(x) do { uint8_t temp = (x); PORTD=temp; PORTD=temp; } while (0)

#define READ_OBFA() (PINC & 0x08)
#define READ_IBFA() (PINC & 0x02)
#define ACK_LOW_SINGLE() PORTC &= ~_BV(2)
#define ACK_HIGH_SINGLE() PORTC |= _BV(2)
#define STB_LOW_SINGLE() PORTC &= ~_BV(0)
#define STB_HIGH_SINGLE() PORTC |= _BV(0)

/* Needed to slow down data send for 82C55 */
#define ACK_LOW() do { ACK_LOW_SINGLE(); ACK_LOW_SINGLE(); ACK_LOW_SINGLE(); ACK_LOW_SINGLE(); ACK_LOW_SINGLE(); } while (0)
#define ACK_HIGH() do { ACK_HIGH_SINGLE();  } while (0)
#define STB_LOW() do { STB_LOW_SINGLE(); STB_LOW_SINGLE(); STB_LOW_SINGLE(); STB_LOW_SINGLE(); STB_LOW_SINGLE(); } while (0)
#define STB_HIGH() do { STB_HIGH_SINGLE(); } while (0)

#define INITIALIZE_CONTROL_PORT() do { \
  PORTC |= (_BV(0) | _BV(1) | _BV(2) | _BV(3)); \
  DDRC |= (_BV(0) | _BV(2)); \
  DDRC &= ~(_BV(1) | _BV(3)); \
  PORTC |= (_BV(0) | _BV(1) | _BV(2) | _BV(3)); \
} while (0) 

#endif _PINDEFS_H
