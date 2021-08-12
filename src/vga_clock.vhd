library IEEE;
use IEEE.std_logic_1164.all;

-- abstraction over Xilinx's implementation

entity vga_clock is
port (
    clock_in: in std_logic;
    clock_out: out std_logic
);
end vga_clock;

architecture Behavioral of vga_clock is
begin
    process begin
        clock_out <= '1';
        wait for 3.367 ns;
        clock_out <= '0';
        wait for 3.367 ns;
    end process;
end Behavioral;