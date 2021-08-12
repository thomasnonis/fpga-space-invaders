-- Object-Mapped Pixel Generation Circuit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use std.textio.all;

-- Alien old is alien rom type
-- Actual alien is the rocket

entity graph is
    generic (
        HD  : natural := 640;  -- horizontal display (active video area)
        VD  : natural := 480   -- vertical display
    );
    port (
        video_on  :  in   std_logic;  -- display enable ('1' = display time, '0' = blanking time)
        row       :  in   natural;    -- row pixel coordinate
        col       :  in   natural;    -- column pixel coordinate
        r         :  out  std_logic_vector(3 downto 0) := (others => '0');  -- red magnitude output to dac
        g         :  out  std_logic_vector(3 downto 0) := (others => '0');  -- green magnitude output to dac
        b         :  out  std_logic_vector(3 downto 0) := (others => '0')   -- blue magnitude output to dac
    );
end graph;

architecture behavioral of graph is

    constant every_n_frames : natural := 2;

    -- Basta inizializzare questi 3 segnali per rimuovere i warnings
    signal pix_x, pix_y : unsigned(9 downto 0) := "0000000000";
    signal graph_rgb : std_logic_vector(2 downto 0) := "000";

    -- SIZE AND BOUNDARY OF THE OBJECTS --
    -- Spaceship user
    -- BAR AS SQUARE
    constant BAR_X_SIZE : natural := 40;
    constant BAR_Y_SIZE : natural := 40;

    constant BAR_X_L :  natural := HD/2 - BAR_X_SIZE/2;
    constant BAR_X_R :  natural := HD/2 + BAR_X_SIZE/2; 

    constant BAR_Y_B: integer := VD - 20;  
    constant BAR_Y_T: integer := BAR_Y_B - BAR_Y_SIZE;

    constant BAR_STEP: natural := 30;
 
    -- Wall of aliens
    constant WALL_Y_T: natural := 0; 
    constant WALL_Y_B: natural := 50;

    constant WALL_STEP: natural := 5; --30;

    -- Missile
    constant BALL_SIZE : natural := 8;

    -- --TODO inizilizzarli
    -- signal ball_x_l: unsigned(9 downto 0) := "0000001000"; -- 8
    -- signal ball_x_r: unsigned(9 downto 0) := "0001000000"; -- 64
    -- signal ball_y_t: unsigned(9 downto 0) := "0000001000"; -- 8
    -- signal ball_y_b: unsigned(9 downto 0) := "0001000000"; -- 64

    -- type rom_type is array(0 to 7) of  std_logic_vector(0 to 7); 
    -- constant BALL_ROM : rom_type := (   
    --     "00111100", 
    --     "01111110",
    --     "11111111", 
    --     "11111111", 
    --     "11111111", 
    --     "11111111",
    --     "01111110",
    --     "00111100"
    -- );

    -- signal rom_rocket_addr : unsigned(2 downto 0) := "000"; 
    -- rom_col: unsigned(2 downto 0) := "000"; 
    -- signal rom_data: std_logic_vector(7 downto 0)  := "00000000";
    -- signal rom_bit: std_logic := '1';

    signal bar_on, wall_on, game_over, win : std_logic := '0';
    -- signal sq_ball_on : std_logic := '0'; -- to indicate if scan coord is within square that contains the round ball
    -- signal rd_ball_on: std_logic := '0'; -- to indicate if scan coord is within round ball 
    signal bar_rgb, wall_rgb, ball_rgb, game_over_rgb, win_rgb : std_logic_vector(2 downto 0) := "000";
    

    -- ROCKET CODE
    -- width of the alien area (8 * 32)
    constant ROCKET_WIDTH: integer := 32; -- 256 -> 8 ALIENS
    constant ROCKET_HEIGHT: integer := 32;
    signal rocket_on: std_logic := '0';
    -- alien_address is made of row and column adresses
    -- alien_addr <= (row_alien_address & col_alien_address);
    signal rocket_addr: std_logic_vector(9 downto 0) := "0000000000";
    signal row_rocket_address, col_rocket_address: std_logic_vector(4 downto 0) := "00000";
    signal rocket_rgb : std_logic_vector(2 downto 0);
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
    signal enemy_ball_rgb : std_logic_vector(2 downto 0);
    -- master chords (them would be an input)
    signal enemy_ball_master_coord_x: unsigned (9 downto 0) := "0000000000"; 
    signal enemy_ball_master_coord_y: unsigned (9 downto 0) := "0000000000";

    begin

        rocket:
        entity work.rocket_rom(content)
        port map(rocket_addr => rocket_addr, data => rocket_rgb);
        
        enemy_ball:
        entity work.enemy_ball_rom(content)
        port map(alien_addr => enemy_ball_addr, data => enemy_ball_rgb);

        process(video_on, row, col)

            variable current_frame : natural := 0;
            variable bar_offset : integer := 0;
            variable hit_r, hit_l : std_logic := '0'; -- hit right, hit left
            variable wall_offset : integer := 0;
            variable rocket_offset_x : unsigned (9 downto 0) := "0000000000";
            variable rocket_offset_y : unsigned (9 downto 0) := "0000000000";
            variable rocket_x_or_y : integer := 0; -- decide to move to x or to y
            constant rocket_STEP : unsigned(4 downto 0) := "10000"; --32
            variable enemy_ball_offset_x : unsigned (9 downto 0) := "0000000000";
            variable enemy_ball_offset_y : unsigned (9 downto 0) := "0000000000";
            -- variable enemy_ball_x_or_y : integer := 0; -- decide to move to x or to y
            constant ENEMY_BALL_STEP : unsigned(4 downto 0) := "10000"; --32

        begin
            
            pix_y <= to_unsigned(row, 10); 
            pix_x <= to_unsigned(col, 10);

            bar_rgb  <= "010"; -- green
            wall_rgb <= "001"; -- blue
            ball_rgb <= "101"; -- purple
            game_over_rgb <= "100"; -- red
            win_rgb <= "010"; -- green
            
            bar_on  <= '0';
            wall_on <= '0';
            --sq_ball_on <= '0'; 
            --rd_ball_on <= '0';
            game_over <= '0';
            win <= '0';

            -- activation boundaries for the bar
            if ((col >= BAR_X_L+bar_offset) and (col <= BAR_X_R+bar_offset) and (BAR_Y_T <= row) and (row <= BAR_Y_B)) then
                bar_on <= '1';
            end if; 
                    
            if ((row >= WALL_Y_T+wall_offset) and (row <= WALL_Y_B+wall_offset)) then
                wall_on <= '1';
            end if;
        
            -- if ((ball_x_l <= col) and (col <= ball_x_r) and (ball_y_t <= row) and (row <= ball_y_b)) then
            --     sq_ball_on <= '1';
            -- end if;

            -- map scan coord to ROM alien_addr/col
            -- rom_alien_addr <= pix_y(2 downto 0) - ball_y_t(2 downto 0);
            -- rom_col  <= pix_x(2 downto 0) - ball_x_l(2 downto 0);
            -- rom_data <= BALL_ROM(to_integer(rom_alien_addr)); -- select one of the arrays in the ball_rom
            -- rom_bit <=  rom_data(to_integer(rom_col)); -- select value by value 1/0 of the rom_data

            -- if (sq_ball_on = '1') and (rom_bit = '1') then
            --     rd_ball_on <= '1';
            -- end if ;

            -- game over if the wall touch the top of the bar
            if ((WALL_Y_B+wall_offset >= BAR_Y_T) or (BAR_Y_T <= enemy_ball_master_coord_y + OFFSET + EB_HEIGHT + enemy_ball_offset_y)) then
                game_over <= '1';
            end if;

            if ((rocket_master_coord_y + OFFSET + rocket_offset_y <= enemy_ball_master_coord_y + OFFSET + EB_HEIGHT + enemy_ball_offset_y)) then
                win <= '1';
            end if;

            -- rocket enable boundaries
            if (col >= rocket_master_coord_x + rocket_offset_x) and (col < rocket_master_coord_x + ROCKET_WIDTH + rocket_offset_x) 
               and (row >= rocket_master_coord_y + OFFSET + rocket_offset_y) and (row < rocket_master_coord_y + OFFSET + ROCKET_HEIGHT + rocket_offset_y) then
                rocket_on <= '1';
            else
                rocket_on <= '0';
            end if;

            row_rocket_address <= std_logic_vector( (pix_y(4 downto 0) - rocket_master_coord_y(4 downto 0) - rocket_offset_y(4 downto 0))) ; 
            col_rocket_address <= std_logic_vector( (pix_x(4 downto 0) - rocket_master_coord_x(4 downto 0) - rocket_offset_x(4 downto 0))) ;
            rocket_addr <= row_rocket_address & col_rocket_address;
            
             -- ENEMY BALL enable boundaries
             if (col >= enemy_ball_master_coord_x + enemy_ball_offset_x) and (col < enemy_ball_master_coord_x + EB_WIDTH + enemy_ball_offset_x) 
             and (row >= enemy_ball_master_coord_y + OFFSET + enemy_ball_offset_y) and (row < enemy_ball_master_coord_y + OFFSET + EB_HEIGHT + enemy_ball_offset_y) then
              enemy_ball_on <= '1';
            else
                enemy_ball_on <= '0';
            end if;

            row_enemy_ball_address <= std_logic_vector( (pix_y(4 downto 0) - enemy_ball_master_coord_y(4 downto 0) - enemy_ball_offset_y(4 downto 0))) ; --- rocket_master_coord_y(4 downto 0);
            col_enemy_ball_address <= std_logic_vector( (pix_x(4 downto 0) - enemy_ball_master_coord_y(4 downto 0) - enemy_ball_offset_x(4 downto 0))) ; -- - rocket_master_coord_x(4 downto 0);
            enemy_ball_addr <= row_enemy_ball_address & col_enemy_ball_address;

            -- Need to alternate 2 different frame to make animation
            -- alien_rgb <= alien11_rgb when frame = '0' else
            --      alien12_rgb;

            if (video_on = '0') then
                graph_rgb <= "000"; -- blank
            else 
                -- priority encoder
                if (bar_on = '1') then 
                    graph_rgb <= bar_rgb;
                elsif (wall_on = '1') then
                    graph_rgb <= wall_rgb;
                elsif (rocket_on = '1') then
                        graph_rgb <= rocket_rgb;
                elsif (enemy_ball_on = '1') then
                        graph_rgb <= enemy_ball_rgb;
                -- elsif (rd_ball_on = '1') then 
                --     graph_rgb <= ball_rgb;
                elsif (game_over = '1') then
                    graph_rgb <= game_over_rgb;
                elsif (win = '1') then
                    graph_rgb <= win_rgb;
                else
                    graph_rgb <= "000"; -- background
                end if;

                if (row = VD - 1 and col = HD - 1) then 
                    -- frame update
                    current_frame := current_frame + 1;

                    -- check if the bar hit the right or left spot
                    if ((BAR_X_R+bar_offset) + BAR_STEP >= HD - 1) then 
                        hit_l := '0';
                        hit_r := '1';
                    elsif ((BAR_X_L+bar_offset) - BAR_STEP <= 0) then
                        hit_r := '0';
                        hit_l := '1';
                    end if;
                    -- changing bar_offset by reading the hit flags. wall_offset change too.
                    enemy_ball_offset_y := enemy_ball_offset_y + rocket_STEP;
                    wall_offset := wall_offset + WALL_STEP;
                    rocket_offset_y := rocket_offset_y - rocket_STEP - rocket_STEP;

                    if hit_r = '1' then
                        bar_offset := bar_offset - BAR_STEP;
                        --wall_offset := wall_offset + WALL_STEP;
                    elsif hit_l = '1' then
                        bar_offset := bar_offset + BAR_STEP;
                        --wall_offset := wall_offset + WALL_STEP;
                    else
                        bar_offset := bar_offset + BAR_STEP;
                        --wall_offset := wall_offset + WALL_STEP;
                        -- decide to move to x or to y
                        -- if (rocket_x_or_y mod 2 /= 0) then
                        --     rocket_offset_x := rocket_offset_x - rocket_STEP;
                        -- else
                        --     rocket_offset_y := rocket_offset_y - rocket_STEP;
                        -- end if;
                        --alien_x_or_y := alien_x_or_y + 1;
                         --twice sub due to debugging
                        -- enemy ball go just down not moving along x axis
                        -- enemy_ball_offset_y := enemy_ball_offset_y + rocket_STEP;
                        

                    end if;
                end if;
            end if;
            r <= (others => graph_rgb(2)); 
            g <= (others => graph_rgb(1));
            b <= (others => graph_rgb(0));

        end process;

        

end architecture;
