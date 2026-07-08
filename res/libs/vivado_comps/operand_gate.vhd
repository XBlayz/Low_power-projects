--------------------------------------------------------------------------------
-- Operand Gate (Gated Input), generic width
--
-- Operand isolation block: passes `d` through unchanged when `gate` = '1',
-- forces the output to all-zeros when `gate` = '0'. Used in the Isolated
-- Reordering variant to freeze the operands feeding the non-selected adder
-- branch, preventing its ripple-carry chain from toggling on operand
-- transitions that will not be selected this cycle.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity operand_gate is
    generic (
        WIDTH : positive := 32
    );
    port (
        d    : in  std_logic_vector(WIDTH - 1 downto 0);
        gate : in  std_logic;  -- '1' passes d through, '0' forces all-zeros
        q    : out std_logic_vector(WIDTH - 1 downto 0)
    );
end entity operand_gate;

architecture rtl of operand_gate is
begin

    q <= d when gate = '1' else (others => '0');

end architecture rtl;
