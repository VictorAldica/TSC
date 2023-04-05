module instr_register
import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
(input  logic          clk,
 input  logic          load_en,
 input  logic          reset_n,
 input  operand_t      operand_a,
 input  operand_t      operand_b,
 input  opcode_t       opcode,
 input  address_t      write_pointer,
 input  address_t      read_pointer,
 output instruction_t  instruction_word
);
  timeunit 1ns/1ns;
 
  result_t       result;
  instruction_t  iw_reg [0:31];  // an array of instruction_word structures

  // write to the register
  always@(posedge clk, negedge reset_n)   // write into register
    if (!reset_n) begin
      foreach (iw_reg[i])
        iw_reg[i] = '{opc:ZERO,default:0};  // reset to all zeros
    end
    else if (load_en) begin
	//TODO result 
      case(opcode) 
	  	ZERO  : result = 'b0;
        PASSA : result = operand_a;
        PASSB : result = operand_b;
        ADD   : result = operand_a+operand_b;
        SUB   : result = operand_a-operand_b;
        MULT  : result = operand_a*operand_b;
        DIV   : result = operand_a/operand_b;
        MOD   : result = operand_a%operand_b;
	  endcase
      iw_reg[write_pointer] = '{opcode,operand_a,operand_b,result};
	 
    end

  // read from the register
  assign instruction_word = iw_reg[read_pointer];  // continuously read from register

// compile with +define+FORCE_LOAD_ERROR to inject a functional bug for verification to catch
`ifdef FORCE_LOAD_ERROR
initial begin
  force operand_b = operand_a; // cause wrong value to be loaded into operand_b
end
`endif

endmodule: instr_register