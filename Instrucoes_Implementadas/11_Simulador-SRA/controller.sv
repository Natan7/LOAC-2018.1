`default_nettype none

// Funcoes da ULA seguindo Apendix A RISC-thesis -- Pagina 113
// funct7  funct3         instruction
/* 0000000 0000 */ parameter ADD  = 'b0000; // operando +
/* 0100000 1000 */ parameter SUB  = 'b1000; // operando -
/* 0000000 0001 */ parameter SLL  = 'b0001; // operando <<
/* 0000000 0010 */ parameter SLT  = 'b0010; // operando < (argumentos numeros inteiros)
/* 0000000 0011 */ parameter SLTU = 'b0011; // operando < (argumentos numeros naturais c/ zero)
/* 0000000 0100 */ parameter XOR  = 'b0100; // operando ^
/* 0000000 0101 */ parameter SRL  = 'b0101; // operando >>
/* 0100000 1101 */ parameter SRA  = 'b1101; // operando >>>
/* 0000000 0110 */ parameter OR   = 'b0110; // operando |
/* 0000000 0111 */ parameter AND  = 'b0111; // operando &

module controller #(parameter NBITS=8, NREGS=32, WIDTH_ALUF=4) (
  input logic clock, reset,

  // Datapath
  output logic [$clog2(NREGS)-1:0] RS2, RS1, RD,
  output logic signed [NBITS-1:0] IMM,
  output logic ALUSrc,
  output logic [WIDTH_ALUF-1:0] ALUControl,
  output logic MemtoReg,
  output logic RegWrite,
  output logic link,   // valida pclink para ser salvo no registrador RD 
  output logic [NBITS-1:0] pclink, // valor proveniente do PC a ser salvo em registrador RD
  input  logic Zero,  // indica que a saida da ULA eh 0
  input  logic Neg,   // indica que a saida da ULA eh negativa
  input  logic Carry, // vai-um sendo gerado pela operacao de subtracao da ULA
  input  logic [NBITS-1:0] PCReg, // usado para transferir o valor do registrador RS1 para o PC

  // Memoria ou cache
  output logic MemWrite,
  output logic MemRead, // indica operação de leitura
  input  logic busy,    // indica que memoria ou cache eh ocupado,ou seja,vai demorar para responder

  // Interrupcao
  input  logic interrupt,

  zoi z);

logic [NBITS-1:0] pc;
logic [NBITS-1:0] pc_;  // PC' o proximo valor do PC considerando interrupcao e desvio
logic [NBITS-1:0] ppc;  // o proximo valor do PC, desconsiderando interrupcao mas considerando desvio
logic [NBITS-1:0] PCBranch; // o proximo valor do PC em caso de desvio
logic [NBITS-1:0] PCPlus; // o proximo valor do PC caso houver nem interrupcao nem desvio
logic [NBITS-1:0] sepc; // guarda o PC para o qual deve retornar da rotina de atendimento a interrupcao

logic [NINSTR_BITS-1:0] instruction;
logic [6:2] op; // opcode sendo que os dois bits menos significativos sao 11
logic [6:0] funct7;
logic [2:0] funct3;

logic Branch;
logic PCSrc;
logic ju;    // indica desvio immediato incondicional
logic jr;    // indica desvio para o valor de um registrador (retorno de subrotina)
logic csrr;  // indica execucao da instruction cssr com argumento sepc
logic eflag; // indica condicao escolhida para desvio condicional


// ***** circuito para gerar o program counter

always_ff @(posedge clock) pc <= pc_;   // NAO MEXE - para compensar o registrador dentro da memoria

// salvar o valor do PC para o qual se deve retornar depois do atendimento da interrupcao
always_ff @(posedge clock) begin
  if (reset)            sepc <= 0;
  else if (interrupt)   sepc <= ppc;
end

always_comb begin
   PCPlus <= pc + 4;
end
always_comb begin
   ppc <= PCPlus;

      if (reset) pc_  <= 0;     // NAO MEXE - reset do pc e do endereco a memoria de instrucao
   else          pc_  <= ppc;
end

// ***** instrucoes

inst i(pc_, clock, instruction);  // NAO MEXE - dentro da memoria a entrada eh registrada

// Funcoes no formato de instruçao seguindo Apendix A RISC-thesis -- Pagina 113
// Despreza os dois bits menos significativos, sao sempre 11
                 // opcode
parameter UType  = 'b01101;
parameter IJal   = 'b11011;
parameter IJalr  = 'b11001;
parameter SBType = 'b11000;
parameter SType  = 'b01000;
parameter IType  = 'b00100;
parameter RType  = 'b01100;
parameter LType  = 'b00000;
parameter ICsrr  = 'b11100;


// ***** sinais de controle para o datapath e para o proprio controller

always_comb begin
   MemtoReg <= (op == -1);
   MemWrite <= (op == -1);
   Branch   <= (op == -1);
   ju       <= (op == -1);
   jr       <= (op == -1);
   csrr     <= (op == -1);
   ALUSrc   <= (op == IType);
end

always_comb begin
   MemRead <= 0;
   RegWrite <= 1;
   eflag <= 0;

   PCSrc <= 0;

   op <= instruction[6:2];	
   funct3 <= instruction[14:12];
	if(ALUSrc) begin
     		/////// ADDI
		ALUControl <= 0;
     		RD <= instruction[11:7];
		RS1 <= instruction[19:15];
     		RS2 <= 0;
     		funct7 <= 0;
     		IMM <= instruction[27:20];
	end else begin
     		/////// SRA
		ALUControl <= SRA;
     		RD <= instruction[11:7];
		RS1 <= instruction[19:15];
     		RS2 <= instruction[24:20];
     		funct7 <= instruction[31:25];
     		IMM <= 0;
	end

end

// zoiada
always_comb begin
   z.pc <= pc;
   z.instruction <= instruction;
   z.Branch <= Branch;
   z.MemWrite <= MemWrite;
end

endmodule
