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
 
    -- Wall of aliens
    constant WALL_Y_T: natural := 0; 
    constant WALL_Y_B: natural := 50;
    

    -- COLOR SIGNALS (used as constants for testing with simple shapes) --
    signal ship_rgb : std_logic_vector(2 downto 0) := YELLOW;
    signal wall_rgb : std_logic_vector(2 downto 0) := BLUE;
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
    constant WALL_STEP: natural := 5; --30;
    constant ROCKET_STEP : natural := 16;
    constant ENEMY_BALL_STEP : unsigned(4 downto 0) := "10000";


    -- ??
    signal pix_x, pix_y : unsigned(9 downto 0) := "0000000000";  
    -- Flags
    signal ship_on, wall_on, game_over, win : std_logic := '0';    

    -- ROCKET
    constant ROCKET_WIDTH: natural := 32; -- 256 -> 8 ALIENS
    constant ROCKET_HEIGHT: natural := 32;

    signal rocket_x : integer := HD/2;
    signal rocket_y : integer := VD - ROCKET_HEIGHT;

    signal rocket_on: std_logic := '0';

    signal row_rocket_address: natural := 0;
    signal col_rocket_address: natural := 0;


    -- 3rd level aliens are at the bottom (64px below master coord)
    constant OFFSET: integer := 64;
    
    -- Enemy Ball
    constant EB_WIDTH: integer := 640; -- 256 -> 8 ALIENS
    constant EB_HEIGHT: integer := 32;
    signal enemy_ball_addr: std_logic_vector(9 downto 0) := "0000000000";
    signal row_enemy_ball_address, col_enemy_ball_address: std_logic_vector(4 downto 0) := "00000";
    signal enemy_ball_on: std_logic := '0';
    -- master chords (them would be an input)
    signal enemy_ball_master_coord_x: unsigned (9 downto 0) := "0000000000"; 
    signal enemy_ball_master_coord_y: unsigned (9 downto 0) := "0000000000";

    signal frame_counter : natural := 0;

    -- INTERNAL CLOCKS
    signal update_clk : std_logic := '0';
    signal frame_clk : std_logic := '0';

    -- FLAGS
    signal rocket_fired : std_logic := '0';

    begin
       
        enemy_ball:entity work.enemy_ball_rom(content) port map(
            alien_addr => enemy_ball_addr,
            data => enemy_ball_rgb
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

        game_proc: process(update_clk, row, col, up, down, left, right, mid)

            variable wall_offset : integer := 0;
            variable enemy_ball_offset_x : unsigned (9 downto 0) := "0000000000";
            variable enemy_ball_offset_y : unsigned (9 downto 0) := "0000000000";

        begin

            if rising_edge(update_clk) then

                -- changing ship_offset by reading the hit flags. wall_offset change too.
                enemy_ball_offset_y := enemy_ball_offset_y + ENEMY_BALL_STEP;
                wall_offset := wall_offset + WALL_STEP;

                

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

            pix_y <= to_unsigned(row, 10); 
            pix_x <= to_unsigned(col, 10);

            ship_on  <= '0';
            wall_on <= '0';
            game_over <= '0';
            win <= '0';

            -- Set flags to decide what to draw on screen
            -- activation boundaries for the ship
            -- One boundary should probably be <, not <=
            if (col >= ship_x - SHIP_WIDTH/2) and (col <= ship_x + SHIP_WIDTH/2) and (row >= ship_y - SHIP_HEIGHT/2) and (row <= ship_y + SHIP_HEIGHT/2) then
                ship_on <= '1';
            end if; 
                    
            if (row >= WALL_Y_T + wall_offset) and (row <= WALL_Y_B + wall_offset) then
                wall_on <= '1';
            end if;

            -- game over if the wall touch the top of the ship
            if (WALL_Y_B + wall_offset >= ship_y + SHIP_HEIGHT/2) or (ship_y + SHIP_HEIGHT/2 <= enemy_ball_master_coord_y + OFFSET + EB_HEIGHT + enemy_ball_offset_y) then
                game_over <= '1';
            end if;

            if (rocket_y <= enemy_ball_master_coord_y + OFFSET + EB_HEIGHT + enemy_ball_offset_y) then
                win <= '1';
            end if;

            -- rocket enable boundaries
            if (col >= rocket_x - ROCKET_WIDTH/2) and (col < rocket_x + ROCKET_WIDTH/2) 
               and (row >= rocket_y - ROCKET_HEIGHT/2) and (row < rocket_y + ROCKET_HEIGHT/2) then
                rocket_on <= '1';
            else
                rocket_on <= '0';
            end if;

            -- Compute px coordinate inside ROM
            row_rocket_address <= row - (rocket_y - ROCKET_HEIGHT/2); 
            col_rocket_address <= col - (rocket_x - ROCKET_WIDTH/2);
            
             -- ENEMY BALL enable boundaries
            if (col >= enemy_ball_master_coord_x + enemy_ball_offset_x) and (col < enemy_ball_master_coord_x + EB_WIDTH + enemy_ball_offset_x) 
            and (row >= enemy_ball_master_coord_y + OFFSET + enemy_ball_offset_y) and (row < enemy_ball_master_coord_y + OFFSET + EB_HEIGHT + enemy_ball_offset_y) then
                enemy_ball_on <= '1';
            else
                enemy_ball_on <= '0';
            end if;

            -- calculate address of px of rom
            row_enemy_ball_address <= std_logic_vector( pix_y(4 downto 0) - enemy_ball_master_coord_y(4 downto 0) - enemy_ball_offset_y(4 downto 0) ) ; --- rocket_master_coord_y(4 downto 0);
            col_enemy_ball_address <= std_logic_vector( pix_x(4 downto 0) - enemy_ball_master_coord_y(4 downto 0) - enemy_ball_offset_x(4 downto 0) ) ; -- - rocket_master_coord_x(4 downto 0);
            enemy_ball_addr <= row_enemy_ball_address & col_enemy_ball_address;


            -- priority encoder
            if ship_on = '1' then 
                graph_rgb <= ship_rgb;
            elsif wall_on = '1' then
                graph_rgb <= wall_rgb;
            elsif rocket_on = '1' then
                graph_rgb <= rocket_rgb;
            elsif enemy_ball_on = '1' then
                graph_rgb <= enemy_ball_rgb;
            elsif game_over = '1' then
                graph_rgb <= gameover_rgb;
            elsif win = '1' then
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
