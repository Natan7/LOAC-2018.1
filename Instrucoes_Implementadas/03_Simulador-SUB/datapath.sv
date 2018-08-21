`default_nettype none

/************************************************************/
// Datapath eh composto por:
// - Register FIle
// - ULA
/************************************************************/

module datapath #(parameter NBITS = 8, NREGS=32, WIDTH_ALUF=4) (
  input logic clock, reset,

  // Controller
  input logic  [$clog2(NREGS)-1:0] RS2,  RS1, RD,
  input logic signed [NBITS-1:0] IMM,
  input logic [WIDTH_ALUF-1:0] ALUControl,
  output logic Zero, Neg, Carry,
  input logic ALUSrc,
  input logic MemtoReg,
  input logic RegWrite,
  input logic link,  // valida pclink para ser salvo no registrador RD 
  input logic [NBITS-1:0] pclink, // valor proveniente do PC a ser salvo em registrador RD
  output logic [NBITS-1:0] PCReg, // registrador RS1 (SrcA) volta para o PC

  // Memoria ou cache
  output logic [NBITS-1:2] Address, 
  output logic [NBITS-1:0] WriteData,
  input logic [NBITS-1:0] ReadData,

  zoi z);

logic [NBITS-1:0] SrcA, SrcB;
logic signed [NBITS-1:0] SrcAs, SrcBs;  // SrcA e SrcB vistas como numeros inteiros
logic [NBITS-1:0] SUBResult;  // para poder recuperar o vai-um
logic [NBITS-1:0] ALUResult, Result;

// ****** banco de registradores

logic [NBITS-1:0] registrador [0:NREGS-1];

always_ff @(posedge clock)
  if (reset) begin
    for (int i=0; i < NREGS; i = i + 1)
		registrador[i] <= 0;
  end else if (RD!=0 && RegWrite) begin
    registrador[RD] <= ALUResult;
  end


always_comb begin // barramentos indo para a ULA
  SrcA <= registrador[RS1];
	if(ALUSrc) begin
		SrcB <= IMM;
	end else begin
		SrcB <= registrador[RS2];
	end

  SrcAs <= $signed(SrcA);
  SrcBs <= $signed(SrcB);
end

// ****** ULA

always_comb begin // barramentos conectados na saida da ULA
  Address <= 0;
  Result <= 0;

	if(ALUControl=='b1000) begin
  		ALUResult <= SrcAs - SrcBs;
	end else begin
  		ALUResult <= SrcA + SrcB;
	end

	//if(ALUResult==0) Zero <= 1;	
	//else 		 Zero <= 0;
end

// a zoiada
always_comb begin
  z.SrcA <= SrcA;
  z.SrcB <= SrcB;
  z.ALUResult <= ALUResult;
  z.Result <= Result;
  z.WriteData <= WriteData;
  z.ReadData <= ReadData;
  z.MemtoReg <= MemtoReg;
  z.RegWrite <= RegWrite;
  z.registrador <= registrador;
end

endmodule
