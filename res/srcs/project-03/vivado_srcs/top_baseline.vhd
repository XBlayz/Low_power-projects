--------------------------------------------------------------------------------
-- Top-Level: Baseline
--
-- The circuit is a two-stage pipelined datapath with registered inputs
-- that samples four 32-bit data operands and two 8-bit selection signals.
-- An 8-bit adder and a parity checker generate a dynamic mux control bit for
-- the two multiplexers used to route either a/b or c/d to the adder.
-- A 32-bit ripple carry adder computes the sum of the selected operands
-- returning a 33-bit result stored in an output register.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity top_baseline is
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
end entity top_baseline;

architecture rtl of top_baseline is

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

    -- selection path: sel1 + sel2 -> parity check -> mux select
    signal sel_sum : std_logic_vector(8 downto 0);
    signal sel_z   : std_logic;

    -- operand multiplexer outputs and adder result
    signal mux_ab_out, mux_cd_out : std_logic_vector(31 downto 0);
    signal adder_sum              : std_logic_vector(32 downto 0);

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
    -- Selection path (combinational, unregistered mux select):
    -- AdderSel (RCA8) -> Pattern (parity_check) -> Z
    ------------------------------------------------------------------

    adder_sel : rca
        generic map (WIDTH => 8)
        port map (a => sel1_1_reg, b => sel2_1_reg, sum => sel_sum);

    pattern : parity_check
        generic map (WIDTH => 8)
        port map (a => sel_sum(7 downto 0), z => sel_z);

    ------------------------------------------------------------------
    -- Operand selection and addition: MUX_AB, MUX_CD -> Adder32EF
    ------------------------------------------------------------------

    mux_ab : mux2
        generic map (WIDTH => 32)
        port map (a => a1_reg, b => b1_reg, sel => sel_z, z => mux_ab_out);

    mux_cd : mux2
        generic map (WIDTH => 32)
        port map (a => c1_reg, b => d1_reg, sel => sel_z, z => mux_cd_out);

    adder_32ef : rca
        generic map (WIDTH => 32)
        port map (a => mux_ab_out, b => mux_cd_out, sum => adder_sum);

    ------------------------------------------------------------------
    -- Output register: Z_reg
    ------------------------------------------------------------------

    reg_z : rtl_reg_sync
        generic map (WIDTH => 33)
        port map (clk => clk, rst => rst, d => adder_sum, q => z);

end architecture rtl;
