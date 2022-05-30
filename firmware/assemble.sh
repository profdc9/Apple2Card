#!/bin/sh 
ca65 Firmware.asm -o firmware.o --listing Firmware.lst --list-bytes 255 || exit 1

ld65 -t none firmware.o -o Firmware.bin || exit 1
# assumes ProDOS-Utilities is in your path: https://github.com/tjboldt/ProDOS-Utilities
rm BlankDriveWithFirmware.po || exit 1
ProDOS-Utilities -c create -d BlankDriveWithFirmware.po -v ROM -s 65535 || exit 1
# ProDOS-Utilities -b 0x0001 -c writeblock -d GamesWithFirmware.po -i Firmware.bin || exit 1
# ProDOS-Utilities -b 0x0001 -c writeblock -d BlankDriveWithFirmware.po -i Firmware.bin || exit 1
# ProDOS-Utilities -b 0x0001 -c readblock -d BlankDriveWithFirmware.po || exit 1
# ProDOS-Utilities -c ls -d BlankDriveWithFirmware.po || exit 1

