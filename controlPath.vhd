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
        cmd <= CMD_ZERO; -- zera tudo pra nao iniciar em UUUU
        ce <= '1'; 
        wr <= '0'; 
        done <= '0';

        case currentState is
            when S0 =>
                ce <= '0'; -- desliga memoria na configuracao
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
                    done <= '1'; -- finaliza operacao
                    nextState <= S0;
                end if;
                
            -- laço de loop

            when S5 => 
                -- atualiza RegI e guarda RAM[I] no DataIn
                cmd.wrI <= '1';
                cmd.mS0 <= '1';
                cmd.ms1 <= "01";
                cmd.wrDataIn <= '1';
                nextState <= S6;
                
            when S6 => 
                -- atualiza RegJ
                cmd.wrJ <= '1';
                cmd.mS2 <= "01";
                cmd.mS0 <= '1';
                cmd.ms1 <= "01";
                nextState <= S7;
                
            when S7 => 
                -- le RAM[J] e guarda no Temp
                cmd.wrTemp <= '1';
                cmd.mS0 <= '1';
                cmd.ms1 <= "11";
                nextState <= S8; 
                
            -- SWAP

            when S8 => 
                -- Grava DataIn (antigo RAM[I]) no endereco J (estado novo que nao existe no diagrama, pois a RAM tem uma porta só)
                cmd.mS0 <= '1';
                cmd.ms1 <= "11";
                cmd.mOut <= '0'; 
                wr <= '1';
                nextState <= S9;
                
            when S9 => 
                -- Grava Temp (antigo RAM[J]) no endereco I
                cmd.mS0 <= '1';
                cmd.ms1 <= "10";
                cmd.mOut <= '1';
                wr <= '1';
                nextState <= S10;

            when S10 => 
                -- Calcula t e guarda RAM[t] no Temp
                cmd.mS2 <= "11";
                cmd.mS0 <= '1';
                cmd.ms1 <= "01";
                cmd.wrTemp <= '1'; 
                nextState <= S11;
                
            when S11 => 
                -- Grava a informacao gerada no endereco K e incrementa K
                cmd.mAdrk <= '1';
                cmd.mOut <= '1';
                wr <= '1';
                cmd.wrK <= '1'; 
                cmd.mS2 <= "10";
                nextState <= S4;   
        end case;
    end process;
end behav;