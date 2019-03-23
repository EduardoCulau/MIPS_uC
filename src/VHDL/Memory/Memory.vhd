-------------------------------------------------------------------------
-- Design unit: Memory
-- Description: 32 bits word memory
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all; 
use std.textio.all;
use work.Util_pkg.all;


entity Memory is
    generic (
        SIZE            : integer := 100;    -- Memory depth
        imageFileName   : string := "UNUSED";        -- Memory content to be loaded
        OFFSET          : UNSIGNED(31 downto 0) := x"00000000"
    );
    port (  
        clock           : in std_logic;
        ce              : in std_logic; -- Enable the memory
        wr              : in std_logic;  -- Write enable
        address         : in std_logic_vector (29 downto 0); 
        data_i          : in std_logic_vector (31 downto 0);
        data_o          : out std_logic_vector (31 downto 0)
    );
end Memory;

architecture BlockRAM of Memory is
    
    type Memory is array (0 to SIZE-1) of std_logic_vector(31 downto 0);
    
    impure function MemoryLoad (imageFileName : in string) return Memory is
        FILE imageFile : text open READ_MODE is imageFileName;
        variable fileLine : line;
        variable memoryArray : Memory;
        variable data_str : string(1 to 8);
    begin   
        for i in Memory'range loop
            readline (imageFile, fileLine);
            read (fileLine, data_str);
            memoryArray(i) := StringToStdLogicVector(data_str);
        end loop;
        return memoryArray;
    end function;
    
    signal memoryArray : Memory := MemoryLoad(imageFileName);
            
    signal arrayAddress : integer;
    
    begin
       
    arrayAddress <= TO_INTEGER(UNSIGNED(address) - OFFSET(31 downto 2));
       
    -- Process to control the memory access
    process(clock)
    begin
        if rising_edge(clock) then    -- Memory writing        
            if ce = '1' then
                if wr = '1' then
                    memoryArray(arrayAddress) <= data_i; 
                    data_o <= data_i; -- "Write first" mode or "transparent" mode
                else
                    -- Synchronous memory read (Block RAM)
                    data_o <= memoryArray(arrayAddress);
                end if;
            end if;
        end if;   
    end process;
    
end BlockRAM;