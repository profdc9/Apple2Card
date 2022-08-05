rem could use the cat command under unix for this
..\Ignore\ProDOS-Utilities -c create -v BLANKVOL -d SingleBlankVol.po -v ROM -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S0D1 -d s0d1.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S0D2 -d s0d2.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S1D1 -d s1d1.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S1D2 -d s1d2.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S2D1 -d s2d1.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S2D2 -d s2d2.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S3D1 -d s3d1.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S3D2 -d s3d2.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S4D1 -d s4d1.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S4D2 -d s4d2.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S5D1 -d s5d1.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S5D2 -d s5d2.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S6D1 -d s6d1.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S6D2 -d s6d2.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S7D1 -d s7d1.po -s 65535 
..\Ignore\ProDOS-Utilities -c create -v S7D2 -d s7d2.po -s 65535
copy /B s0d1.po+zeroblock.bin+s1d1.po+zeroblock.bin+s2d1.po+zeroblock.bin+s3d1.po+zeroblock.bin+s4d1.po+zeroblock.bin+s5d1.po+zeroblock.bin+s6d1.po+zeroblock.bin+s7d1.po+zeroblock.bin+s0d2.po+zeroblock.bin+s1d2.po+zeroblock.bin+s2d2.po+zeroblock.bin+s3d2.po+zeroblock.bin+s4d2.po+zeroblock.bin+s5d2.po+zeroblock.bin+s6d2.po+zeroblock.bin+s7d2.po+zeroblock.bin BlankVols.po
copy /B s0d1.po+zeroblock.bin+s1d1.po+zeroblock.bin+s2d1.po+zeroblock.bin+s3d1.po+zeroblock.bin+s4d1.po+zeroblock.bin+s5d1.po+zeroblock.bin+s6d1.po+zeroblock.bin+s7d1.po+zeroblock.bin BlankVolsSlot1.po
copy /B s0d2.po+zeroblock.bin+s1d2.po+zeroblock.bin+s2d2.po+zeroblock.bin+s3d2.po+zeroblock.bin+s4d2.po+zeroblock.bin+s5d2.po+zeroblock.bin+s6d2.po+zeroblock.bin+s7d2.po+zeroblock.bin BlankVolsSlot2.po
del s0d1.po
del s0d2.po
del s1d1.po
del s1d2.po
del s2d1.po
del s2d2.po
del s3d1.po
del s3d2.po
del s4d1.po
del s4d2.po
del s5d1.po
del s5d2.po
del s6d1.po
del s6d2.po
del s7d1.po
del s7d2.po
