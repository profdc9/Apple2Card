/* Apple2Arduino firmware */
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

/* Note to self to create objdump:
 *  
 C:\Users\dmarks\Documents\ArduinoData\packages\arduino\tools\avr-gcc\4.8.1-arduino5\bin\avr-objdump.exe -x -t -s Apple2Arduino.ino.elf > s155143
*/

#include <Arduino.h>
#include <EEPROM.h>
#include "diskio.h"
#include "mmc_avr.h"
#include "ff.h"
#include "pindefs.h"

#undef DEBUG_SERIAL

#ifdef DEBUG_SERIAL
#include <SoftwareSerial.h>
SoftwareSerial softSerial(SOFTWARE_SERIAL_RX,SOFTWARE_SERIAL_TX);
#define SERIALPORT() (&softSerial)
#endif

#define EEPROM_INIT 0
#define EEPROM_SLOT0 1
#define EEPROM_SLOT1 2

#define SLOT_STATE_NODEV 0
#define SLOT_STATE_BLOCKDEV 1
#define SLOT_STATE_WIDEDEV 2
#define SLOT_STATE_FILEDEV 3

FATFS   fs;
FIL     slotfile;

uint8_t slot0_state = SLOT_STATE_NODEV;
uint8_t slot0_fileno;

uint8_t slot1_state = SLOT_STATE_NODEV;
uint8_t slot1_fileno;

extern "C" {
  void write_string(const char *c)
  {
#ifdef DEBUG_SERIAL
    SERIALPORT()->print(c);
    SERIALPORT()->flush();
#endif
  }
}

void read_eeprom(void)
{
  if (EEPROM.read(EEPROM_INIT) != 255)
  {
    slot0_fileno = EEPROM.read(EEPROM_SLOT0);
    slot1_fileno = EEPROM.read(EEPROM_SLOT1);
  } else
  {
    slot0_fileno = 0;
    slot1_fileno = 1;
  }
}

void write_eeprom(void)
{
  if (EEPROM.read(EEPROM_SLOT0) != slot0_fileno)
    EEPROM.write(EEPROM_SLOT0, slot0_fileno);
  if (EEPROM.read(EEPROM_SLOT1) != slot1_fileno)
    EEPROM.write(EEPROM_SLOT1, slot1_fileno);
  if (EEPROM.read(EEPROM_INIT) == 255)
    EEPROM.write(EEPROM_INIT, 0);
}

void setup_pins(void)
{
  INITIALIZE_CONTROL_PORT();
  DISABLE_RXTX_PINS();
  DATAPORT_MODE_RECEIVE();
}

void setup_serial(void)
{
  Serial.end();
  DISABLE_RXTX_PINS();
#ifdef DEBUG_SERIAL
#ifdef SOFTWARE_SERIAL
  softSerial.begin(9600);
  pinMode(SOFTWARE_SERIAL_RX,INPUT);
  pinMode(SOFTWARE_SERIAL_TX,OUTPUT);
#endif
#endif
}

void write_dataport(uint8_t ch)
{
  while (READ_IBFA() != 0);
  DATAPORT_MODE_TRANS();
  WRITE_DATAPORT(ch);
  STB_LOW();
  STB_HIGH();
  DATAPORT_MODE_RECEIVE();
}

uint8_t read_dataport(void)
{
  uint8_t byt;

  while (READ_OBFA() != 0);
  ACK_LOW();
  byt = READ_DATAPORT();
  ACK_HIGH();
  return byt;
}

static uint8_t unit;
static uint16_t buf;
static uint16_t blk;

void get_unit_buf_blk(void)
{
  unit = read_dataport();
#ifdef DEBUG_SERIAL
  SERIALPORT()->print("0000 unit=");
  SERIALPORT()->println(unit,HEX);
#endif
  buf = read_dataport();
  buf |= (((uint16_t)read_dataport()) << 8);
#ifdef DEBUG_SERIAL
  SERIALPORT()->print("0000 buf=");
  SERIALPORT()->println(buf,HEX);
#endif
  blk = read_dataport();
  blk |= (((uint16_t)read_dataport()) << 8);
#ifdef DEBUG_SERIAL
  SERIALPORT()->print("0000 blk=");
  SERIALPORT()->println(blk,HEX);
#endif
}

static char blockvolzero[] = "0:";
static char blockvolone[] = "1:";

static char blockdev_filename[] = "X:BLKDEVXX.PO";

uint8_t hex_digit(uint8_t ch)
{
  if (ch < 10) return ch + '0';
  return ch - 10 + 'A';
}

void set_blockdev_filename(uint8_t fileno)
{
  blockdev_filename[8] = hex_digit(fileno >> 4);
  blockdev_filename[9] = hex_digit(fileno & 0x0F);
}

void check_status(void)
{
  if (unit & 0x80)
  {
    if (slot1_state == SLOT_STATE_NODEV)
    {
      if (slot1_fileno == 255)
      {
        if (slot0_state == SLOT_STATE_NODEV)
        {
          if (disk_initialize(0) == 0)
            slot0_state = slot1_state = SLOT_STATE_WIDEDEV;
        }
      } else if (slot1_fileno == 0)
      {
        if (disk_initialize(1) == 0)
          slot1_state = SLOT_STATE_BLOCKDEV;
      } else 
      {
        if (slot0_state != SLOT_STATE_FILEDEV)
        {
          if (f_mount(&fs,blockvolone,0) == FR_OK)
          {
            set_blockdev_filename(slot1_fileno);
            blockdev_filename[0] = '1';
            if (f_open(&slotfile, blockdev_filename, FA_READ | FA_WRITE) == FR_OK)
            {
              slot1_state = SLOT_STATE_FILEDEV;
            } 
          }
        }
      }
    }
  } else
  {
    if (slot0_state == SLOT_STATE_NODEV)
    {
      if (slot0_fileno == 255)
      {
        if (slot1_state == SLOT_STATE_NODEV)
        {
          if (disk_initialize(0) == 0)
            slot0_state = slot1_state = SLOT_STATE_WIDEDEV;
        }
      } else if (slot0_fileno == 0)
      {
        if (disk_initialize(0) == 0)
          slot0_state = SLOT_STATE_BLOCKDEV;
      } else
      {
        if (slot1_state != SLOT_STATE_FILEDEV)
        {
          if (f_mount(&fs,blockvolzero,0) == FR_OK)
          {
            set_blockdev_filename(slot0_fileno);
            blockdev_filename[0] = '0';
            if (f_open(&slotfile, blockdev_filename, FA_READ | FA_WRITE) == FR_OK)
              slot0_state = SLOT_STATE_FILEDEV;
          }
        }
      }
    }
  }
}

void unmount_drive(void)
{
  if (unit & 0x80)
  {
    switch (slot1_state)
    {
      case SLOT_STATE_NODEV:
         return;
      case SLOT_STATE_WIDEDEV:
      case SLOT_STATE_BLOCKDEV:
         slot1_state = SLOT_STATE_NODEV;
         return;
      case SLOT_STATE_FILEDEV:
         f_close(&slotfile);
         f_unmount(blockvolone);
         slot1_state = SLOT_STATE_NODEV;
         return;
    }
  } else
  {
    switch (slot0_state)
    {
      case SLOT_STATE_NODEV:
         return;
      case SLOT_STATE_WIDEDEV:
      case SLOT_STATE_BLOCKDEV:
         slot0_state = SLOT_STATE_NODEV;
         return;
      case SLOT_STATE_FILEDEV:
         f_close(&slotfile);
         f_unmount(blockvolzero);
         slot0_state = SLOT_STATE_NODEV;
         return;
    }  
  }
}

uint8_t check_unit_nodev(void)
{
  if (unit & 0x80)
  {
    if (slot1_state == SLOT_STATE_NODEV)
    {
      write_dataport(0x28);
      return 0;
    }
  } else
  {
    if (slot0_state == SLOT_STATE_NODEV)
    {
      write_dataport(0x28);
      return 0;
    } 
  }
  return 1;
}

void do_status(void)
{
  get_unit_buf_blk();
  check_status();
  if (check_unit_nodev())
     write_dataport(0x00);
}

static uint32_t blockloc;

uint32_t calculate_block_location(uint8_t voltype)
{
  uint8_t unitshift = unit & ((voltype == SLOT_STATE_WIDEDEV) ? 0xF0 : 0x70);
  blockloc = ((uint32_t)blk) | (((uint32_t)(unitshift)) << 12);
}

uint32_t calculate_file_location(void)
{
  blockloc = ((uint32_t)blk) << 9;
}

void do_read(void)
{
  UINT br;
  uint8_t buf[512];
  
  get_unit_buf_blk();
  check_status();
  if (check_unit_nodev() == 0) return;
  if (unit & 0x80)
  {
    switch (slot1_state)
    {
      case SLOT_STATE_WIDEDEV:
      case SLOT_STATE_BLOCKDEV:
           calculate_block_location(slot1_state);
           if (disk_read(slot1_state == SLOT_STATE_BLOCKDEV ? 1 : 0, buf, blockloc, 1) != 0) 
           {
             write_dataport(0x27); 
             return;
           }
           break;
      case SLOT_STATE_FILEDEV:
           calculate_file_location();
           if ((f_lseek(&slotfile, blockloc) != FR_OK) ||
               (f_read(&slotfile, buf, 512, &br) != FR_OK) ||
               (br != 512))
           {
             write_dataport(0x27); 
             return;
           }
           break;
     }
  } else
  {   
    switch (slot0_state)
    {
      case SLOT_STATE_WIDEDEV:
      case SLOT_STATE_BLOCKDEV:
           calculate_block_location(slot0_state);
           if (disk_read(0, buf, blockloc, 1) != 0) 
           {
             write_dataport(0x27); 
             return;
           }
           break;
      case SLOT_STATE_FILEDEV:
           calculate_file_location();
           if ((f_lseek(&slotfile, blockloc) != FR_OK) ||
               (f_read(&slotfile, buf, 512, &br) != FR_OK) ||
               (br != 512))
           {
             write_dataport(0x27); 
             return;
           }
           break;
     }
  }   
  write_dataport(0x00);            
  DATAPORT_MODE_TRANS();
  for (uint16_t i=0;i<512;i++)
  {
     while (READ_IBFA() != 0);
     WRITE_DATAPORT(buf[i]);
     STB_LOW();
     STB_HIGH(); 
  }
  DATAPORT_MODE_RECEIVE();
}

void do_write(void)
{
  UINT br;
  uint8_t buf[512];
  
  get_unit_buf_blk();
  check_status();

  if (check_unit_nodev() == 0) return;
  write_dataport(0x00);            

  for (uint16_t i=0;i<512;i++)
  {
    while (READ_OBFA() != 0);
    ACK_LOW();
    buf[i] = READ_DATAPORT();
    ACK_HIGH();
  }

  if (unit & 0x80)
  {
    switch (slot1_state)
    {
      case SLOT_STATE_WIDEDEV:
      case SLOT_STATE_BLOCKDEV:
           calculate_block_location(slot1_state);
           disk_write(slot1_state == SLOT_STATE_BLOCKDEV ? 1 : 0, buf, blockloc, 1);
           break;
      case SLOT_STATE_FILEDEV:
           calculate_file_location();
           if ((f_lseek(&slotfile, blockloc) != FR_OK) ||
               (f_write(&slotfile, buf, 512, &br) != FR_OK) ||
               (br != 512))
               return;
           break;
     }
  } else
  {   
    switch (slot0_state)
    {
      case SLOT_STATE_WIDEDEV:
      case SLOT_STATE_BLOCKDEV:
           calculate_block_location(slot0_state);
           disk_write(0, buf, blockloc, 1);
           break;
      case SLOT_STATE_FILEDEV:
           calculate_file_location();
           if ((f_lseek(&slotfile, blockloc) != FR_OK) ||
               (f_write(&slotfile, buf, 512, &br) != FR_OK) ||
               (br != 512))
               return;
           break;
     }
  }               
  return;
}

void do_format(void)
{
  get_unit_buf_blk();
  check_status();
  if (check_unit_nodev() == 0) return;
  write_dataport(0x00);
}

void do_set_volume(void)
{
  get_unit_buf_blk();
  unit = 0;
  unmount_drive();
  unit = 0x80;
  unmount_drive();
  slot0_fileno = blk & 0xFF;
  slot1_fileno = (blk >> 8);
  write_eeprom();
  unit = 0;
  check_status();
  unit = 0x80;
  check_status();
  write_dataport(0x00);
}

void do_command()
{
  uint8_t cmd = read_dataport();
#ifdef DEBUG_SERIAL
  SERIALPORT()->print("0000 cmd=");
  SERIALPORT()->println(cmd,HEX);
#endif
  switch (cmd)
  {
    case 0:  do_status();
             break;
    case 1:  do_read();
             break;
    case 2:  do_write();
             break;
    case 3:  do_format();
             break;
    case 4:  do_set_volume();
             break;

    default: write_dataport(0x27);
             break;
  }
}

int freeRam () 
{
  extern int __heap_start, *__brkval; 
  int v; 
  return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval); 
}

void setup()
{
  setup_pins();
  setup_serial();
  read_eeprom();

  unit = 0;
  check_status();
  unit = 0x80;
  check_status();

#ifdef DEBUG_SERIAL
  SERIALPORT()->println("0000");
  SERIALPORT()->print("d=");
  SERIALPORT()->print(sizeof(fs));
  SERIALPORT()->print(" f=");
  SERIALPORT()->print(freeRam());
  SERIALPORT()->print(" s=");
  SERIALPORT()->print(slot0_state);
  SERIALPORT()->print(" ");
  SERIALPORT()->println(slot1_state);
  SERIALPORT()->flush();
#endif

  DATAPORT_MODE_RECEIVE();
}

void loop()
{
  uint8_t instr = read_dataport();
  if (instr == 0xAC) do_command();
}
