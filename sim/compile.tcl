# TCL ModelSim compile script
# Pay attention on the compilation order!!!



# Sets the compiler
#set compiler vlog
set compiler vcom


# Creats the work library if it does not exist
if { ![file exist work] } {
    vlib work
}




#########################
### Source files list ###
#########################

# Source files listed in hierarchical order: botton -> top
set sourceFiles {
    ../src/VHDL/MIPS/MIPS_pkg.vhd
    ../src/VHDL/MIPS/Register_n_bits.vhd
    ../src/VHDL/MIPS/RegisterFile.vhd
    ../src/VHDL/MIPS/ALU.vhd
    ../src/VHDL/MIPS/DataPath.vhd 
    ../src/VHDL/MIPS/ControlPath.vhd
    ../src/VHDL/MIPS/MIPS_MultiCycle.vhd
    ../src/VHDL/Memory/Util_pkg.vhd
    ../src/VHDL/Memory/Memory.vhd
    ../src/VHDL/DCM/ClockManager.vhd
    ../src/VHDL/synchronization.vhd
    ../src/VHDL/BidirectionalPort.vhd
    ../src/VHDL/MIPS_uC.vhd
    ../src/VHDL/CryptoMessage/CryptoMessage.vhd
    
    MIPS_uC_tb.vhd
}



set top MIPS_uC_tb.vhd



###################
### Compilation ###
###################

if { [llength $sourceFiles] > 0 } {
    
    foreach file $sourceFiles {
        if [ catch {$compiler $file} ] {
            puts "\n*** ERROR compiling file $file :( ***" 
            return;
        }
    }
}




################################
### Lists the compiled files ###
################################

if { [llength $sourceFiles] > 0 } {
    
    puts "\n*** Compiled files:"  
    
    foreach file $sourceFiles {
        puts \t$file
    }
}


puts "\n*** Compilation OK ;) ***"

#vsim $top
#set StdArithNoWarnings 1

