..\Ignore\cc65\bin\ca65 Firmware.asm -o firmware.o --listing Firmware.lst --list-bytes 255 
..\Ignore\cc65\bin\ld65 -t none firmware.o -o Firmware.bin 
..\Ignore\cc65\bin\ca65 flash.asm -o flash.o --listing flash.lst --list-bytes 255 
..\Ignore\cc65\bin\ld65 -t none flash.o -o flash.bin 
copy /b flash.bin+Firmware.bin flash.system
rem assumes ProDOS-Utilities is in your path: https://github.com/tjboldt/ProDOS-Utilities
rem del x.po
rem ..\Ignore\ProDOS-Utilities -c create -d x.po -v ROM -s 65535 
rem copy x.po+zeroblock.bin BlankDriveWithFirmware.po 
rem del x.po
rem ..\Ignore\ProDOS-Utilities -b 0x0000 -c readblock -d BlankDriveWithFirmware.po 
rem ..\Ignore\ProDOS-Utilities -c ls -d BlankDriveWithFirmware.po 
