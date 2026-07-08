--------------------------------------------------------------------------------
-- Parity Check
--
-- XOR-tree reducing the input vector to a single parity bit. Fed by the
-- 8-bit sum of sel1 + sel2 (RCA8 output, LSBs only): z = '1' when the sum is
-- odd (selects operands A, C), z = '0' when the sum is even (selects
-- operands B, D).
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity parity_check is
    generic (
        WIDTH : positive := 8
    );
    port (
        a : in  std_logic_vector(WIDTH - 1 downto 0);
        z : out std_logic
    );
end entity parity_check;

architecture rtl of parity_check is
begin

    process (a) is
        variable parity_v : std_logic;
    begin
        parity_v := '0';
        for i in a'range loop
            parity_v := parity_v xor a(i);
        end loop;
        z <= parity_v;
    end process;

end architecture rtl;
