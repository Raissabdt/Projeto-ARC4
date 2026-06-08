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

    -- Structural
   signal done_str     : std_logic;
   signal mem_wr_str   : std_logic;
   signal mem_ce_str   : std_logic;
   signal mem_addr_str : std_logic_vector(ADDR_WIDTH-1 downto 0);
   signal proc_mem_str : std_logic_vector(DATA_WIDTH-1 downto 0);
   signal mem_proc_str : std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Behavioral
   signal done_beh     : std_logic;
   signal mem_wr_beh   : std_logic;
   signal mem_ce_beh   : std_logic;
   signal mem_addr_beh : std_logic_vector(ADDR_WIDTH-1 downto 0);
   signal proc_mem_beh : std_logic_vector(DATA_WIDTH-1 downto 0);
   signal mem_proc_beh : std_logic_vector(DATA_WIDTH-1 downto 0);
begin

    -- 1. Inst�ncias do Processador
    PROCESSOR_STRUCTURAL: entity work.GenerateKeyStream(structural)
    generic map (
        ADDR_WIDTH => ADDR_WIDTH,
        DATA_WIDTH => DATA_WIDTH
    )
    port map (
        clk      => clk,
        rst      => rst,
        data_av  => data_av,
        data     => data,
        done     => done_str,
        wr       => mem_wr_str,
        ce       => mem_ce_str,
        address  => mem_addr_str,
        data_out => proc_mem_str,
        data_in  => mem_proc_str
    );

    PROCESSOR_BEHAV: entity work.GenerateKeyStream(behav)
    generic map (
        ADDR_WIDTH => ADDR_WIDTH,
        DATA_WIDTH => DATA_WIDTH
    )
    port map (
        clk      => clk,
        rst      => rst,
        data_av  => data_av,
        data     => data,
        done     => done_beh,
        wr       => mem_wr_beh,
        ce       => mem_ce_beh,
        address  => mem_addr_beh,
        data_out => proc_mem_beh,
        data_in  => mem_proc_beh
    );

    -- 2. Inst�ncias da Mem�ria
    RAM_STRUCTURAL: entity work.Memory
    generic map (
        DATA_WIDTH    => DATA_WIDTH,
        ADDR_WIDTH    => ADDR_WIDTH,
        imageFileName => "ram_init.txt"
    )
    port map (
        clk      => clk,
        ce       => mem_ce_str,
        wr       => mem_wr_str,
        address  => mem_addr_str,
        data_in  => proc_mem_str,
        data_out => mem_proc_str
    );

    RAM_BEHAV: entity work.Memory
    generic map (
        DATA_WIDTH    => DATA_WIDTH,
        ADDR_WIDTH    => ADDR_WIDTH,
        imageFileName => "ram_init.txt"
    )
    port map (
        clk      => clk,
        ce       => mem_ce_beh,
        wr       => mem_wr_beh,
        address  => mem_addr_beh,
        data_in  => proc_mem_beh,
        data_out => mem_proc_beh
    );
    -- 3. Gerador de Clock de 25ns
    clk <= not clk after 25 ns;

    process(clk)
    begin
        if rising_edge(clk) then

            assert done_str = done_beh
            report "Divergencia no DONE"
            severity error;

        end if;
    end process;

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
       wait until done_str = '1' and done_beh = '1';

       wait for 100 ns;

       assert false
       report "=== CRIPTOGRAFIA FINALIZADA COM SUCESSO! ==="
       severity note;
       wait;
    end process;

end sim;