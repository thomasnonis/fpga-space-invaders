library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity Top is
    Port (
        sys_clk : in std_logic;
        btn_up : in std_logic;
        btn_down : in std_logic;
        btn_left : in std_logic;
        btn_right : in std_logic;
        btn_mid : in std_logic;
        r : out std_logic_vector(3 downto 0);
        g : out std_logic_vector(3 downto 0);
        b : out std_logic_vector(3 downto 0);
        h_sync : out std_logic;
        v_sync : out std_logic;
        led : out std_logic_vector(7 downto 0)
    );
end Top;

architecture Behavioral of Top is

    signal reset : std_logic := '1';
    signal px_clk : std_logic := '1';
    signal display_enable : std_logic; 
    signal col : unsigned(9 downto 0);
    signal row : unsigned(9 downto 0);
    signal up, down, left, right, mid : std_logic;

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

    
    image : entity work.Graph
        Port map(
            px_clk => px_clk,
            display_enable => display_enable,
            row => row,
            col => col,
            up => up,
            down => down,
            left => left,
            right => right,
            mid => mid,
            r => r,
            g => g,
            b => b
        );

    -- TODO change sys_clk to px_clk
    up_db: entity work.Debouncer(bypass) Port map ( -- Why bypass instead of behavioral?
        clk => sys_clk,
        reset => '1',
        btn_in => btn_up,
        btn_out => up
    );

    down_db: entity work.Debouncer(bypass) Port map (
        clk => sys_clk,
        reset => '1',
        btn_in => btn_down,
        btn_out => down
    );

    left_db: entity work.Debouncer(bypass) Port map (
        clk => sys_clk,
        reset => '1',
        btn_in => btn_left,
        btn_out => left
    );

    right_db: entity work.Debouncer(bypass) Port map (
        clk => sys_clk,
        reset => '1',
        btn_in => btn_right,
        btn_out => right
    );

    mid_db: entity work.Debouncer(bypass) Port map (
        clk => sys_clk,
        reset => '1',
        btn_in => btn_mid,
        btn_out => mid
    );

    led <= up & down & left & right & mid & "000";
    
    -- clk_sim: process begin
    --     px_clk <= not px_clk;
    --     wait for 20 ns;
    -- end process;

end Behavioral;
