------------------------------------------------------------------------------
-- DESIGN UNIT  : UART RX                                                   --
-- DESCRIPTION  : Start bit/8 data bits/Stop bit                            --
--              :                                                           --
-- AUTHOR       : Everton Alceu Carara                                      --
-- CREATED      : May, 2016                                                 --
-- VERSION      : 1.0                                                       --
-- HISTORY      : Version 1.0 - May, 2016 - Everton Alceu Carara            --         
------------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UART_RX is
    generic (
        RATE_FREQ_BAUD_ADDR : std_logic_vector(1 downto 0);    -- NO ALTERAR! 
        REG_DATA_ADDR       : std_logic_vector(1 downto 0)     -- NO ALTERAR!
    );
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        ce          : in std_logic;
        rx          : in std_logic;
        data_in     : in std_logic_vector(15 downto 0);
        data_out    : out std_logic_vector(7 downto 0);
        address     : in std_logic_vector (1 downto 0);  
        data_av     : out std_logic
    );
end UART_RX;

architecture behavioral of UART_RX is

     signal clkCounter: integer range 0 to 10416; 
     signal bitCounter: integer range 0 to 8;
     signal sampling: std_logic;
         
     type State is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
     signal currentState: State;
     
     signal rx_data: std_logic_vector(7 downto 0);
     
     signal RATE_FREQ_BAUD: std_logic_vector(15 downto 0);
     
     signal ce_reg: std_logic_vector(1 downto 0);
     
begin

    CE_DECODER: ce_reg <=  "01" when address = REG_DATA_ADDR and ce = '1' else -- reg data
                           "10" when address = RATE_FREQ_BAUD_ADDR and ce = '1' else -- RATE_FREQ_BAUD
                           "00";

    process(clk, rst)
    begin
        if rst = '1' then
            RATE_FREQ_BAUD <= x"0000";
        elsif rising_edge(clk) then
            if ce_reg(1) = '1' then
                RATE_FREQ_BAUD <= data_in;
            end if;
        end if;
    end process;

    process(clk,rst)
    begin
        if rst = '1' then
            clkCounter <= 0;
         elsif rising_edge(clk) then
            if currentState /= IDLE then
                if clkCounter = TO_INTEGER(UNSIGNED(RATE_FREQ_BAUD))-1 then
                    clkCounter <= 0;
                else
                    clkCounter <= clkCounter + 1;
                end if;
            else
                clkCounter <= 0;
            end if;
         end if;
    end process;

    data_out <= rx_data;
    
    sampling <= '1' when clkCounter = TO_INTEGER(UNSIGNED(RATE_FREQ_BAUD))/2 else '0';  
    
    process(clk,rst)
    begin
        if rst = '1' then
            bitCounter <= 0;
            rx_data <= (others=>'0');
            currentState <= IDLE;
        
        elsif rising_edge(clk) then
            case currentState is
                when IDLE =>
                    bitCounter <= 0;
                    if rx = '0' then
                        currentState <= START_BIT;
                    else
                        currentState <= IDLE;
                    end if;
                    
                when START_BIT =>
                    if sampling = '1' then
                        currentState <= DATA_BITS;
                    else
                        currentState <= START_BIT;
                    end if;                    
                        
                when DATA_BITS =>
                    if bitCounter = 8 then
                        currentState <= STOP_BIT;
                    elsif sampling = '1' then           
                        rx_data <= rx & rx_data(7 downto 1);
                        bitCounter <= bitCounter + 1;
                        currentState <= DATA_BITS;
                    else
                        currentState <= DATA_BITS;
                    end if;
                    
                when STOP_BIT =>
                    if rx = '1' and sampling = '1' then
                        currentState <= IDLE;
                    else
                        currentState <= STOP_BIT;
                    end if;
                                      
            end case;
        end if;
    end process;
    
    data_av <= sampling when currentState = STOP_BIT else '0';
    
end behavioral;

--architecture oversampling of UART_RX is
--
--     signal clkCounter: integer range 0 to RATE_FREQ_BAUD; 
--     signal tick: std_logic;
--     signal tickCounter: UNSIGNED(3 downto 0);
--     signal bitCounter: integer range 0 to 8;
--     signal sampling: std_logic;
--          
--     type State is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
--     signal currentState: State;
--     
--     signal rx_data: std_logic_vector(7 downto 0);
--     
--begin
--
--    data_out <= rx_data;
--    
--    sampling <= tick when tickCounter = 8 else '0';
--    
--    process(clk,rst)
--    begin
--        if rst = '1' then
--            clkCounter <= 0;
--            tick <= '0';
--            tickCounter <= (others=>'0');
--        
--        elsif rising_edge(clk) then
--            if currentState /= IDLE then
--                if clkCounter = RATE_FREQ_BAUD-1 then
--                    tick <= '1';
--                    tickCounter <= tickCounter + 1;
--                    clkCounter <= 0;
--                else
--                    tick <= '0';
--                    clkCounter <= clkCounter + 1;
--                end if;
--            end if;
--        end if;
--    end process;
--    
--    process(clk,rst)
--    begin
--        if rst = '1' then
--            bitCounter <= 0;
--            currentState <= IDLE;
--        
--        elsif rising_edge(clk) then
--            case currentState is
--                when IDLE =>
--                    bitCounter <= 0;
--                    if rx = '0' then
--                        currentState <= START_BIT;
--                    else
--                        currentState <= IDLE;
--                    end if;
--                    
--                when START_BIT =>
--                    if sampling = '1' then
--                        currentState <= DATA_BITS;
--                    else
--                        currentState <= START_BIT;
--                    end if;                    
--                        
--                when DATA_BITS =>
--                    if bitCounter = 8 then
--                        currentState <= STOP_BIT;
--                    elsif sampling = '1' then           
--                        rx_data <= rx & rx_data(7 downto 1);
--                        bitCounter <= bitCounter + 1;
--                        currentState <= DATA_BITS;
--                    else
--                        currentState <= DATA_BITS;
--                    end if;
--                    
--                when STOP_BIT =>
--                    if rx = '1' and sampling = '1' then
--                        currentState <= IDLE;
--                    else
--                        currentState <= STOP_BIT;
--                    end if;
--                                      
--            end case;
--        end if;
--    end process;
--    
--    data_av <= tick when currentState = STOP_BIT and tickCounter = 8 else '0';
--    
--end oversampling;