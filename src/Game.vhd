library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Game is
    generic (
        HD  : unsigned(9 downto 0) := to_unsigned(640, 10);  -- horizontal size
        VD  : unsigned(9 downto 0) := to_unsigned(480, 10)   -- vertical size
    );
    port (
        px_clk : in std_logic;
        display_enable  :  in   std_logic;  -- display enable ('1' = display time, '0' = blanking time)
        row       :  in   unsigned(9 downto 0);  -- row pixel coordinate
        col       :  in   unsigned(9 downto 0);  -- column pixel coordinate
        down, left, right : in std_logic;
        r         :  out  std_logic_vector(3 downto 0) := (others => '0');  -- red magnitude output
        g         :  out  std_logic_vector(3 downto 0) := (others => '0');  -- green magnitude output
        b         :  out  std_logic_vector(3 downto 0) := (others => '0')   -- blue magnitude output
    );
end Game;

architecture behavioral of Game is

    -- COLOR CONSTANTS
    constant RED : std_logic_vector(2 downto 0) := "100";
    constant GREEN : std_logic_vector(2 downto 0) := "010";
    constant BLUE : std_logic_vector(2 downto 0) := "001";
    constant CYAN : std_logic_vector(2 downto 0) := "011";
    constant MAGENTA : std_logic_vector(2 downto 0) := "101";
    constant YELLOW : std_logic_vector(2 downto 0) := "110";
    constant BLACK : std_logic_vector(2 downto 0) := "000";
    constant WHITE : std_logic_vector(2 downto 0) := "111";

    -- GAME STATUS
    type status_type is (RUNNING, GAMEOVER, WIN);

    signal status : status_type := RUNNING;
    signal gameover_rgb : std_logic_vector(2 downto 0) := RED;
    signal win_rgb : std_logic_vector(2 downto 0) := GREEN;

    -- SHIP
    constant SHIP_WIDTH : unsigned(9 downto 0) := "0000100000";
    constant SHIP_HEIGHT : unsigned(9 downto 0) := "0000100000";
    constant SHIP_STEP: unsigned(9 downto 0) := "0000001010";

    signal ship_x : unsigned(9 downto 0) := shift_right(HD, 1);
    signal ship_y : unsigned(9 downto 0) := VD - SHIP_HEIGHT;
    signal row_ship_address: unsigned(4 downto 0) := "00000";
    signal col_ship_address: unsigned(4 downto 0) := "00000";
    signal ship_on : std_logic := '0';  
    signal ship_rgb : std_logic_vector(2 downto 0);   

    -- ROCKET
    constant ROCKET_WIDTH: unsigned(9 downto 0) := "0000100000";
    constant ROCKET_HEIGHT: unsigned(9 downto 0) := "0000100000";
    constant ROCKET_STEP : unsigned(9 downto 0) := "0000010000";

    signal rocket_x : unsigned(9 downto 0) := shift_right(HD, 1);
    signal rocket_y : unsigned(9 downto 0) := VD - ROCKET_HEIGHT;
    signal rocket_on: std_logic := '0';
    signal rocket_rgb : std_logic_vector(2 downto 0);
    signal row_rocket_address: unsigned(4 downto 0) := "00000";
    signal col_rocket_address: unsigned(4 downto 0) := "00000";
   
    -- ENEMY
    constant EB_WIDTH: unsigned(9 downto 0) := HD;
    constant EB_HEIGHT: unsigned(9 downto 0) := "0000100000";
    constant enemy_STEP : unsigned(9 downto 0) := "0000010000";

    signal enemy_x : unsigned(9 downto 0) := shift_right(HD, 1);
    signal enemy_y : unsigned(9 downto 0) := shift_right(EB_HEIGHT, 1);
    signal row_enemy_address: unsigned(4 downto 0) := "00000";
    signal col_enemy_address: unsigned(4 downto 0) := "00000";
    signal enemy_on: std_logic := '0';
    signal enemy_rgb : std_logic_vector(2 downto 0);
    
    -- INTERNAL RGB
    signal graph_rgb : std_logic_vector(2 downto 0) := BLACK;

    begin
       
        enemy: entity work.Rom(EnemyBall) port map(
            row => row_enemy_address,
            col => col_enemy_address,
            rgb => enemy_rgb
        );

        rocket: entity work.Rom(Rocket) port map(
            row => row_rocket_address,
            col => col_rocket_address,
            rgb => rocket_rgb
        );

        ship: entity work.Rom(Ship) port map(
            row => row_ship_address,
            col => col_ship_address,
            rgb => ship_rgb
        );


        game_proc: process(px_clk, row, col, down, left, right)
        
            variable n : unsigned(4 downto 0) := to_unsigned(0, 5);

        begin

            if rising_edge(px_clk) then
                -- Faster response for GUI
                if col = to_unsigned(0, 10) and row = to_unsigned(0, 10) then

                    if n(0) = '0' then --even
                
                        if down = '1' then
                            enemy_y <= shift_right(EB_HEIGHT, 1);
                            ship_x <= HD/2;
                            status <= RUNNING;
                        end if;

                        if left = '1' and ship_x - shift_right(SHIP_WIDTH, 1) > to_unsigned(15, 10) then
                            ship_x <= ship_x - SHIP_STEP;
                        elsif right = '1' and ship_x + shift_right(SHIP_WIDTH, 1) < HD - to_unsigned(15, 10) then
                            ship_x <= ship_x + SHIP_STEP;
                        end if;

                    end if;

                    n := n + 1;


                    -- update enemy position every 16 frames
                    if n = to_unsigned(0, 5) and status = RUNNING then                
                        enemy_y <= enemy_y + enemy_STEP;                
                    end if;   

                end if;
            
                -- Set ship canvas
                if (col >= ship_x - shift_right(SHIP_WIDTH, 1)) and (col <= ship_x + shift_right(SHIP_WIDTH, 1)) and (row >= ship_y - shift_right(SHIP_HEIGHT, 1)) and (row <= ship_y + shift_right(SHIP_HEIGHT, 1)) then
                    ship_on <= '1';
                else
                    ship_on <= '0';
                end if;
                
                -- Set enemy canvas
                if (((col < to_unsigned(32*10, 10)) or (col >= HD-to_unsigned(32*6, 10))) and (row >= enemy_y - EB_HEIGHT/2) and (row < enemy_y + EB_HEIGHT/2))
                    or (((col >= 32*7) and (col < to_unsigned(32*7 + 32*5, 10))) and (row >= enemy_y - to_unsigned(32*5, 10) - EB_HEIGHT/2) and (row < enemy_y - to_unsigned(32*5, 10) + EB_HEIGHT/2))
                    or ((((col > to_unsigned(32*2, 10)) and (col <= to_unsigned(32*5, 10))) or (col > HD-to_unsigned(32*8, 10) and col <= HD-(32*1))) and (row >= enemy_y - to_unsigned(32*5+32*3, 10) - EB_HEIGHT/2) and (row < enemy_y - to_unsigned(32*5+32*3, 10) + EB_HEIGHT/2)) then
                    enemy_on <= '1';
                else
                    enemy_on <= '0';
                end if;

                -- Compute px coordinate of ship inside ROM
                row_ship_address <= row(4 downto 0) - (ship_y(4 downto 0) - shift_right(SHIP_HEIGHT, 1)(4 downto 0));
                col_ship_address <= col(4 downto 0) - (ship_x(4 downto 0) - shift_right(SHIP_WIDTH, 1)(4 downto 0));

                -- Compute px coordinate of enemy ball inside ROM
                row_enemy_address <= row(4 downto 0) - (enemy_y(4 downto 0) - shift_right(EB_HEIGHT, 1)(4 downto 0)); 
                col_enemy_address <= col(4 downto 0) - (enemy_x(4 downto 0) - shift_right(EB_WIDTH, 1)(4 downto 0));

                if ship_on = '1' and enemy_on = '1' then
                    status <= GAMEOVER;
                elsif enemy_y > to_unsigned(32*5+32*3, 10) + EB_HEIGHT/2 + VD then
                    status <= WIN;
                end if;

                -- Set z axis order
                if ship_on = '1' and ship_rgb /= "000" then 
                    -- poor man's alpha channel
                    graph_rgb <= ship_rgb;
                elsif rocket_on = '1' and rocket_rgb /= "000" then
                    -- poor man's alpha channel
                    graph_rgb <= rocket_rgb;
                elsif enemy_on = '1' and enemy_rgb /= "000" then
                    -- poor man's alpha channel
                    graph_rgb <= enemy_rgb;
                elsif status = GAMEOVER then
                    graph_rgb <= gameover_rgb;
                elsif status = WIN then
                    graph_rgb <= win_rgb;
                else
                    -- background
                    graph_rgb <= BLACK;
                end if;

            end if; -- rising_edge(px_clk)

        end process;

        r <= (others => graph_rgb(2)) when display_enable = '1' else (others => '0'); 
        g <= (others => graph_rgb(1)) when display_enable = '1' else (others => '0');
        b <= (others => graph_rgb(0)) when display_enable = '1' else (others => '0');

        

end architecture;