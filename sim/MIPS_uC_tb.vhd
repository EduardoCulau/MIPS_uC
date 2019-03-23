-------------------------------------------------------------------------
-- Design unit: MIPS_uC test bench
-- Description: Test Bench 
-------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MIPS_pkg.all;

use std.textio.all;
--use work.Util_pkg.all;  --Pegar na pasta da memoria (VHDL)


entity MIPS_uC_tb is
end MIPS_uC_tb;


architecture structural of MIPS_uC_tb is

	constant SPEED           : integer := 9600;
	constant FREQ_CLOCK_UART : integer := 50000000;      

	constant SIZE           : integer := 13;      --numero de instruçoes
	signal   SIZE_INST      : integer := 13;
	signal   SIZE_DATA      : integer := 13;
   --constant imageFileName   : string := "bin_data_file.txt";  --nome do arquivo
   
   type byteVec is array (0 to 4*SIZE-1) of std_logic_vector(7 downto 0);
   
   
   impure function PROGRAMLoad (imageFileName : in string) return byteVec is
        FILE imageFile : text open READ_MODE is imageFileName;
        variable fileLine : line;
        variable BinArray : byteVec;
        variable data_str : bit; --string(1 to 2);
		  variable bin : std_logic_vector(7 downto 0);
    begin   
        for i in 1 to SIZE loop
            readline (imageFile, fileLine);
            for j in 1 to 4 loop
					 for k in 7 downto 0 loop
						  read (fileLine, data_str);
						  bin(k) := to_stdulogic(data_str);
				    end loop;
                BinArray((i*4)-j) := bin; --StringToStdLogicVector(data_str);
            end loop; 
        end loop;
        return BinArray;
    end function;
     
	signal TXArray   : byteVec;
   signal INSTArray : byteVec := PROGRAMLoad("bin_code.txt");
	signal DATAArray : byteVec := PROGRAMLoad("bin_data.txt");

	 constant PERIOD : time := 10 ns; -- 100 MHz
    signal clock, clock_uart: std_logic := '1';
    signal reset: std_logic;
    
    -- MIPS signals
    signal port_io  : std_logic_vector(15 downto 0);
    signal port_i   : std_logic_vector(1 downto 0);
    signal tx, rx   : std_logic;
	 
	 -- UART signals
	 signal address : std_logic_vector(1 downto 0);
	 signal data_tx_i, data_rx_i : std_logic_vector(15 downto 0);
	 signal data_rx_o : std_logic_vector(7 downto 0);
	 signal data_tx_o, data_av_rx, data_av_tx : std_logic;
begin
	 
    clock <= not clock after PERIOD/2; 
    
    reset <= '1', '0' after 160 ns;
	     
    DCM: entity work.ClockManager(xilinx)
         port map (
            clk_100MHz           => clock,
            -- Clock out ports
            clk_50MHz            => clock_uart,
            clk_25MHz            => open,
            clk_10MHz            => open,
            clk_5MHz             => open
        );
    
    MIPS_uC: entity work.MIPS_uC(structural)
        port map (
            clk               => clock,
            rst               => reset,
            port1_io          => port_io,
            port2_i           => port_i,
			   tx                => tx,
			   rx                => rx
        );
        
   port_io <= x"0000";
	TXArray <= INSTArray when port_i(0) = '0' else DATAArray;
--	port_i <= "00"; -- mode. mem.
	
	process
	    variable i : integer := 0;
		 variable j : integer := 0;
	begin	
       port_i <= "00"; -- exec
	    address <= "01";
		 data_av_tx <= '0';
		 data_tx_i <= STD_LOGIC_VECTOR(TO_UNSIGNED(FREQ_CLOCK_UART/(SPEED),16)); --5208, 16));
		 wait until reset = '0';
		 data_av_tx <= '1';
		 wait for PERIOD;
		 data_av_tx <= '0';
		 address <= "00";
		 data_tx_i <= (others => 'Z');
		 wait for 2500 us;
		 
		 wait;
				 
--		 data_tx_i <= x"00" & x"42";
--		 wait for PERIOD;
--		 data_av_tx <= '1';
--		 wait for PERIOD;
--		 data_av_tx <= '0';
--		 
--		 wait until data_tx_o = '1';
--		 data_tx_i <= x"00" & x"43";
--		 wait for 4*PERIOD;
--		 data_av_tx <= '1';
--		 wait for PERIOD;
--		 data_av_tx <= '0';
--		 
--		 wait until data_tx_o = '1';
--		 data_tx_i <= x"00" & x"0D";
--		 wait for 4*PERIOD;
--		 data_av_tx <= '1';
--		 wait for PERIOD;
--		 data_av_tx <= '0';
--		 
--		 port_i <= "10"; -- prog. inst.
--		 wait for 2 ms;
--		 
--		 while i < 1*4
--		 loop
--			if data_tx_o = '1' then
--		     data_tx_i <= x"00" & TXArray(i);
--			  i := i + 1;
--			  data_av_tx <= '1';
--			  wait for 2*PERIOD;
--			  data_av_tx <= '0';
--			end if;
--         wait until data_tx_o = '1';			
--			wait for PERIOD;
--		 end loop;
--		 
--		 wait for 1000*PERIOD;
--		 port_i <= "11"; -- prog. data
----		 wait for 3 ms;
----		 
----		 while j < SIZE_DATA*4
----		 loop
----			if data_tx_o = '1' then
----		     data_tx_i <= x"00" & TXArray(j);
----			  j := j + 1;
----			  data_av_tx <= '1';
----			  wait for 2*PERIOD;
----			  data_av_tx <= '0';
----			end if;
----         wait until data_tx_o = '1';	
----			wait for PERIOD;			
----		 end loop;
----		 
----		 wait for 10000*PERIOD;
----		 port_i <= "01"; -- prog. data
--		 wait;
	end process;
	
	TX_TB: entity work.UART_TX(Behavioral)
        generic map (
            RATE_FREQ_BAUD_ADDR => "01",
            REG_DATA_ADDR       => "00" 
        )
        port map(
            clk         => not clock_uart,
            rst         => reset,
            tx          => rx,
            data_in     => data_tx_i,
            address     => address,
            data_av     => data_av_tx,
            ready       => data_tx_o     -- When '1', module is available to send a new byte
        );
		  
	RX_TB: entity work.UART_RX(Behavioral)
        generic map (
            RATE_FREQ_BAUD_ADDR => "01",
            REG_DATA_ADDR       => "00"
        )
        port map(
            clk         => not clock_uart,
            rst         => reset,
            ce          => '1',
            rx          => tx,
            data_in     => STD_LOGIC_VECTOR(TO_UNSIGNED(FREQ_CLOCK_UART/(SPEED), 16)),
            data_out    => data_rx_o,    
            address     => "01",
            data_av     => data_av_rx  -- When '1', data_out has one byte available 
        );
		  
end structural;