--------------------------------------------------------------------------------
-- Top-Level: Registering
--
-- Extends top_baseline with a second register stage (A2/B2/C2/D2_reg,
-- sel1_2_reg) feeding MUX_AB / MUX_CD, and a further pipeline stage
-- (E1_reg, F1_reg) registering the multiplexer outputs *before* the 32-bit
-- addition (Pitingolo, Fig. 2.1). Both multiplexers receive the registered,
-- glitch-free select sel1_2_reg (time-aligned with the stage-2 operand
-- registers), removing the transient invalid operand pairs that reach
-- Adder32EF in the Baseline.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity top_registering is
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
end entity top_registering;

architecture rtl of top_registering is

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

    -- selection path: sel1_1_reg + sel2_1_reg -> parity check -> sel_z
    signal sel_sum : std_logic_vector(8 downto 0);
    signal sel_z   : std_logic;

    -- second register stage: operand and selection-signal pipeline stage
    -- (time-aligned: both are one cycle after stage 1)
    signal a2_reg, b2_reg, c2_reg, d2_reg : std_logic_vector(31 downto 0);
    signal sel1_2_reg                     : std_logic_vector(0 downto 0);  -- registered sel_z

    -- operand multiplexer outputs, registered before the adder
    signal mux_ab_out, mux_cd_out : std_logic_vector(31 downto 0);
    signal e1_reg, f1_reg         : std_logic_vector(31 downto 0);

    -- adder result
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
    -- sel1_2_reg. Registering sel_z here is what removes the glitch
    -- at the MUX_AB / MUX_CD select input.
    ------------------------------------------------------------------

    reg_a2 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => a1_reg, q => a2_reg);
    reg_b2 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => b1_reg, q => b2_reg);
    reg_c2 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => c1_reg, q => c2_reg);
    reg_d2 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => d1_reg, q => d2_reg);

    reg_sel1_2 : rtl_reg_sync
        generic map (WIDTH => 1)
        port map (clk => clk, rst => rst, d(0) => sel_z, q => sel1_2_reg);

    ------------------------------------------------------------------
    -- Operand selection: MUX_AB, MUX_CD, driven by the registered,
    -- glitch-free sel1_2_reg
    ------------------------------------------------------------------

    mux_ab : mux2
        generic map (WIDTH => 32)
        port map (a => a2_reg, b => b2_reg, sel => sel1_2_reg(0), z => mux_ab_out);

    mux_cd : mux2
        generic map (WIDTH => 32)
        port map (a => c2_reg, b => d2_reg, sel => sel1_2_reg(0), z => mux_cd_out);

    ------------------------------------------------------------------
    -- Pipeline stage registering the multiplexer outputs, *before*
    -- the 32-bit addition: E1_reg, F1_reg
    ------------------------------------------------------------------

    reg_e1 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => mux_ab_out, q => e1_reg);
    reg_f1 : rtl_reg_sync generic map (WIDTH => 32) port map (clk => clk, rst => rst, d => mux_cd_out, q => f1_reg);

    ------------------------------------------------------------------
    -- Addition: Adder32EF
    ------------------------------------------------------------------

    adder_32ef : rca
        generic map (WIDTH => 32)
        port map (a => e1_reg, b => f1_reg, sum => adder_sum);

    ------------------------------------------------------------------
    -- Output register: Z_reg
    ------------------------------------------------------------------

    reg_z : rtl_reg_sync
        generic map (WIDTH => 33)
        port map (clk => clk, rst => rst, d => adder_sum, q => z);

end architecture rtl;
