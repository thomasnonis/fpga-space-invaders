-- square for testing

library ieee;
use ieee.std_logic_1164.all;

entity square is
  generic(
    HD :  natural := 480; --478;   --row that first color will persist until
    VD :  natural := 640 --600;  --column that first color will persist until
    );
    port(
    disp_ena :  in   std_logic;  --display enable ('1' = display time, '0' = blanking time)
    row      :  in   integer;    --row pixel coordinate
    column   :  in   integer;    --column pixel coordinate
    red      :  out  std_logic_vector(3 downto 0) := (others => '0');  --red magnitude output to dac
    green    :  out  std_logic_vector(3 downto 0) := (others => '0');  --green magnitude output to dac
    blue     :  out  std_logic_vector(3 downto 0) := (others => '0')); --blue magnitude output to dac
end square;

architecture behavior of square is
  
signal box_x, box_y : integer := 40;

constant every_n_frames : natural := 2;

begin
  process(disp_ena, row, column)
  
    variable current_frame : natural := 0;
    variable offset_Y : natural  := 100; --range 0 to VD
    constant box_size: integer := 20;
    begin

    if(disp_ena = '1') then        --display time
      
      if(row > offset_Y and row < offset_Y+box_size and column < box_size) then
        red <= (others => '1');
        green  <= (others => '1');
        blue <= (others => '0');
      else --black
        red <= (others => '0');
        green  <= (others => '0');
        blue <= (others => '0');
      end if;

      if column = VD - 1 and row = HD - 1 then
        current_frame := current_frame + 1;
      end if;
    end if;
  
  end process;
end behavior;
