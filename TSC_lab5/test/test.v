/***********************************************************************
 * test.v
 *
 * Sanity check to make sure simulation runs.
 *
 **********************************************************************/
module test;

  initial
    begin
      $display("\n\nHello World!\n\n");
      #10 $finish;
    end

endmodule
