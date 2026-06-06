library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 

package GenerateKeyStream_pkg is
	type Command is record
		wrState, wrStateSize, wrTextSize, wrKeyStream, WrDatain, wrTemp: std_logic;
		wrJ, wrI, wrK: std_logic;
		mOut, mAdrk, mS0, mComp: std_logic;
		mS2, ms1: std_logic_vector(1 downto 0); -- talvez seja melhor separar em std_logic
		rstart: std_logic; -- reset de inicio d processamento
	end record;
	
	-- Adicionando constantes para nao inicializar em UUUUUUU --
	constant CMD_ZERO : Command := (
        wrState => '0', wrStateSize => '0', wrTextSize => '0', wrKeyStream => '0', WrDatain => '0', wrTemp => '0',
        wrJ => '0', wrI => '0', wrK => '0',
        mOut => '0', mAdrk => '0', mS0 => '0', mComp => '0',
        mS2 => "00", ms1 => "00",
        rstart => '0'
    );
end GenerateKeyStream_pkg;
			