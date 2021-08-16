# ----------------------------------------------------------------------------
# Clock Source - Bank 13
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN Y9 [get_ports {sys_clk}];  # "GCLK"
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {sys_clk}];

# ----------------------------------------------------------------------------
# VGA Output - Bank 33
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN Y21  [get_ports {b[0]}];  # "VGA-B1"
set_property PACKAGE_PIN Y20  [get_ports {b[1]}];  # "VGA-B2"
set_property PACKAGE_PIN AB20 [get_ports {b[2]}];  # "VGA-B3"
set_property PACKAGE_PIN AB19 [get_ports {b[3]}];  # "VGA-B4"
set_property PACKAGE_PIN AB22 [get_ports {g[0]}];  # "VGA-G1"
set_property PACKAGE_PIN AA22 [get_ports {g[1]}];  # "VGA-G2"
set_property PACKAGE_PIN AB21 [get_ports {g[2]}];  # "VGA-G3"
set_property PACKAGE_PIN AA21 [get_ports {g[3]}];  # "VGA-G4"
set_property PACKAGE_PIN AA19 [get_ports {h_sync}];  # "VGA-HS"
set_property PACKAGE_PIN V20  [get_ports {r[0]}];  # "VGA-R1"
set_property PACKAGE_PIN U20  [get_ports {r[1]}];  # "VGA-R2"
set_property PACKAGE_PIN V19  [get_ports {r[2]}];  # "VGA-R3"
set_property PACKAGE_PIN V18  [get_ports {r[3]}];  # "VGA-R4"
set_property PACKAGE_PIN Y19  [get_ports {v_sync}];  # "VGA-VS"

# ----------------------------------------------------------------------------
# User LEDs - Bank 33
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN T22 [get_ports {led[0]}];  # "LD0"
set_property PACKAGE_PIN T21 [get_ports {led[1]}];  # "LD1"
set_property PACKAGE_PIN U22 [get_ports {led[2]}];  # "LD2"
set_property PACKAGE_PIN U21 [get_ports {led[3]}];  # "LD3"
set_property PACKAGE_PIN V22 [get_ports {led[4]}];  # "LD4"
set_property PACKAGE_PIN W22 [get_ports {led[5]}];  # "LD5"
set_property PACKAGE_PIN U19 [get_ports {led[6]}];  # "LD6"
set_property PACKAGE_PIN U14 [get_ports {led[7]}];  # "LD7"

# ----------------------------------------------------------------------------
# User Push Buttons - Bank 34
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN P16 [get_ports {btn_mid}];  # "BTNC"
set_property PACKAGE_PIN R16 [get_ports {btn_down}];  # "BTND"
set_property PACKAGE_PIN N15 [get_ports {btn_left}];  # "BTNL"
set_property PACKAGE_PIN R18 [get_ports {btn_right}];  # "BTNR"
set_property PACKAGE_PIN T18 [get_ports {btn_up}];  # "BTNU"

# ----------------------------------------------------------------------------
# User DIP Switches - Bank 35
# ---------------------------------------------------------------------------- 
# set_property PACKAGE_PIN F22 [get_ports {SW0}];  # "SW0"
# set_property PACKAGE_PIN G22 [get_ports {SW1}];  # "SW1"
# set_property PACKAGE_PIN H22 [get_ports {SW2}];  # "SW2"
# set_property PACKAGE_PIN F21 [get_ports {SW3}];  # "SW3"
# set_property PACKAGE_PIN H19 [get_ports {SW4}];  # "SW4"
# set_property PACKAGE_PIN H18 [get_ports {SW5}];  # "SW5"
# set_property PACKAGE_PIN H17 [get_ports {SW6}];  # "SW6"
# set_property PACKAGE_PIN M15 [get_ports {SW7}];  # "SW7"

# ----------------------------------------------------------------------------
# IOSTANDARD Constraints
#
# Note that these IOSTANDARD constraints are applied to all IOs currently
# assigned within an I/O bank.  If these IOSTANDARD constraints are 
# evaluated prior to other PACKAGE_PIN constraints being applied, then 
# the IOSTANDARD specified will likely not be applied properly to those 
# pins.  Therefore, bank wide IOSTANDARD constraints should be placed 
# within the XDC file in a location that is evaluated AFTER all 
# PACKAGE_PIN constraints within the target bank have been evaluated.
#
# Un-comment one or more of the following IOSTANDARD constraints according to
# the bank pin assignments that are required within a design.
# ---------------------------------------------------------------------------- 


set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];
