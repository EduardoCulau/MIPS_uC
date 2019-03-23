-------------------------------------------------------------------------
-- Design unit: MIPS package
-- Description:
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package MIPS_pkg is  
        
    -- Instruction_type defines the instructions decodable by the control unit
    type Instruction_type is (ADDU, SUBU, AAND, OOR, SW, LW, ADDIU, ORI, SLT, SLTU, BEQ, J, 
                              LUI, INVALID_INSTRUCTION, BNE, XXOR, NNOR, ANDI, XORI, SLTI, 
                              SLTIU, SSLL, SSRL, BGEZ, BLEZ, BGTZ, BLTZ, JAL, JALR, JR, 
                              ERET, ADDI, MULTU, DIVU, MFHI, MFLO, MTC0, MFC0, ADD, SUB, 
                              SYSCALL);
    
    -- ALU_Operation defines the ALU operations
    type ALU_Operation is (ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_SLT, ALU_SLTU, ALU_LUI, ALU_XOR, ALU_NOR, ALU_SLL, ALU_SRL, ALU_MUL_HI, ALU_MUL_LO, ALU_DIV_HI, ALU_DIV_LO);
    
    -- PCWriteCond_type defines the PCWriteCond conditions
    type PCWriteCond_type is (C_BEQ, C_BNE, C_BGEZ, C_BLEZ, C_BLTZ, C_BGTZ, C_NONE); 
 
    
    type Microinstruction is record
        -- Control signals to data path
        PCWriteCond : PCWriteCond_type;
        PCWrite     : std_logic;
        IRWrite     : std_logic;
        PCSource    : std_logic_vector(2 downto 0);
        RegWrite    : std_logic;        
        ALUop       : ALU_Operation;
        ALUSrcB     : std_logic_vector(2 downto 0);        
        ALUSrcA     : std_logic_vector(1 downto 0);
        RegDst      : std_logic_vector(1 downto 0);        
        MemToReg    : std_logic_vector(3 downto 0);
        Instruction : Instruction_type; -- Decoded instruction  
        HIWrite     : std_logic;
        LOwrite     : std_logic;
        CauseWrite  : std_logic;
        IntCause    : std_logic_vector(2 downto 0);
        EPCWrite    : std_logic;
        ISR_ADWrite : std_logic;
        ESR_ADWrite : std_logic;
        EPCsel      : std_logic;
        
        -- Memory control
        ce_ins      : std_logic;        -- Instruction memory chip enable
        ce_data     : std_logic;        -- Data memory chip enable
        MemWrite    : std_logic;        -- Data memory write access      
    end record;
                
end MIPS_pkg;


