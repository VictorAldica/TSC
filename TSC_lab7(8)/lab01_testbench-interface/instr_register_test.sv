/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
    // user-defined types are defined in instr_register_pkg.sv
  (tb_ifc.TEST tbintf);
 /* (input  logic        test_clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
  );
*/ 
  timeunit 1ns/1ns;
  import instr_register_pkg::*;
 
  parameter NUMBER_OF_TRANSACTION = 100;
  parameter int seed = 555;
  parameter RND_CASE = 0;
  parameter TEST_NAME = "N/A";
  int number_of_errors = 0;
  instruction_t actual [0:31];
  result_t expected [0:31];

  initial begin
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(    "***********************************************************");

    $display("\nReseting the instruction register..");

    //cov_calc = new();

    tbintf.write_pointer  <= 5'h00;         // initialize write pointer
    tbintf.read_pointer   <= 5'h1F;         // initialize read pointer
    tbintf.load_en        <= 1'b0;          // initialize load control line
    tbintf.reset_n        <= 1'b0;          // assert reset_n (active low)
    repeat (2) @(posedge tbintf.test_clk) ;     // hold in reset for 2 clock cycles
    tbintf.reset_n        <= 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack..");
    @(posedge tbintf.test_clk) tbintf.load_en <= 1'b1;  // enable writing to register
    repeat (NUMBER_OF_TRANSACTION) begin
      @(posedge tbintf.test_clk) randomize_transaction;
      @(negedge tbintf.test_clk) print_transaction;
    end
    @(posedge tbintf.test_clk) tbintf.load_en <= 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written..");
    for (int i=0; i<NUMBER_OF_TRANSACTION; i++) begin
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back

    // cov_calc.sample();

      if (RND_CASE == 0 || RND_CASE == 2)
        @(posedge tbintf.test_clk) tbintf.read_pointer <= i; 
      else       //TODO read_pointer random 
        @(posedge tbintf) tbintf.read_pointer <= $unsigned($random)%32;
      actual[tbintf.read_pointer].result = (tbintf.instruction_word.result);
      @(negedge tbintf.test_clk) print_results; 
    end
    @(posedge tbintf.test_clk) ;

     check_results();

     $display("\nErrors : %d", number_of_errors);
    if(number_of_errors)   $display("\n TEST FAILLED");
    else    $display("\n TEST PASSED");

    $display("\n***********************************************************");
    $display(  "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(  "***********************************************************\n");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp = 0;//toate variabilele declarate de la oricate apeluri de functie, variabila static respectiva va pointa atre aceiasi zona
    tbintf.operand_a     <= $random(seed)%16;                 // between -15 and 15
    tbintf.operand_b     <= $unsigned($random)%16;            // between 0 and 15
    tbintf.opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
//TODO write pointer sa ia valori random intre 0 si 31
     if (RND_CASE == 0 || RND_CASE == 1) tbintf.write_pointer <=temp++;
    else tbintf.write_pointer <= $unsigned($random)%32;;
    actual[tbintf.write_pointer] = '{tbintf.opcode,tbintf.operand_a,tbintf.operand_b, 'b0};
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", tbintf.write_pointer);
    $display("  opcode = %0d (%s)", tbintf.opcode, tbintf.opcode.name);
    $display("  operand_a = %0d",   tbintf.operand_a);
    $display("  operand_b = %0d\n", tbintf.operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", tbintf.read_pointer);
    $display("  opcode = %0d (%s)", tbintf.instruction_word.opc, tbintf.instruction_word.opc.name);
    $display("  operand_a = %0d",   tbintf.instruction_word.op_a);
    $display("  operand_b = %0d\n", tbintf.instruction_word.op_b);
    $display("  result = %0d\n", tbintf.instruction_word.result);
  endfunction: print_results

  
  function void check_results();
  foreach(actual[i])begin
     case(actual[i].opc) 
	  	  ZERO  : expected[i] = 'b0;
        PASSA : expected[i] = actual[i].op_a;
        PASSB : expected[i] = actual[i].op_b;
        ADD   : expected[i] = actual[i].op_a+actual[i].op_b;
        SUB   : expected[i] = actual[i].op_a-actual[i].op_b;
        MULT  : expected[i] = actual[i].op_a*actual[i].op_b;
        DIV   : expected[i] = actual[i].op_a/actual[i].op_b;
        MOD   : expected[i] = actual[i].op_a%actual[i].op_b;
	  endcase
    if(expected[i] != actual[i].result) begin
      number_of_errors++;
       $error("\n i = %0d: opcode = %0d (%s)  operand_a = %0d operand_b = %0d \n expected result = %0d  actual result = %0d \n",i , actual[i].opc, actual[i].opc.name, actual[i].op_a, actual[i].op_b, expected[i],actual[i].result);
    end
   end
  endfunction: check_results

endmodule: instr_register_test
