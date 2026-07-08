--------------------------------------------------------------------------------
-- Testbench: tb_top
--
-- Single, variant-agnostic testbench body: drives pseudo-random A, B, C, D,
-- sel1, sel2 stimuli, computes the expected Z via a behavioral reference
-- model (Z = A+C when parity(sel1+sel2) is odd, else B+D), and self-checks
-- the DUT output against a reference pipeline delayed by PIPELINE_LATENCY
-- cycles -- so the SAME testbench body works across all architectural
-- variants despite their differing pipeline depth (2 cycles for
-- Baseline/Reordering, 4 cycles for Registering/Reordering & Registering/
-- Isolated Reordering).
--
-- The DUT is instantiated via the generic `dut_if` component; which
-- concrete top-level entity it binds to is resolved by the active
-- `configuration` (one per variant, declared at the end of this file), not
-- hardcoded in the testbench body itself. PIPELINE_LATENCY is a generic,
-- expected to be set per variant via the simulation fileset's `generic`
-- property (see tcl/variants.tcl / select_variant).
--
-- Requires VHDL-2008 (uses std.env.stop and to_hstring); set the file type
-- accordingly in Vivado (see tcl/create_project.tcl).
--
-- NOTE: the exact PIPELINE_LATENCY -> check-window alignment below is
-- reasoned from the pipeline structure of each top_*.vhd, but has not been
-- exercised on an actual simulator. Verify against the first behavioral
-- simulation run and adjust by +-1 cycle if a systematic offset is
-- observed (i.e. every check reports the same fixed mismatch pattern).
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.env.all;

entity tb_top is
    generic (
        PIPELINE_LATENCY : positive := 2;     -- cycles from input capture to Z valid; set per variant
        NUM_TRANSACTIONS  : positive := 200;  -- random stimulus vectors to apply
        CLK_PERIOD        : time     := 10 ns;
        RAND_SEED_1        : positive := 1;
        RAND_SEED_2        : positive := 1
    );
end entity tb_top;

architecture sim of tb_top is

    -- generic DUT interface: matches every top_*.vhd entity's port list
    -- exactly; the concrete binding is resolved by the active
    -- `configuration`, not by this declaration.
    component dut_if is
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
    end component dut_if;

    signal clk        : std_logic := '0';
    signal rst         : std_logic := '1';
    signal a, b, c, d   : std_logic_vector(31 downto 0) := (others => '0');
    signal sel1, sel2   : std_logic_vector(7 downto 0)  := (others => '0');
    signal z            : std_logic_vector(32 downto 0);

    signal sim_done : boolean := false;

    -- reference pipeline: shift register of expected Z values, depth
    -- PIPELINE_LATENCY, self-aligning the check to each variant's latency
    type z_pipeline_t is array (0 to PIPELINE_LATENCY - 1) of std_logic_vector(32 downto 0);
    signal expected_pipeline : z_pipeline_t                         := (others => (others => '0'));
    signal valid_pipeline    : std_logic_vector(0 to PIPELINE_LATENCY - 1) := (others => '0');

    signal check_count : natural := 0;
    signal error_count  : natural := 0;

    -- --------------------------------------------------------------------
    -- rand_slv: generates a pseudo-random std_logic_vector of the given
    -- width, one bit at a time via ieee.math_real.uniform, to avoid the
    -- reduced low-bit entropy of naively scaling a single real draw to a
    -- wide integer range.
    -- --------------------------------------------------------------------
    impure function rand_slv (
        width  : positive;
        seed1  : inout positive;
        seed2  : inout positive
    ) return std_logic_vector is
        variable result : std_logic_vector(width - 1 downto 0);
        variable r      : real;
    begin
        for i in result'range loop
            uniform(seed1, seed2, r);
            if r >= 0.5 then
                result(i) := '1';
            else
                result(i) := '0';
            end if;
        end loop;
        return result;
    end function rand_slv;

    -- --------------------------------------------------------------------
    -- xor_reduce_v: manual XOR-tree reduction, matching parity_check.vhd's
    -- own reference-model logic (kept local, no ieee.std_logic_misc
    -- dependency).
    -- --------------------------------------------------------------------
    function xor_reduce_v (v : std_logic_vector) return std_logic is
        variable parity_v : std_logic := '0';
    begin
        for i in v'range loop
            parity_v := parity_v xor v(i);
        end loop;
        return parity_v;
    end function xor_reduce_v;

begin

    ------------------------------------------------------------------
    -- DUT instance (entity binding resolved by the active
    -- `configuration`)
    ------------------------------------------------------------------
    dut : dut_if
        port map (
            clk => clk, rst => rst,
            a => a, b => b, c => c, d => d,
            sel1 => sel1, sel2 => sel2,
            z => z
        );

    ------------------------------------------------------------------
    -- Clock generation
    ------------------------------------------------------------------
    clk_gen : process is
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process clk_gen;

    ------------------------------------------------------------------
    -- Reset generation: held for the first few cycles
    ------------------------------------------------------------------
    rst_gen : process is
    begin
        rst <= '1';
        wait for CLK_PERIOD * 4;
        rst <= '0';
        wait;
    end process rst_gen;

    ------------------------------------------------------------------
    -- Stimulus + behavioral reference model + expected-value pipeline
    ------------------------------------------------------------------
    stimulus : process is
        variable seed1_v : positive := RAND_SEED_1;
        variable seed2_v : positive := RAND_SEED_2;

        variable a_v, b_v, c_v, d_v : std_logic_vector(31 downto 0);
        variable sel1_v, sel2_v     : std_logic_vector(7 downto 0);

        variable sel_sum_v  : unsigned(8 downto 0);
        variable parity_v   : std_logic;
        variable expected_v : unsigned(32 downto 0);
    begin
        wait until rst = '0';
        wait until rising_edge(clk);

        for i in 1 to NUM_TRANSACTIONS loop

            a_v    := rand_slv(32, seed1_v, seed2_v);
            b_v    := rand_slv(32, seed1_v, seed2_v);
            c_v    := rand_slv(32, seed1_v, seed2_v);
            d_v    := rand_slv(32, seed1_v, seed2_v);
            sel1_v := rand_slv(8, seed1_v, seed2_v);
            sel2_v := rand_slv(8, seed1_v, seed2_v);

            a    <= a_v;
            b    <= b_v;
            c    <= c_v;
            d    <= d_v;
            sel1 <= sel1_v;
            sel2 <= sel2_v;

            -- reference model: Z = A+C when parity(sel1+sel2) is odd
            -- (Z=1), else B+D (mirrors AdderSel + Pattern/parity_check)
            sel_sum_v := resize(unsigned(sel1_v), 9) + resize(unsigned(sel2_v), 9);
            parity_v  := xor_reduce_v(std_logic_vector(sel_sum_v(7 downto 0)));

            if parity_v = '1' then
                expected_v := resize(unsigned(a_v), 33) + resize(unsigned(c_v), 33);
            else
                expected_v := resize(unsigned(b_v), 33) + resize(unsigned(d_v), 33);
            end if;

            expected_pipeline <= std_logic_vector(expected_v) & expected_pipeline(0 to PIPELINE_LATENCY - 2);
            valid_pipeline    <= '1' & valid_pipeline(0 to PIPELINE_LATENCY - 2);

            wait until rising_edge(clk);

        end loop;

        -- drain: let the pipeline flush before ending the simulation
        for i in 1 to PIPELINE_LATENCY + 2 loop
            valid_pipeline <= '0' & valid_pipeline(0 to PIPELINE_LATENCY - 2);
            wait until rising_edge(clk);
        end loop;

        sim_done <= true;

        report "TB_TOP: " & integer'image(check_count) & " checks, " &
               integer'image(error_count) & " errors."
               severity note;

        if error_count = 0 then
            report "TB_TOP: PASS" severity note;
        else
            report "TB_TOP: FAIL" severity error;
        end if;

        std.env.stop;
        wait;
    end process stimulus;

    ------------------------------------------------------------------
    -- Self-checking: compare the DUT output against the oldest
    -- (deepest) entry in the expected-value pipeline, once valid
    ------------------------------------------------------------------
    check : process (clk) is
    begin
        if rising_edge(clk) then
            if valid_pipeline(PIPELINE_LATENCY - 1) = '1' then
                check_count <= check_count + 1;
                if z /= expected_pipeline(PIPELINE_LATENCY - 1) then
                    error_count <= error_count + 1;
                    report "TB_TOP: MISMATCH at check " & integer'image(check_count) &
                           " : expected=" & to_hstring(expected_pipeline(PIPELINE_LATENCY - 1)) &
                           " got=" & to_hstring(z)
                           severity error;
                end if;
            end if;
        end if;
    end process check;

end architecture sim;

--------------------------------------------------------------------------------
-- Configurations: one per architectural variant, binding the `dut`
-- component instance to the concrete top-level entity. Select the active
-- configuration as the simulation top per variant (see
-- tcl/variants.tcl / select_variant), instead of editing this file.
--------------------------------------------------------------------------------

configuration cfg_baseline of tb_top is
    for sim
        for dut : dut_if
            use entity work.top_baseline(rtl);
        end for;
    end for;
end configuration cfg_baseline;

configuration cfg_registering of tb_top is
    for sim
        for dut : dut_if
            use entity work.top_registering(rtl);
        end for;
    end for;
end configuration cfg_registering;

configuration cfg_reordering of tb_top is
    for sim
        for dut : dut_if
            use entity work.top_reordering(rtl);
        end for;
    end for;
end configuration cfg_reordering;

configuration cfg_reordering_registering of tb_top is
    for sim
        for dut : dut_if
            use entity work.top_reordering_registering(rtl);
        end for;
    end for;
end configuration cfg_reordering_registering;

configuration cfg_isolated_reordering of tb_top is
    for sim
        for dut : dut_if
            use entity work.top_isolated_reordering(rtl);
        end for;
    end for;
end configuration cfg_isolated_reordering;
