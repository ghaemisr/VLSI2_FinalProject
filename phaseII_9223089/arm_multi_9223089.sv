// arm_multi.sv
// David_Harris@hmc.edu, Sarah_Harris@hmc.edu 25 December 2013
// Multi-cycle implementation of a subset of ARMv4

// 16 32-bit registers
// Data-processing instructions
//   ADD, SUB, AND, ORR
//   INSTR <cond> <S> <Rd>, <Rn>, #immediate
//   INSTR <cond> <S> <Rd>, <Rn>, <Rm>
//    Rd <- <Rn> INSTR <Rm>	    	if (S) Update Status Flags
//    Rd <- <Rn> INSTR immediate	if (S) Update Status Flags
//   Instr[31:28] = cond
//   Instr[27:26] = Op = 00
//   Instr[25:20] = Funct
//                  [25]:    1 for immediate, 0 for register
//                  [24:21]: 0100 (ADD) / 0010 (SUB) /
//                           0000 (AND) / 1100 (ORR)
//                  [20]:    S (1 = update CPSR status Flags)
//   Instr[19:16] = Rn
//   Instr[15:12] = Rd
//   Instr[11:8]  = 0000
//   Instr[7:0]   = immed_8  (for #immediate type) / 
//                  0000<Rm> (for register type)
//   
// Load/Store instructions
//   LDR, STR
//   INSTR <Rd>, [<Rn>, #offset]
//    LDR: Rd <- Mem[<Rn>+offset]
//    STR: Mem[<Rn>+offset] <- Rd
//   Instr[31:28] = cond
//   Instr[27:26] = Op = 01 
//   Instr[25:20] = Funct
//                  [25]:    0 (A)
//                  [24:21]: 1100 (P/U/B/W)
//                  [20]:    L (1 for LDR, 0 for STR)
//   Instr[19:16] = Rn
//   Instr[15:12] = Rd
//   Instr[11:0]  = imm (zero extended)
//
// Branch instruction (PC <= PC + offset, PC holds 8 bytes past Branch
//   B
//   INSTR <target>
//    PC <- PC + 8 + imm << 2
//   Instr[31:28] = cond
//   Instr[27:25] = Op = 10
//   Instr[25:24] = Funct
//                  [25]: 1 (Branch)
//                  [24]: 0 (link)
//   Instr[23:0]  = offset (sign extend, shift left 2)
//   Note: no Branch delay slot on ARM
//
// Other:
//   R15 reads as PC+8
//   Conditional Encoding
//    cond  Meaning                       Flag
//    0000  Equal                         Z = 1
//    0001  Not Equal                     Z = 0
//    0010  Carry Set                     C = 1
//    0011  Carry Clear                   C = 0
//    0100  Minus                         N = 1
//    0101  Plus                          N = 0
//    0110  Overflow                      V = 1
//    0111  No Overflow                   V = 0
//    1000  Unsigned Higher               C = 1 & Z = 0
//    1001  Unsigned Lower/Same           C = 0 | Z = 1
//    1010  Signed greater/equal          N = V
//    1011  Signed less                   N != V
//    1100  Signed greater                N = V & Z = 0
//    1101  Signed less/equal             N != V | Z = 1
//    1110  Always                        any
//   Writes to register 15 (PC) are ignored 

module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, Adr, 
           output logic        MemWrite);

  logic [31:0] PC, Instr, ReadData;
  
  // instantiate processor and shared memory
  arm arm(clk, reset, MemWrite, Adr, 
          WriteData, ReadData);
  mem mem(clk, MemWrite, Adr, WriteData, ReadData);
endmodule

module mem(input  logic        clk, we,
           input  logic [31:0] a, wd,
           output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  initial
      $readmemh("memfile.dat",RAM);

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule

module arm(input  logic        clk, reset,
           output logic        MemWrite,
           output logic [31:0] Adr, WriteData,
           input  logic [31:0] ReadData);

  logic [31:0] Instr;
  logic [3:0]  ALUFlags;
  logic        PCWrite, RegWrite, IRWrite;
  logic        AdrSrc;
  logic [1:0]  RegSrc, ALUSrcA, ALUSrcB, ImmSrc, ALUControl, ResultSrc;

  controller c(clk, reset, Instr[31:12], ALUFlags, 
               PCWrite, MemWrite, RegWrite, IRWrite,
               AdrSrc, RegSrc, ALUSrcA, ALUSrcB, ResultSrc,
               ImmSrc, ALUControl);
  datapath dp(clk, reset, Adr, WriteData, ReadData, Instr, ALUFlags,
              PCWrite, RegWrite, IRWrite,
              AdrSrc, RegSrc, ALUSrcA, ALUSrcB, ResultSrc,
              ImmSrc, ALUControl);
endmodule

module controller(input  logic         clk,
                  input  logic         reset,
                  input  logic [31:12] Instr,
                  input  logic [3:0]   ALUFlags,
                  output logic         PCWrite,
                  output logic         MemWrite,
                  output logic         RegWrite,
                  output logic         IRWrite,
                  output logic         AdrSrc,
                  output logic [1:0]   RegSrc,
                  output logic [1:0]   ALUSrcA,
                  output logic [1:0]   ALUSrcB,
                  output logic [1:0]   ResultSrc,
                  output logic [1:0]   ImmSrc,
                  output logic [1:0]   ALUControl);
                  
  logic [1:0] FlagW;
  logic       PCS, NextPC, RegW, MemW;
  
  decode dec(clk, reset, Instr[27:26], Instr[25:20], Instr[15:12],
             FlagW, PCS, NextPC, RegW, MemW,
             IRWrite, AdrSrc, ResultSrc, 
             ALUSrcA, ALUSrcB, ImmSrc, RegSrc, ALUControl);
  condlogic cl(clk, reset, Instr[31:28], ALUFlags,
               FlagW, PCS, NextPC, RegW, MemW,
               PCWrite, RegWrite, MemWrite);
endmodule

module decode(input  logic       clk, reset,
              input  logic [1:0] Op,
              input  logic [5:0] Funct,
              input  logic [3:0] Rd,
              output logic [1:0] FlagW,
              output logic       PCS, NextPC, RegW, MemW,
              output logic       IRWrite, AdrSrc,
              output logic [1:0] ResultSrc, ALUSrcA, ALUSrcB, 
              output logic [1:0] ImmSrc, RegSrc, ALUControl);

  logic       Branch, ALUOp;

  // Main FSM
  mainfsm fsm(clk, reset, Op, Funct, 
              IRWrite, AdrSrc, 
              ALUSrcA, ALUSrcB, ResultSrc,
              NextPC, RegW, MemW, Branch, ALUOp);

  // ALU Decoder           
  always_comb
    if (ALUOp) begin                 // which DP Instr?
      case(Funct[4:1]) 
  	    4'b0100: ALUControl = 2'b00; // ADD
  	    4'b0010: ALUControl = 2'b01; // SUB
        4'b0000: ALUControl = 2'b10; // AND
  	    4'b1100: ALUControl = 2'b11; // ORR
  	    default: ALUControl = 2'bx;  // unimplemented
      endcase
      // update flags if S bit is set 
	  // (C & V only updated for arith instructions)
      FlagW[1] = Funct[0]; // FlagW[1] = S-bit
	  // FlagW[0] = S-bit & (ADD | SUB)
      FlagW[0] = Funct[0] & (ALUControl == 2'b00 | ALUControl == 2'b01); 
    end else begin
      ALUControl = 2'b00; // add for non-DP instructions
      FlagW      = 2'b00; // don't update Flags
    end
	
  // PC Logic
  assign PCS  = ((Rd == 4'b1111) & RegW) | Branch; 

  // Instr Decoder
  assign ImmSrc    = Op;
  always_comb
	  case(Op)
		2'b00: 	 RegSrc = 2'b00; //Data-processing
		2'b01: 	 RegSrc = 2'b10; //Memory-Instr
		2'b10: 	 RegSrc = 2'b01; // Branch
		default: RegSrc = 2'bx;  // unimplemented
	  endcase
endmodule

module mainfsm(input  logic         clk,
               input  logic         reset,
               input  logic [1:0]   Op,
               input  logic [5:0]   Funct,
               output logic         IRWrite,
               output logic         AdrSrc,
               output logic [1:0]   ALUSrcA, ALUSrcB, ResultSrc,
               output logic         NextPC, RegW, MemW, Branch, ALUOp);  
              
  typedef enum logic [3:0] {FETCH, DECODE, MEMADR, MEMRD, MEMWB, 
                            MEMWR, EXECUTER, EXECUTEI, ALUWB, BRANCH, 
				     UNKNOWN} statetype;
  
  statetype state, nextstate;
  logic [12:0] controls;
  
  // state register
  always @(posedge clk or posedge reset)
    if (reset) state <= FETCH;
    else state <= nextstate;

  // next state logic
  always_comb
    casex(state)
      FETCH:                     nextstate = DECODE;
      DECODE: case(Op)
                2'b00: 
                  if (Funct[5]) nextstate = EXECUTEI;
                  else          nextstate = EXECUTER;
                2'b01:          nextstate = MEMADR;
                2'b10:          nextstate = BRANCH;
                default:        nextstate = UNKNOWN;
              endcase
      EXECUTER: 				nextstate = ALUWB;                
      EXECUTEI: 				nextstate = ALUWB;        
      MEMADR: if (Funct[0]) 	nextstate = MEMRD;
			  else 				nextstate = MEMWR;
      MEMRD:               		nextstate = MEMWB;
      default:                  nextstate = FETCH; 
    endcase

  // state-dependent output logic
  always_comb
    case(state)
      FETCH: 	controls = 13'b10001_010_01100; 
      DECODE:  	controls = 13'b00000_010_01100;      
      EXECUTER: controls = 13'b00000_000_00001;
      EXECUTEI: controls = 13'b00000_000_00011;
      ALUWB: 	controls = 13'b00010_000_00000;
      MEMADR:   controls = 13'b00000_000_00010;
      MEMWR: 	controls = 13'b00100_100_00000;
      MEMRD: 	controls = 13'b00000_100_00000;
      MEMWB: 	controls = 13'b00010_001_00000;
      BRANCH: 	controls = 13'b01000_010_10010;
      default: 	controls = 13'bxxxxx_xxx_xxxxx;
    endcase

  assign {NextPC, Branch, MemW, RegW, IRWrite,
          AdrSrc, ResultSrc,   
          ALUSrcA, ALUSrcB, ALUOp} = controls;
endmodule              

module condlogic(input  logic       clk, reset,
                 input  logic [3:0] Cond,
                 input  logic [3:0] ALUFlags,
                 input  logic [1:0] FlagW,
                 input  logic       PCS, NextPC, RegW, MemW,
                 output logic       PCWrite, RegWrite, MemWrite);

  logic [1:0] FlagWrite;
  logic [3:0] Flags;
  logic       CondEx, CondExDelayed;
  
  flopenr #(2)flagreg1(clk, reset, FlagWrite[1], 
                       ALUFlags[3:2], Flags[3:2]);
  flopenr #(2)flagreg0(clk, reset, FlagWrite[0], 
                       ALUFlags[1:0], Flags[1:0]);
					   
  condcheck cc(Cond, Flags, CondEx);					   
  flopr #(1)condreg(clk, reset, CondEx, CondExDelayed);
  
  assign FlagWrite = FlagW & {2{CondEx}};				   
  assign RegWrite  = RegW & CondExDelayed;
  assign MemWrite  = MemW & CondExDelayed;
  assign PCWrite   = (PCS & CondExDelayed) | NextPC;
  

  
endmodule    

module condcheck(input  logic [3:0] Cond,
                 input  logic [3:0] Flags,
                 output logic       CondEx);

  logic neg, zero, carry, overflow, ge;
  
  assign {neg, zero, carry, overflow} = Flags;
  assign ge = (neg == overflow);
                  
  always_comb
    case(Cond)
      4'b0000: CondEx = zero;             // EQ
      4'b0001: CondEx = ~zero;            // NE
      4'b0010: CondEx = carry;            // CS
      4'b0011: CondEx = ~carry;           // CC
      4'b0100: CondEx = neg;              // MI
      4'b0101: CondEx = ~neg;             // PL
      4'b0110: CondEx = overflow;         // VS
      4'b0111: CondEx = ~overflow;        // VC
      4'b1000: CondEx = carry & ~zero;    // HI
      4'b1001: CondEx = ~(carry & ~zero); // LS
      4'b1010: CondEx = ge;               // GE
      4'b1011: CondEx = ~ge;              // LT
      4'b1100: CondEx = ~zero & ge;       // GT
      4'b1101: CondEx = ~(~zero & ge);    // LE
      4'b1110: CondEx = 1'b1;             // Always
      default: CondEx = 1'bx;             // undefined
    endcase
endmodule


// ADD CODE BELOW
// Complete the datapath module below for PhaseII.
// You do not need to complete this module for phas1.
// The datapath unit is a structural SystemVerilog module. That is,
// it is composed of instances of its sub-modules. For example,
// the instruction register is instantiated as a 32-bit flopenr.
// The other submodules are likewise instantiated. 

module datapath(input  logic        clk, reset,
                output logic [31:0] Adr, WriteData,
                input  logic [31:0] ReadData,
                output logic [31:0] Instr,
                output logic [3:0]  ALUFlags,
                input  logic        PCWrite, RegWrite,
                input  logic        IRWrite,
                input  logic        AdrSrc, 
                input  logic [1:0]  RegSrc, 
                input  logic [1:0]  ALUSrcA, ALUSrcB, ResultSrc,
                input  logic [1:0]  ImmSrc, ALUControl);

  logic [31:0] PCNext, PC;
  logic [31:0] ExtImm, SrcA, SrcB, Result;
  logic [31:0] Data, RD1, RD2, A, ALUResult, ALUOut;
  logic [3:0]  RA1, RA2;

  //Registers
  flopenr #(32) pcreg(clk, reset, PCWrite, PCNext, PC);
  flopenr #(32) instrreg(clk, reset, IRWrite, ReadData, Instr);
  flopr #(32)   datareg(clk, reset, ReadData, Data);
  flopr #(32)   rd1reg(clk, reset, RD1, A);
  flopr #(32)   rd2reg(clk, reset, RD2, WriteData);
  flopr #(32)   alureg(clk, reset, ALUResult, ALUOut);
  
  //Multiplexers
  mux2 #(32)    adrmux(PC, Result, AdrSrc, Adr);
  mux2 #(4)     ra1mux(Instr[19:16], 4'b1111, RegSrc[0], RA1);
  mux2 #(4)     ra2mux(Instr[3:0], Instr[15:12], RegSrc[1], RA2);  
  mux3 #(32)    srcAmux(A, PC, ALUOut, ALUSrcA, SrcA);
  mux3 #(32)    srcBmux(WriteData, ExtImm, 32'h0000_0004, ALUSrcB, SrcB);
  mux3 #(32)    alumux(ALUOut, Data, ALUResult, ResultSrc, Result);
  
  //Register File
  regfile       rf(clk, RegWrite, RA1, RA2, Instr[15:12], Result, Result, RD1, RD2); 
  
  //Extend
  extend        ext(Instr[23:0], ImmSrc, ExtImm);
  
  //ALU
  alu           alu(SrcA, SrcB, ALUControl, ALUResult, ALUFlags);
  
  assign PCNext = Result;
  
endmodule


// ADD CODE BELOW
// Add needed building blocks below (i.e., parameterizable muxes, 
// registers, etc.). Remember, you can reuse code from previous labs.
// We've also provided a parameterizable 3:1 mux below for your 
// convenience.

module flopenr #(parameter WIDTH = 8)
                (input  logic             clk, reset, en,
                 input  logic [WIDTH-1:0] d, 
                 output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset)   q <= 0;
    else if (en) q <= d;
endmodule

module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

  assign y = s[1] ? d2 : (s[0] ? d1 : d0); 
endmodule

module mux2 #(parameter WIDTH = 8)
			 (input logic [WIDTH-1:0] d0, d1,
			  input logic s,
			  output logic [WIDTH-1:0] y);
			  
  assign y = s ? d1 : d0;
endmodule

module regfile(input  logic        clk, 
               input  logic        we3, 
               input  logic [3:0]  ra1, ra2, wa3, 
               input  logic [31:0] wd3, r15,
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[14:0];

  // three ported register file
  // read two ports combinationally
  // write third port on rising edge of clock
  // register 15 reads PC+8 instead

  always_ff @(posedge clk)
    if (we3) rf[wa3] <= wd3;	

  assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
  assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];
endmodule

module extend(input  logic [23:0] Instr,
              input  logic [1:0]  ImmSrc,
              output logic [31:0] ExtImm);
 
  always_comb
    case(ImmSrc) 
               // 8-bit unsigned immediate
      2'b00:   ExtImm = {24'b0, Instr[7:0]};  
               // 12-bit unsigned immediate 
      2'b01:   ExtImm = {20'b0, Instr[11:0]}; 
               // 24-bit two's complement shifted branch 
      2'b10:   ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00}; 
      default: ExtImm = 32'bx; // undefined
    endcase             
endmodule
