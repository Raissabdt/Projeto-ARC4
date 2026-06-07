library IEEE;                        
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.GenerateKeyStream_pkg.all;

entity dataPath is 
	generic (
		DATA_WIDTH  : integer := 8;
		ADDR_WIDTH  : integer := 8
	);
	port (
		clk: in std_logic;
		rst: in std_logic;
		data: in std_logic_vector(DATA_WIDTH-1 downto 0);
		
		-- ControlPath Interface
		status: out std_logic;
		cmd: in Command;

		-- Memory Interface
		data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
		data_out: out std_logic_vector(DATA_WIDTH-1 downto 0);
		address: out std_logic_vector(ADDR_WIDTH-1 downto 0)
	);
end dataPath;

architecture arch1 of dataPath is

	-- Signals dos Registradores
	signal s_regState, s_regStateSize, s_regTextSize, s_regKeyStream, s_regI,
	s_regJ, s_regK, s_regTemp, s_regDatain : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	-- Signal Entrada K
	signal k_in : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	-- Signals das Saídas dos Módulos
	signal sum1, sum2, div : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	-- Signals das Entradas dos Módulos
	signal sum1_0, sum1_1, sum2_0, sum2_1, div_0, div_1 : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	-- Outros Signals
	signal restDiv : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	-- Sinais auxiliares para a lógica do Status
    signal fio_quociente_1 : std_logic;
    signal fio_resto_nao_0 : std_logic;

begin

	-- Structural

	RegState: entity work.RegisterNbits
        generic map (
            WIDTH   => DATA_WIDTH
        )
        port map (
            clock   => clk,
            reset   => rst,
            ce      => cmd.wrState,
            d       => data,
            q       => s_regState     
        );
        
	RegStateSize: entity work.RegisterNbits
        generic map (
            WIDTH   => DATA_WIDTH
        )
        port map (
            clock   => clk,
            reset   => rst,
            ce      => cmd.wrStateSize,
            d       => data,
            q       => s_regStateSize     
        );
        
	RegTextSize: entity work.RegisterNbits
        generic map (
            WIDTH   => DATA_WIDTH
        )
        port map (
            clock   => clk,
            reset   => rst,
            ce      => cmd.wrTextSize,
            d       => data,
            q       => s_regTextSize          
        );

	RegKeyStream: entity work.RegisterNbits
        generic map (
            WIDTH   => DATA_WIDTH
        )
        port map (
            clock   => clk,
            reset   => rst,
            ce      => cmd.wrKeyStream,
            d       => data,
            q       => s_regKeyStream          
        );
        
    RegI: entity work.RegisterNbits
        generic map (
            WIDTH   => DATA_WIDTH
        )
        port map (
            clock   => clk,
            reset   => rst,
            ce      => cmd.wrI,
            d       => restDiv,
            q       => s_regI          
        );
        
	RegJ: entity work.RegisterNbits
        generic map (
            WIDTH   => DATA_WIDTH
        )
        port map (
            clock   => clk,
            reset   => rst,
            ce      => cmd.wrJ,
            d       => restDiv,
            q       => s_regJ           
        );

	RegK: entity work.RegisterNbits
        generic map (
            WIDTH   => DATA_WIDTH
        )
        port map (
            clock   => clk,
            reset   => rst,
            ce      => cmd.wrK,
            d       => k_in,
            q       => s_regK           
        );
        
	RegTemp: entity work.RegisterNbits
        generic map (
            WIDTH   => DATA_WIDTH
        )
        port map (
            clock   => clk,
            reset   => rst,
            ce      => cmd.wrTemp,
            d       => data_in,
            q       => s_regTemp           
        );
        
	RegDatain: entity work.RegisterNbits
        generic map (
            WIDTH   => DATA_WIDTH
        )
        port map (
            clock   => clk,
            reset   => rst,
            ce      => cmd.wrDatain,
            d       => data_in,
            q       => s_regDatain            
        );
        
	-- Behavioral

	k_in <= data when cmd.mAdrk = '0' else sum2; 

	sum1_0 <= s_regKeyStream when cmd.mS0 = '0' else s_regState;
	sum1_1 <= s_regTextSize when cmd.ms1 = "00" else
		  restDiv when cmd.ms1 = "01" else
		  s_regI when cmd.ms1 = "10" else
		  s_regJ;

	sum1 <= std_logic_vector(UNSIGNED(sum1_0) + UNSIGNED(sum1_1));

	sum2_0 <= s_regI when cmd.mS2 = "00" else
		 s_regJ when cmd.mS2 = "01" else
		 s_regK when cmd.mS2 = "10" else
		 s_regTemp;
		
	sum2_1 <= s_regDatain when cmd.mS2(0) = '1' else std_logic_vector(to_unsigned(1, DATA_WIDTH));

	sum2 <= std_logic_vector(UNSIGNED(sum2_0) + UNSIGNED(sum2_1));

	div_0 <= sum2 when cmd.mcomp = '0' else s_regK;
	div_1 <= sum1 when cmd.mcomp = '1' else s_regStateSize;


	-- Verificar outras formas de fazer isso aqui, provavelmente não vai funcionar

	-- Proteção contra Divisão por Zero no tempo 0 ns
    process(div_0, div_1)
    begin
        if div_1 = std_logic_vector(to_unsigned(0, DATA_WIDTH)) then
            div     <= std_logic_vector(UNSIGNED(div_0) / 1);
            restDiv <= std_logic_vector(UNSIGNED(div_0) rem 1);
        else
            div     <= std_logic_vector(UNSIGNED(div_0) / UNSIGNED(div_1));
            restDiv <= std_logic_vector(UNSIGNED(div_0) rem UNSIGNED(div_1));
        end if;
    end process;

	-- Outputs
	address <= sum1 when cmd.mAdrk = '0' else s_regK;

	data_out <= s_regDatain when cmd.mOut = '0' else s_regTemp;

	-- Status
	
    -- Verifica se o Quociente (div) tem apenas o bit 0 em nível alto
    fio_quociente_1 <= not(div(0) and (not div(1)) and (not div(2)) and (not div(3)) 
                       and (not div(4)) and (not div(5)) and (not div(6)) and (not div(7)));

    -- Verifica se o Resto (restDiv) tem qualquer bit em nível alto
    fio_resto_nao_0 <= restDiv(0) or restDiv(1) or restDiv(2) or restDiv(3) 
                       or restDiv(4) or restDiv(5) or restDiv(6) or restDiv(7);

    -- Verifica se algum dos dois acima foi ativado
    status <= fio_quociente_1 or fio_resto_nao_0;

end arch1;





