#!/bin/sh

clear

echo 'Digite o que deseja fazer'
echo '<1> -> Dump HexText'
echo '<2> -> Dump Binary'
echo '<3> -> Dump BinaryText'

read buffer

echo 'Digite qual a aplicação'
echo '<1> -> main.asm'
echo '<2> -> welcome.asm'
#echo '<3> -> contador.asm'

read application

if [ "$buffer" -eq 1 ]
then
    echo 'HexText'
    if [ "$application" -eq 1 ]
    then
        echo 'main.asm'
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .text HexText ../VHDL/Memory/Application_code.txt _root.asm main.asm
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .data HexText ../VHDL/Memory/Application_data.txt _root.asm main.asm
    elif [ "$application" -eq 2 ]
    then
        echo 'welcome.asm'
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .text HexText ../VHDL/Memory/Application_code.txt _root.asm welcome.asm
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .data HexText ../VHDL/Memory/Application_data.txt _root.asm welcome.asm
    fi
    echo 'Finish'
elif [ "$buffer" -eq 2 ]
then
    echo 'Binary'
    if [ "$application" -eq 1 ]
    then
        echo 'main.asm'
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .text Binary ~/bin/Application_code.bin _root.asm main.asm
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .data Binary ~/bin/Application_data.bin _root.asm main.asm
    elif [ "$application" -eq 2 ]
    then
        echo 'welcome.asm'
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .text Binary ~/bin/Application_code.bin _root.asm welcome.asm
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .data Binary ~/bin/Application_data.bin _root.asm welcome.asm
    fi
    echo 'Finish'
elif [ "$buffer" -eq 3 ]
then
    echo 'BinaryText'
    if [ "$application" -eq 1 ]
    then
        echo 'main.asm'
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .text BinaryText ../../sim/bin_code.txt _root.asm main.asm
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .data BinaryText ../../sim/bin_data.txt _root.asm main.asm
    elif [ "$application" -eq 2 ]
    then
        echo 'welcome.asm'
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .text BinaryText ../../sim/bin_code.txt _root.asm welcome.asm
        java -jar Mars4_5.jar a mc CompactTextAtZero dump .data BinaryText ../../sim/bin_data.txt _root.asm welcome.asm
    fi
    echo 'Finish'
fi
