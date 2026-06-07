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
	signal stateSize_r, textSize_r, dataIn_r, I_r, J_r, temp_r: std_logic_vector(DATA_WIDTH-1 downto 0); 
	
	signal state_r, keyStream_r, K, arrayEnd: UNSIGNED(ADDR_WIDTH-1 downto 0); --K sao endereços
	--signal count
begin
	process(clk, rst)
	begin 
	  
	if rst = '1' then 
       	  currentState <= S0;

	elsif rising_edge(clk) then

	   case currentState is 
	 	when S0 =>
	
		  if data_av = '1' then			
			state_r <= UNSIGNED(data);
			currentState <= S1;
		  end if; 			
	
		when S1 =>
		  
		  if data_av = '1' then			
			stateSize_r <= data;
			currentState <= S2; 
		  end if; 
		 
		when S2 =>
		  
		  if data_av = '1' then			
			textSize_r <= data;
			currentState <= S3;
		  end if;  

		when S3 =>
		  
		  if data_av = '1' then			
			keyStream_r <= UNSIGNED(data);
			K <= UNSIGNED(data);
			currentState <= S4;
			arrayEnd <= UNSIGNED(data) + UNSIGNED(textSize_r);			
		  end if;
	  
		when S4 =>
			
		  if K < arrayEnd then
			currentState <= S5; 			
		  else			
			currentState <= S0;
			done <= '1';
		  end if;
			


		when S5 =>
			currentState <= S6;
		when S6 =>
		when S7 =>
		when S8 =>
		when S9 =>
		when S10 =>
		when S11 =>
		when S12 =>

		when others => currentState <= S0;

	end case;
	end if;
	end process;

end behav;
