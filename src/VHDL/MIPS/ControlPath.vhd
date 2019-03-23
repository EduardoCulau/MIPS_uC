------------------------------------------------------------------------------
-- Design unit: Control path (FSM implmentation)                            --
-- Description: MIPS control path supporting ADDU, SUBU, AND, OR, LW, SW,   -- 
--  ADDIU, ORI, SLT, SLTU, BEQ, J, LUI, BNE, XOR, NOR instructions          --
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.MIPS_pkg.all;

entity ControlPath is
    port (  
        clock           : in std_logic;
        reset           : in std_logic;
        instruction     : in std_logic_vector(31 downto 0); -- Instruction stored on instruction register (data path)
        uins            : out microinstruction; -- Control signals to data path and memory
        intr            : in std_logic;
		Ov				: in std_logic;
		DBZ             : in std_logic
    );
end ControlPath;
                   

architecture behavioral of ControlPath is

    -- Alias to identify the instructions based on the 'opcode' and 'funct' fields
    alias  opcode: std_logic_vector(5 downto 0) is instruction(31 downto 26);
    alias  funct: std_logic_vector(5 downto 0) is instruction(5 downto 0);
    
    -- Retrieves the rs, rt field from the instruction
    alias rs: std_logic_vector(4 downto 0) is instruction(25 downto 21);
    alias rt: std_logic_vector(4 downto 0) is instruction(20 downto 16);
    alias rd: std_logic_vector(4 downto 0) is instruction(15 downto 11);
	 
    -- FSM states
    type State is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18);
    signal currentState, nextState: State;
    
    -- Interruption flag
    signal fintr : std_logic;
    
    signal decodedInstruction: Instruction_type;
    
begin
       
    -- Instruction decode
    decodedInstruction <=   ADDU    when opcode = "000000" and funct = "100001" else
                            SUBU    when opcode = "000000" and funct = "100011" else
                            AAND    when opcode = "000000" and funct = "100100" else
                            OOR     when opcode = "000000" and funct = "100101" else
                            SLT     when opcode = "000000" and funct = "101010" else
                            SLTU    when opcode = "000000" and funct = "101011" else
                            SW      when opcode = "101011" else
                            LW      when opcode = "100011" else
                            ADDIU   when opcode = "001001" else
                            ORI     when opcode = "001101" else
                            BEQ     when opcode = "000100" else
                            J       when opcode = "000010" else
                            LUI     when opcode = "001111" and rs = "00000" else
                            BNE     when opcode = "000101" else
                            XXOR    when opcode = "000000" and funct = "100110" else
                            NNOR    when opcode = "000000" and funct = "100111" else
                            ANDI    when opcode = "001100" else
                            XORI    when opcode = "001110" else
                            SSLL    when opcode = "000000" and funct = "000000" else
                            SSRL    when opcode = "000000" and funct = "000010" else
                            BGEZ    when opcode = "000001" and rt = "00001" else
                            BLEZ    when opcode = "000110" and rt = "00000" else 
                            BGTZ    when opcode = "000111" and rt = "00000" else
                            BLTZ    when opcode = "000001" and rt = "00000" else
                            SLTI    when opcode = "001010" else
                            SLTIU   when opcode = "001011" else
                            JAL     when opcode = "000011" else
                            JALR    when opcode = "000000" and funct = "001001" else
                            JR      when opcode = "000000" and funct = "001000" else
                            ERET    when opcode = "010000" and funct = "011000" else
                            ADDI    when opcode = "001000" else
                            MULTU   when opcode = "000000" and funct = "011001" else
                            DIVU    when opcode = "000000" and funct = "011011" else
                            MFHI    when opcode = "000000" and funct = "010000" else
                            MFLO    when opcode = "000000" and funct = "010010" else
                            MTC0    when opcode = "010000" and rs = "00100" else
                            MFC0    when opcode = "010000" and rs = "00000" else
                            ADD     when opcode = "000000" and funct = "100000" else
                            SUB     when opcode = "000000" and funct = "100010" else
                            SYSCALL when opcode = "000000" and funct = "001100" else
                            INVALID_INSTRUCTION ;    -- Invalid or not implemented instruction         
      
    uins.Instruction <= decodedInstruction;
    
    
    
    
    
    --------------------
    -- State register --
    --------------------
    STATE_REGISTER: process (clock, reset)
    begin
        if(reset = '1') then
            currentState <= S0;
        elsif rising_edge(clock) then
            currentState <= nextState;
        end if;
    end process;

    
    

    
    ------------------------------------------------------------------------
    -- Next State Logic                                                   --
    --      The next state depends on currentState and decodedInstruction --
    ------------------------------------------------------------------------
    NEXT_STATE_LOGIC: process(currentState, decodedInstruction, intr, fintr, DBZ, Ov)
    begin
        case currentState is
            
            -- Instruction fetch and PC++
            when S0 =>
                if intr = '0' or fintr = '1' then
                    nextState <= S1;
                elsif intr = '1' and fintr = '0' then -- gerou interrupcao e nao esta no estado de interrupcao
                    nextState <= S15; 
                end if;
            
            -- Instruction decode, register file reading and branch target computation
            when S1 => 
                case decodedInstruction is  -- NextState depends on the decodedInstruction
                    when LW | SW =>
                        nextState <= S2;
                    
                    -- R-Type
                    when ADDU | AAND | OOR | SUBU | SLT | SLTU | XXOR | NNOR | MULTU | DIVU | SUB | ADD => 
                        nextState <= S6;
                        
                    when MFHI | MFLO =>
                        nextState <= S7;
                        
                    when SSRL | SSLL =>
                        nextState <= S12;
                    
                    -- I-Type (logic/arithmetic)
                    when ADDIU | LUI | SLTI | SLTIU | ADDI => 
                        nextState <= S10;
                    
                    when ORI | ANDI | XORI =>
                        nextState <= S11;
                    
                    when BEQ | BNE =>
                        nextState <= S8;
                        
                    when BGEZ | BLEZ | BGTZ | BLTZ =>
                        nextState <= S13;
                    
                    when J | JR =>
                        nextState <= S9;
                        
                    when JAL | JALR =>
                        nextState <= S14;
                    -- Coprocesor    
                    when ERET =>
                        nextState <= S16;
                        
                    when MTC0 | MFC0 =>
                        nextState <= S18;
                        
                    when others =>  -- SYSCALL | INVALID_INSTRUCTION
                        nextState <= S15;
                end case;
            
            -- Load/store: memory address computation
            when S2 =>
                if decodedInstruction = LW then
                    nextState <= S3;
                else
                    nextState <= S5;
                end if;
            
            -- Load: Memory read
            when S3 =>
                nextState <= S4;
            
            -- Logic/Arithmetic instructions execution            
            when S6 =>
                if decodedInstruction = MULTU or (decodedInstruction = DIVU and DBZ = '0') then
                    nextState <= S17;
                elsif ((decodedInstruction = DIVU and DBZ = '1') or (decodedInstruction = ADD and Ov = '1') or (decodedInstruction = SUB and Ov = '1')) and fintr = '0' then
                    nextState <= S15;
                else
                    nextState <= S7;
                end if;
					 
			   when S10 =>
					 if decodedInstruction = ADDI and Ov = '1' and fintr = '0' then 
                    nextState <= S15;
                else
						  nextState <= S7;
					 end if;
                
            when S11 | S12 =>
					 nextState <= S7;
            
            when others =>
                nextState <= S0;
        end case;
    end process;
    
    -- assert currentState /= INVALID_INSTRUCTION
    -- report "******************* INVALID_INSTRUCTION *************"
    -- severity failure;  

    --------------------------------
    -- Flag Interruption Register --
    -------------------------------
    FINTR_REGISTER: process (clock, reset)
    begin
        if reset = '1' then
            fintr <= '0';
        elsif rising_edge(clock) then
            if currentState = S15 then
                fintr <= '1';
            elsif currentState = S16 then
                fintr <= '0';
            end if;
        end if;
    end process;
    
    
    
    ---------------------------------------------
    -- Control signals generation to data path --
    ---------------------------------------------
    
    -- Register file multiplexers
    uins.MemToReg <=    "0101" when decodedInstruction = MFHI else -- RegisterFile.WriteData <- HI
                        "0100" when decodedInstruction = MFLO else -- RegisterFile.WriteData <- LO
                        "0011" when decodedInstruction = LW else -- RegisterFile.WriteData <- MDR
                        "0001" when decodedInstruction = JAL or decodedInstruction = JALR else -- RegisterFile.WriteData <- PC
								"1000" when decodedInstruction = MFC0 and rd = "01110" else -- RegisterFile.WriteData <- EPC
								"1001" when decodedInstruction = MFC0 and rd = "01101" else -- RegisterFile.WriteData <- Cause
								"1010" when decodedInstruction = MFC0 and rd = "11111" else -- RegisterFile.WriteData <- ISR_AD
								"1011" when decodedInstruction = MFC0 and rd = "11110" else -- RegisterFile.WriteData <- ESR_AD
                        "0000"; -- RegisterFile.WriteData <- ALUOut
                        
    uins.RegDst <=  "00" when decodedInstruction = ADDIU or decodedInstruction = LUI   or 
                              decodedInstruction = ORI   or decodedInstruction = LW    or 
                              decodedInstruction = ANDI  or decodedInstruction = XORI  or 
                              decodedInstruction = SLTI  or decodedInstruction = SLTIU or
                              decodedinstruction = ADDI  or decodedInstruction = MFC0 else  -- RegisterFile.WriteRegister <- rt
                    "01" when decodedInstruction = JAL else -- RegisterFile.WriteRegister <- 31
                    "11"; -- RegisterFile.WriteRegister <- rd
    
    -- ALU multiplexers
    uins.ALUSrcB <= "001" when currentState = S0 else -- PC++ 
                    "011" when currentState = S1 else -- Branch address computation
                    "010" when currentState = S2 or currentState = S10 else  -- Memory address computation or I-Type logic/arithmetic with sign extension               
                    "100" when currentState = S11 else -- I-Type logic/arithmetic with zero extension
                    "101" when currentState = S9 or currentState = S13 or currentState = S14 else -- BGEZ, BLEZ, BGTZ, BLTZ, JAL, JALR, JR
                    "000"; -- Register B (R-Type, BEQ, BNE)
    
    uins.ALUSrcA <= "00" when currentState = S0 or currentState = S1 else -- PC++ and branch address computation
                    "01" when currentState = S12 else -- SLL, SRL
                    "11";
                    
    -- PC multiplexer
    uins.PCSource <= "001" when currentState = S8 or currentState = S13 else -- ALUOut (BEQ, BNE, BGEZ, BLEZ, BGTZ, BLTZ)
                     "010" when (currentState = S9 and decodedInstruction = J) or (currentState = S14 and decodedInstruction = JAL) else -- Jump address (J), JAL                     
                     "100" when currentState = S16 else -- ERET
							"011" when currentState = S15 else -- Exception/Interruption
                     "000"; -- ALU result output (PC++), JALR, JR
   
   
   
    -- ALU control    
    uins.ALUOp <= ALU_ADD   when currentState = S0 or currentState = S1 or decodedInstruction = ADDU or decodedInstruction = ADDIU or decodedInstruction = LW or decodedInstruction = SW or decodedInstruction = ADDI or decodedInstruction = ADD else
                  ALU_AND   when decodedInstruction = AAND or decodedInstruction = ANDI else -- AND, ANDI
                  ALU_OR    when decodedInstruction = OOR or decodedInstruction = ORI else -- OR, ORI
                  ALU_SLT   when decodedInstruction = SLT or decodedInstruction = SLTI else -- SLT, SLTI
                  ALU_SLTU  when decodedInstruction = SLTU or decodedInstruction = SLTIU else -- SLTU, SLTIU
                  ALU_LUI   when decodedInstruction = LUI else -- LUI
                  ALU_XOR   when decodedInstruction = XXOR or decodedInstruction = XORI else -- XOR, XORI
                  ALU_NOR   when decodedInstruction = NNOR else -- NOR
                  ALU_SLL   when decodedInstruction = SSLL else -- SLL
                  ALU_SRL   when decodedInstruction = SSRL else -- SRL
                  ALU_MUL_HI   when decodedInstruction = MULTU and currentState = S17 else -- MULTU (HI)
                  ALU_MUL_LO   when decodedInstruction = MULTU and currentState = S6  else -- MULTU (LO)
                  ALU_DIV_HI   when decodedInstruction = DIVU  and currentState = S17 else -- DIVU  (HI)
                  ALU_DIV_LO   when decodedInstruction = DIVU  and currentState = S6  else -- DIVU  (LO)
                  ALU_SUB; -- SUBU, BEQ, BNE, BGEZ, BLEZ, BGTZ, BLTZ, SUB
    
    
    
    -- Registers write control
    uins.PCWriteCond <= C_BEQ  when currentState = S8  and decodedInstruction = BEQ  else -- BEQ
                        C_BNE  when currentState = S8  and decodedInstruction = BNE  else -- BNE
                        C_BGEZ when currentState = S13 and decodedInstruction = BGEZ else -- BGEZ
                        C_BLEZ when currentState = S13 and decodedInstruction = BLEZ else -- BLEZ
                        C_BGTZ when currentState = S13 and decodedInstruction = BGTZ else -- BGTZ
                        C_BLTZ when currentState = S13 and decodedInstruction = BLTZ else -- BLTZ
                        C_NONE; --Not a branch
                        
    uins.IntCause    <= "000" when currentState = S15 and decodedInstruction = INVALID_INSTRUCTION else
                        "001" when currentState = S15 and decodedInstruction = SYSCALL else
                        "010" when currentState = S15 and (decodedInstruction = ADD or decodedInstruction = SUB or decodedInstruction = ADDI) else
                        "011" when currentState = S15 and decodedInstruction = DIVU else
								"100" when currentState = S0 and intr = '1' and fintr = '0' else
								"101";
                        
    uins.PCWrite  <= '1'    when currentState = S0 or currentState = S9 or currentState = S14 or currentState = S15 or currentState = S16 else '0'; -- PC++, J, JR, JAL, JALR
    uins.IRWrite  <= '1'    when currentState = S0 else '0'; -- Instruction fetch
    uins.RegWrite <= '1'    when currentState = S4 or currentState = S7 or currentState = S14 or (currentState = S18 and decodedInstruction = MFC0) else '0'; -- Load, Logic/Arithmetic, JAL, JALR, MFC0
    uins.LOWrite  <= '1'    when currentState = S6 and (decodedInstruction = MULTU or decodedInstruction = DIVU) else '0'; -- MULTU, DIVU
    uins.HIWrite  <= '1'    when currentState = S17 else '0'; -- MULTU, DIVU
    
    -- Coprocessor 0
    uins.CauseWrite  <= '1'  when (currentState = S0 and intr = '1' and fintr = '0') or currentState = S15 or (currentState = S18 and ((decodedInstruction = MTC0 and rd = "01101") or (decodedInstruction = MFC0 and rt = "01101"))) else '0'; -- Exception or MCT0(C0[13])
    uins.ISR_ADWrite <= '1'  when currentState = S18 and ((decodedInstruction = MTC0 and rd = "11111") or (decodedInstruction = MFC0 and rt = "11111"))  else '0'; -- MTC0 (C0[31])
    uins.ESR_ADWrite <= '1'  when currentState = S18 and ((decodedInstruction = MTC0 and rd = "11110") or (decodedInstruction = MFC0 and rt = "11110")) else '0'; -- MTC0 (C0[30])
    uins.EPCWrite    <= '1'  when (((currentState = S0 and intr = '1') or 
                                  (currentState = S1 and (decodedInstruction = INVALID_INSTRUCTION or decodedInstruction = SYSCALL)) or
                                  (currentState = S6 and ((DBZ = '1' and decodedInstruction = DIVU) or (Ov = '1' and decodedInstruction = ADD) or (Ov = '1' and decodedInstruction = SUB))) or
                                  (currentState = S10 and Ov = '1' and decodedInstruction = ADDI)) and fintr = '0') or -- Exception 
                                  (currentState = S18 and decodedInstruction = MTC0 and rd = "01110") else -- MCT0(C0[14])
                        '0'; -- Interruption. Pega PC e não PC++
	 uins.EPCsel      <= '1' when (currentState = S18 and decodedInstruction = MTC0 and rd = "01110") else '0';
    
    
    
    -- Data memory write control
    uins.MemWrite <= '1' when currentState = S5 else '0'; -- Store
    uins.ce_data  <= '1' when currentState = S3 or currentState = S5 else '0';   -- Load/Store
    
    -- Instruction memory read control
    uins.ce_ins <= '1' when currentState = S0 else '0';  -- Instruction fetch
    
end behavioral;