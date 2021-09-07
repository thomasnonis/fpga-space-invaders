library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity Top is
    Port (
        sys_clk : in std_logic;
        btn_down : in std_logic;
        btn_left : in std_logic;
        btn_right : in std_logic;
        r : out std_logic_vector(3 downto 0);
        g : out std_logic_vector(3 downto 0);
        b : out std_logic_vector(3 downto 0);
        h_sync : out std_logic;
        v_sync : out std_logic
    );
end Top;

architecture Behavioral of Top is

    signal reset : std_logic := '1';
    signal px_clk : std_logic := '1';
    signal display_enable : std_logic; 
    signal col : unsigned(9 downto 0);
    signal row : unsigned(9 downto 0);

begin

    clk_gen : entity work.clk_wiz_0 Port map (sys_clk => sys_clk, px_clk => px_clk); -- 100 MHz -> 25 MHz

    VGA_Controller : entity work.VGA_controller
        Port map (
            px_clk => px_clk,
            reset => reset,
            h_sync => h_sync,
            v_sync => v_sync,
            display_enable => display_enable,
            col => col, 
            row => row  
        );

    
    image : entity work.Game
        Port map(
            px_clk => px_clk,
            display_enable => display_enable,
            row => row,
            col => col,
            down => btn_down,
            left => btn_left,
            right => btn_right,
            r => r,
            g => g,
            b => b
        );

end Behavioral;
