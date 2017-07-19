`timescale 1ns / 1ps
module alu #(parameter N = 32)
			  (input logic [N-1:0] a, b,
			   input logic [1:0] ALUControl,
			   output logic [N-1:0] Result,
			   output logic [3:0] ALUFlags);
	logic [N-1:0] sum, bb;
	always_comb
	begin
		ALUFlags[1] = 1'b0;
		case(f)
			3'b00: {ALUFlags[1], Result} = a + b;
			3'b01: Result = a - b;
			3'b10: Result = a & b;
			3'b11: Result = a | b;
		endcase;
		
		ALUFlags[3] = Result[31];
		ALUFlags[2] = (Result == 0);
		assign ALUFlags[0] = (~ALUControl[1]) & (Result[31] ^ a[31]) & (~(a[31] ^ b[31] ^ ALUControl[0]));
	end
endmodule