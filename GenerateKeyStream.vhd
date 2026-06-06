library IEEE;                        
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.GenerateKeyStream_pkg.all;

entity GenerateKeyStream is
	generic (
		ADDR_WIDTH : integer := 8; -- Address Deafult Value
		DATA_WIDTH : integer := 8 -- Address Deafult Value 
	); 
	port (
		clk: in std_logic;
		rst: in std_logic;
		
		-- Data
		data_av: in std_logic;
		data: in std_logic_vector(DATA_WIDTH-1 downto 0);
		done: out std_logic;

		-- Memory Interface
		wr: out std_logic;
		ce: out std_logic;
		address: out std_logic_vector(ADDR_WIDTH-1 downto 0);
		data_out: out std_logic_vector(DATA_WIDTH-1 downto 0);
		data_in: in std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end GenerateKeyStream;

architecture structural of GenerateKeyStream is
	signal cmd: Command := CMD_ZERO;
	signal sts: std_logic := '0';
begin

	CONTROL_PATH: entity work.controlPath
		port map (
			clk => clk,
			rst => rst,
			status => sts,
			cmd => cmd,
			data_av => data_av,
			done => done,
			wr => wr,
			ce => ce
		);

	DATA_PATH: entity work.dataPath
		port map (
			clk => clk,
			rst => rst,
			status => sts,
			cmd => cmd,
			data => data,
			data_in => data_in,
			data_out => data_out,
			address => address
		);
end structural;

--architecture behavioral of GenerateKeyStream is
	-- Parte 2 do Trabalho
--begin
--end behavioral;