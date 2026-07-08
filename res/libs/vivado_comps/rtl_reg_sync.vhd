--------------------------------------------------------------------------------
-- Synchronous Register (RTL_REG_SYNC), generic width
--
-- Generic WIDTH-bit register with asynchronous, active-high reset and an
-- optional clock-enable (`ce`, defaults to '1' = always enabled). Used for
-- every pipeline/register stage across all architectural variants
-- (operand registers, selection-signal registers, output register).
--
-- `ce` defaults to '1' so every pre-existing instantiation (without a `ce`
-- port map) is unaffected; only the Isolated Reordering variant (STEP 6)
-- explicitly maps `ce` to gate the non-selected branch's result register.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity rtl_reg_sync is
    generic (
        WIDTH : positive := 32
    );
    port (
        clk : in  std_logic;
        rst : in  std_logic;  -- asynchronous, active-high
        ce  : in  std_logic := '1';  -- clock enable, active-high, default always-enabled
        d   : in  std_logic_vector(WIDTH - 1 downto 0);
        q   : out std_logic_vector(WIDTH - 1 downto 0)
    );
end entity rtl_reg_sync;

architecture rtl of rtl_reg_sync is
begin

    process (clk, rst) is
    begin
        if rst = '1' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            if ce = '1' then
                q <= d;
            end if;
        end if;
    end process;

end architecture rtl;
