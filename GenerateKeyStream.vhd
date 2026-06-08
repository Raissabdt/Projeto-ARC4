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

architecture behav of GenerateKeyStream is 
	
	type State is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10);
	signal currentState: State;

	-- sinais para registradores 
	signal stateSize_r, textSize_r, dataIn_r, I_r, J_r, temp_r: UNSIGNED(DATA_WIDTH-1 downto 0); 
	
	signal state_r, keyStream_r, K, arrayEnd: UNSIGNED(ADDR_WIDTH-1 downto 0); --K sao endereços
	--signal count
begin
	process(clk, rst)
	begin 

	ce <= '1'; 
        wr <= '0'; 
        done <= '0';
	  
	if rst = '1' then 
       	  currentState <= S0;

	  I_r <= (others => '0');
	  J_r <= (others => '0');
	  temp_r <= (others => '0');
	  dataIn_r <= (others => '0');

	  state_r <= (others => '0');
	  stateSize_r <= (others => '0');
	  textSize_r <= (others => '0');
	  keyStream_r <= (others => '0');

	  K <= (others => '0');
	  arrayEnd <= (others => '0');

	elsif rising_edge(clk) then

	   case currentState is 
	 	when S0 =>
		  ce <= '0';
		  if data_av = '1' then			
			state_r <= UNSIGNED(data);
			currentState <= S1;
		  end if; 			
	
		when S1 =>
		  ce <= '0';
		  if data_av = '1' then			
			stateSize_r <= UNSIGNED(data);
			currentState <= S2; 
		  end if; 
		 
		when S2 =>
		  ce <= '0';
		  if data_av = '1' then			
			textSize_r <= UNSIGNED(data);
			currentState <= S3;
		  end if;  

		when S3 =>
		  ce <= '0';
		  if data_av = '1' then			
			keyStream_r <= UNSIGNED(data);
			K <= UNSIGNED(data);
			arrayEnd <= UNSIGNED(data) + UNSIGNED(textSize_r);			
			currentState <= S4;		
		  end if;
	  
		when S4 =>
		  ce <= '0';
		  if K < arrayEnd then
			currentState <= S5; 			
		  else			
			currentState <= S0;
			done <= '1';
		  end if;
			
		when S5 => -- S5 e S6 do diagrama original mesclados  
		  currentState <= S6;
		  I_r <= (I_r + 1) rem stateSize_r;
		  dataIn_r <= UNSIGNED(data_in); 	

		when S6 => 
		  currentState <= S7; 
		  J_r <= (J_r + dataIn_r) rem stateSize_r;
		  
		when S7 =>
		  currentState <= S8;
		  temp_r <= UNSIGNED(data_in);		  
		  wr <= '1';

		when S8 =>
		  currentState <= S9;
		  wr <= '1';
		  
		when S9 =>
		  currentState <= S10;
		  temp_r <= UNSIGNED(data_in);		  	  

		when S10 =>
		  currentState <= S4;
		  wr <= '1';
		  K  <= K + 1;  		  	  	

		when others => currentState <= S0;

	end case;
	end if;
	end process;

	address <= std_logic_vector(((I_r + 1) rem stateSize_r) + state_r) when currentState = S5 else
		std_logic_vector((UNSIGNED(J_r) + UNSIGNED(dataIn_r)) rem stateSize_r + state_r) when currentState = S6 else
		std_logic_vector(J_r + state_r) when currentState = S7 else 
		std_logic_vector(I_r + state_r) when currentState = S8 else 
		std_logic_vector(((dataIn_r + temp_r) rem stateSize_r) + state_r) when currentState = S9 else
		std_logic_vector(K) when currentState = S10 else (others => 'Z');
	
	data_out <= std_logic_vector(dataIn_r) when currentState = S7 else 
		std_logic_vector(temp_r) when currentState = S8 or currentState = S10 else
		(others => 'Z');

end behav;
