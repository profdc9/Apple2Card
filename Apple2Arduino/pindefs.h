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

#define DISABLE_RXTX_PINS() UCSR0B &= ~(_BV(RXEN0)|_BV(TXEN0))
#define ENABLE_RXTX_PINS() UCSR0B |= (_BV(RXEN0)|_BV(TXEN0))

#define DATAPORT_MODE_TRANS() DDRD = 0xFF
#define DATAPORT_MODE_RECEIVE() DDRD = 0x00

#define READ_DATAPORT() (PORTD)
#define WRITE_DATAPORT(x) PORTD=(x)

#define READ_OBFA() (PORTC & 0x01)
#define READ_IBFA() (PORTC & 0x08)
#define ACK_LOW() PORTC = _BV(2)
#define ACK_HIGH() PORTC = _BV(1) | _BV(2)
#define STB_LOW() PORTC = _BV(1)
#define STB_HIGH() PORTC = _BV(1) | _BV(2)

#define SLOT_STATE_NODEV 0
#define SLOT_STATE_BLOCKDEV 1
#define SLOT_STATE_FILEDEV 2

#endif _PINDEFS_H
