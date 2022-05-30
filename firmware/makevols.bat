rem assumes ProDOS-Utilities is in your path: https://github.com/tjboldt/ProDOS-Utilities
del x.po
..\Ignore\ProDOS-Utilities -c create -d x.po -v ROM -s 65535 
rem could use the cat command under unix for this
copy /B x.po+zeroblock.bin y.po 
del x.po
..\Ignore\ProDOS-Utilities -b 0x0000 -c readblock -d y.po 
..\Ignore\ProDOS-Utilities -c ls -d y.po 
rem could use the cat command under unix for this
copy /B y.po+y.po+y.po+y.po+y.po+y.po+y.po+y.po+y.po+y.po+y.po+y.po+y.po+y.po BlankVols.po
del y.po
