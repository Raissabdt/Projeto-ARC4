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
    
    -- sem nextState
    type State is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10);
    signal currentState: State;

    -- Sinais que vao virar registradores
    signal stateSize_r, textSize_r, dataIn_r, I_r, J_r, temp_r: UNSIGNED(DATA_WIDTH-1 downto 0); 
    signal state_r, keyStream_r, K, arrayEnd: UNSIGNED(ADDR_WIDTH-1 downto 0);
    
begin
    process(clk, rst)
    begin  
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
                    if data_av = '1' then 
                        state_r <= UNSIGNED(data);
                        currentState <= S1; 
                    end if;
                    
                when S1 => 
                    if data_av = '1' then 
                        stateSize_r <= UNSIGNED(data);
                        currentState <= S2; 
                    end if;
                    
                when S2 => 
                    if data_av = '1' then 
                        textSize_r <= UNSIGNED(data);
                        currentState <= S3; 
                    end if;
                    
                when S3 => 
                    if data_av = '1' then 
                        keyStream_r <= UNSIGNED(data);
                        K <= UNSIGNED(data); 
                        arrayEnd <= UNSIGNED(data) + UNSIGNED(textSize_r);
                        currentState <= S4; 
                    end if;
                    
                when S4 => 
                    if K < arrayEnd then 
                        currentState <= S5; 
                    else 
                        currentState <= S0; 
                    end if;
                    
                when S5 => 
                    -- Acao do datapath e troca de estado juntos
                    I_r <= (I_r + 1) mod stateSize_r;
                    dataIn_r <= UNSIGNED(data_in);
                    currentState <= S6;
                    
                when S6 => 
                    J_r <= (J_r + dataIn_r) mod stateSize_r;
                    currentState <= S7;
                    
                when S7 => 
                    temp_r <= UNSIGNED(data_in);
                    currentState <= S8;
                    
                when S8 => 
                    currentState <= S9;
                    
                when S9 => 
                    temp_r <= UNSIGNED(data_in); 
                    currentState <= S10; 
                    
                when S10 => 
                    K <= K + 1;
                    currentState <= S4;
                    
                when others => 
                    currentState <= S0;
            end case;
        end if;
    end process;

    -- ATRIBUIÇÕES FORA DO PROCESS
    
    ce <= '0' when (currentState = S0 or currentState = S1 or currentState = S2 or currentState = S3) else '1';

    done <= '1' when (currentState = S4 and K >= arrayEnd) else '0';

    -- Sinais da memoria que ficam de fora para agirem instantaneamente como fios
    wr <= '1' when currentState = S7 else   
          '1' when currentState = S8 else  
          '1' when currentState = S10 else  
          '0';

    address <= std_logic_vector(((I_r + 1) mod stateSize_r) + state_r) when currentState = S5 else 
               std_logic_vector(J_r + state_r) when currentState = S7 else 
               std_logic_vector(I_r + state_r) when currentState = S8 else 
               std_logic_vector(((dataIn_r + temp_r) mod stateSize_r) + state_r) when currentState = S9 else 
               std_logic_vector(K) when currentState = S10 else 
               (others => '0');

    data_out <= std_logic_vector(dataIn_r) when currentState = S7 else  
                std_logic_vector(temp_r) when currentState = S8 else    
                std_logic_vector(temp_r) when currentState = S10 else   
                (others => '0');

end behav;
