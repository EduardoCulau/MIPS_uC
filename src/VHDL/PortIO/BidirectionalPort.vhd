library IEEE;
use IEEE.std_logic_1164.all;

entity BidirectionalPort  is
    generic (
        DATA_WIDTH           : integer;    -- Port width in bits
        PORT_DATA_ADDR       : std_logic_vector(1 downto 0);     -- NO ALTERAR!
        PORT_CONFIG_ADDR     : std_logic_vector(1 downto 0);     -- NO ALTERAR! 
        PORT_ENABLE_ADDR     : std_logic_vector(1 downto 0);      -- NO ALTERAR!
        PORT_IRQ_ENABLE_ADDR : std_logic_vector(1 downto 0)      -- NO ALTERAR!
    );
    port (  
        clock         : in std_logic;
        reset         : in std_logic; 
        
        -- Processor interface
        data_i      : in std_logic_vector (DATA_WIDTH-1 downto 0);
        data_o      : out std_logic_vector (DATA_WIDTH-1 downto 0);
        address     : in std_logic_vector (1 downto 0);     -- NO ALTERAR!
        irq         : out std_logic_vector(DATA_WIDTH-1 downto 0); -- alterado
        rw          : in std_logic; -- 0: read; 1: write
        ce          : in std_logic;
        
        -- External interface
        port_io     : inout std_logic_vector (DATA_WIDTH-1 downto 0)
    );
end BidirectionalPort ;


architecture Behavioral of BidirectionalPort  is
    signal ce_port : std_logic_vector(3 downto 0);
    signal ce_data, selectPortData : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal data_portdata_i, data_portdata_o, data_portconfig_o, data_portenable_o, data_portirq_o, port_io_synch : std_logic_vector(DATA_WIDTH-1 downto 0);
begin
    -- Registers
    PortConfig: entity work.Register_n_bits
        generic map (
            LENGTH      => DATA_WIDTH,
            INIT_VALUE  => 0
        )
        port map (  
            clock       => clock,
            reset       => reset,
            ce          => ce_port(1),
            d           => data_i,
            q           => data_portconfig_o
        );

    PortEnable: entity work.Register_n_bits
        generic map (
            LENGTH      => DATA_WIDTH,
            INIT_VALUE  => 0
        )
        port map (  
            clock       => clock,
            reset       => reset,
            ce          => ce_port(2),
            d           => data_i,
            q           => data_portenable_o
        );  
        
    IrqEnable: entity work.Register_n_bits
        generic map (
            LENGTH      => DATA_WIDTH,
            INIT_VALUE  => 0
        )
        port map (  
            clock       => clock,
            reset       => reset,
            ce          => ce_port(3),
            d           => data_i,
            q           => data_portirq_o 
        );  
        
    CE_DECODER: ce_port <=  "0001" when address = PORT_DATA_ADDR       and ce = '1' and rw = '1' else -- PortData
                            "0010" when address = PORT_CONFIG_ADDR     and ce = '1' and rw = '1' else -- PortConfig
                            "0100" when address = PORT_ENABLE_ADDR     and ce = '1' and rw = '1' else -- PortEnable
                            "1000" when address = PORT_IRQ_ENABLE_ADDR and ce = '1' and rw = '1' else -- PortIrqEnable 
                            "0000";
                            
    MUX_READ_TRISTATE:  data_o <=   data_portdata_o   when address = PORT_DATA_ADDR   else -- PortData
                                    data_portconfig_o when address = PORT_CONFIG_ADDR else -- PortConfig
                                    data_portenable_o when address = PORT_ENABLE_ADDR else -- PortEnable
                                    data_portirq_o; -- PortIrqEnable
                                    
    AND_IRQ: irq <= data_portdata_o and data_portconfig_o and data_portenable_o and data_portirq_o;
                                    
    -- for generate mux, and, synch
    PORT_DATA_SYNCH: for i in 0 to DATA_WIDTH-1 generate
    
        SYNCH_DATA: entity work.synchronization(behavioral)
            port map (
                clock               => clock,
                unsynch             => port_io(i),
                synch               => port_io_synch(i)								
            );
            
        selectPortData(i) <= not data_portconfig_o(i) and data_portenable_o(i);
        
        MUX_PORT_DATA: data_portdata_i(i) <= port_io_synch(i) when selectPortData(i) = '0' else data_i(i);
        
        ce_data(i) <= ce_port(0) or (data_portconfig_o(i) and data_portenable_o(i)); -- sempre escreve quando pino_in ou instrucao sw

        PortData: entity work.Register_n_bits
            generic map (
                LENGTH      => 1,
                INIT_VALUE  => 0
            )
            port map (  
                clock       => clock,
                reset       => reset,
                ce          => ce_data(i),
                d(0)        => data_portdata_i(i),
                q(0)        => data_portdata_o(i)
            );
            
        port_io(i) <= data_portdata_o(i) when selectPortData(i) = '1' else 'Z';

    end generate;
    
end Behavioral;