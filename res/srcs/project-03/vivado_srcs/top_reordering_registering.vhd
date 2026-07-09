--------------------------------------------------------------------------------
-- Top-Level: Reordering & Registering
--
-- Combines Reordering (dual dedicated adders, Adder32AC/Adder32BD) with
-- Registering (Pitingolo, Fig. 2.9): a second register stage (A2/B2/C2/D2_reg)
-- feeds the two adders, and their outputs are registered (E1_reg, F1_reg)
-- before MUX_SUM. Since the selected sum now arrives two register stages
-- after the initial capture (stage 1 -> stage 2 -> adder -> E1_reg/F1_reg),
-- the selection signal is re-aligned through two cascaded registers
-- (sel1_2_reg, sel1_3_reg) so MUX_SUM's select and its two data inputs are
-- always time-aligned, removing the glitch on MUX_SUM's select line that
-- Reordering alone still exhibits.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity top_reordering_registering is
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
end entity top_reordering_registering;

architecture rtl of top_reordering_registering is

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

    component rca is
        generic (
            WIDTH : positive
        );
        port (
            a   : in  std_logic_vector(WIDTH - 1 downto 0);
            b   : in  std_logic_vector(WIDTH - 1 downto 0);
            sum : out std_logic_vector(WIDTH downto 0)
        );
    end component rca;

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

    -- first register stage: operand and selection-signal sampling
    signal a1_reg, b1_reg, c1_reg, d1_reg : std_logic_vector(31 downto 0);
    signal sel1_1_reg, sel2_1_reg         : std_logic_vector(7 downto 0);

    -- selection path (combinational): sel1_1_reg + sel2_1_reg ->
    -- parity check -> sel_z
    signal sel_sum : std_logic_vector(8 downto 0);
    signal sel_z   : std_logic;

    -- second register stage: operand pipeline stage feeding the adders,
    -- and first selection re-alignment register (both one cycle after
    -- stage 1)
    signal a2_reg, b2_reg, c2_reg, d2_reg : std_logic_vector(31 downto 0);
    signal sel1_2_reg                     : std_logic_vector(0 downto 0);  -- registered sel_z

    -- dedicated adder branches, computed from stage-2 operand registers
    signal sum_ac, sum_bd : std_logic_vector(32 downto 0);

    -- pipeline register on the adder outputs, and second selection
    -- re-alignment register (both two cycles after stage 1, time-aligned)
    signal e1_reg, f1_reg : std_logic_vector(32 downto 0);
    signal sel1_3_reg     : std_logic_vector(0 downto 0);  -- registered sel1_2_reg

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

    adder_sel : rca
        generic map (WIDTH => 8)
        port map (a => sel1_1_reg, b => sel2_1_reg, sum => sel_sum);

    pattern : parity_check
        generic map (WIDTH => 8)
        port map (a => sel_sum(7 downto 0), z => sel_z);

    ------------------------------------------------------------------
    -- Second register stage: A2_reg, B2_reg, C2_reg, D2_reg,
    -- sel1_2_reg (first selection re-alignment register)
    ------------------------------------------------------------------

    reg_a2 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => a1_reg, q => a2_reg);
    reg_b2 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => b1_reg, q => b2_reg);
    reg_c2 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => c1_reg, q => c2_reg);
    reg_d2 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => d1_reg, q => d2_reg);

    reg_sel1_2 : rtl_reg_sync
        generic map (WIDTH => 1)
        port map (clk => clk, rst => rst, d(0) => sel_z, q => sel1_2_reg);

    ------------------------------------------------------------------
    -- Dedicated adders: Adder32AC (A+C), Adder32BD (B+D), fed by the
    -- stage-2 operand registers
    ------------------------------------------------------------------

    adder_32ac : rca
        generic map (WIDTH => 32)
        port map (a => a2_reg, b => c2_reg, sum => sum_ac);

    adder_32bd : rca
        generic map (WIDTH => 32)
        port map (a => b2_reg, b => d2_reg, sum => sum_bd);

    ------------------------------------------------------------------
    -- Pipeline stage registering the adder outputs: E1_reg, F1_reg,
    -- and second selection re-alignment register: sel1_3_reg (kept
    -- internal, not exposed as a port, for interface uniformity
    -- across variants)
    ------------------------------------------------------------------

    reg_e1 : rtl_reg_sync generic map (WIDTH => 33) port map (clk => clk, rst => rst, d => sum_ac, q => e1_reg);
    reg_f1 : rtl_reg_sync generic map (WIDTH => 33) port map (clk => clk, rst => rst, d => sum_bd, q => f1_reg);

    reg_sel1_3 : rtl_reg_sync
        generic map (WIDTH => 1)
        port map (clk => clk, rst => rst, d => sel1_2_reg, q => sel1_3_reg);

    ------------------------------------------------------------------
    -- Post-addition result selection: MUX_SUM, driven by the
    -- registered, time-aligned sel1_3_reg
    ------------------------------------------------------------------

    mux_sum : mux2
        generic map (WIDTH => 33)
        port map (a => e1_reg, b => f1_reg, sel => sel1_3_reg(0), z => adder_sum);

    ------------------------------------------------------------------
    -- Output register: Z_reg
    ------------------------------------------------------------------

    reg_z : rtl_reg_sync
        generic map (WIDTH => 33)
        port map (clk => clk, rst => rst, d => adder_sum, q => z);

end architecture rtl;
