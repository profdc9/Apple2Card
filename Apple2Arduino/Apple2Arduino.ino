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

#include <Arduino.h>
#include "diskio.h"
#include "mmc_avr.h"

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

uint8_t slot0_state = SLOT_STATE_NODEV;
uint8_t slot0_fileno = 0;
FIL     slot0file;

uint8_t slot1_state = SLOT_STATE_NODEV;
uint8_t slot1_fileno = 0;
FIL     slot1file;

void setup_pins(void)
{
  PORTC = _BV(1) | _BV(2);
  DDRC = _BV(1) | _BV(2);
  PORTC = _BV(1) | _BV(2);
  DATAPORT_MODE_RECEIVE();
  WRITE_DATAPORT(0);
}

void setup_serial(void)
{
  Serial.begin(115200);
  DISABLE_RXTX_PINS();
}

void printbuf(const uint8_t *buf)
{
    for (int i=0;i<512;i++)
    {
      if ((i % 16) == 0)
      {
        Serial.println("");
        if (i<16) Serial.print('0');
        Serial.print(i,HEX);
        Serial.print(": ");
      }
      if (buf[i] < 16) Serial.print('0');
      Serial.print(buf[i],HEX);
      Serial.print(' ');
    }
    Serial.println("");
}

#if 0
FATFS fs0;

void test()
{
  delay(1000);
  FRESULT fr;
  FIL fdst;
  Serial.print("mount=");
  Serial.println(f_mount(&fs0,"0:",0));
  Serial.print("create=");
  Serial.println(fr = f_open(&fdst, "0:file.bin", FA_WRITE | FA_CREATE_ALWAYS));
  f_close(&fdst);
  Serial.print("read=");
  Serial.println(fr = f_open(&fdst, "0:file.bin", FA_READ));
  f_close(&fdst);
  f_unmount("0:");
}
#endif

void setup() {
  setup_pins();
  uint32_t sec = 814235;
  uint8_t buf[512];
  uint8_t buf2[512];
  uint8_t buf3[512];
  setup_serial();
  ENABLE_RXTX_PINS();

//  test();
#if 0
  Serial.print("Initialize=");
  Serial.println(mmc_disk_initialize(),HEX); 

  for (;;)
  {
    int er = mmc_disk_read(buf,sec,1);
    if (er != 0)
    {
      Serial.print("error ");
      Serial.println(er);
    }
  }
  Serial.print("Reading sector: ");
  Serial.println(mmc_disk_read(buf,sec,1));
  printbuf(buf);

  for (int i=0;i<512;i++) buf2[i] = i;

  Serial.print("Writing sector: ");
  Serial.println(mmc_disk_write(buf2,sec,1));

  Serial.print("Reading sector: ");
  Serial.println(mmc_disk_read(buf3,sec,1));
  printbuf(buf3);

  Serial.print("Writing sector: ");
  Serial.println(mmc_disk_write(buf,sec,1));

  Serial.print("Reading sector: ");
  Serial.println(mmc_disk_read(buf3,sec,1));
  printbuf(buf3);
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
  uint8_t instr;

  while (READ_OBFA() != 0);
  ACK_LOW();
  instr = READ_DATAPORT();
  ACK_HIGH();
  return instr;
}

static uint8_t unit;
static uint16_t buf;
static uint16_t blk;

void get_unit_buf_blk(void)
{
  unit = read_dataport();
  buf = read_dataport();
  buf |= (((uint16_t)read_dataport()) << 8);
  blk = read_dataport();
  blk |= (((uint16_t)read_dataport()) << 8);
}

static char blockdev_filename[] = "X:BLKDEVXX.BIN\000";

uint8_t hex_digit(uint8_t ch)
{
  if (ch < 10) return ch;
  return ch - 10 + 'A';
}

void set_blockdev_filename(uint8_t fileno)
{
  blockdev_filename[8] = hex_digit(fileno >> 4);
  blockdev_filename[9] = hex_digit(fileno & 0x0F);
}

void check_status(void)
{
  if (unit & 0x01)
  {
    if (slot1_state == SLOT_STATE_NODEV)
    {
      if (slot1_fileno == 0)
      {
        if (disk_initialize(1) == 0)
          slot1_state = SLOT_STATE_BLOCKDEV;
      } else
      {
        set_blockdev_filename(slot1_fileno);
        blockdev_filename[0] = '1';
        if (f_open(&slot1file, blockdev_filename, FA_READ | FA_WRITE) == FR_OK)
          slot1_state = SLOT_STATE_FILEDEV;
      }
    }
  } else
  {
    if (slot0_state == SLOT_STATE_NODEV)
    {
      if (slot0_fileno == 0)
      {
        if (disk_initialize(0) == 0)
          slot0_state = SLOT_STATE_BLOCKDEV;
      } else
      {
        set_blockdev_filename(slot0_fileno);
        blockdev_filename[0] = '0';
        if (f_open(&slot0file, blockdev_filename, FA_READ | FA_WRITE) == FR_OK)
          slot0_state = SLOT_STATE_FILEDEV;
      }
    }
  }
}

void unmount_drive(void)
{
  if (unit & 0x01)
  {
    switch (slot1_state)
    {
      case SLOT_STATE_NODEV:
         return;
      case SLOT_STATE_BLOCKDEV:
         slot1_state = SLOT_STATE_BLOCKDEV;
         return;
      case SLOT_STATE_FILEDEV:
         f_close(&slot1file);
         slot1_state = SLOT_STATE_BLOCKDEV;
         return;
    }
  } else
  {
    switch (slot0_state)
    {
      case SLOT_STATE_NODEV:
         return;
      case SLOT_STATE_BLOCKDEV:
         slot0_state = SLOT_STATE_BLOCKDEV;
         return;
      case SLOT_STATE_FILEDEV:
         f_close(&slot0file);
         slot0_state = SLOT_STATE_BLOCKDEV;
         return;
    }  
  }
}

uint8_t check_unit_nodev(void)
{
  if (unit & 0x01)
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
  write_dataport(0x00);
  return 1;
}

void do_status(void)
{
  get_unit_buf_blk();
  check_status();
  check_unit_nodev();
}

uint32_t blockloc;

uint32_t calculate_block_location(void)
{
  blockloc = ((uint32_t)blk) | (((uint32_t)(unit & 0x70)) << 12);
}

uint32_t calculate_file_location(void)
{
  blockloc = ((uint32_t)blk) << 9;
}

void do_read(void)
{
  UINT br;
  char buf[512];
  
  get_unit_buf_blk();
  check_status();
  if (check_unit_nodev() == 0) return;  
  if (unit & 0x01)
  {
    switch (slot1_state)
    {
      case SLOT_STATE_BLOCKDEV:
           calculate_block_location();
           if (disk_read(1, buf, blockloc, 1) != 0) 
           {
             write_dataport(0x27); 
             return;
           }
           break;
      case SLOT_STATE_FILEDEV:
           calculate_file_location();
           if ((f_lseek(&slot1file, blockloc) != FR_OK) ||
               (f_read(&slot1file, buf, 512, &br) != FR_OK) ||
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
      case SLOT_STATE_BLOCKDEV:
           calculate_block_location();
           if (disk_read(0, buf, blockloc, 1) != 0) 
           {
             write_dataport(0x27); 
             return;
           }
           break;
      case SLOT_STATE_FILEDEV:
           calculate_file_location();
           if ((f_lseek(&slot0file, blockloc) != FR_OK) ||
               (f_read(&slot0file, buf, 512, &br) != FR_OK) ||
               (br != 512))
           {
             write_dataport(0x27); 
             return;
           }
           break;
     }
  }               
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
  char buf[512];
  
  get_unit_buf_blk();
  check_status();

  if (check_unit_nodev() == 0) return;

  for (uint16_t i=0;i<512;i++)
  {
    while (READ_OBFA() != 0);
    ACK_LOW();
    buf[i] = READ_DATAPORT();
    ACK_HIGH();
  }

  if (unit & 0x01)
  {
    switch (slot1_state)
    {
      case SLOT_STATE_BLOCKDEV:
           calculate_block_location();
           disk_write(1, buf, blockloc, 1);
           break;
      case SLOT_STATE_FILEDEV:
           calculate_file_location();
           if ((f_lseek(&slot1file, blockloc) != FR_OK) ||
               (f_write(&slot1file, buf, 512, &br) != FR_OK) ||
               (br != 512))
               return;
           break;
     }
  } else
  {   
    switch (slot0_state)
    {
      case SLOT_STATE_BLOCKDEV:
           calculate_block_location();
           disk_write(0, buf, blockloc, 1);
           break;
      case SLOT_STATE_FILEDEV:
           calculate_file_location();
           if ((f_lseek(&slot0file, blockloc) != FR_OK) ||
               (f_write(&slot0file, buf, 512, &br) != FR_OK) ||
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

void do_command()
{
  uint8_t cmd = read_dataport();
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
    default: write_dataport(0x07);
             break;
  }
}

void loop() {
  uint8_t instr = read_dataport();
  if (instr == 0xAC) do_command();
}
