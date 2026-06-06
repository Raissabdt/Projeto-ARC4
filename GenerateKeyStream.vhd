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

architecture behav of GenerateKeyStream is --ESBOÇO, nao testado
	
	type State is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12);
	signal currentState: State;

	-- sinais para registradores 
	signal state, stateSize, textSize, keyStream, dataIn, I, J, K, temp: std_logic_vector(DATAWIDTH-1 downto 0); 
	signal count, arrayEnd: std_logic_vector(DATA_WIDTH-1 downto 0);

begin
	process(clk, rst)
	begin 
	  
	if rst = '1' then 
       	  currentState <= S0;

	elsif rising_edge(clk) then

	   case currentState is 
	 	when S0 =>
	
		  if data_av = '1' then	
		
			state <= data;
			currentState <= S1;
		  end if; 			
	
		when S1 =>
		  
		  if data_av = '1' then	
		
			stateSize <= data;
			currentState <= S2; 
		  end if; 
		 
		when S2 =>
		  
		  if data_av = '1' then	
		
			textSize <= data;
			currentState <= S3;
		  end if;  

		when S3 =>
		  
		  if data_av = '1' then	
		
			keyStream <= data;
			K <= data;
			currentState <= S4;
			arrayEnd <= keyStream + textSize;
			
		  end if;
	  
		when S4 =>
			
		  if K < arrayEnd then
			currentState <= S5;
			


		when S5 =>
		when S6 =>
		when S7 =>
		when S8 =>
		when S9 =>
		when S10 =>
		when S11 =>
		when S12 =>



end behav;
