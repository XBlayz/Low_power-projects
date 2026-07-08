--------------------------------------------------------------------------------
-- Top-Level: Isolated Reordering
--
-- STEP 6: extends top_reordering_registering with Gated Inputs,
-- Precomputing, and Clock Gating. The selection signal sel_z depends only
-- on sel1/sel2 (via AdderSel/Pattern), so it is available *before* it is
-- needed to select the final sum -- it is precomputed and reused as an
-- operand-isolation and clock-enable control signal for the non-selected
-- adder branch:
--
--   - Gated Inputs: the operands feeding the non-selected adder
--     (Adder32AC or Adder32BD, depending on sel1_2_reg) are frozen to
--     all-zeros via `operand_gate`, so its ripple-carry chain does not
--     toggle on operand transitions that will not be selected this cycle.
--   - Clock Gating: the pipeline register capturing the non-selected
--     branch's sum (E1_reg / F1_reg) is driven with an explicit clock
--     enable tied to sel1_2_reg / not sel1_2_reg, so it does not clock in
--     the (already frozen) discarded value.
--
-- This preserves Reordering & Registering's glitch-free MUX_SUM timing
-- while removing the redundant-computation power cost that plain
-- Reordering pays for eliminating the pre-adder glitch.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity top_isolated_reordering is
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
end entity top_isolated_reordering;

architecture rtl of top_isolated_reordering is

    component rtl_reg_sync is
        generic (
            WIDTH : positive
        );
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            ce  : in  std_logic := '1';
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

    component operand_gate is
        generic (
            WIDTH : positive
        );
        port (
            d    : in  std_logic_vector(WIDTH - 1 downto 0);
            gate : in  std_logic;
            q    : out std_logic_vector(WIDTH - 1 downto 0)
        );
    end component operand_gate;

    -- first register stage: operand and selection-signal sampling
    signal a1_reg, b1_reg, c1_reg, d1_reg : std_logic_vector(31 downto 0);
    signal sel1_1_reg, sel2_1_reg         : std_logic_vector(7 downto 0);

    -- selection path (combinational, precomputed): sel1_1_reg +
    -- sel2_1_reg -> parity check -> sel_z
    signal sel_sum : std_logic_vector(8 downto 0);
    signal sel_z   : std_logic;

    -- second register stage: operand pipeline stage feeding the gated
    -- adder inputs, and first selection re-alignment register (both one
    -- cycle after stage 1, time-aligned)
    signal a2_reg, b2_reg, c2_reg, d2_reg : std_logic_vector(31 downto 0);
    signal sel1_2_reg                     : std_logic_vector(0 downto 0);  -- registered sel_z

    -- gated (isolated) operands: only the selected branch's operands pass
    -- through unchanged, the non-selected branch's operands are frozen to
    -- all-zeros
    signal gated_a, gated_c : std_logic_vector(31 downto 0);  -- AC branch, gated by sel1_2_reg
    signal gated_b, gated_d : std_logic_vector(31 downto 0);  -- BD branch, gated by not sel1_2_reg

    -- dedicated adder branches, fed by gated operands
    signal sum_ac, sum_bd : std_logic_vector(32 downto 0);

    -- clock-gated pipeline register on the adder outputs: only the
    -- selected branch's register is actually clocked (CE tied to
    -- sel1_2_reg / not sel1_2_reg); the non-selected register holds its
    -- previous (irrelevant) value without updating
    signal e1_reg, f1_reg : std_logic_vector(32 downto 0);

    -- second selection re-alignment register, time-aligned with
    -- e1_reg/f1_reg (two cycles after stage 1)
    signal sel1_3_reg : std_logic_vector(0 downto 0);  -- registered sel1_2_reg

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
    -- Selection path (combinational, precomputed): AdderSel (RCA8) ->
    -- Pattern (parity_check) -> sel_z
    ------------------------------------------------------------------

    adder_sel : rca_gen
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
    -- Gated Inputs: freeze the non-selected branch's operands to
    -- all-zeros, using the time-aligned sel1_2_reg
    ------------------------------------------------------------------

    gate_a : operand_gate generic map (WIDTH => 32) port map (d => a2_reg, gate => sel1_2_reg(0), q => gated_a);
    gate_c : operand_gate generic map (WIDTH => 32) port map (d => c2_reg, gate => sel1_2_reg(0), q => gated_c);
    gate_b : operand_gate generic map (WIDTH => 32) port map (d => b2_reg, gate => not sel1_2_reg(0), q => gated_b);
    gate_d : operand_gate generic map (WIDTH => 32) port map (d => d2_reg, gate => not sel1_2_reg(0), q => gated_d);

    ------------------------------------------------------------------
    -- Dedicated adders: Adder32AC (gated A + gated C), Adder32BD
    -- (gated B + gated D) -- only the selected branch's ripple-carry
    -- chain toggles meaningfully
    ------------------------------------------------------------------

    adder_32ac : rca_gen
        generic map (WIDTH => 32)
        port map (a => gated_a, b => gated_c, sum => sum_ac);

    adder_32bd : rca_gen
        generic map (WIDTH => 32)
        port map (a => gated_b, b => gated_d, sum => sum_bd);

    ------------------------------------------------------------------
    -- Clock Gating: pipeline register on the adder outputs, CE tied
    -- to sel1_2_reg / not sel1_2_reg -- only the selected branch's
    -- register is clocked. Second selection re-alignment register:
    -- sel1_3_reg (kept internal, not exposed as a port, for interface
    -- uniformity across variants)
    ------------------------------------------------------------------

    reg_e1 : rtl_reg_sync
        generic map (WIDTH => 33)
        port map (clk => clk, rst => rst, ce => sel1_2_reg(0), d => sum_ac, q => e1_reg);

    reg_f1 : rtl_reg_sync
        generic map (WIDTH => 33)
        port map (clk => clk, rst => rst, ce => not sel1_2_reg(0), d => sum_bd, q => f1_reg);

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
