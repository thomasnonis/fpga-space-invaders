library ieee;
use ieee.std_logic_1164.all;

entity image_tester is
    generic(
        HD :  natural := 480; --478;   --row that first color will persist until
        VD :  natural := 640 --600;  --column that first color will persist until
    );
    port(
        display_enable : in std_logic;  --display enable ('1' = display time, '0' = blanking time)
        row : in integer;    --row pixel coordinate
        col : in integer;    --col pixel coordinate
        r : out std_logic_vector(3 downto 0) := (others => '0');  --red magnitude output to dac
        g : out std_logic_vector(3 downto 0) := (others => '0');  --green magnitude output to dac
        b : out std_logic_vector(3 downto 0) := (others => '0') --blue magnitude output to dac
    );
    end image_tester;

architecture Behavioral of image_tester is

begin
    process(display_enable, row, col)
  
    variable current_frame : natural := 0;
    variable offset_Y : natural  := 100; --range 0 to VD
    constant box_size : integer := 20;
    
    begin

    if(display_enable = '1') then        --display time
        if(row > offset_Y and row < offset_Y + box_size and col < box_size) then
            r <= (others => '1');
            g <= (others => '1');
            b <= (others => '0');
        else
            --black
            r <= (others => '0');
            g <= (others => '0');
            b <= (others => '0');
        end if;

        if col = VD - 1 and row = HD - 1 then
            current_frame := current_frame + 1;
        end if;
    end if;
  
  end process;
end Behavioral;
