library IEEE;
use IEEE.std_logic_1164.all;
use work.GenerateKeyStream_pkg.all; 

entity ControlPath_tb is
end ControlPath_tb;

architecture sim of ControlPath_tb is

    -- Entradas
    signal tb_clk     : std_logic := '0';
    signal tb_rst     : std_logic := '1'; -- começa com o reset ativado
    signal tb_status  : std_logic := '0';
    signal tb_data_av : std_logic := '0';

    -- Saídas
    signal tb_cmd     : Command;
    signal tb_ce      : std_logic;
    signal tb_wr      : std_logic;
    signal tb_done    : std_logic;

begin

    -- Instancia o ControlPath
    DUT: entity work.controlPath
        port map (
            clk     => tb_clk,
            rst     => tb_rst,
            status  => tb_status,
            data_av => tb_data_av,
            cmd     => tb_cmd,
            ce      => tb_ce,
            wr      => tb_wr,
            done    => tb_done
        );

    -- Gerador de Clock infinito (Gera um ciclo completo a cada 20 ns)
    tb_clk <= not tb_clk after 10 ns;

    process
    begin
        -- 1. ativa o reset, maquina vai para o estado S0
        -- tempo atual: 0 ns
        wait for 20 ns;
        tb_rst <= '0';
        -- tempo atual: 20 ns

        -- 2. ativa o (data_av = 1) e espera a máquina ir até o estado S4
        wait for 20 ns;
        tb_data_av <= '1';
        -- tempo atual: 40 ns
        
        wait for 80 ns;
        -- tempo atual: 120 ns
        
        -- 3. desativa o data_av = 1 e ativa o status para ele rodar o loop
        tb_data_av <= '0';
        tb_status  <= '1';

        -- 4. espera 180ns para dar o tempo exato dele estar no estado S12 para ele parar o loop.
        -- 120 ns + 180 ns = 300 ns
        wait for 180 ns;
        
        -- 5. tempo atual: exatos 300 ns. a maquina chegou no estado S4 novamente e agora ele sai do laço por causa do status = 0
        tb_status <= '0';

        -- espera um pouco para o sinal de 'done' aparecer e ficar visível no gráfico
        wait for 40 ns;

        -- trava a simulação
        wait;
    end process;

end sim;