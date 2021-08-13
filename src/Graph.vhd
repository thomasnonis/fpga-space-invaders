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

    constant every_n_frames : natural := 60;

    -- SIZE AND BOUNDARY OF THE OBJECTS --

    -- SHIP
    constant SHIP_WIDTH : natural := 40;
    constant SHIP_HEIGHT : natural := 40;
    -- Left boundary of ship intialized at center - half width
    constant SHIP_X_L :  natural := HD/2 - SHIP_WIDTH/2;
    -- Right boundary of ship intialized at center + half width
    constant SHIP_X_R :  natural := HD/2 + SHIP_WIDTH/2; 
    -- Bottom boundary of ship initialized at bottom of screen - 20
    constant SHIP_Y_B: integer := VD - 20;  
    -- Top boundary of ship initialized at desired height with respect to bottom
    constant SHIP_Y_T: integer := SHIP_Y_B - SHIP_HEIGHT;
 
    -- Wall of aliens
    constant WALL_Y_T: natural := 0; 
    constant WALL_Y_B: natural := 50;
    

    -- COLOR SIGNALS (used as constants for testing with simple shapes) --
    signal ship_rgb : std_logic_vector(2 downto 0) := GREEN;
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
    constant ROCKET_STEP : unsigned(4 downto 0) := "10000"; --32
    constant ENEMY_BALL_STEP : unsigned(4 downto 0) := "10000"; --32


    -- ??
    signal pix_x, pix_y : unsigned(9 downto 0) := "0000000000";  
    -- Flags
    signal ship_on, wall_on, game_over, win : std_logic := '0';    

    -- ROCKET CODE
    -- width of the alien area (8 * 32)
    constant ROCKET_WIDTH: integer := 32; -- 256 -> 8 ALIENS
    constant ROCKET_HEIGHT: integer := 32;
    signal rocket_on: std_logic := '0';
    -- alien_address is made of row and column adresses
    -- alien_addr <= (row_alien_address & col_alien_address);
    signal rocket_addr: std_logic_vector(9 downto 0) := "0000000000";
    signal row_rocket_address, col_rocket_address: std_logic_vector(4 downto 0) := "00000";
    -- 3rd level aliens are at the bottom (64px below master coord)
    constant OFFSET: integer := 64;
    -- master chords (them would be an input)
    signal rocket_master_coord_x: unsigned (9 downto 0) := to_unsigned((HD / 2) - ROCKET_WIDTH/2, 10); 
    signal rocket_master_coord_y: unsigned (9 downto 0) := to_unsigned(VD-100-32,10);
    
    -- Enemy Ball
    constant EB_WIDTH: integer := 640; -- 256 -> 8 ALIENS
    constant EB_HEIGHT: integer := 32;
    signal enemy_ball_addr: std_logic_vector(9 downto 0) := "0000000000";
    signal row_enemy_ball_address, col_enemy_ball_address: std_logic_vector(4 downto 0) := "00000";
    signal enemy_ball_on: std_logic := '0';
    -- master chords (them would be an input)
    signal enemy_ball_master_coord_x: unsigned (9 downto 0) := "0000000000"; 
    signal enemy_ball_master_coord_y: unsigned (9 downto 0) := "0000000000";

    begin

        rocket: entity work.rocket_rom(content) port map(
            rocket_addr => rocket_addr,
            data => rocket_rgb
        );
        
        enemy_ball:entity work.enemy_ball_rom(content) port map(
            alien_addr => enemy_ball_addr,
            data => enemy_ball_rgb
        );

        process(row, col, up, down, left, right, mid)

            variable current_frame : natural := 0;
            variable ship_offset : integer := 0;
            variable hit_r, hit_l : std_logic := '0'; -- hit right, hit left
            variable wall_offset : integer := 0;
            variable rocket_offset_x : unsigned (9 downto 0) := "0000000000";
            variable rocket_offset_y : unsigned (9 downto 0) := "0000000000";
            variable rocket_x_or_y : integer := 0; -- decide to move to x or to y
            variable enemy_ball_offset_x : unsigned (9 downto 0) := "0000000000";
            variable enemy_ball_offset_y : unsigned (9 downto 0) := "0000000000";

        begin

            if row = 0 and col = 0 then
                current_frame := current_frame + 1;

                if current_frame > every_n_frames then
                    current_frame := 0;
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
            if (col >= SHIP_X_L + ship_offset) and (col <= SHIP_X_R + ship_offset) and (SHIP_Y_T <= row) and (row <= SHIP_Y_B) then
                ship_on <= '1';
            end if; 
                    
            if (row >= WALL_Y_T + wall_offset) and (row <= WALL_Y_B + wall_offset) then
                wall_on <= '1';
            end if;

            -- game over if the wall touch the top of the ship
            if (WALL_Y_B + wall_offset >= SHIP_Y_T) or (SHIP_Y_T <= enemy_ball_master_coord_y + OFFSET + EB_HEIGHT + enemy_ball_offset_y) then
                game_over <= '1';
            end if;

            if (rocket_master_coord_y + OFFSET + rocket_offset_y <= enemy_ball_master_coord_y + OFFSET + EB_HEIGHT + enemy_ball_offset_y) then
                win <= '1';
            end if;

            -- rocket enable boundaries
            if (col >= rocket_master_coord_x + rocket_offset_x) and (col < rocket_master_coord_x + ROCKET_WIDTH + rocket_offset_x) 
               and (row >= rocket_master_coord_y + OFFSET + rocket_offset_y) and (row < rocket_master_coord_y + OFFSET + ROCKET_HEIGHT + rocket_offset_y) then
                rocket_on <= '1';
            else
                rocket_on <= '0';
            end if;

            -- calculate address of px of rom
            row_rocket_address <= std_logic_vector( pix_y(4 downto 0) - rocket_master_coord_y(4 downto 0) - rocket_offset_y(4 downto 0) ) ; 
            col_rocket_address <= std_logic_vector( pix_x(4 downto 0) - rocket_master_coord_x(4 downto 0) - rocket_offset_x(4 downto 0) ) ;
            rocket_addr <= row_rocket_address & col_rocket_address;
            
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

            if row = VD - 1 and col = HD - 1 then 
            -- frame update

                -- check if the ship hit the right or left spot
                if SHIP_X_R + ship_offset + SHIP_STEP >= HD - 1 then 
                    hit_l := '0';
                    hit_r := '1';
                elsif SHIP_X_L + ship_offset - SHIP_STEP <= 0 then
                    hit_r := '0';
                    hit_l := '1';
                end if;

                -- changing ship_offset by reading the hit flags. wall_offset change too.
                enemy_ball_offset_y := enemy_ball_offset_y + ROCKET_STEP;
                wall_offset := wall_offset + WALL_STEP;
                rocket_offset_y := rocket_offset_y - ROCKET_STEP - ROCKET_STEP;

                -- if hit_r = '1' then
                --     ship_offset := ship_offset - SHIP_STEP;
                -- elsif hit_l = '1' then
                --     ship_offset := ship_offset + SHIP_STEP;
                -- else
                --     ship_offset := ship_offset + SHIP_STEP;
                -- end if;

                if left = '1' then
                    ship_offset := ship_offset - SHIP_STEP;
                elsif right = '1' then
                    ship_offset := ship_offset + SHIP_STEP;
                end if;

            end if;

        end process;

        r <= (others => graph_rgb(2)) when display_enable = '1' else (others => '0'); 
        g <= (others => graph_rgb(1)) when display_enable = '1' else (others => '0');
        b <= (others => graph_rgb(0)) when display_enable = '1' else (others => '0');

        

end architecture;
