--------------------------------------------------------------------------------
-- Full Adder (1-bit)
--
-- Structural building block for the Ripple Carry Adder (RCA). Combinational,
-- single-bit adder with carry-in and carry-out, chained by `rca_gen` to build
-- an N-bit ripple carry adder.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity full_adder is
    port (
        a    : in  std_logic;  -- addend bit
        b    : in  std_logic;  -- addend bit
        cin  : in  std_logic;  -- carry-in
        sum  : out std_logic;  -- sum bit
        cout : out std_logic   -- carry-out
    );
end entity full_adder;

architecture rtl of full_adder is
begin

    sum  <= a xor b xor cin;
    cout <= (a and b) or (cin and (a xor b));

end architecture rtl;
