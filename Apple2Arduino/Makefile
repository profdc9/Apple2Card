all: Apple2Arduino.ino.hex fuses.cfg
	@echo To burn the firmware under Linux, execute:
	@echo -e "\tminipro -p 'ATMEGA328P@DIP28' -c code -w Apple2Arduino.ino.hex -f ihex -e"
	@echo -e "\tminipro -p 'ATMEGA328P@DIP28' -c config -w fuses.cfg -e"

Apple2Arduino.ino.hex:
	arduino-cli compile -b arduino:avr:uno --output-dir . Apple2Arduino.ino

clean:
	rm Apple2Arduino.ino.eep Apple2Arduino.ino.elf Apple2Arduino.ino.hex Apple2Arduino.ino.with_bootloader.bin Apple2Arduino.ino.with_bootloader.hex
