-----------------------------------------------------------------------------
-- 
-- Module: Dataflow
--
-- Author: Christopher Kitras
-- Class:  ECEN 620, Section 1, Fall 2022
-- Date: 2022-09-20
--
-- Description: Top-level module that will control segments based on various
--			    inputs from buttons and switches on the FPGA.
--
--              Adapted from Mike Wirthlin, Jeff Goeders 7 seg controller
--
--
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real."ceil";
use ieee.math_real."log2";
use ieee.numeric_std.all;

entity SevenSegmentController is
    generic(
        CLOCK_RATE  :integer    := 100000000;                                   -- Corresponds to clock cycles per second
        DISPLAY_MS  :integer    := 20                                           -- The refresh rate of the entire display of digits in milliseconds
    );
    port(
        clk     :in  std_logic;                                                 -- System clk
        reset   :in  std_logic;                                                 -- Reset the counters for the module
        dataIn  :in  std_logic_vector(31 downto 0);                             -- Buffer of bits that contains the digits displayed by the seven segment controller      
        digDisp :in  std_logic_vector(7  downto 0);                             -- Controls which bits are available for display
        digPnt  :in  std_logic_vector(7  downto 0);                             -- Controls when and where digit points are enabled
        segment :out std_logic_vector(7  downto 0);                             -- Controls the segments of the digits
        anode   :out std_logic_vector(7  downto 0)                              -- Controls which digit is being written to
    );
end SevenSegmentController;

architecture rtl of SevenSegmentController is

    --
    constant COUNT_BITS :integer   := integer(ceil(
                                             log2(
                                             real(CLOCK_RATE*DISPLAY_MS/8000)
                                                 )));                           


    signal countVal     :std_logic_vector(COUNT_BITS - 1 downto 0);             -- Bit counter that relies on the clk to control the granularity of the delay
    signal anodeSelect  :std_logic_vector(2              downto 0);             -- Describes the number of digit that needs to be written to
    signal curAnode     :std_logic_vector(7              downto 0);             -- Describes which digit will be the active one that needs to be written to
    signal curDataIn    :std_logic_vector(3              downto 0);             -- Nibble that describes the digit to be displayed

begin

    -- Counter which relies on the speed of the clock to cause a delay by
    -- looping through all the digits and causing the upper three bits to
    -- be the anodeSelect values
    process(clk)
    begin
        if (clk'event and clk = '1') then
            if reset = '1' then
                countVal <= (COUNT_BITS - 1 downto 0 => '0');
            else
                countVal <= std_logic_vector(unsigned(countVal) + 1);
            end if;
        end if;
    end process;

    -- Signal to indicate which anode we are driving
    process (countVal)
    begin
        anodeSelect <= countVal(COUNT_BITS-1 downto COUNT_BITS-3);
    end process;

    -- Based on the upper digits of the counter, it will write the correct
    -- value to the anode to enable the digit that needs to be written to
    process(anodeSelect)
    begin
        if (anodeSelect = "000") then
            curAnode <= "11111110";
        elsif (anodeSelect = "001") then
            curAnode <= "11111101";
        elsif (anodeSelect = "010") then
            curAnode <= "11111011";
        elsif (anodeSelect = "011") then
            curAnode <= "11110111";
        elsif (anodeSelect = "100") then
            curAnode <= "11101111";
        elsif (anodeSelect = "101") then
            curAnode <= "11011111";
        elsif (anodeSelect = "110") then
            curAnode <= "10111111";
        else
            curAnode <= "01111111";
        end if;
    end process;


    -- Mask anode values that are not enabled with digit display
    -- (if a bit of digitDisplay is '0' (off), then it will be
    -- inverted and "ored" with the anode making it '1' (no drive)
    process (curAnode, digDisp)
    begin
        anode <= curAnode or not(digDisp);
    end process;

    -- Based on the current anode that needs to be written, it will
    -- denote which value needs to be written by looking at the val
    -- of digitPoint buffer and the write range in the entire data
    process (anodeSelect, dataIn, digPnt)
    begin
        if anodeSelect = "000" then
            curDataIn  <= datain(3 downto 0);
            segment(7) <= not digPnt(0);
        elsif anodeSelect = "001" then
            curDataIn  <= datain(7 downto 4);
            segment(7) <= not digPnt(1);
        elsif anodeSelect = "010" then
            curDataIn  <= datain(11 downto 8);
            segment(7) <= not digPnt(2);
        elsif anodeSelect = "011" then
            curDataIn  <= datain(15 downto 12);
            segment(7) <= not digPnt(3);
        elsif anodeSelect = "100" then
            curDataIn  <= datain(19 downto 16);
            segment(7) <= not digPnt(4);
        elsif anodeSelect = "101" then
            curDataIn  <= datain(23 downto 20);
            segment(7) <= not digPnt(5);
        elsif anodeSelect = "110" then
            curDataIn  <= datain(27 downto 24);
            segment(7) <= not digPnt(6);
        else
            curDataIn  <= datain(31 downto 28);
            segment(7) <= not digPnt(7);
        end if;
    end process;

    -- LUT for Segment values
    -- 0s are asserted and 1s are not
    process (curDataIn)
    begin
        if to_integer(unsigned(curDataIn)) = 0 then
            segment(6 downto 0) <= "1000000";
        elsif to_integer(unsigned(curDataIn)) = 1 then
            segment(6 downto 0) <= "1111001";
        elsif to_integer(unsigned(curDataIn)) = 2 then
            segment(6 downto 0) <= "0100100";
        elsif to_integer(unsigned(curDataIn)) = 3 then
            segment(6 downto 0) <= "0110000";
        elsif to_integer(unsigned(curDataIn)) = 4 then
            segment(6 downto 0) <= "0011001";
        elsif to_integer(unsigned(curDataIn)) = 5 then
            segment(6 downto 0) <= "0010010";
        elsif to_integer(unsigned(curDataIn)) = 6 then
            segment(6 downto 0) <= "0000010";
        elsif to_integer(unsigned(curDataIn)) = 7 then
            segment(6 downto 0) <= "1111000";
        elsif to_integer(unsigned(curDataIn)) = 8 then
            if anodeSelect = "110" then
                segment(6 downto 0) <= "0101011";
            else
                segment(6 downto 0) <= "0000000";
            end if;
        elsif to_integer(unsigned(curDataIn)) = 9 then
            if anodeSelect = "111" then
                segment(6 downto 0) <= "0100001";
            else
                segment(6 downto 0) <= "0010000";
            end if;
        elsif to_integer(unsigned(curDataIn)) = 10 then
            if anodeSelect = "110" then
                segment(6 downto 0) <= "0001100";
            else
                segment(6 downto 0) <= "0001000";
            end if;   
        elsif to_integer(unsigned(curDataIn)) = 11 then
            if anodeSelect = "111" then
                segment(6 downto 0) <= "1100011";
            else
                segment(6 downto 0) <= "0000011";
            end if;   
        elsif to_integer(unsigned(curDataIn)) = 12 then
            if anodeSelect = "110" then
                segment(6 downto 0) <= "0000111";
            else
                segment(6 downto 0) <= "1000110";
            end if;   
        elsif to_integer(unsigned(curDataIn)) = 13 then
        if anodeSelect = "111" then
                segment(6 downto 0) <= "0101111";
            else
                segment(6 downto 0) <= "0100001";
            end if;  
        elsif to_integer(unsigned(curDataIn)) = 14 then
            if anodeSelect = "110" then
                segment(6 downto 0) <= "0001110";
            else
                segment(6 downto 0) <= "0000110";
            end if;   
        else
            if anodeSelect = "111" then
                segment(6 downto 0) <= "1000111";
            else
                segment(6 downto 0) <= "0001110";
            end if;   
        end if;
    end process;

end rtl;