library IEEE;                                  
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.GenerateKeyStream_pkg.all;

entity controlPath is
    port ( 
        status, data_av: in std_logic;
        clk, rst: in std_logic;
        cmd: out Command; 
        ce, wr: out std_logic; 
        done: out std_logic
    );
end controlPath;
        
architecture behav of controlPath is
    type State is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11);
    signal currentState, nextState : State := S0;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            currentState <= S0;
        elsif rising_edge(clk) then
            currentState <= nextState;
        end if;
    end process;

    process(currentState, status, data_av)
    begin
        -- Estado base seguro: Nada é gravado, memória apenas lê
        cmd <= CMD_ZERO;
        ce <= '1'; 
        wr <= '0'; 
        done <= '0';

        case currentState is
            when S0 =>
                ce <= '0'; -- Memória desligada na configuração
                if data_av = '1' then
                    cmd.wrState <= '1'; 
                    nextState <= S1; 
                else
                    cmd.rstart <= '1';
                    nextState <= S0;
                end if;
                
            when S1 =>
                ce <= '0';
                if data_av = '1' then
                    cmd.wrStateSize <= '1'; 
                    nextState <= S2; 
                else
                    nextState <= S1;
                end if;
                
            when S2 =>
                ce <= '0';
                if data_av = '1' then
                    cmd.wrTextSize <= '1'; 
                    nextState <= S3; 
                else
                    nextState <= S2;
                end if;
                
            when S3 =>
                ce <= '0';
                if data_av = '1' then
                    cmd.wrKeyStream <= '1'; 
                    nextState <= S4; 
                else
                    nextState <= S3;
                end if; 
                
            when S4 => 
                ce <= '0';
                cmd.mComp <= '1';
                if status = '1' then
                    nextState <= S5; 
                else
                    done <= '1'; -- Acende o Done se acabou
                    nextState <= S0;
                end if;
                
            -- === INÍCIO DO LOOP PRGA ===

            when S5 => 
                -- Calcula i = (i + 1) mod N e aponta memória para S[i]
                cmd.wrI <= '1';
                cmd.mS2 <= "00";
                cmd.mS0 <= '1';
                cmd.ms1 <= "01";
				cmd.wrDataIn <= '1';
                nextState <= S6;
                
                
            when S6 => 
                -- Calcula j = (j + S[i]) mod N e aponta memória para S[j]
                cmd.wrJ <= '1';
                cmd.mS2 <= "01";
                cmd.mS0 <= '1';
                cmd.ms1 <= "01";
                nextState <= S7;
                
            when S7 => 
                -- Salva S[j] no Temp
                cmd.wrTemp <= '1';
                -- Mantém endereço S[j] estável
                cmd.mS0 <= '1';
                cmd.ms1 <= "11";
                nextState <= S8;
                
            -- === O SWAP (TROCA) ===

            when S8 => 
                -- Escreve Datain (antigo S[i]) no endereço S[j]
                cmd.mS0 <= '1';
                cmd.ms1 <= "11";
                cmd.mOut <= '0';
                wr <= '1'; -- HABILITA ESCRITA DA MEMÓRIA
                nextState <= S9;
                
            when S9 => 
                -- Escreve Temp (antigo S[j]) no endereço S[i]
                cmd.mS0 <= '1';
                cmd.ms1 <= "10";
                cmd.mOut <= '1';
                wr <= '1'; -- HABILITA ESCRITA DA MEMÓRIA
                nextState <= S10;
                
            -- === A GERAÇÃO DO BYTE ===

            when S10 => 
                -- Calcula t = (S[i] + S[j]) mod N e lê S[t]
                cmd.mS2 <= "11";
                cmd.mS0 <= '1';
                cmd.ms1 <= "01";
                cmd.wrTemp <= '1'; -- Salva o byte gerado no Temp
                nextState <= S11;
                
            when S11 => 
                -- Escreve Temp no endereço RegK
                cmd.mAdrk <= '1';
                cmd.mOut <= '1';
                wr <= '1'; -- HABILITA ESCRITA DA MEMÓRIA
                
                -- Incrementa o K
                cmd.wrK <= '1';
                cmd.mS2 <= "10";
                nextState <= S4;      
        end case;
    end process;
end behav;