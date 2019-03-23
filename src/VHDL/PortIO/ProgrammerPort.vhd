library IEEE;
use IEEE.std_logic_1164.all;

entity ProgrammerPort  is
    port (  
        clock       : in std_logic;
        reset       : in std_logic; 
        
        -- Processor interface
        data_o      : out std_logic;
        rst_prog    : out std_logic;
        prog_mode   : out std_logic;
        address     : in std_logic_vector (1 downto 0);
        -- External interface
        port_i     : in std_logic_vector (1 downto 0)
    );
end ProgrammerPort ;


architecture Behavioral of ProgrammerPort  is
    signal data_portdata_i, data_portdata_o, port_i_synch, ff : std_logic_vector(1 downto 0);
begin
        
    -- for generate mux, and, synch
    PORT_DATA_SYNCH: for i in 0 to 1 generate
    
        SYNCH_DATA: entity work.synchronization(behavioral)
            port map (
                clock               => clock,
                unsynch             => port_i(i),
                synch               => port_i_synch(i)								
            );
            
        PortData: entity work.Register_n_bits
            generic map (
                LENGTH      => 1,
                INIT_VALUE  => 0
            )
            port map (  
                clock       => clock,
                reset       => reset,
                ce          => '1',
                d(0)        => data_portdata_i(i),
                q(0)        => data_portdata_o(i)
            );
    end generate;
    
    DE_BOUNCE_PROG_MODE: entity work.debounce(logic)
        generic map (
            counter_size        => 16 -- prototipação
--				counter_size        => 8 -- simulação
        )
        port map (
            clk       => clock,
				rst       => reset,
            button    => port_i_synch(1),
            result    => data_portdata_i(1)
        );
--      data_portdata_i(1) <= port_i_synch(1);
    
    DE_BOUNCE_PROG_MEM: entity work.debounce(logic)
        generic map (
            counter_size        => 8  -- prototipação
--              counter_size        => 4 -- simulação
        )
        port map (
            clk       => clock,
				rst       => reset,
            button    => port_i_synch(0),
            result    => data_portdata_i(0)
        );
--    data_portdata_i(0) <= port_i_synch(1);
        
    data_o <= data_portdata_o(0) when address = "00" else data_portdata_o(1);
    
    prog_mode <= data_portdata_o(1);
    rst_prog  <= data_portdata_o(1) xor ff(1);
    
    process(clock)
    begin
		  if reset = '1' then
				ff <= "00";
		  elsif rising_edge(clock) then 
            ff(0) <= data_portdata_o(1);
            ff(1) <= ff(0);
        end if;
    end process;
    
end Behavioral;