--------------------------------------------------------------------------------
-- Top-Level: Reordering
--
-- Restructures the Baseline (Pitingolo, Fig. 2.5): the shared Adder32EF is
-- replaced by two dedicated 32-bit adders, Adder32AC (A+C) and Adder32BD
-- (B+D), operating unconditionally in parallel every cycle. The correct sum
-- is selected downstream via MUX_SUM, driven directly (combinationally,
-- unregistered) by the Pattern (parity_check) output. A single register
-- stage is used, same as the Baseline: Reordering alone does not add
-- pipeline depth, and MUX_SUM's select signal retains the same glitch
-- susceptibility as MUX_AB/MUX_CD in the Baseline.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity top_reordering is
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        a    : in  std_logic_vector(31 downto 0);
        b    : in  std_logic_vector(31 downto 0);
        c    : in  std_logic_vector(31 downto 0);
        d    : in  std_logic_vector(31 downto 0);
        sel1 : in  std_logic_vector(7 downto 0);
        sel2 : in  std_logic_vector(7 downto 0);
        z    : out std_logic_vector(32 downto 0)
    );
end entity top_reordering;

architecture rtl of top_reordering is

    component rtl_reg_sync is
        generic (
            WIDTH : positive
        );
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            d   : in  std_logic_vector(WIDTH - 1 downto 0);
            q   : out std_logic_vector(WIDTH - 1 downto 0)
        );
    end component rtl_reg_sync;

    component rca_gen is
        generic (
            WIDTH : positive
        );
        port (
            a   : in  std_logic_vector(WIDTH - 1 downto 0);
            b   : in  std_logic_vector(WIDTH - 1 downto 0);
            sum : out std_logic_vector(WIDTH downto 0)
        );
    end component rca_gen;

    component parity_check is
        generic (
            WIDTH : positive
        );
        port (
            a : in  std_logic_vector(WIDTH - 1 downto 0);
            z : out std_logic
        );
    end component parity_check;

    component mux2 is
        generic (
            WIDTH : positive
        );
        port (
            a   : in  std_logic_vector(WIDTH - 1 downto 0);
            b   : in  std_logic_vector(WIDTH - 1 downto 0);
            sel : in  std_logic;
            z   : out std_logic_vector(WIDTH - 1 downto 0)
        );
    end component mux2;

    -- first (only) register stage: operand and selection-signal sampling
    signal a1_reg, b1_reg, c1_reg, d1_reg : std_logic_vector(31 downto 0);
    signal sel1_1_reg, sel2_1_reg         : std_logic_vector(7 downto 0);

    -- selection path (combinational, unregistered): sel1_1_reg +
    -- sel2_1_reg -> parity check -> sel_z
    signal sel_sum : std_logic_vector(8 downto 0);
    signal sel_z   : std_logic;

    -- dedicated adder branches, both computed unconditionally every cycle
    signal sum_ac, sum_bd : std_logic_vector(32 downto 0);

    -- post-addition selected sum
    signal adder_sum : std_logic_vector(32 downto 0);

begin

    ------------------------------------------------------------------
    -- First register stage: A1_reg, B1_reg, C1_reg, D1_reg,
    -- sel1_1_reg, sel2_1_reg
    ------------------------------------------------------------------

    reg_a1 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => a, q => a1_reg);
    reg_b1 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => b, q => b1_reg);
    reg_c1 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => c, q => c1_reg);
    reg_d1 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => d, q => d1_reg);

    reg_sel1_1 : rtl_reg_sync generic map (WIDTH => 8) port map (clk => clk, rst => rst, d => sel1, q => sel1_1_reg);
    reg_sel2_1 : rtl_reg_sync generic map (WIDTH => 8) port map (clk => clk, rst => rst, d => sel2, q => sel2_1_reg);

    ------------------------------------------------------------------
    -- Selection path (combinational): AdderSel (RCA8) -> Pattern
    -- (parity_check) -> sel_z
    ------------------------------------------------------------------

    adder_sel : rca_gen
        generic map (WIDTH => 8)
        port map (a => sel1_1_reg, b => sel2_1_reg, sum => sel_sum);

    pattern : parity_check
        generic map (WIDTH => 8)
        port map (a => sel_sum(7 downto 0), z => sel_z);

    ------------------------------------------------------------------
    -- Dedicated adders: Adder32AC (A+C), Adder32BD (B+D), both
    -- computed unconditionally every cycle
    ------------------------------------------------------------------

    adder_32ac : rca_gen
        generic map (WIDTH => 32)
        port map (a => a1_reg, b => c1_reg, sum => sum_ac);

    adder_32bd : rca_gen
        generic map (WIDTH => 32)
        port map (a => b1_reg, b => d1_reg, sum => sum_bd);

    ------------------------------------------------------------------
    -- Post-addition result selection: MUX_SUM, driven combinationally
    -- (unregistered) by sel_z
    ------------------------------------------------------------------

    mux_sum : mux2
        generic map (WIDTH => 33)
        port map (a => sum_ac, b => sum_bd, sel => sel_z, z => adder_sum);

    ------------------------------------------------------------------
    -- Output register: Z_reg
    ------------------------------------------------------------------

    reg_z : rtl_reg_sync
        generic map (WIDTH => 33)
        port map (clk => clk, rst => rst, d => adder_sum, q => z);

end architecture rtl;
