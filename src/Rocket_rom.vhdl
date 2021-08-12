library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;

entity rocket_rom is
    port(
        rocket_addr: in std_logic_vector(9 downto 0); -- row
        data: out std_logic_vector(2 downto 0) -- rgb value
    );
end rocket_rom;

architecture content of rocket_rom is
    type rgb_array is array(0 to 31) of std_logic_vector(2 downto 0); -- 32 rgb value for each column of the row
    type rom_type is array(0 to 31) of rgb_array; -- array wich contains all rgb value of every row

    signal rgb_row: rgb_array;

    constant rocket: rom_type :=
    (
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "010", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "101", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "101", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "101", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "101", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "101", "101", "101", "101", "101", "101", "101", "101", "101", "101", "101", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "101", "101", "001", "001", "001", "001", "001", "101", "101", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "101", "101", "001", "001", "001", "001", "001", "101", "101", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "101", "101", "001", "001", "001", "001", "001", "101", "101", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "101", "100", "100", "101", "101", "001", "001", "001", "001", "001", "101", "101", "100", "100", "101", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "101", "100", "101", "101", "001", "001", "001", "001", "001", "101", "101", "100", "101", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "101", "101", "101", "101", "101", "101", "101", "101", "101", "101", "101", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "000", "000", "000", "000"),
        ("000", "000", "000", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "000", "000") 
    );
begin
    rgb_row <= rocket(to_integer(unsigned(rocket_addr(9 downto 5)))); -- 5 bit to obtain 32x32 (takes the n row)
    data <= rgb_row(to_integer(unsigned(rocket_addr(4 downto 0))));  -- takes the 3 bit value of the column
end content;