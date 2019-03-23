-------------------------------------------------------------------------
-- Design unit: Register
-- Description: Parametrizable length clock enabled register.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 


entity synchronization is
    generic (
        DATA_WIDTH  : integer := 1
    );
    port (  
        clock       : in std_logic;
        unsynch     : in std_logic; 
        synch       : out std_logic
    );
end synchronization;


architecture behavioral of synchronization is
    signal d1, d2    : std_logic;  -- REG_1
    signal q1, q2    : std_logic;  -- REG_2
begin

    d1 <= unsynch;
    d2 <= q1;
    
    process(clock)
    begin        
        if rising_edge(clock) then
            q1 <= d1;
            q2 <= d2;
        end if;
    end process;
    
    -- Synchronized output
    synch <= q2;
        
end behavioral;