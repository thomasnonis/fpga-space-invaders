----------------------------------------------------------------------------------
-- Author: Lisa Santarossa @unitn
--
--VGA Controller which is always the same for a given VGA mode
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 

-- Basic VGA mode
-- 640 x 480 x 60Hz 
-- The drawing of one line takes 800 clock cycles, while one frame requires a 
-- time equivalent to 525 lines.
-- Consequently, to be able to generate 60 frames per second, the clock frequency 
-- must be 800x525x60 = 25.175 MHz
--  -----------------------------------------------------------
--  |                                     |     |       |     |
--  |                                     |  h  |   h   |  h  |
--  |                                     |     |       |     |
--  |                                     |  f  |   s   |  b  |
--  |                                     |  r  |   y   |  c  |
--  |                                     |  t  |   n   |  k  |
--  |                                     |     |   c   |     |
--  |          ACTIVE  DISPLAY            |  p  |   h   |  p  |
--  |                                     |  o  |       |  o  |
--  |                                     |  r  |   r   |  r  |
--  |                                     |  c  |   e   |  c  |
--  |                                     |  h  |   t   |  h  |
--  |                                     |     |       |     |
--  |                                     |(HFP)| (HR)  |(HBP)|
--  -----------------------------------------------------------
--  |   Vertical front porch   (VFP)                          |
--  -----------------------------------------------------------
--  |   Vertical sync retrace  (VR)                           |
--  -----------------------------------------------------------
--  |   Vertical back porch    (VBP)                          |
--  -----------------------------------------------------------


entity VGA_controller is
    generic(
        h_MAX : natural := 800;
        v_MAX : natural := 525;

        HD  : natural := 640;   -- horizontal display (active video area)
        HFP : natural := 16;    -- h_sync front porch
        HR  : natural := 96;    -- h_sync retrace (width of the horizontal synchronization pulse)
        HBP : natural := 48;    -- h_sync back porch 
        VD  : natural := 480;   -- vertical display
        VFP : natural := 10;    -- v_sync front porch 
        VR  : natural := 2;     -- v_sync retrace 
        VBP : natural := 33     -- v_sync back porch 
    );
    port(
        clk       : in      std_logic;          -- system clock: 100 MHz in our board
        reset     : in      std_logic;          -- active low asycnchronous reset
        h_sync    : out     std_logic := '0';   -- horiztonal sync pulse
        v_sync    : out     std_logic := '0';   -- vertical sync pulse
        px_clk    : in      std_logic;          -- pixel clock at frequency of VGA mode being used : 25.175 MHz 
        video_on  : out     std_logic := '0';   -- display enable ('1' = display time, '0' = blanking time)
        col       : out     natural := 0;            -- horizontal pixel coordinate
        row       : out     natural := 0            -- vertical pixel coordinate
        );
end  VGA_controller;

architecture Behavioral of VGA_controller is

    signal h_count : natural range 0 to (h_MAX);
    signal v_count : natural range 0 to (v_MAX);

    begin

    -- Signals generation:
    process (clk, px_clk, reset) begin
        if reset = '0' then
            if rising_edge(clk) then
                h_count <= 0;
                h_sync <= '0';  
                v_count <= 0;
                v_sync <= '0';  
                col <= 0;
                row <= 0;
            end if;

        elsif rising_edge(px_clk) then

            -- Counters 
            if h_count >= h_MAX - 1 then
                h_count <= 0;
                if v_count >= v_MAX - 1 then
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;    
            end if;

            -- Horizontal sync signal
            if (h_count < HD + HFP - 1) or (h_count >= HD + HFP + HR - 1) then
                h_sync <= '1';
            else h_sync <= '0';
            end if;

            -- Vertical sync signal
            if (v_count < VD + VFP - 1) or (v_count >= VD + VFP + VR - 1) then
                v_sync <= '1';
            else v_sync <= '0';
            end if;

            -- Set pixel coordinates
            if h_count < HD then
                col <= h_count;
            end if;
            if v_count < VD then
                row <= v_count;
            end if;

            -- Display enable generation
            if h_count < HD and v_count < VD then
                video_on <= '1'; -- enable display
            else
                video_on <= '0'; -- disable display
            end if;
        end if;
    end process;
end architecture Behavioral;


