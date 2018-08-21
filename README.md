# LOAC-2018.1
###Na pasta do codigo assemly Risc-v

riscv32-unknown-elf-gcc -nostdlib -nostartfiles -Tlink.ld -o inst inst.s
riscv32-unknown-elf-objdump -s -j .text inst | egrep " [0-9a-f]{4} [0-9a-f]{8}" | cut -b7-41 > inst.objdump

make 

###Conferindo resultado do simulador, pelo spike

spike-bm -m2 -d inst

	#No prompt":"
		a) Enter - executa uma instrução/vez
		b) reg 0 - visualiza os registradores
c) q - sairimplementação de algumas instruções requisitadas na prova das tirinhas, da disciplina de Laboratório de Arquitetura de Computadores (LOAC).
