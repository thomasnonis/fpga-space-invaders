library ieee;
use ieee.std_logic_1164.all;

entity Top is
    Port (
        r : out std_logic_vector(3 downto 0);
        g : out std_logic_vector(3 downto 0);
        b : out std_logic_vector(3 downto 0);
        h_sync : out std_logic;
        v_sync : out std_logic;
        px_clk : buffer std_logic
    );
end Top;

architecture Behavioral of Top is

    constant refresh_rate : real := 60.0;

    signal reset : std_logic := '1';

    signal display_enable : std_logic; 

    signal col : natural;
    signal row : natural;

begin

    VGA_Controller : entity work.VGA_controller
        Port map (
            clk => px_clk,
            reset => reset,
            h_sync => h_sync,
            v_sync => v_sync,
            pixel_clk => px_clk,
            video_on => display_enable,
            col => col,
            row => row
        );

    
    image : entity work.graph
        Port map(
            r => r,
            g => g,
            b => b,
            video_on => display_enable,
            col => col,
            row => row
        );

end Behavioral;
