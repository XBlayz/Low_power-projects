--------------------------------------------------------------------------------
-- 2-to-1 Multiplexer, generic width
--
-- Selects between two WIDTH-bit inputs based on `sel`. Instantiated as
-- MUX_AB / MUX_CD (32-bit operand selection, Baseline/Registering variants)
-- and as MUX_SUM (33-bit result selection, Reordering variants).
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity mux2 is
    generic (
        WIDTH : positive := 32
    );
    port (
        a   : in  std_logic_vector(WIDTH - 1 downto 0);
        b   : in  std_logic_vector(WIDTH - 1 downto 0);
        sel : in  std_logic;  -- '1' selects a, '0' selects b
        z   : out std_logic_vector(WIDTH - 1 downto 0)
    );
end entity mux2;

architecture rtl of mux2 is
begin

    z <= a when sel = '1' else b;

end architecture rtl;
