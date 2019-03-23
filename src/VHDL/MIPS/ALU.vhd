-------------------------------------------------------------------------
-- Design unit: ALU
-- Description: Logic and Arithmetic Unit
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MIPS_pkg.all;

entity ALU is
    port( 
        operand1    : in std_logic_vector(31 downto 0);
        operand2    : in std_logic_vector(31 downto 0);
        result      : out std_logic_vector(31 downto 0);
        zero        : out std_logic;
        negative    : out std_logic;     
        overflow    : out std_logic;
        divided_zero : out std_logic;
        operation   : in ALU_Operation
    );
end ALU;

architecture behavioral of ALU is
    signal temp: SIGNED(31 downto 0);
    signal op1, op2: SIGNED(31 downto 0);
    signal u_op1, u_op2: UNSIGNED(31 downto 0);
    signal temp_mul: SIGNED(63 downto 0);
begin

    op1 <= SIGNED(operand1);
    op2 <= SIGNED(operand2);
    
    u_op1 <= UNSIGNED(operand1);
    u_op2 <= UNSIGNED(operand2);
    
    temp_mul <= to_SIGNED(to_integer(u_op1)*to_integer(u_op2), 64); -- multiplier 64b
    
    result <= STD_LOGIC_VECTOR(to_unsigned(to_integer(u_op1)/to_integer(u_op2), 32))       when operation = ALU_DIV_LO and not (u_op2 = x"00000000") else -- Instruction: DIVU quotient
				  STD_LOGIC_VECTOR(to_unsigned(to_integer(u_op1) mod to_integer(u_op2), 32))   when operation = ALU_DIV_HI and not (u_op2 = x"00000000") else -- Instruction: DIVU remainder
	           STD_LOGIC_VECTOR(temp); 
        
    temp <= op1 - op2       when operation = ALU_SUB else -- Instructions: SUBU, BEQ
            op1 and op2     when operation = ALU_AND else -- Instructions: AND
            op1 or op2      when operation = ALU_OR else -- Instructions: OR, ORI
            x"00000001"     when (operation = ALU_SLT and op1 < op2) or (operation = ALU_SLTU and u_op1 < u_op2) else -- Instructions: SLT, SLTU (true)
            x"00000000"     when (operation = ALU_SLT and not(op1 < op2)) or (operation = ALU_SLTU and not(u_op1) < u_op2) else -- Instructions: SLT, SLTU (false)
            op2(15 downto 0) & x"0000" when operation = ALU_LUI else -- Instructions: LUI
            op1 xor op2     when operation = ALU_XOR else -- Instruction: XOR
            op1 nor op2     when operation = ALU_NOR else -- Instruction: NOR
            SHIFT_LEFT(op2,  TO_INTEGER(op1)) when operation = ALU_SLL else -- Instruction: SLL
            SHIFT_RIGHT(op2, TO_INTEGER(op1)) when operation = ALU_SRL else -- Instruction: SRL
            temp_mul(31 downto 0)     when operation = ALU_MUL_LO else -- Instruction: MUL low part
            temp_mul(63 downto 32)    when operation = ALU_MUL_HI else -- Instruction: MUL high part
            op1 + op2;  -- Instructions: ADDU, ADDIU, LW, SW and PC++
            

    -- Generates the zero flag
    zero <= '1' when temp = 0 else '0';
    
    -- Generates the N flag
    negative <= temp(31); 
    
    -- Generates the Ov flag
    overflow <= ((op1(31) xor op2(31)) and not (temp(31) xor op2(31))) when operation = ALU_SUB else 
	             (temp(31) xor op1(31)) and (temp(31) xor op2(31));
    
    -- Generates the DBZ flag
    divided_zero <= '1' when (operation = ALU_DIV_LO or operation = ALU_DIV_HI) and op2 = x"00000000" else '0'; 
    
end behavioral;