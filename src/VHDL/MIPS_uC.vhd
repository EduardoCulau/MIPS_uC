-------------------------------------------------------------------------
-- Design unit: MIPS_uC
-- Description: Top file
-------------------------------------------------------------------------
-- Frequence entering the clk input in Hz / Baud rate (bits per sencond)
            -- Considering clk = 100MHz
            --      9600: RATE_FREQ_BAUD = 10416
            --      19200: RATE_FREQ_BAUD = 5208
            --      38400: RATE_FREQ_BAUD = 2604
            --      57600: RATE_FREQ_BAUD = 1736
            --      115200: RATE_FREQ_BAUD = 868 <--
            --      460800: RATE_FREQ_BAUD = 217
            --      921600: RATE_FREQ_BAUD = 108

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MIPS_pkg.all;


entity MIPS_uC is
    port (
        clk              : in std_logic;
        rst              : in std_logic;

        -- Port I/O interface
        port1_io         : inout std_logic_vector(15 downto 0);
		  -- Port programmer
        port2_i          : in std_logic_vector(1 downto 0);
		  -- UART
        tx               : out std_logic;
        rx               : in std_logic
    );
end MIPS_uC;

architecture structural of MIPS_uC is

    signal reset_sync, reset_all, clk_div, clk_5MHz, clk_25MHz, clk_n: std_logic;

    -- MIPS interface
    signal instructionAddress, dataAddress, instruction, data_mips_i, data_mips_o : std_logic_vector(31 downto 0);
    signal wbe: std_logic_vector(3 downto 0);
    signal ce_data, ce_data_mem, ce_ins, wr: std_logic;
    signal ce_data_perif : std_logic_vector(7 downto 0);

    -- Memories interface
    signal data_mem_o, data_boot_o, data_ins_o : std_logic_vector(31 downto 0);
	 signal instAddress : std_logic_vector(29 downto 0);

    -- Port I/O interface
    signal data_port1_i, data_port1_o, irq : std_logic_vector(15 downto 0);
    signal intr : std_logic;

    -- PIC interface
    signal data_pic_io : std_logic_vector(7 downto 0);

    -- TX interface
    signal data_tx_i : std_logic_vector(15 downto 0);
    signal data_tx_o, data_av_tx : std_logic;

    -- RX interface
    signal data_rx_i : std_logic_vector(15 downto 0);
    signal data_rx_o : std_logic_vector(7 downto 0);
    signal data_av_rx, ce_rx: std_logic;

    -- Port Programmer interface
    signal data_port2_o, rst_prog, prog_mode : std_logic;

    -- Timer interface
    signal data_timer_io : std_logic_vector(31 downto 0);
    signal time_out : std_logic;

    constant PC_START_ADDRESS  : std_logic_vector(31 downto 0) := x"00000000"; --:= x"00400000";
begin

    DCM: entity work.ClockManager(xilinx)
         port map (
            clk_100MHz           => clk,
            -- Clock out ports
            clk_50MHz            => open,
            clk_25MHz            => clk_25MHz,
            clk_10MHz            => open,
            clk_5MHz             => clk_5MHz
        );
	 clk_div <= clk_5MHz;  -- prototipação
--	 clk_div <= clk_25MHz; -- simulação

    RESET_SYNCHRONIZATION: entity work.synchronization(behavioral)
        port map (
            clock               => clk_div,
            unsynch             => rst,
            synch               => reset_sync
        );

    reset_all <= reset_sync  or rst_prog;

    MIPS_MULTICYCLE: entity work.MIPS_MultiCycle(structural)
        generic map (
            PC_START_ADDRESS  => TO_INTEGER(UNSIGNED(PC_START_ADDRESS))
        )
         port map (
            clock               => clk_div,
            reset               => reset_all,

            -- Instruction memory interface
            instructionAddress  => instructionAddress,
            instruction         => instruction,
            ce_ins              => ce_ins,

             -- Data memory interface
            dataAddress         => dataAddress,
            data_i              => data_mips_i,
            data_o              => data_mips_o,
            wbe                 => wbe,
            ce_data             => ce_data,

            -- Interruption interface
            intr                => intr
        );

    clk_n <= not clk_div;

    BOOTLOADER_MEMORY: entity work.Memory(BlockRAM)
        generic map (
            SIZE            => 45,                 -- Memory depth
    		imageFileName   => "bootloader.txt",
            OFFSET          => UNSIGNED(PC_START_ADDRESS)
        )
        port map (
            clock           => clk_n,
            ce              => ce_ins and prog_mode,
            wr              => '0',  -- Only reads (ROM)
            address         => instructionAddress(31 downto 2), -- Converts byte address to word address
            data_i          => data_mips_o,
            data_o          => data_boot_o
        );

    INSTRUCTION_MEMORY: entity work.Memory(BlockRAM)
        generic map (
            SIZE            => 1024,                 -- Memory depth
            imageFileName   => "Application_code.txt",
			   --imageFileName   => "teste1_code.txt",
            OFFSET          => UNSIGNED(PC_START_ADDRESS)
        )
        port map (
            clock           => clk_n,
            ce              => ce_ins or ce_data_perif(6), -- instruction (execution mode), data (programmer mode)
            wr              => wr,
            address         => instAddress, -- Converts byte address to word address
            data_i          => data_mips_o,
            data_o          => data_ins_o
        );

	instAddress <= "0000" & dataAddress(27 downto 2) when ce_data_perif(6) = '1' else instructionAddress(31 downto 2);
    instruction  <= data_ins_o when prog_mode = '0' else data_boot_o;

    wr <= wbe(3) and wbe(2) and wbe(1) and wbe(0);

    DATA_MEMORY: entity work.Memory(BlockRAM)
        generic map (
            SIZE            => 1024,              -- Memory depth
            imageFileName   => "Application_data.txt",
			   --imageFileName   => "teste1_data.txt",
            OFFSET          => x"00002000"		-- Data start address on MARS
        )
        port map (
            clock           => clk_n,
            ce              => ce_data_perif(0),
            wr              => wr,
            address         => dataAddress(31 downto 2), -- Converts byte address to word address
            data_i          => data_mips_o,
            data_o          => data_mem_o
        );

    -- ce decoder -- transformar este decoder em uma entidade semelhante ao BidirectionalPort, max 16 port
    CE_DECODER: ce_data_perif <= "00000001" when dataAddress(31 downto 28) = "0000" and ce_data = '1' else -- DataMemory
                                 "00000010" when dataAddress(31 downto 28) = "0001" and ce_data = '1' else -- PortIO
                                 "00000100" when dataAddress(31 downto 28) = "0010" and ce_data = '1' else -- PIC
                                 "00001000" when dataAddress(31 downto 28) = "0011" and ce_data = '1' else -- TX
                                 "00010000" when dataAddress(31 downto 28) = "0100" and ce_data = '1' else -- RX
                                 "00100000" when dataAddress(31 downto 28) = "0101" and ce_data = '1' else -- PortProgrammer
                                 "01000000" when dataAddress(31 downto 28) = "0110" and ce_data = '1' else -- InstructionMemory (programmer mode)
                                 "10000000" when dataAddress(31 downto 28) = "0111" and ce_data = '1' else -- Timer
                                 "00000000";

    -- Input bus
    data_mips_i <=  x"0000" & data_port1_o            when ce_data_perif(1) = '1' else -- portIO
                    x"000000" & data_pic_io           when ce_data_perif(2) = '1' else -- pic
                    x"0000000" & "000" & data_tx_o    when ce_data_perif(3) = '1' else -- tx
                    x"000000" & data_rx_o             when ce_data_perif(4) = '1' else -- rx
                    x"0000000" & "000" & data_port2_o when ce_data_perif(5) = '1' else -- portProgrammer
				    data_ins_o                        when ce_data_perif(6) = '1' else -- Instruction Memory
                    data_timer_io                     when ce_data_perif(7) = '1' else -- Timer
                    data_mem_o;  -- memory

    -- Perifericos --

    -- to bidirectional
    data_port1_i <= data_mips_o(15 downto 0);

    BIDIRECTIONAL_PORT1_IO: entity work.BidirectionalPort(Behavioral)
        generic map (
            DATA_WIDTH           => 16,
            PORT_DATA_ADDR       => "00",
            PORT_CONFIG_ADDR     => "01",
            PORT_ENABLE_ADDR     => "10",
            PORT_IRQ_ENABLE_ADDR => "11"
        )
        port map (
            clock         => clk_n,
            reset         => reset_all,

            -- Processor interface
            data_i      => data_port1_i,
            data_o      => data_port1_o,
            address     => dataAddress(1 downto 0),
            irq         => irq,
            rw          => wr,
            ce          => ce_data_perif(1),

            -- External interface
            port_io     => port1_io
        );

    -- to pic
    data_pic_io <= data_mips_o(7 downto 0) when wr = '1' and ce_data_perif(2) = '1' else (others => 'Z');

    PIC: entity work.InterruptController(Behavioral)
        generic map (
            IRQ_ID_ADDR     => "00", -- Interruption request number (vector)
            INT_ACK_ADDR    => "01", -- Interrupt acknowledgement address
            MASK_ADDR       => "10"  -- Mask register address
        )
        port map (
            clk         => clk_n,
            rst         => reset_all,

            data        => data_pic_io,
            address     => dataAddress(1 downto 0),
            rw          => wr,
            ce          => ce_data_perif(2),
            intr        => intr, -- To processor
            irq         => irq(15 downto 12) & "00" & data_av_rx & time_out
        );

    -- to tx
    data_tx_i <= data_mips_o(15 downto 0);
	data_av_tx <= '1' when ce_data_perif(3) = '1' and wr = '1' else '0';

    TXX: entity work.UART_TX(Behavioral)
        generic map (
            RATE_FREQ_BAUD_ADDR => "01",
            REG_DATA_ADDR       => "00"
        )
        port map(
            clk         => clk_n,
            rst         => reset_all,
            tx          => tx,
            data_in     => data_tx_i,
            address     => dataAddress(1 downto 0),
            data_av     => data_av_tx,
            ready       => data_tx_o     -- When '1', module is available to send a new byte
        );

    -- to rx
    data_rx_i <= data_mips_o(15 downto 0); -- to configure the FREQ_BAUD_RATE
    ce_rx     <= '1' when ce_data_perif(4) = '1' and wr = '1' else '0';

    RXX: entity work.UART_RX(Behavioral)
        generic map (
            RATE_FREQ_BAUD_ADDR => "01",
            REG_DATA_ADDR       => "00"
        )
        port map(
            clk         => clk_n,
            rst         => reset_all,
            ce          => ce_rx,
            rx          => rx,
            data_in     => data_rx_i,
            data_out    => data_rx_o,
            address     => dataAddress(1 downto 0),
            data_av     => data_av_rx  -- When '1', data_out has one byte available
        );


    PROGRAMMER_PORT2_IO: entity work.ProgrammerPort(Behavioral)
        port map (
            clock         => clk_5MHz,
            reset         => reset_sync,

            -- Processor interface
            data_o      => data_port2_o,
            prog_mode   => prog_mode,
            rst_prog    => rst_prog,
            address     => dataAddress(1 downto 0),

            -- External interface
            port_i      => port2_i
        );

    -- to Timer
    data_timer_io <= data_mips_o when wr = '1' and ce_data_perif(7) = '1' else (others => 'Z');

    TIMER: entity work.Timer(Behavioral)
        generic map (
            DATA_WIDTH  => 32
        )
        port map (
            clk         => clk_5MHz,
            rst         => reset_all,

            -- Processor interface
            data        => data_timer_io,
            rw          => wr,
            ce          => ce_data_perif(7),
            time_out    => time_out
        );

end structural;
