/*++
Abstract:
    Coefficient LUT for polyphase filter
    Dual port ROM, combinational output
--*/

`include "macros.v"
`include "fixed_point.v"

module fir_coef_lut(
  rd_addr1_i, 
  rd_addr2_i,
  rd_data1_o, 
  rd_data2_o
  );
  parameter LUT_WIDTH = `P_LEN*`FIR_CO_WIDTH; //coefficients 1.13
  parameter LUT_LEN = (2**`L_LDN)+1;
  input  [`L_LDN:0] rd_addr1_i;
  input  [`L_LDN:0] rd_addr2_i;
  output [LUT_WIDTH-1:0] rd_data1_o;
  output [LUT_WIDTH-1:0] rd_data2_o;
  
`ifdef ASIC
  rom_asic_fir rom_asic_fir(
    .rd_addr1_i        (rd_addr1_i),
    .rd_addr2_i        (rd_addr2_i),
    .rd_data1_o        (rd_data1_o),
    .rd_data2_o        (rd_data2_o)
  );
`elsif FPGA
  rom_fpga_fir rom_fpga_fir(
    .rd_addr1_i        (rd_addr1_i),
    .rd_addr2_i        (rd_addr2_i),
    .rd_data1_o        (rd_data1_o),
    .rd_data2_o        (rd_data2_o)
  );  
`else      //simulation
  wire [LUT_WIDTH-1:0] rd_data1_o;
  wire [LUT_WIDTH-1:0] rd_data2_o;
  reg  [LUT_WIDTH-1:0] rom_mem[LUT_LEN-1:0];
  reg  [`FIR_CO_WIDTH-1:0] temp_coef[`P_LEN-1:0];
  integer fir_lut[(2**`L_LDN)*`P_LEN-1:0];
  integer lut_file;
  integer bin_file;
  integer rt_code;
  integer i,j;
  integer temp;
  
  initial
  begin
    //$readmemb(`BIN_FIR_COEF_FILE, rom_mem); 
    lut_file = $fopen(`FIR_COEF_FILE,"r");  
    bin_file = $fopen(`BIN_FIR_COEF_FILE);  
    
    for (i = 0; i < (2**`L_LDN)*`P_LEN; i = i+1) begin
      rt_code = $fscanf(lut_file, "%d", temp);
      if (rt_code > 0) begin
        fir_lut[i] = temp;
      end
    end 
    
    for(i = 0; i < 2**`L_LDN; i = i + 1) begin
      for(j = 0; j < `P_LEN; j = j + 1) begin
        temp_coef[j] = fir_lut[i+j*(2**`L_LDN)];
      end
      //special case P_LEN = 6
      rom_mem[i] = {temp_coef[5], temp_coef[4], temp_coef[3], temp_coef[2], temp_coef[1], temp_coef[0]};
      $fdisplay(bin_file, "%b", rom_mem[i]); 
    end
    //special case, last entry
    {temp_coef[5], temp_coef[4], temp_coef[3], temp_coef[2], temp_coef[1], temp_coef[0]} = rom_mem[0];
    rom_mem[LUT_LEN-1] = {temp_coef[0], temp_coef[5], temp_coef[4], temp_coef[3], temp_coef[2], temp_coef[1]};
    $fdisplay(bin_file, "%b", rom_mem[LUT_LEN-1]); 
    
    $fclose(lut_file); 
    $fclose(bin_file);  
  end

  assign rd_data1_o = rom_mem[rd_addr1_i];
  assign rd_data2_o = rom_mem[rd_addr2_i];  
`endif

endmodule
