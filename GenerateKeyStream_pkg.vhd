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
end GenerateKeyStream_pkg;
			