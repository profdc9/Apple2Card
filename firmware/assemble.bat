..\Ignore\cc65\bin\ca65 Firmware.asm -o firmware.o --listing Firmware.lst --list-bytes 255 
..\Ignore\cc65\bin\ld65 -t none firmware.o -o Firmware.bin 
rem assumes ProDOS-Utilities is in your path: https://github.com/tjboldt/ProDOS-Utilities
del x.po
..\Ignore\ProDOS-Utilities -c create -d x.po -v ROM -s 65535 
copy x.po+zeroblock.bin BlankDriveWithFirmware.po 
del x.po
..\Ignore\ProDOS-Utilities -b 0x0000 -c readblock -d BlankDriveWithFirmware.po 
..\Ignore\ProDOS-Utilities -c ls -d BlankDriveWithFirmware.po 
