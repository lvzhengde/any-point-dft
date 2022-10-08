
`include "macros.v"

module testbench;
  harness harness();
  //integer i;
  //real temp;
  //integer ret_val;
  
  initial
  begin: test_procedure
   //open related files
   //i = 0;
   harness.reset;    
   //harness.stimuli.stimuli_file = $fopen(`STIMULI_FILE,"r");
   //harness.monitor.dump_file    = $fopen(`DUMP_FILE);
   //harness.fft_duv.radix4_unit2.test_file = $fopen(`TEST_FILE);
   fork
     harness.stimuli.gen_blk_stimuli;
     harness.monitor.monitor_act;
   join  
  end
  
  //always@(harness.monitor.rvd_frms) begin
  // i = harness.monitor.rvd_frms;
  //  if (i == `DUMP_FRAMES+1) begin
  //    //$fclose(harness.stimuli.stimuli_file);
  //    //$fclose(harness.monitor.dump_file);
  //    //$fclose(harness.fft_duv.radix4_unit2.test_file);
  //    $stop;
  //  end
  //end
  
  initial
  begin
    $dumpfile(`DUMP_VCD_FILE);
    $dumpvars(0, testbench.harness);
    $dumpoff;
  end
endmodule