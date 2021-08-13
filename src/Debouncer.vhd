library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Debouncer is
  generic (
    counter_size : integer := 12
  );
  port (
    clk, reset, btn_in : in std_logic;
    btn_out : out std_logic
  );
end Debouncer;

architecture behavioral of Debouncer is

  signal counter : integer;
  signal candidate_value, stable_value, delayed_stable_value : std_logic;

begin

  process ( clk, reset ) begin
    if reset = '0' then
      counter <= counter_size;
      stable_value <= '0';
      candidate_value <= '0';
    elsif rising_edge( clk ) then
      -- Controlla se il segnale e' stabile
      if btn_in = candidate_value then
        -- Segnale stabile. Controlla per quanto tempo
        if counter = 0 then
          -- Aggiorna il valore stabile
          stable_value <= candidate_value;
        else
          counter <= counter - 1;
          
        end if;
      else
        -- Segnale non stabile. Aggiorna il valore candidato e resetta il contatore
        candidate_value <= btn_in;
        counter <= counter_size;
        -- stable_value <= '0';
        -- candidate_value <= '0';
        
      end if;
    end if;
  end process;

  -- Processo che crea una versione ritardata del segnale stable (delayed_stable_value)
  process ( clk, reset ) begin
    if reset = '0' then
      -- Assegnazione valore di reset
      delayed_stable_value <= '0';
    elsif rising_edge( clk ) then
      -- Assegnazione valore ad ogni ciclo di clk
      delayed_stable_value <= stable_value;
    end if;
  end process;

  -- Genera impulso d'uscita
  btn_out <= '1' when stable_value = '1' and delayed_stable_value = '0' else
           '0';

end behavioral;

