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
    type status_type is (RUNNING, GAMEOVER, WIN, RESET);
    signal gameover_rgb : std_logic_vector(2 downto 0) := RED;
    signal win_rgb : std_logic_vector(2 downto 0) := GREEN;

    -- SHIP
    constant SHIP_WIDTH : natural := 32;
    constant SHIP_HEIGHT : natural := 32;
    constant SHIP_STEP: natural := 10; --30
    signal row_ship_address: natural := 0;
    signal col_ship_address: natural := 0;
    signal ship_rgb : std_logic_vector(2 downto 0);  
   
    -- ENEMY BALL
    constant EB_WIDTH: integer := HD;
    constant EB_HEIGHT: integer := 32;
    constant ENEMY_BALL_STEP : natural := 16;
    signal row_enemy_ball_address: natural := 0;
    signal col_enemy_ball_address: natural := 0;
    signal enemy_ball_rgb : std_logic_vector(2 downto 0);

    -- OTHER
    signal graph_rgb : std_logic_vector(2 downto 0) := BLACK;

    -- INTERNAL CLOCKS
    signal update_clk : std_logic := '0';
    signal frame_clk : std_logic := '0';
    
    begin
       
        enemy_ball: entity work.Rom(EnemyBall) port map(
            row => row_enemy_ball_address,
            col => col_enemy_ball_address,
            rgb => enemy_ball_rgb
        );

        ship: entity work.Rom(Ship) port map(
            row => row_ship_address,
            col => col_ship_address,
            rgb => ship_rgb
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
        
            --  GAME STATUS
            variable status : status_type := RUNNING;

            -- SHIP
            variable ship_x : integer := HD/2;
            variable ship_y : integer := VD - SHIP_HEIGHT;
            variable ship_on : std_logic := '0';  

            -- ENEMY BALL
            variable enemy_ball_x : integer := HD/2;
            variable enemy_ball_y : integer := EB_HEIGHT/2;
            variable enemy_ball_on: std_logic := '0';

        begin

            -- Faster response for GUI
            if rising_edge(frame_clk) then

                if down = '1' then

                    status := RESET;

                    enemy_ball_y := EB_HEIGHT/2;
                    ship_x := HD/2;

                end if;

                if left = '1' and ship_x - SHIP_WIDTH/2 > 0 then

                    ship_x := ship_x - SHIP_STEP;

                elsif right = '1' and ship_x + SHIP_WIDTH/2 < HD - 1 then

                    ship_x := ship_x + SHIP_STEP;

                end if;
                

            end if;

            if rising_edge(update_clk) then

                if status = RUNNING then
                    enemy_ball_y := enemy_ball_y + ENEMY_BALL_STEP;
                end if;

            end if;   

            -- Set ship canvas
            if (col >= ship_x - SHIP_WIDTH/2) and (col < ship_x + SHIP_WIDTH/2) and (row >= ship_y - SHIP_HEIGHT/2) and (row < ship_y + SHIP_HEIGHT/2) then
                ship_on := '1';
            else
                ship_on := '0';
            end if;
            
            -- Set enemy ball canvas
            if (((col < 32*10) or (col >= HD-(32*6))) and (row >= enemy_ball_y - EB_HEIGHT/2) and (row < enemy_ball_y + EB_HEIGHT/2))
                or (((col >= 32*7) and (col < 32*7 + 32*5)) and (row >= enemy_ball_y - 160 - EB_HEIGHT/2) and (row < enemy_ball_y - 160 + EB_HEIGHT/2))
                or ((((col > 32*2) and (col <= 32*5)) or (col > HD-(32*8) and col <= HD-(32*1))) and (row >= enemy_ball_y - 160+32*3 - EB_HEIGHT/2) and (row < enemy_ball_y - 160+32*3 + EB_HEIGHT/2)) then
                
                enemy_ball_on := '1';
            else
                enemy_ball_on := '0';
            end if;

            -- Compute px coordinate of ship inside ROM
            row_ship_address <= row - (ship_y - SHIP_HEIGHT/2);
            col_ship_address <= col - (ship_x - SHIP_WIDTH/2);


            -- Compute px coordinate of enemy ball inside ROM
            row_enemy_ball_address <= row - (enemy_ball_y - EB_HEIGHT/2);
            col_enemy_ball_address <= col - (enemy_ball_x - EB_WIDTH/2);



            -- !!!!!!!!!!!!

            -- Conditions should work, but in practice it is not reliable
            if ship_on = '1' and enemy_ball_on = '1' then
                status := GAMEOVER;
            end if;

            -- !!!!!!!!!!!!




            -- Set z axis order
            if ship_on = '1' and ship_rgb /= "000" then 
                -- poor man's alpha channel
                graph_rgb <= ship_rgb;
            elsif enemy_ball_on = '1' and enemy_ball_rgb /= "000" then
                -- poor man's alpha channel
                graph_rgb <= enemy_ball_rgb;
            elsif status = GAMEOVER then
                graph_rgb <= gameover_rgb;
            elsif status = WIN then
                graph_rgb <= win_rgb;
            else
                -- background
                graph_rgb <= BLACK;
            end if;

            if status = RESET then
                status := RUNNING;
            end if;

        end process;

        r <= (others => graph_rgb(2)) when display_enable = '1' else (others => '0'); 
        g <= (others => graph_rgb(1)) when display_enable = '1' else (others => '0');
        b <= (others => graph_rgb(0)) when display_enable = '1' else (others => '0');

        

end architecture;