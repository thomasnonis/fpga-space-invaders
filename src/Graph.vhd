-- Object-Mapped Pixel Generation Circuit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity graph is
    generic (
        HD  : natural := 640;  -- horizontal display (active video area)
        VD  : natural := 480   -- vertical display
    );
    port (
        px_clk : in std_logic;
        display_enable  :  in   std_logic;  -- display enable ('1' = display time, '0' = blanking time)
        row       :  in   natural;    -- row pixel coordinate
        col       :  in   natural;    -- column pixel coordinate
        up, down, left, right, mid : in std_logic;
        r         :  out  std_logic_vector(3 downto 0) := (others => '0');  -- red magnitude output to dac
        g         :  out  std_logic_vector(3 downto 0) := (others => '0');  -- green magnitude output to dac
        b         :  out  std_logic_vector(3 downto 0) := (others => '0')   -- blue magnitude output to dac
    );
end graph;

architecture behavioral of graph is

    type status_type is (RUNNING, GAMEOVER, WIN);
    signal status : status_type := RUNNING;

    -- Color constants definition
    constant RED : std_logic_vector(2 downto 0) := "100";
    constant GREEN : std_logic_vector(2 downto 0) := "010";
    constant BLUE : std_logic_vector(2 downto 0) := "001";
    constant CYAN : std_logic_vector(2 downto 0) := "011";
    constant MAGENTA : std_logic_vector(2 downto 0) := "101";
    constant YELLOW : std_logic_vector(2 downto 0) := "110";
    constant BLACK : std_logic_vector(2 downto 0) := "000";
    constant WHITE : std_logic_vector(2 downto 0) := "111";

    constant every_n_frames : natural := 180;

    -- SIZE AND BOUNDARY OF THE OBJECTS --

    -- SHIP
    constant SHIP_WIDTH : natural := 40;
    constant SHIP_HEIGHT : natural := 40;

    signal ship_x : integer := HD/2;
    signal ship_y : integer := VD - SHIP_HEIGHT;
    

    -- COLOR SIGNALS (used as constants for testing with simple shapes) --
    signal ship_rgb : std_logic_vector(2 downto 0) := YELLOW;
    signal ball_rgb : std_logic_vector(2 downto 0) := MAGENTA;
    signal gameover_rgb : std_logic_vector(2 downto 0) := RED;
    signal win_rgb : std_logic_vector(2 downto 0) := GREEN;
    signal rocket_rgb : std_logic_vector(2 downto 0);
    signal enemy_ball_rgb : std_logic_vector(2 downto 0);
    -- main signal for px color
    signal graph_rgb : std_logic_vector(2 downto 0) := BLACK;


    -- STEPS --
    -- Step for each movement of ship
    constant SHIP_STEP: natural := 10; --30
    constant ROCKET_STEP : natural := 16;
    constant ENEMY_BALL_STEP : natural := 16;


    -- Flags
    signal ship_on : std_logic := '0';    

    -- ROCKET
    constant ROCKET_WIDTH: natural := 32; -- 256 -> 8 ALIENS
    constant ROCKET_HEIGHT: natural := 32;

    signal rocket_x : integer := HD/2;
    signal rocket_y : integer := VD - ROCKET_HEIGHT;

    signal rocket_on: std_logic := '0';

    signal row_rocket_address: natural := 0;
    signal col_rocket_address: natural := 0;
   
    -- Enemy Ball
    constant EB_WIDTH: integer := HD;
    constant EB_HEIGHT: integer := 32;

    signal enemy_ball_x : integer := HD/2;
    signal enemy_ball_y : integer := EB_HEIGHT/2;

    signal row_enemy_ball_address: natural := 0;
    signal col_enemy_ball_address: natural := 0;

    signal enemy_ball_on: std_logic := '0';


    signal frame_counter : natural := 0;

    -- INTERNAL CLOCKS
    signal update_clk : std_logic := '0';
    signal frame_clk : std_logic := '0';

    -- FLAGS
    signal rocket_fired : std_logic := '0';

    begin
       
        enemy_ball: entity work.Rom(EnemyBall) port map(
            row => row_enemy_ball_address,
            col => col_enemy_ball_address,
            rgb => enemy_ball_rgb
        );

        rocket: entity work.Rom(Rocket) port map(
            row => row_rocket_address,
            col => col_rocket_address,
            rgb => rocket_rgb
        );

        internal_clk_proc: process (px_clk, col, row) is

            variable n : natural := 0;

        begin

            if rising_edge(px_clk) then

                if col = 0 and row = 0 then
                    frame_clk <= not frame_clk;
                    n := n + 1;
                end if;

                if n > 15 then
                    n := 0;
                    update_clk <= not update_clk;
                end if;

            end if;

        end process;

        game_proc: process(update_clk, row, col, up, down, left, right, mid) begin

            if rising_edge(update_clk) then

                enemy_ball_y <= enemy_ball_y + ENEMY_BALL_STEP;                

                -- if rocket is launched, move upwards
                -- if rocket_fired = '1' then
                    rocket_y <= rocket_y - ROCKET_STEP;
                -- end if;

                -- if rocket reaches top allow new rocket to be launched
                -- if rocket_y + ROCKET_HEIGHT/2 <= 0 then
                --     rocket_fired <= '0';
                -- end if;
                
            end if;

            -- Faster response for GUI
            if rising_edge(frame_clk) then

                if left = '1' and ship_x - SHIP_WIDTH/2 > 0 then

                    ship_x <= ship_x - SHIP_STEP;

                elsif right = '1' and ship_x + SHIP_WIDTH/2 < HD - 1 then

                    ship_x <= ship_x + SHIP_STEP;

                end if;
                
                -- Separated if so that it can be fired whilst moving the ship
                if up = '1' then

                    -- if rocket_fired = '0' then
                        rocket_x <= ship_x;
                        rocket_y <= ship_y;
                    --     rocket_fired <= '1';
                    -- end if;
                    
                end if;

            end if;

            ship_on  <= '0';

            -- Set flags to decide what to draw on screen
            -- activation boundaries for the ship
            -- One boundary should probably be <, not <=
            if (col >= ship_x - SHIP_WIDTH/2) and (col <= ship_x + SHIP_WIDTH/2) and (row >= ship_y - SHIP_HEIGHT/2) and (row <= ship_y + SHIP_HEIGHT/2) then
                ship_on <= '1';
            end if;

            -- game over if the enemies touch the top of the ship
            if (ship_y + SHIP_HEIGHT/2 <= enemy_ball_y - EB_HEIGHT/2) then -- likely need to change conditions
                status <= GAMEOVER;
            end if;

            -- will probably need to fix condition
            if (rocket_y <= enemy_ball_y) then
                status <= WIN;
            end if;

            -- rocket enable boundaries
            if (col >= rocket_x - ROCKET_WIDTH/2) and (col < rocket_x + ROCKET_WIDTH/2) and (row >= rocket_y - ROCKET_HEIGHT/2) and (row < rocket_y + ROCKET_HEIGHT/2) then
                rocket_on <= '1';
            else
                rocket_on <= '0';
            end if;

            -- Compute px coordinate inside ROM
            row_rocket_address <= row - (rocket_y - ROCKET_HEIGHT/2); 
            col_rocket_address <= col - (rocket_x - ROCKET_WIDTH/2);
            
             -- ENEMY BALL enable boundaries
            if (col >= enemy_ball_x - EB_WIDTH/2) and (col < enemy_ball_x + EB_WIDTH/2) and (row >= enemy_ball_y - EB_HEIGHT/2) and (row < enemy_ball_y + EB_HEIGHT/2) then
                enemy_ball_on <= '1';
            else
                enemy_ball_on <= '0';
            end if;

            -- Compute px coordinate inside ROM
            row_enemy_ball_address <= row - (enemy_ball_y - EB_HEIGHT/2); 
            col_enemy_ball_address <= col - (enemy_ball_x - EB_WIDTH/2);

            -- priority encoder
            if ship_on = '1' then 
                graph_rgb <= ship_rgb;
            elsif rocket_on = '1' then
                graph_rgb <= rocket_rgb;
            elsif enemy_ball_on = '1' then
                graph_rgb <= enemy_ball_rgb;
            elsif status = GAMEOVER then
                graph_rgb <= gameover_rgb;
            elsif status = WIN then
                graph_rgb <= win_rgb;
            else
                graph_rgb <= BLACK; -- background
            end if;

            -- if left = '1' then
            --     graph_rgb <= WHITE;
            -- end if;

        end process;

        r <= (others => graph_rgb(2)) when display_enable = '1' else (others => '0'); 
        g <= (others => graph_rgb(1)) when display_enable = '1' else (others => '0');
        b <= (others => graph_rgb(0)) when display_enable = '1' else (others => '0');

        

end architecture;
