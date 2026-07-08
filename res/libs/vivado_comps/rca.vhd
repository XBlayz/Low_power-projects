--------------------------------------------------------------------------------
-- Ripple Carry Adder (RCA), generic width
--
-- Structural N-bit Ripple Carry Adder built as a chain of `WIDTH` instances
-- of `full_adder`, with the carry-out of stage `i` feeding the carry-in of
-- stage `i+1`. Instantiated as RCA8 (WIDTH => 8, for sel1 + sel2) and RCA32
-- (WIDTH => 32, for the 32-bit operand additions).
--
-- The result is WIDTH+1 bits wide (sum(WIDTH-1 downto 0) & final carry-out)
-- to accommodate the overflow bit, matching the reference circuit's 33-bit
-- output register for the 32-bit case.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity rca is
    generic (
        WIDTH : positive := 32
    );
    port (
        a   : in  std_logic_vector(WIDTH - 1 downto 0);
        b   : in  std_logic_vector(WIDTH - 1 downto 0);
        sum : out std_logic_vector(WIDTH downto 0)  -- WIDTH downto 0: includes carry-out
    );
end entity rca;

architecture structural of rca is

    component full_adder is
        port (
            a    : in  std_logic;
            b    : in  std_logic;
            cin  : in  std_logic;
            sum  : out std_logic;
            cout : out std_logic
        );
    end component full_adder;

    signal carry_chain : std_logic_vector(WIDTH downto 0);  -- carry_chain(0) = cin of stage 0

begin

    carry_chain(0) <= '0';  -- no external carry-in

    adder_chain : for i in 0 to WIDTH - 1 generate
    begin

        stage_i : full_adder
            port map (
                a    => a(i),
                b    => b(i),
                cin  => carry_chain(i),
                sum  => sum(i),
                cout => carry_chain(i + 1)
            );

    end generate adder_chain;

    sum(WIDTH) <= carry_chain(WIDTH);  -- final carry-out is the MSB of the result

end architecture structural;
