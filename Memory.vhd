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
        DATA_WIDTH      : integer := 16;
        ADDR_WIDTH      : integer := 16;        
        imageFileName   : string := "UNUSED"  -- Memory content to be loaded
    );
    port (  
        clk             : in std_logic;
        ce              : in std_logic; -- Enable the memory
        wr              : in std_logic;  -- Write enable
        address         : in std_logic_vector (ADDR_WIDTH - 1 downto 0); 
        data_in         : in std_logic_vector (DATA_WIDTH - 1 downto 0);
        data_out        : out std_logic_vector (DATA_WIDTH - 1 downto 0)
    );
end Memory;

architecture BlockRAM of Memory is
    
    type Memory is array (0 to 2 ** ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    impure function MemoryLoad (imageFileName : in string) return Memory is
        FILE imageFile          : text open READ_MODE is imageFileName;
        variable fileLine       : line;
        variable memoryArray    : Memory;
        variable data_str       : string(1 to DATA_WIDTH / 4);
        variable i : natural    := 0;
    begin   
    
        -- Main loop to read the image file
        while NOT (endfile(imageFile)) loop
            readline (imageFile, fileLine);
            read (fileLine, data_str);
            memoryArray(i) := StringToStdLogicVector(data_str);
            i := i + 1;
        end loop;
        
        return memoryArray;
        
    end function;
    
        signal memoryArray : Memory := MemoryLoad(imageFileName);
            
        signal arrayAddress : natural;
    
    begin
       
    arrayAddress <= TO_INTEGER(UNSIGNED(address));
       
    -- Process to control the memory access
    process(clk)
    begin
        if rising_edge(clk) then    -- Memory writing        
            if ce = '1' then
                if wr = '1' then
                    memoryArray(arrayAddress) <= data_in; 
                -- Uncomment the following lines for a synchronous memory read
                --    data_out <= data_in; -- "Write first" mode or "transparent" mode
                --else
                --    -- Synchronous memory read (Block RAM)
                --    data_out <= memoryArray(arrayAddress);
                end if;
            end if;
        end if;   
    end process;
    
    -- Asynchronous memory read 
    -- Comment the following line for a synchronous memory read
    data_out <= memoryArray(arrayAddress);
    
end BlockRAM;
