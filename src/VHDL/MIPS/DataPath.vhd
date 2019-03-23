---------------------------------------------------------------------------
-- Design unit: Data path                                                --
-- Description: MIPS data path supporting ADDU, SUBU, AND, OR, LW, SW,   --
--  ADDIU, ORI, SLT, SLTU, BEQ, J, LUI, BNE, XOR, NOR, ERET instructions --
---------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 
use work.MIPS_pkg.all;

entity DataPath is
    generic (
        PC_START_ADDRESS    : integer := 0  -- PC initial value (first instruction address)
    );
    port (  
        clock               : in  std_logic; 
        reset               : in  std_logic; 
        
        -- Instruction memory interface
        instructionAddress  : out std_logic_vector(31 downto 0);  -- Instruction memory address bus
        instruction         : in  std_logic_vector(31 downto 0);  -- Data bus from instruction memory
        
        -- Data memory interface
        dataAddress         : out std_logic_vector(31 downto 0);  -- Data memory address bus
        data_i              : in  std_logic_vector(31 downto 0);  -- Data bus from data memory
        data_o              : out std_logic_vector(31 downto 0);  -- Data bus to data memory
        
        -- Control path interface
        uins                : in  Microinstruction;               -- Control path microinstruction (control signals)
        IR                  : out std_logic_vector(31 downto 0);  -- Instruction register to control path
        Ov                  : out std_logic;  -- Overflow control
        DBZ                 : out std_logic   -- Divided-by-zero control 
    );
end DataPath;


architecture structural of DataPath is

    ----------------------------------------------
    -- Internal nets to interconnect components --
    ----------------------------------------------
	 
	 
    
    -- Registers signals
    signal PC_q, PC_d, MDR_q, MDR_d, IR_q, A_q, B_q, ALUOut_q, EPC_d,EPC_q, HI_q, LO_q, ISR_AD_q, Cause_d, Cause_q, ESR_AD_q, SR_init: std_logic_vector(31 downto 0);
    signal writePC, HIWrite, LOWrite: std_logic;
    
    -- Register file signals
    signal readData1, readData2, writeData  : std_logic_vector(31 downto 0);
    signal writeRegister                    : std_logic_vector(4 downto 0);
    
    -- ALU signals
    signal result, ALUOperand1, ALUoperand2 : std_logic_vector(31 downto 0);
    signal zero  : std_logic;
    signal Neg   : std_logic;
    
    -- Bit extension
    signal signExtended, zeroExtend: std_logic_vector(31 downto 0);  
    signal saZeroExtend: std_logic_vector(31 downto 0);
    
    -- Branch/jump signals
    signal branchOffset, jumpTarget: std_logic_vector(31 downto 0);
    
    -- Branch comparison signals
    signal isBEQ, isBNE, isBGEZ, isBLEZ, isBLTZ, isBGTZ : std_logic;
    signal GEOpr: std_logic;
    signal LEOpr: std_logic;
    
    ----------------------------------
    -- Instruction register aliases --
    ----------------------------------
    -- Retrieves the rs field from the instruction
    alias rs: std_logic_vector(4 downto 0) is IR_q(25 downto 21);
        
    -- Retrieves the rt field from the instruction
    alias rt: std_logic_vector(4 downto 0) is IR_q(20 downto 16);
        
    -- Retrieves the rd field from the instruction
    alias rd: std_logic_vector(4 downto 0) is IR_q(15 downto 11);
    
    -- Retrieves the sa field from the instruction
    alias sa: std_logic_vector(4 downto 0) is IR_q(10 downto 6); 

begin


    -- PC_q register
    PROGRAM_COUNTER: entity work.Register_n_bits(behavioral)
        generic map (
            LENGTH      => 32,
            INIT_VALUE  => PC_START_ADDRESS
        )
        port map (
            clock       => clock,
            reset       => reset,
            ce          => writePC, 
            d           => PC_d, 
            q           => PC_q
        );
        
    -- EPC_q register
    EXCEPTION_PROGRAM_COUNTER: entity work.Register_n_bits(behavioral)
        generic map (
            LENGTH      => 32,
            INIT_VALUE  => 0
        )
        port map (
            clock       => clock,
            reset       => reset,
            ce          => uins.EPCWrite, 
            d           => EPC_d, 
            q           => EPC_q
        );
        
     -- Cause
    Cause: entity work.Register_n_bits(behavioral)
        generic map (
            LENGTH      => 32,
            INIT_VALUE  => 0
        )
        port map (
            clock       => clock,
            reset       => reset,
            ce          => uins.CauseWrite, 
            d           => Cause_d, 
            q           => Cause_q
        ); 
       
    -- Register at ISR address  
    ISR_AD: entity work.Register_n_bits(behavioral)
        generic map(
            LENGTH      => 32,
            INIT_VALUE  => 0
        )
        port map(
            clock       => clock,
            reset       => reset,
            ce          => uins.ISR_ADWrite, 
            d           => B_q, 
            q           => ISR_AD_q
       );   
    
    -- Register at ESR address
    ESR_AD: entity work.Register_n_bits(behavioral)
        generic map (
            LENGTH      => 32,
            INIT_VALUE  => 0
        )
        port map (
            clock       => clock,
            reset       => reset,
            ce          => uins.ESR_ADWrite, 
            d           => B_q, 
            q           => ESR_AD_q
        ); 
		  
	 MUX_EPC: EPC_d <= PC_q when uins.EPCsel = '0' else -- 
							 B_q; -- MTC0
        
    MUX_CAUSE: Cause_d <= x"00000004" when uins.IntCause = "000" else -- 1 INVALID_INSTRUCTION
                          x"00000020" when uins.IntCause = "001" else -- 8 syscall
                          x"00000030" when uins.IntCause = "010" else -- 12 overflow
                          x"0000003c" when uins.IntCause = "011" else -- 15 divided-by-zero;								  
                          x"00000001" when uins.IntCause = "100" else -- ISR
								  x"00000000" when uins.IntCause = "101" else -- ESR
								  B_q; -- data_in
								  
	 MUX_ServiceRoutine: SR_init <= ESR_AD_q  when Cause_q(0) = '0' else -- Exception Address
	                                ISR_AD_q; -- Interruption Address
        
    -- Write PC logic
    writePC <= (zero and isBEQ) or (not zero and isBNE) or (GEOpr and isBGEZ) or (LEOpr and isBLEZ) or (not LEOpr and isBGTZ) or (not GEOpr and isBLTZ) or uins.PCWrite;
    
    -- Comparison operators
    GEOpr <= zero or not Neg; -- Greater than or equal operator
    LEOpr <= zero or Neg;     -- Less    than or equal operator 
        
    -- PCWriteCond comparison    
    isBEQ  <= '1' when uins.PCWriteCond = C_BEQ  else '0';
    isBNE  <= '1' when uins.PCWriteCond = C_BNE  else '0';
    isBGEZ <= '1' when uins.PCWriteCond = C_BGEZ else '0';
    isBLEZ <= '1' when uins.PCWriteCond = C_BLEZ else '0';
    isBLTZ <= '1' when uins.PCWriteCond = C_BLTZ else '0';
    isBGTZ <= '1' when uins.PCWriteCond = C_BGTZ else '0';
        
     
    -- Instruction memory is addressed by the PC register
    instructionAddress <= PC_q;
     
    -- Multiplexer at PC input
    MUX_PC: PC_d <= result    when uins.PCSource = "000" else -- PC++, JALR, JR
                    ALUOut_q  when uins.PCSource = "001" else -- Branch
                    SR_init   when uins.PCSource = "011" else -- Interruption/Exception Address
                    EPC_q     when uins.PCSource = "100" else -- ERET
                    jumpTarget; -- Jump
						  
		
    
     -- Instruction register
     INSTRUCTION_REGISTER: entity work.Register_n_bits(behavioral)
        generic map (
            LENGTH      => 32
        )
        port map (
            clock       => clock,
            reset       => reset,
            ce          => uins.IRWrite, 
            d           => instruction, -- Data coming from instruction memory
            q           => IR_q
        );
    
    -- Connects the instruction register to control path for instruction decoding
    IR <= IR_q;
    
    
    
    
    -- Stores data coming from the data memory on load instructions
    MEMORY_DATA_REGISTER: entity work.Register_n_bits(behavioral)
        generic map(
            LENGTH      => 32
        )
        port map(
            clock       => clock,
            reset       => reset,
            ce          => '1', 
            d           => data_i, -- Data coming from data memory
            q           => MDR_q
       );
       
       
       

       
    -- Registers File
    REGISTER_FILE: entity work.RegisterFile(behavioral)
        port map (
            clock           => clock,
            reset           => reset,            
            write           => uins.RegWrite,            
            readRegister1   => rs,    
            readRegister2   => rt,
            writeRegister   => writeRegister,
            writeData       => writeData,          
            readData1       => readData1,        
            readData2       => readData2
        );
        
    -- Multiplexers at register file inputs
    -- Selects the instruction field witch contains the register to be written 
    MUX_WRITE_REGISTER: writeRegister <= rt      when uins.regDst = "00" else 
                                         "11111" when uins.regDst = "01" else -- reg[31] JAL
                                         rd; 
    
    -- Selects the data source to be written to register file (MDR or PC or ALUout or HI or LO)
    MUX_WRITE_DATA: writeData <= ALUOut_q when uins.memToReg = "0000" else 
                                 PC_q     when uins.memToReg = "0001" else 
                                 LO_q     when uins.memToReg = "0100" else
                                 HI_q     when uins.memToReg = "0101" else									
                                 MDR_q		when uins.memToReg = "0011" else
											EPC_q    when uins.memToReg = "1000" else
											Cause_q  when uins.memToReg = "1001" else
											ISR_AD_q when uins.memToReg = "1010" else
											ESR_AD_q;  
       
       
       
       
       
    -- Register at register file readData1 output
    A_REGISTER: entity work.Register_n_bits(behavioral)
        generic map(
            LENGTH      => 32
        )
        port map(
            clock       => clock,
            reset       => reset,
            ce          => '1', 
            d           => readData1, 
            q           => A_q
       );
       
    -- Register at register file readData2 output  
    B_REGISTER: entity work.Register_n_bits(behavioral)
        generic map(
            LENGTH      => 32
        )
        port map(
            clock       => clock,
            reset       => reset,
            ce          => '1', 
            d           => readData2, 
            q           => B_q
       );
       
    -- Data to be written on data memory when executing store came from register B
    data_o <= B_q;
    
    -- Sign extends the instruction register low word (15:0)
    SIGN_EXTEND: signExtended <=    x"FFFF" & IR_q(15 downto 0) when IR_q(15) = '1' else -- usa os bits (15 downto 0) da instrucao
                                    x"0000" & IR_q(15 downto 0);
  
    ZERO_EXTEND: zeroExtend <= x"0000" & IR_q(15 downto 0);
    
    -- Converts the branch offset from words to bytes (multiply by 4) in order to add with PC_q
    SHIFT_LEFT_2: branchOffset <= signExtended(29 downto 0) & "00";
    
    -- Generates the jump target address
    JUMP_ADDRESS: jumpTarget <= PC_q(31 downto 28) & IR_q(25 downto 0) & "00";
       
    -- Zero extends the instruction register (10:6) [shift amount]   
    SA_ZERO_EXTEND: saZeroExtend <=  x"000000" & "000" & sa;
       
       
       
    -- Arithmetic/Logic Unit
    ALU: entity work.ALU(behavioral)
        port map (
            operand1    => ALUOperand1,
            operand2    => ALUoperand2,
            result      => result,
            zero        => zero, 
            negative    => Neg,
            overflow    => Ov,
            divided_zero=> DBZ,
            operation   => uins.ALUop
        );   
    
    -- Multiplexers at ALU inputs
    MUX_ALU1: ALUOperand1 <= PC_q         when uins.ALUSrcA = "00" else 
                             saZeroExtend when uins.ALUSrcA = "01" else 
                             A_q;
    
    MUX_ALU2: ALUoperand2 <= B_q when uins.ALUSrcB = "000" else   
                             x"00000004" when uins.ALUSrcB = "001" else  -- PC++
                             signExtended when uins.ALUSrcB = "010" else -- Instruction low word (15:0) sign extended
                             zeroExtend when uins.ALUSrcB = "100" else -- Instruction low word (15:0) zero extended
                             x"00000000" when uins.ALUSrcB = "101" else -- Instructions: BGEZ, BLEZ, BGTZ, BLTZ, JAL, JALR
                             branchOffset; 
                             
    -- Register at the most significant ALU (MUL, DIV) result output
    HI_REGISTER: entity work.Register_n_bits(behavioral)
        generic map(
            LENGTH      => 32,
            INIT_VALUE  => 0
        )
        port map(
            clock       => clock,
            reset       => reset,
            ce          => uins.HIWrite, 
            d           => result, 
            q           => HI_q
       );
       
    -- Register at the less significant ALU (MUL, DIV) result output
    LO_REGISTER: entity work.Register_n_bits(behavioral)
        generic map(
            LENGTH      => 32,
            INIT_VALUE  => 0
        )
        port map(
            clock       => clock,
            reset       => reset,
            ce          => uins.LOWrite, 
            d           => result, 
            q           => LO_q
       );
        
    -- Register at the ALU result output
    ALUOut_REGISTER: entity work.Register_n_bits(behavioral)
        generic map(
            LENGTH      => 32
        )
        port map(
            clock       => clock,
            reset       => reset,
            ce          => '1', 
            d           => result, 
            q           => ALUOut_q
       );
       
    -- The ALUOut register address the data memory
    dataAddress <= ALUOut_q;
           

end structural;