Instr[31:12] = 20'b1110_00_1_0100_0_0010_0001; //ADD R1, R2, #2
ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
Instr[31:12] = 20'b1110_00_0_0010_0_0011_0100; //SUB R4, R3, R5
ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
Instr[31:12] = 20'b1110_00_0_0000_1_0010_0111; //ANDS R7, R2, R3
ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
Instr[31:12] = 20'b0001_00_1_1100_0_0001_0010; //ORNE R2, R1, #5
ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
Instr[31:12] = 20'b1110_01_0_1100_1_0001_0011; //LDR R3, [R1, #10]
ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
Instr[31:12] = 20'b1110_01_0_1100_0_0010_0101; //STR R5, [R2, #2]
ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
Instr[31:12] = 20'b0000_10_1_0_000000000000; //BEQ
ALUFlags = 4'b0000; //{neg, zero, carry, overflow} = Flags;
Instr[31:12] = 20'b0000_10_1_0_000000000000; //BEQ
ALUFlags = 4'b0100; //{neg, zero, carry, overflow} = Flags;