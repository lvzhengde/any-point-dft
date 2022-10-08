/*++
Abstract:
  Rom for frequency compensation factors
--*/

`include "macros.v"
`include "fixed_point.v"

module freq_comp_rom(
  rom_addr,
  rom_data
);
  input  [13:0] rom_addr;
  output [25:0] rom_data;

`ifdef ASIC
  freq_comp_asic_rom freq_comp_asic_rom(
    .rom_addr    (rom_addr),
    .rom_data    (rom_data)
  );
`elsif FPGA
  freq_comp_fpga_rom freq_comp_fpga_rom(
    .rom_addr    (rom_addr),
    .rom_data    (rom_data)
  );
`else   //simulation
  wire [25:0] rom_data;
  reg  [25:0] rom_mem[8999:0];
  reg  [25:0] comp;
  integer rom_file;
  integer bin_file;  
  integer rt_code;
  integer i;
  integer temp;
  
  initial
  begin
    //$readmemb(`BIN_COMP_FILE, rom_mem);     
    rom_file = $fopen(`COMP_FILE,"r");  
    bin_file = $fopen(`BIN_COMP_FILE);   
       
    for (i = 0; i < 9000; i = i+1) begin
      rt_code = $fscanf(rom_file, "%d", temp);
      if (rt_code > 0) begin
        comp = temp;
        rom_mem[i] = comp;
        $fdisplay(bin_file, "%b", rom_mem[i]);
      end
    end  
    
    $fclose(rom_file);
    $fclose(bin_file);  
  end

  assign rom_data = rom_mem[rom_addr];
`endif

endmodule
