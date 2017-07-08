`timescale 1ns / 1ps
module testbench();

  logic         clk;
  logic         reset;
  logic [31:12] Instr;
  logic [3:0]   ALUFlags;
  
  logic         PCWrite;
  logic         MemWrite;
  logic         RegWrite;
  logic         IRWrite;
  logic         AdrSrc;
  logic [1:0]   RegSrc;
  logic [1:0]   ALUSrcA;
  logic [1:0]   ALUSrcB;
  logic [1:0]   ResultSrc;
  logic [1:0]   ImmSrc;
  logic [1:0]   ALUControl;
  

  // instantiate device to be tested
  controller dut(clk, reset, Instr, ALUFlags, PCWrite, MemWrite, RegWrite, IRWrite, AdrSrc,
				 RegSrc, ALUSrcA, ALUSrcB, ResultSrc, ImmSrc, ALUControl);
  
  // initialize test
  initial
    begin
      reset <= 1; # 15; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  //Generate test signals
  initial
	begin
	  #10
	  Instr = 20'b1110_00_1_0100_0_0010_0001; //ADD R1, R2, #2
	  ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;		
	  #40;
	  Instr = 20'b1110_00_0_0010_0_0011_0100; //SUB R4, R3, R5
	  ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
	  #40;
	  Instr = 20'b1110_00_0_0000_1_0010_0111; //ANDS R7, R2, R3
	  ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
	  #40;
	  Instr = 20'b0001_00_1_1100_0_0001_0010; //ORNE R2, R1, #5
	  ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
	  #40;
	  Instr = 20'b1110_01_0_1100_1_0001_0011; //LDR R3, [R1, #10]
	  ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
	  #50;
	  Instr = 20'b1110_01_0_1100_0_0010_0101; //STR R5, [R2, #2]
	  ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
	  #40;
	  Instr = 20'b1110_10_1_0_000000000000; //B
	  ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
	  #30;
	  Instr = 20'b0001_10_1_0_000000000000; //BNE
	  ALUFlags = 4'b0100; //{neg, zero, carry, overflow} = Flags;
	  #30;
	  Instr = 20'b0000_10_1_0_000000000000; //BEQ
	  ALUFlags = 4'b0100; //{neg, zero, carry, overflow} = Flags;
	  #30;
	end
endmodule