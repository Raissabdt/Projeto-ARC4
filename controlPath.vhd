library IEEE;                        
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.GenerateKeyStream_pkg.all;

--NAO TESTADO
entity controlPath is
	port ( 
		status, data_av: in std_logic; --entradas principais
		clk, rst: in std_logic;
		cmd: out Command; --todos os sinais de saida pro dtph
		ce, wr: out std_logic; --controle da memoria, equiv: sel, ld
		done: out std_logic -- ver necessidade de um sinal reset do ctrlp pro dtph
	);
end controlPath;
		
architecture behav of controlPath is
	type State is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12);
   	signal currentState, nextState : State;
begin
   process(clk, rst) -- rst e logica para estado atualizar estado
   begin
		if rst = '1' then
	            currentState <= S0;
        
	        elsif rising_edge(clk) then
	            currentState <= nextState;
        	end if;
   end process;

   process(currentState, status, data_av) -- novo proximo estado
   begin
        
	case currentState is
	  when S0 =>
	 	if data_av = '1' then
		  nextState <= S1; else
		  nextState <= S0;
		end if;
	  when S1 =>
	 	if data_av = '1' then
		  nextState <= S2; else
		  nextState <= S1;
		end if;
	 when S2 =>
	 	if data_av = '1' then
		  nextState <= S3; else
		  nextState <= S2;
		end if;
	 when S3 =>
	 	if data_av = '1' then
		  nextState <= S4; else
		  nextState <= S3;
		end if; 
	 when S4 => 
		if status = '1' then
		  nextState <= S5; else
		  nextState <= S0;
		end if;
	when S5 => nextState <= S6;
	when S6 => nextState <= S7;
	when S7 => nextState <= S8;
	when S8 => nextState <= S9;
	when S9 => nextState <= S10;
	when S10 => nextState <= S11;
	when S11 => nextState <= S12;
	when S12 => nextState <= S4;	     
            
        end case;
        
    end process;

	done <= '1' when currentState = S4 and status = '0' else '0'; 
	cmd.rstart <= '1' when currentState = S0 and data_av = '0' else '0';
	
	-- diferença entre logisim e aq: 
	-- no esquematico, sel nao precisava estar ativo na leitura porque era lido do registrador
	-- mas ce tem que estar ativo tanto para leitura qnt escrita
	-- estados de uso da memoria: S5, S6, S7, S8, S9, S10, S11, S12
	ce <= '0' when currentState = S0 or currentState = S1 or currentState = S2 or 
		currentState = S3 or currentState = S4 else '1';

	--equivale a ld invertido: ld = 0 -> wr = 1 
	wr <= '0' when currentState = S5 or currentState = S7 or currentState = S10 else '1';
	
	cmd.wrState <= '1' when currentState = S0 and data_av = '1' else '0';
	cmd.wrStateSize <= '1' when currentState = S1 and data_av = '1' else '0';
	cmd.wrTextSize <= '1' when currentState = S2 and data_av = '1' else '0';
	cmd.wrKeyStream <= '1' when currentState = S3 and data_av = '1' else '0'; 
	cmd.wrDataIn <= '1' when currentState = S6 else '0'; 
	cmd.wrTemp <= '1' when currentState = S8 or currentState = S11 else '0';
	cmd.wrJ <= '1' when currentState = S7 else '0';
	cmd.wrI <= '1' when currentState = S5 else '0'; 
	cmd.wrK <= '1' when currentState = S12 else '0';

	cmd.mOut <= '1' when currentState = S9 or currentState = S12 else '0'; 
	cmd.mAdrk <= '1' when currentState = S12 else '0';
	cmd.mComp <= '1' when currentState = S4 else '0';
	cmd.mS2 <= "11" when currentState = S10 else "10" when currentState = S12 else
		"01" when currentState = S7 else "00"; 
	cmd.mS1 <= "11" when currentState = S8 else "10" when currentState = S9 else
		"01" when currentState = S5 or currentState = S7 or currentState = S10  else "00";
	cmd.mS0 <= '1' when currentState = S5 or currentState = S7 or currentState = S8 or
		currentState = S9 or currentState = S10 else '0';

end behav;