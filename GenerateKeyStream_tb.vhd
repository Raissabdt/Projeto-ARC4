library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity GenerateKeyStream_tb is
end GenerateKeyStream_tb;

architecture sim of GenerateKeyStream_tb is
    constant DATA_WIDTH : integer := 8;
    constant ADDR_WIDTH : integer := 8;

    -- Sinais do Processador
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal data_av  : std_logic := '0';
    signal data     : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal done     : std_logic;

    -- Sinais de Interface com a Memória
    signal mem_wr       : std_logic;
    signal mem_ce       : std_logic;
    signal mem_address  : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal proc_to_mem  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem_to_proc  : std_logic_vector(DATA_WIDTH-1 downto 0);
begin

    -- 1. Instância do Processador (Forçando o uso da arquitetura Structural)
    PROCESSOR: entity work.GenerateKeyStream(structural)
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            data_av  => data_av,
            data     => data,
            done     => done,
            wr       => mem_wr,
            ce       => mem_ce,
            address  => mem_address,
            data_out => proc_to_mem,
            data_in  => mem_to_proc
        );

    -- 2. Instância da Memória RAM
    RAM: entity work.Memory
        generic map (
            DATA_WIDTH    => DATA_WIDTH,
            ADDR_WIDTH    => ADDR_WIDTH,
            imageFileName => "ram_init.txt"
        )
        port map (
            clk      => clk,
            ce       => mem_ce,
            wr       => mem_wr,
            address  => mem_address,
            data_in  => proc_to_mem,
            data_out => mem_to_proc
        );

    -- 3. Gerador de Clock de 25ns
    clk <= not clk after 25 ns;

    -- 4. O Teste de Injeção de Dados (Cenário do Logisim)
    process
    begin
        -- T = 0 ns
        wait for 20 ns;
        rst <= '0';
        
        wait until falling_edge(clk);
        
        -- CICLO S0: state = 0x08 (Endereço inicial do array)
        data_av <= '1';
        data <= x"08"; 
        
        -- CICLO S1: stateSize = 0x08
        wait until falling_edge(clk);
        data <= x"08"; 
        
        -- CICLO S2: textSize = 0x05 ("teste")
        wait until falling_edge(clk);
        data <= x"05"; 
        
        -- CICLO S3: keyStream = 0x00 (Destino da gravação)
        wait until falling_edge(clk);
        data <= x"00"; 
        
        -- CICLO S4: Processador entra no loop
        wait until falling_edge(clk);
        data_av <= '0';
        data <= x"00";
        
        -- Espera terminar
        wait until done = '1';
        wait for 100 ns;
        assert false report "=== CRIPTOGRAFIA FINALIZADA COM SUCESSO! ===" severity note;
        wait;
    end process;

end sim;