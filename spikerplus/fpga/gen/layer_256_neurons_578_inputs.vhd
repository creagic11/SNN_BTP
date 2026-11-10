---------------------------------------------------------------------------------
-- This is free and unencumbered software released into the public domain.
--
-- Anyone is free to copy, modify, publish, use, compile, sell, or
-- distribute this software, either in source code form or as a compiled
-- binary, for any purpose, commercial or non-commercial, and by any
-- means.
--
-- In jurisdictions that recognize copyright laws, the author or authors
-- of this software dedicate any and all copyright interest in the
-- software to the public domain. We make this dedication for the benefit
-- of the public at large and to the detriment of our heirs and
-- successors. We intend this dedication to be an overt act of
-- relinquishment in perpetuity of all present and future rights to this
-- software under copyright law.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
-- OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.
--
-- For more information, please refer to <http://unlicense.org/>
---------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.spiker_pkg.all;


entity layer_256_neurons_578_inputs is
    generic (
        n_exc_inputs : integer := 578;
        n_inh_inputs : integer := 256;
        exc_cnt_bitwidth : integer := 10;
        inh_cnt_bitwidth : integer := 8;
        neuron_bit_width : integer := 16;
        inh_weights_bit_width : integer := 8;
        exc_weights_bit_width : integer := 8;
        shift : integer := 4
    );
    port (
        clk : in std_logic;
        rst_n : in std_logic;
        start : in std_logic;
        restart : in std_logic;
        exc_spikes : in std_logic_vector(n_exc_inputs-1 downto 0);
        inh_spikes : in std_logic_vector(n_inh_inputs-1 downto 0);
        ready : out std_logic;
        out_spikes : out std_logic_vector(255 downto 0)
    );
end entity layer_256_neurons_578_inputs;

architecture behavior of layer_256_neurons_578_inputs is


    constant v_th_00 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_01 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_02 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_03 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_04 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_05 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_06 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_07 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_08 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_09 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_0a : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_0b : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_0c : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_0d : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_0e : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_0f : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_10 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_11 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_12 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_13 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_14 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_15 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_16 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_17 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_18 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_19 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_1a : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_1b : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_1c : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_1d : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_1e : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_1f : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_20 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_21 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_22 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_23 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_24 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_25 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_26 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_27 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_28 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_29 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_2a : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_2b : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_2c : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_2d : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_2e : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_2f : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_30 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_31 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_32 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_33 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_34 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_35 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_36 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_37 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_38 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_39 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_3a : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_3b : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_3c : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_3d : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_3e : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_3f : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_40 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_41 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_42 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_43 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_44 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_45 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_46 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_47 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_48 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_49 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_4a : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_4b : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_4c : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_4d : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_4e : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_4f : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_50 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_51 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_52 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_53 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_54 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_55 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_56 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_57 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_58 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_59 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_5a : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_5b : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_5c : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_5d : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_5e : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_5f : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_60 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_61 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_62 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_63 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_64 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_65 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_66 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_67 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_68 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_69 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_6a : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_6b : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_6c : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_6d : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_6e : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_6f : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_70 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_71 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_72 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_73 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_74 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_75 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_76 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_77 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_78 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_79 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_7a : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_7b : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_7c : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_7d : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_7e : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_7f : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_80 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_81 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_82 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_83 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_84 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_85 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_86 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_87 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_88 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_89 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_8a : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_8b : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_8c : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_8d : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_8e : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_8f : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_90 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_91 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_92 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_93 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_94 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_95 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_96 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_97 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_98 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_99 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_9a : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_9b : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_9c : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_9d : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_9e : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_9f : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_a0 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_a1 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_a2 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_a3 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_a4 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_a5 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_a6 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_a7 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_a8 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_a9 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_aa : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ab : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ac : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ad : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ae : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_af : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_b0 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_b1 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_b2 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_b3 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_b4 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_b5 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_b6 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_b7 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_b8 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_b9 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ba : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_bb : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_bc : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_bd : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_be : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_bf : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_c0 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_c1 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_c2 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_c3 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_c4 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_c5 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_c6 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_c7 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_c8 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_c9 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ca : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_cb : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_cc : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_cd : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ce : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_cf : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_d0 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_d1 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_d2 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_d3 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_d4 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_d5 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_d6 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_d7 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_d8 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_d9 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_da : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_db : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_dc : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_dd : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_de : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_df : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_e0 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_e1 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_e2 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_e3 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_e4 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_e5 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_e6 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_e7 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_e8 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_e9 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ea : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_eb : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ec : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ed : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ee : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ef : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_f0 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_f1 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_f2 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_f3 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_f4 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_f5 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_f6 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_f7 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_f8 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_f9 : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_fa : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_fb : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_fc : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_fd : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_fe : signed(neuron_bit_width-1 downto 0) := "0000000001000000";
    constant v_th_ff : signed(neuron_bit_width-1 downto 0) := "0000000001000000";

    component multi_input_578_exc_256_inh is
        generic (
            n_exc_inputs : integer := 578;
            n_inh_inputs : integer := 256;
            exc_cnt_bitwidth : integer := 10;
            inh_cnt_bitwidth : integer := 8
        );
        port (
            clk : in std_logic;
            rst_n : in std_logic;
            restart : in std_logic;
            start : in std_logic;
            exc_spikes : in std_logic_vector(n_exc_inputs-1 downto 0);
            inh_spikes : in std_logic_vector(n_inh_inputs-1 downto 0);
            neurons_ready : in std_logic;
            exc_cnt : out std_logic_vector(exc_cnt_bitwidth - 1 downto 0);
            inh_cnt : out std_logic_vector(inh_cnt_bitwidth - 1 downto 0);
            ready : out std_logic;
            neuron_restart : out std_logic;
            exc : out std_logic;
            inh : out std_logic;
            out_sample : out std_logic;
            exc_spike : out std_logic;
            inh_spike : out std_logic
        );
    end component;

    component neuron_subtractive is
        generic (
            neuron_bit_width : integer := 16;
            inh_weights_bit_width : integer := 8;
            exc_weights_bit_width : integer := 8;
            shift : integer := 4
        );
        port (
            v_th : in signed(neuron_bit_width-1 downto 0);
            inh_weight : in signed(inh_weights_bit_width-1 downto 0);
            exc_weight : in signed(exc_weights_bit_width-1 downto 0);
            clk : in std_logic;
            rst_n : in std_logic;
            restart : in std_logic;
            exc : in std_logic;
            inh : in std_logic;
            exc_spike : in std_logic;
            inh_spike : in std_logic;
            neuron_ready : out std_logic;
            out_spike : out std_logic
        );
    end component;

    component rom_578x256_exclif1 is
        port (
            clka : in std_logic;
            addra : in std_logic_vector(9 downto 0);
            dout_00 : out std_logic_vector(7 downto 0);
            dout_01 : out std_logic_vector(7 downto 0);
            dout_02 : out std_logic_vector(7 downto 0);
            dout_03 : out std_logic_vector(7 downto 0);
            dout_04 : out std_logic_vector(7 downto 0);
            dout_05 : out std_logic_vector(7 downto 0);
            dout_06 : out std_logic_vector(7 downto 0);
            dout_07 : out std_logic_vector(7 downto 0);
            dout_08 : out std_logic_vector(7 downto 0);
            dout_09 : out std_logic_vector(7 downto 0);
            dout_0a : out std_logic_vector(7 downto 0);
            dout_0b : out std_logic_vector(7 downto 0);
            dout_0c : out std_logic_vector(7 downto 0);
            dout_0d : out std_logic_vector(7 downto 0);
            dout_0e : out std_logic_vector(7 downto 0);
            dout_0f : out std_logic_vector(7 downto 0);
            dout_10 : out std_logic_vector(7 downto 0);
            dout_11 : out std_logic_vector(7 downto 0);
            dout_12 : out std_logic_vector(7 downto 0);
            dout_13 : out std_logic_vector(7 downto 0);
            dout_14 : out std_logic_vector(7 downto 0);
            dout_15 : out std_logic_vector(7 downto 0);
            dout_16 : out std_logic_vector(7 downto 0);
            dout_17 : out std_logic_vector(7 downto 0);
            dout_18 : out std_logic_vector(7 downto 0);
            dout_19 : out std_logic_vector(7 downto 0);
            dout_1a : out std_logic_vector(7 downto 0);
            dout_1b : out std_logic_vector(7 downto 0);
            dout_1c : out std_logic_vector(7 downto 0);
            dout_1d : out std_logic_vector(7 downto 0);
            dout_1e : out std_logic_vector(7 downto 0);
            dout_1f : out std_logic_vector(7 downto 0);
            dout_20 : out std_logic_vector(7 downto 0);
            dout_21 : out std_logic_vector(7 downto 0);
            dout_22 : out std_logic_vector(7 downto 0);
            dout_23 : out std_logic_vector(7 downto 0);
            dout_24 : out std_logic_vector(7 downto 0);
            dout_25 : out std_logic_vector(7 downto 0);
            dout_26 : out std_logic_vector(7 downto 0);
            dout_27 : out std_logic_vector(7 downto 0);
            dout_28 : out std_logic_vector(7 downto 0);
            dout_29 : out std_logic_vector(7 downto 0);
            dout_2a : out std_logic_vector(7 downto 0);
            dout_2b : out std_logic_vector(7 downto 0);
            dout_2c : out std_logic_vector(7 downto 0);
            dout_2d : out std_logic_vector(7 downto 0);
            dout_2e : out std_logic_vector(7 downto 0);
            dout_2f : out std_logic_vector(7 downto 0);
            dout_30 : out std_logic_vector(7 downto 0);
            dout_31 : out std_logic_vector(7 downto 0);
            dout_32 : out std_logic_vector(7 downto 0);
            dout_33 : out std_logic_vector(7 downto 0);
            dout_34 : out std_logic_vector(7 downto 0);
            dout_35 : out std_logic_vector(7 downto 0);
            dout_36 : out std_logic_vector(7 downto 0);
            dout_37 : out std_logic_vector(7 downto 0);
            dout_38 : out std_logic_vector(7 downto 0);
            dout_39 : out std_logic_vector(7 downto 0);
            dout_3a : out std_logic_vector(7 downto 0);
            dout_3b : out std_logic_vector(7 downto 0);
            dout_3c : out std_logic_vector(7 downto 0);
            dout_3d : out std_logic_vector(7 downto 0);
            dout_3e : out std_logic_vector(7 downto 0);
            dout_3f : out std_logic_vector(7 downto 0);
            dout_40 : out std_logic_vector(7 downto 0);
            dout_41 : out std_logic_vector(7 downto 0);
            dout_42 : out std_logic_vector(7 downto 0);
            dout_43 : out std_logic_vector(7 downto 0);
            dout_44 : out std_logic_vector(7 downto 0);
            dout_45 : out std_logic_vector(7 downto 0);
            dout_46 : out std_logic_vector(7 downto 0);
            dout_47 : out std_logic_vector(7 downto 0);
            dout_48 : out std_logic_vector(7 downto 0);
            dout_49 : out std_logic_vector(7 downto 0);
            dout_4a : out std_logic_vector(7 downto 0);
            dout_4b : out std_logic_vector(7 downto 0);
            dout_4c : out std_logic_vector(7 downto 0);
            dout_4d : out std_logic_vector(7 downto 0);
            dout_4e : out std_logic_vector(7 downto 0);
            dout_4f : out std_logic_vector(7 downto 0);
            dout_50 : out std_logic_vector(7 downto 0);
            dout_51 : out std_logic_vector(7 downto 0);
            dout_52 : out std_logic_vector(7 downto 0);
            dout_53 : out std_logic_vector(7 downto 0);
            dout_54 : out std_logic_vector(7 downto 0);
            dout_55 : out std_logic_vector(7 downto 0);
            dout_56 : out std_logic_vector(7 downto 0);
            dout_57 : out std_logic_vector(7 downto 0);
            dout_58 : out std_logic_vector(7 downto 0);
            dout_59 : out std_logic_vector(7 downto 0);
            dout_5a : out std_logic_vector(7 downto 0);
            dout_5b : out std_logic_vector(7 downto 0);
            dout_5c : out std_logic_vector(7 downto 0);
            dout_5d : out std_logic_vector(7 downto 0);
            dout_5e : out std_logic_vector(7 downto 0);
            dout_5f : out std_logic_vector(7 downto 0);
            dout_60 : out std_logic_vector(7 downto 0);
            dout_61 : out std_logic_vector(7 downto 0);
            dout_62 : out std_logic_vector(7 downto 0);
            dout_63 : out std_logic_vector(7 downto 0);
            dout_64 : out std_logic_vector(7 downto 0);
            dout_65 : out std_logic_vector(7 downto 0);
            dout_66 : out std_logic_vector(7 downto 0);
            dout_67 : out std_logic_vector(7 downto 0);
            dout_68 : out std_logic_vector(7 downto 0);
            dout_69 : out std_logic_vector(7 downto 0);
            dout_6a : out std_logic_vector(7 downto 0);
            dout_6b : out std_logic_vector(7 downto 0);
            dout_6c : out std_logic_vector(7 downto 0);
            dout_6d : out std_logic_vector(7 downto 0);
            dout_6e : out std_logic_vector(7 downto 0);
            dout_6f : out std_logic_vector(7 downto 0);
            dout_70 : out std_logic_vector(7 downto 0);
            dout_71 : out std_logic_vector(7 downto 0);
            dout_72 : out std_logic_vector(7 downto 0);
            dout_73 : out std_logic_vector(7 downto 0);
            dout_74 : out std_logic_vector(7 downto 0);
            dout_75 : out std_logic_vector(7 downto 0);
            dout_76 : out std_logic_vector(7 downto 0);
            dout_77 : out std_logic_vector(7 downto 0);
            dout_78 : out std_logic_vector(7 downto 0);
            dout_79 : out std_logic_vector(7 downto 0);
            dout_7a : out std_logic_vector(7 downto 0);
            dout_7b : out std_logic_vector(7 downto 0);
            dout_7c : out std_logic_vector(7 downto 0);
            dout_7d : out std_logic_vector(7 downto 0);
            dout_7e : out std_logic_vector(7 downto 0);
            dout_7f : out std_logic_vector(7 downto 0);
            dout_80 : out std_logic_vector(7 downto 0);
            dout_81 : out std_logic_vector(7 downto 0);
            dout_82 : out std_logic_vector(7 downto 0);
            dout_83 : out std_logic_vector(7 downto 0);
            dout_84 : out std_logic_vector(7 downto 0);
            dout_85 : out std_logic_vector(7 downto 0);
            dout_86 : out std_logic_vector(7 downto 0);
            dout_87 : out std_logic_vector(7 downto 0);
            dout_88 : out std_logic_vector(7 downto 0);
            dout_89 : out std_logic_vector(7 downto 0);
            dout_8a : out std_logic_vector(7 downto 0);
            dout_8b : out std_logic_vector(7 downto 0);
            dout_8c : out std_logic_vector(7 downto 0);
            dout_8d : out std_logic_vector(7 downto 0);
            dout_8e : out std_logic_vector(7 downto 0);
            dout_8f : out std_logic_vector(7 downto 0);
            dout_90 : out std_logic_vector(7 downto 0);
            dout_91 : out std_logic_vector(7 downto 0);
            dout_92 : out std_logic_vector(7 downto 0);
            dout_93 : out std_logic_vector(7 downto 0);
            dout_94 : out std_logic_vector(7 downto 0);
            dout_95 : out std_logic_vector(7 downto 0);
            dout_96 : out std_logic_vector(7 downto 0);
            dout_97 : out std_logic_vector(7 downto 0);
            dout_98 : out std_logic_vector(7 downto 0);
            dout_99 : out std_logic_vector(7 downto 0);
            dout_9a : out std_logic_vector(7 downto 0);
            dout_9b : out std_logic_vector(7 downto 0);
            dout_9c : out std_logic_vector(7 downto 0);
            dout_9d : out std_logic_vector(7 downto 0);
            dout_9e : out std_logic_vector(7 downto 0);
            dout_9f : out std_logic_vector(7 downto 0);
            dout_a0 : out std_logic_vector(7 downto 0);
            dout_a1 : out std_logic_vector(7 downto 0);
            dout_a2 : out std_logic_vector(7 downto 0);
            dout_a3 : out std_logic_vector(7 downto 0);
            dout_a4 : out std_logic_vector(7 downto 0);
            dout_a5 : out std_logic_vector(7 downto 0);
            dout_a6 : out std_logic_vector(7 downto 0);
            dout_a7 : out std_logic_vector(7 downto 0);
            dout_a8 : out std_logic_vector(7 downto 0);
            dout_a9 : out std_logic_vector(7 downto 0);
            dout_aa : out std_logic_vector(7 downto 0);
            dout_ab : out std_logic_vector(7 downto 0);
            dout_ac : out std_logic_vector(7 downto 0);
            dout_ad : out std_logic_vector(7 downto 0);
            dout_ae : out std_logic_vector(7 downto 0);
            dout_af : out std_logic_vector(7 downto 0);
            dout_b0 : out std_logic_vector(7 downto 0);
            dout_b1 : out std_logic_vector(7 downto 0);
            dout_b2 : out std_logic_vector(7 downto 0);
            dout_b3 : out std_logic_vector(7 downto 0);
            dout_b4 : out std_logic_vector(7 downto 0);
            dout_b5 : out std_logic_vector(7 downto 0);
            dout_b6 : out std_logic_vector(7 downto 0);
            dout_b7 : out std_logic_vector(7 downto 0);
            dout_b8 : out std_logic_vector(7 downto 0);
            dout_b9 : out std_logic_vector(7 downto 0);
            dout_ba : out std_logic_vector(7 downto 0);
            dout_bb : out std_logic_vector(7 downto 0);
            dout_bc : out std_logic_vector(7 downto 0);
            dout_bd : out std_logic_vector(7 downto 0);
            dout_be : out std_logic_vector(7 downto 0);
            dout_bf : out std_logic_vector(7 downto 0);
            dout_c0 : out std_logic_vector(7 downto 0);
            dout_c1 : out std_logic_vector(7 downto 0);
            dout_c2 : out std_logic_vector(7 downto 0);
            dout_c3 : out std_logic_vector(7 downto 0);
            dout_c4 : out std_logic_vector(7 downto 0);
            dout_c5 : out std_logic_vector(7 downto 0);
            dout_c6 : out std_logic_vector(7 downto 0);
            dout_c7 : out std_logic_vector(7 downto 0);
            dout_c8 : out std_logic_vector(7 downto 0);
            dout_c9 : out std_logic_vector(7 downto 0);
            dout_ca : out std_logic_vector(7 downto 0);
            dout_cb : out std_logic_vector(7 downto 0);
            dout_cc : out std_logic_vector(7 downto 0);
            dout_cd : out std_logic_vector(7 downto 0);
            dout_ce : out std_logic_vector(7 downto 0);
            dout_cf : out std_logic_vector(7 downto 0);
            dout_d0 : out std_logic_vector(7 downto 0);
            dout_d1 : out std_logic_vector(7 downto 0);
            dout_d2 : out std_logic_vector(7 downto 0);
            dout_d3 : out std_logic_vector(7 downto 0);
            dout_d4 : out std_logic_vector(7 downto 0);
            dout_d5 : out std_logic_vector(7 downto 0);
            dout_d6 : out std_logic_vector(7 downto 0);
            dout_d7 : out std_logic_vector(7 downto 0);
            dout_d8 : out std_logic_vector(7 downto 0);
            dout_d9 : out std_logic_vector(7 downto 0);
            dout_da : out std_logic_vector(7 downto 0);
            dout_db : out std_logic_vector(7 downto 0);
            dout_dc : out std_logic_vector(7 downto 0);
            dout_dd : out std_logic_vector(7 downto 0);
            dout_de : out std_logic_vector(7 downto 0);
            dout_df : out std_logic_vector(7 downto 0);
            dout_e0 : out std_logic_vector(7 downto 0);
            dout_e1 : out std_logic_vector(7 downto 0);
            dout_e2 : out std_logic_vector(7 downto 0);
            dout_e3 : out std_logic_vector(7 downto 0);
            dout_e4 : out std_logic_vector(7 downto 0);
            dout_e5 : out std_logic_vector(7 downto 0);
            dout_e6 : out std_logic_vector(7 downto 0);
            dout_e7 : out std_logic_vector(7 downto 0);
            dout_e8 : out std_logic_vector(7 downto 0);
            dout_e9 : out std_logic_vector(7 downto 0);
            dout_ea : out std_logic_vector(7 downto 0);
            dout_eb : out std_logic_vector(7 downto 0);
            dout_ec : out std_logic_vector(7 downto 0);
            dout_ed : out std_logic_vector(7 downto 0);
            dout_ee : out std_logic_vector(7 downto 0);
            dout_ef : out std_logic_vector(7 downto 0);
            dout_f0 : out std_logic_vector(7 downto 0);
            dout_f1 : out std_logic_vector(7 downto 0);
            dout_f2 : out std_logic_vector(7 downto 0);
            dout_f3 : out std_logic_vector(7 downto 0);
            dout_f4 : out std_logic_vector(7 downto 0);
            dout_f5 : out std_logic_vector(7 downto 0);
            dout_f6 : out std_logic_vector(7 downto 0);
            dout_f7 : out std_logic_vector(7 downto 0);
            dout_f8 : out std_logic_vector(7 downto 0);
            dout_f9 : out std_logic_vector(7 downto 0);
            dout_fa : out std_logic_vector(7 downto 0);
            dout_fb : out std_logic_vector(7 downto 0);
            dout_fc : out std_logic_vector(7 downto 0);
            dout_fd : out std_logic_vector(7 downto 0);
            dout_fe : out std_logic_vector(7 downto 0);
            dout_ff : out std_logic_vector(7 downto 0)
        );
    end component;

    component rom_256x256_inhlif1 is
        port (
            clka : in std_logic;
            addra : in std_logic_vector(7 downto 0);
            dout_00 : out std_logic_vector(7 downto 0);
            dout_01 : out std_logic_vector(7 downto 0);
            dout_02 : out std_logic_vector(7 downto 0);
            dout_03 : out std_logic_vector(7 downto 0);
            dout_04 : out std_logic_vector(7 downto 0);
            dout_05 : out std_logic_vector(7 downto 0);
            dout_06 : out std_logic_vector(7 downto 0);
            dout_07 : out std_logic_vector(7 downto 0);
            dout_08 : out std_logic_vector(7 downto 0);
            dout_09 : out std_logic_vector(7 downto 0);
            dout_0a : out std_logic_vector(7 downto 0);
            dout_0b : out std_logic_vector(7 downto 0);
            dout_0c : out std_logic_vector(7 downto 0);
            dout_0d : out std_logic_vector(7 downto 0);
            dout_0e : out std_logic_vector(7 downto 0);
            dout_0f : out std_logic_vector(7 downto 0);
            dout_10 : out std_logic_vector(7 downto 0);
            dout_11 : out std_logic_vector(7 downto 0);
            dout_12 : out std_logic_vector(7 downto 0);
            dout_13 : out std_logic_vector(7 downto 0);
            dout_14 : out std_logic_vector(7 downto 0);
            dout_15 : out std_logic_vector(7 downto 0);
            dout_16 : out std_logic_vector(7 downto 0);
            dout_17 : out std_logic_vector(7 downto 0);
            dout_18 : out std_logic_vector(7 downto 0);
            dout_19 : out std_logic_vector(7 downto 0);
            dout_1a : out std_logic_vector(7 downto 0);
            dout_1b : out std_logic_vector(7 downto 0);
            dout_1c : out std_logic_vector(7 downto 0);
            dout_1d : out std_logic_vector(7 downto 0);
            dout_1e : out std_logic_vector(7 downto 0);
            dout_1f : out std_logic_vector(7 downto 0);
            dout_20 : out std_logic_vector(7 downto 0);
            dout_21 : out std_logic_vector(7 downto 0);
            dout_22 : out std_logic_vector(7 downto 0);
            dout_23 : out std_logic_vector(7 downto 0);
            dout_24 : out std_logic_vector(7 downto 0);
            dout_25 : out std_logic_vector(7 downto 0);
            dout_26 : out std_logic_vector(7 downto 0);
            dout_27 : out std_logic_vector(7 downto 0);
            dout_28 : out std_logic_vector(7 downto 0);
            dout_29 : out std_logic_vector(7 downto 0);
            dout_2a : out std_logic_vector(7 downto 0);
            dout_2b : out std_logic_vector(7 downto 0);
            dout_2c : out std_logic_vector(7 downto 0);
            dout_2d : out std_logic_vector(7 downto 0);
            dout_2e : out std_logic_vector(7 downto 0);
            dout_2f : out std_logic_vector(7 downto 0);
            dout_30 : out std_logic_vector(7 downto 0);
            dout_31 : out std_logic_vector(7 downto 0);
            dout_32 : out std_logic_vector(7 downto 0);
            dout_33 : out std_logic_vector(7 downto 0);
            dout_34 : out std_logic_vector(7 downto 0);
            dout_35 : out std_logic_vector(7 downto 0);
            dout_36 : out std_logic_vector(7 downto 0);
            dout_37 : out std_logic_vector(7 downto 0);
            dout_38 : out std_logic_vector(7 downto 0);
            dout_39 : out std_logic_vector(7 downto 0);
            dout_3a : out std_logic_vector(7 downto 0);
            dout_3b : out std_logic_vector(7 downto 0);
            dout_3c : out std_logic_vector(7 downto 0);
            dout_3d : out std_logic_vector(7 downto 0);
            dout_3e : out std_logic_vector(7 downto 0);
            dout_3f : out std_logic_vector(7 downto 0);
            dout_40 : out std_logic_vector(7 downto 0);
            dout_41 : out std_logic_vector(7 downto 0);
            dout_42 : out std_logic_vector(7 downto 0);
            dout_43 : out std_logic_vector(7 downto 0);
            dout_44 : out std_logic_vector(7 downto 0);
            dout_45 : out std_logic_vector(7 downto 0);
            dout_46 : out std_logic_vector(7 downto 0);
            dout_47 : out std_logic_vector(7 downto 0);
            dout_48 : out std_logic_vector(7 downto 0);
            dout_49 : out std_logic_vector(7 downto 0);
            dout_4a : out std_logic_vector(7 downto 0);
            dout_4b : out std_logic_vector(7 downto 0);
            dout_4c : out std_logic_vector(7 downto 0);
            dout_4d : out std_logic_vector(7 downto 0);
            dout_4e : out std_logic_vector(7 downto 0);
            dout_4f : out std_logic_vector(7 downto 0);
            dout_50 : out std_logic_vector(7 downto 0);
            dout_51 : out std_logic_vector(7 downto 0);
            dout_52 : out std_logic_vector(7 downto 0);
            dout_53 : out std_logic_vector(7 downto 0);
            dout_54 : out std_logic_vector(7 downto 0);
            dout_55 : out std_logic_vector(7 downto 0);
            dout_56 : out std_logic_vector(7 downto 0);
            dout_57 : out std_logic_vector(7 downto 0);
            dout_58 : out std_logic_vector(7 downto 0);
            dout_59 : out std_logic_vector(7 downto 0);
            dout_5a : out std_logic_vector(7 downto 0);
            dout_5b : out std_logic_vector(7 downto 0);
            dout_5c : out std_logic_vector(7 downto 0);
            dout_5d : out std_logic_vector(7 downto 0);
            dout_5e : out std_logic_vector(7 downto 0);
            dout_5f : out std_logic_vector(7 downto 0);
            dout_60 : out std_logic_vector(7 downto 0);
            dout_61 : out std_logic_vector(7 downto 0);
            dout_62 : out std_logic_vector(7 downto 0);
            dout_63 : out std_logic_vector(7 downto 0);
            dout_64 : out std_logic_vector(7 downto 0);
            dout_65 : out std_logic_vector(7 downto 0);
            dout_66 : out std_logic_vector(7 downto 0);
            dout_67 : out std_logic_vector(7 downto 0);
            dout_68 : out std_logic_vector(7 downto 0);
            dout_69 : out std_logic_vector(7 downto 0);
            dout_6a : out std_logic_vector(7 downto 0);
            dout_6b : out std_logic_vector(7 downto 0);
            dout_6c : out std_logic_vector(7 downto 0);
            dout_6d : out std_logic_vector(7 downto 0);
            dout_6e : out std_logic_vector(7 downto 0);
            dout_6f : out std_logic_vector(7 downto 0);
            dout_70 : out std_logic_vector(7 downto 0);
            dout_71 : out std_logic_vector(7 downto 0);
            dout_72 : out std_logic_vector(7 downto 0);
            dout_73 : out std_logic_vector(7 downto 0);
            dout_74 : out std_logic_vector(7 downto 0);
            dout_75 : out std_logic_vector(7 downto 0);
            dout_76 : out std_logic_vector(7 downto 0);
            dout_77 : out std_logic_vector(7 downto 0);
            dout_78 : out std_logic_vector(7 downto 0);
            dout_79 : out std_logic_vector(7 downto 0);
            dout_7a : out std_logic_vector(7 downto 0);
            dout_7b : out std_logic_vector(7 downto 0);
            dout_7c : out std_logic_vector(7 downto 0);
            dout_7d : out std_logic_vector(7 downto 0);
            dout_7e : out std_logic_vector(7 downto 0);
            dout_7f : out std_logic_vector(7 downto 0);
            dout_80 : out std_logic_vector(7 downto 0);
            dout_81 : out std_logic_vector(7 downto 0);
            dout_82 : out std_logic_vector(7 downto 0);
            dout_83 : out std_logic_vector(7 downto 0);
            dout_84 : out std_logic_vector(7 downto 0);
            dout_85 : out std_logic_vector(7 downto 0);
            dout_86 : out std_logic_vector(7 downto 0);
            dout_87 : out std_logic_vector(7 downto 0);
            dout_88 : out std_logic_vector(7 downto 0);
            dout_89 : out std_logic_vector(7 downto 0);
            dout_8a : out std_logic_vector(7 downto 0);
            dout_8b : out std_logic_vector(7 downto 0);
            dout_8c : out std_logic_vector(7 downto 0);
            dout_8d : out std_logic_vector(7 downto 0);
            dout_8e : out std_logic_vector(7 downto 0);
            dout_8f : out std_logic_vector(7 downto 0);
            dout_90 : out std_logic_vector(7 downto 0);
            dout_91 : out std_logic_vector(7 downto 0);
            dout_92 : out std_logic_vector(7 downto 0);
            dout_93 : out std_logic_vector(7 downto 0);
            dout_94 : out std_logic_vector(7 downto 0);
            dout_95 : out std_logic_vector(7 downto 0);
            dout_96 : out std_logic_vector(7 downto 0);
            dout_97 : out std_logic_vector(7 downto 0);
            dout_98 : out std_logic_vector(7 downto 0);
            dout_99 : out std_logic_vector(7 downto 0);
            dout_9a : out std_logic_vector(7 downto 0);
            dout_9b : out std_logic_vector(7 downto 0);
            dout_9c : out std_logic_vector(7 downto 0);
            dout_9d : out std_logic_vector(7 downto 0);
            dout_9e : out std_logic_vector(7 downto 0);
            dout_9f : out std_logic_vector(7 downto 0);
            dout_a0 : out std_logic_vector(7 downto 0);
            dout_a1 : out std_logic_vector(7 downto 0);
            dout_a2 : out std_logic_vector(7 downto 0);
            dout_a3 : out std_logic_vector(7 downto 0);
            dout_a4 : out std_logic_vector(7 downto 0);
            dout_a5 : out std_logic_vector(7 downto 0);
            dout_a6 : out std_logic_vector(7 downto 0);
            dout_a7 : out std_logic_vector(7 downto 0);
            dout_a8 : out std_logic_vector(7 downto 0);
            dout_a9 : out std_logic_vector(7 downto 0);
            dout_aa : out std_logic_vector(7 downto 0);
            dout_ab : out std_logic_vector(7 downto 0);
            dout_ac : out std_logic_vector(7 downto 0);
            dout_ad : out std_logic_vector(7 downto 0);
            dout_ae : out std_logic_vector(7 downto 0);
            dout_af : out std_logic_vector(7 downto 0);
            dout_b0 : out std_logic_vector(7 downto 0);
            dout_b1 : out std_logic_vector(7 downto 0);
            dout_b2 : out std_logic_vector(7 downto 0);
            dout_b3 : out std_logic_vector(7 downto 0);
            dout_b4 : out std_logic_vector(7 downto 0);
            dout_b5 : out std_logic_vector(7 downto 0);
            dout_b6 : out std_logic_vector(7 downto 0);
            dout_b7 : out std_logic_vector(7 downto 0);
            dout_b8 : out std_logic_vector(7 downto 0);
            dout_b9 : out std_logic_vector(7 downto 0);
            dout_ba : out std_logic_vector(7 downto 0);
            dout_bb : out std_logic_vector(7 downto 0);
            dout_bc : out std_logic_vector(7 downto 0);
            dout_bd : out std_logic_vector(7 downto 0);
            dout_be : out std_logic_vector(7 downto 0);
            dout_bf : out std_logic_vector(7 downto 0);
            dout_c0 : out std_logic_vector(7 downto 0);
            dout_c1 : out std_logic_vector(7 downto 0);
            dout_c2 : out std_logic_vector(7 downto 0);
            dout_c3 : out std_logic_vector(7 downto 0);
            dout_c4 : out std_logic_vector(7 downto 0);
            dout_c5 : out std_logic_vector(7 downto 0);
            dout_c6 : out std_logic_vector(7 downto 0);
            dout_c7 : out std_logic_vector(7 downto 0);
            dout_c8 : out std_logic_vector(7 downto 0);
            dout_c9 : out std_logic_vector(7 downto 0);
            dout_ca : out std_logic_vector(7 downto 0);
            dout_cb : out std_logic_vector(7 downto 0);
            dout_cc : out std_logic_vector(7 downto 0);
            dout_cd : out std_logic_vector(7 downto 0);
            dout_ce : out std_logic_vector(7 downto 0);
            dout_cf : out std_logic_vector(7 downto 0);
            dout_d0 : out std_logic_vector(7 downto 0);
            dout_d1 : out std_logic_vector(7 downto 0);
            dout_d2 : out std_logic_vector(7 downto 0);
            dout_d3 : out std_logic_vector(7 downto 0);
            dout_d4 : out std_logic_vector(7 downto 0);
            dout_d5 : out std_logic_vector(7 downto 0);
            dout_d6 : out std_logic_vector(7 downto 0);
            dout_d7 : out std_logic_vector(7 downto 0);
            dout_d8 : out std_logic_vector(7 downto 0);
            dout_d9 : out std_logic_vector(7 downto 0);
            dout_da : out std_logic_vector(7 downto 0);
            dout_db : out std_logic_vector(7 downto 0);
            dout_dc : out std_logic_vector(7 downto 0);
            dout_dd : out std_logic_vector(7 downto 0);
            dout_de : out std_logic_vector(7 downto 0);
            dout_df : out std_logic_vector(7 downto 0);
            dout_e0 : out std_logic_vector(7 downto 0);
            dout_e1 : out std_logic_vector(7 downto 0);
            dout_e2 : out std_logic_vector(7 downto 0);
            dout_e3 : out std_logic_vector(7 downto 0);
            dout_e4 : out std_logic_vector(7 downto 0);
            dout_e5 : out std_logic_vector(7 downto 0);
            dout_e6 : out std_logic_vector(7 downto 0);
            dout_e7 : out std_logic_vector(7 downto 0);
            dout_e8 : out std_logic_vector(7 downto 0);
            dout_e9 : out std_logic_vector(7 downto 0);
            dout_ea : out std_logic_vector(7 downto 0);
            dout_eb : out std_logic_vector(7 downto 0);
            dout_ec : out std_logic_vector(7 downto 0);
            dout_ed : out std_logic_vector(7 downto 0);
            dout_ee : out std_logic_vector(7 downto 0);
            dout_ef : out std_logic_vector(7 downto 0);
            dout_f0 : out std_logic_vector(7 downto 0);
            dout_f1 : out std_logic_vector(7 downto 0);
            dout_f2 : out std_logic_vector(7 downto 0);
            dout_f3 : out std_logic_vector(7 downto 0);
            dout_f4 : out std_logic_vector(7 downto 0);
            dout_f5 : out std_logic_vector(7 downto 0);
            dout_f6 : out std_logic_vector(7 downto 0);
            dout_f7 : out std_logic_vector(7 downto 0);
            dout_f8 : out std_logic_vector(7 downto 0);
            dout_f9 : out std_logic_vector(7 downto 0);
            dout_fa : out std_logic_vector(7 downto 0);
            dout_fb : out std_logic_vector(7 downto 0);
            dout_fc : out std_logic_vector(7 downto 0);
            dout_fd : out std_logic_vector(7 downto 0);
            dout_fe : out std_logic_vector(7 downto 0);
            dout_ff : out std_logic_vector(7 downto 0)
        );
    end component;

    component addr_converter is
        generic (
            N : integer := 10
        );
        port (
            addr_in : in std_logic_vector(N-1 downto 0);
            addr_out : out std_logic_vector(N-1 downto 0)
        );
    end component;

    component barrier is
        generic (
            N : integer := 256
        );
        port (
            clk : in std_logic;
            rst_n : in std_logic;
            restart : in std_logic;
            out_sample : in std_logic;
            reg_in : in std_logic_vector(N-1 downto 0);
            ready : out std_logic;
            reg_out : out std_logic_vector(N-1 downto 0)
        );
    end component;


    signal start_neurons : std_logic;
    signal neurons_restart : std_logic;
    signal neurons_ready : std_logic;
    signal exc : std_logic;
    signal inh : std_logic;
    signal exc_spike : std_logic;
    signal inh_spike : std_logic;
    signal exc_cnt : std_logic_vector(exc_cnt_bitwidth - 1 downto 0);
    signal inh_cnt : std_logic_vector(inh_cnt_bitwidth - 1 downto 0);
    signal exc_addr : std_logic_vector(exc_cnt_bitwidth - 1 downto 0);
    signal inh_addr : std_logic_vector(inh_cnt_bitwidth - 1 downto 0);
    signal neuron_restart : std_logic;
    signal barrier_ready : std_logic;
    signal out_spikes_inst : std_logic_vector(255 downto 0);
    signal out_sample : std_logic;
    signal neuron_ready_00 : std_logic;
    signal inh_weight_00 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_00 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_01 : std_logic;
    signal inh_weight_01 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_01 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_02 : std_logic;
    signal inh_weight_02 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_02 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_03 : std_logic;
    signal inh_weight_03 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_03 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_04 : std_logic;
    signal inh_weight_04 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_04 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_05 : std_logic;
    signal inh_weight_05 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_05 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_06 : std_logic;
    signal inh_weight_06 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_06 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_07 : std_logic;
    signal inh_weight_07 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_07 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_08 : std_logic;
    signal inh_weight_08 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_08 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_09 : std_logic;
    signal inh_weight_09 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_09 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_0a : std_logic;
    signal inh_weight_0a : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_0a : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_0b : std_logic;
    signal inh_weight_0b : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_0b : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_0c : std_logic;
    signal inh_weight_0c : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_0c : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_0d : std_logic;
    signal inh_weight_0d : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_0d : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_0e : std_logic;
    signal inh_weight_0e : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_0e : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_0f : std_logic;
    signal inh_weight_0f : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_0f : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_10 : std_logic;
    signal inh_weight_10 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_10 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_11 : std_logic;
    signal inh_weight_11 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_11 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_12 : std_logic;
    signal inh_weight_12 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_12 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_13 : std_logic;
    signal inh_weight_13 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_13 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_14 : std_logic;
    signal inh_weight_14 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_14 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_15 : std_logic;
    signal inh_weight_15 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_15 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_16 : std_logic;
    signal inh_weight_16 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_16 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_17 : std_logic;
    signal inh_weight_17 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_17 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_18 : std_logic;
    signal inh_weight_18 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_18 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_19 : std_logic;
    signal inh_weight_19 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_19 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_1a : std_logic;
    signal inh_weight_1a : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_1a : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_1b : std_logic;
    signal inh_weight_1b : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_1b : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_1c : std_logic;
    signal inh_weight_1c : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_1c : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_1d : std_logic;
    signal inh_weight_1d : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_1d : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_1e : std_logic;
    signal inh_weight_1e : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_1e : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_1f : std_logic;
    signal inh_weight_1f : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_1f : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_20 : std_logic;
    signal inh_weight_20 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_20 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_21 : std_logic;
    signal inh_weight_21 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_21 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_22 : std_logic;
    signal inh_weight_22 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_22 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_23 : std_logic;
    signal inh_weight_23 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_23 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_24 : std_logic;
    signal inh_weight_24 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_24 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_25 : std_logic;
    signal inh_weight_25 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_25 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_26 : std_logic;
    signal inh_weight_26 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_26 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_27 : std_logic;
    signal inh_weight_27 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_27 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_28 : std_logic;
    signal inh_weight_28 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_28 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_29 : std_logic;
    signal inh_weight_29 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_29 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_2a : std_logic;
    signal inh_weight_2a : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_2a : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_2b : std_logic;
    signal inh_weight_2b : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_2b : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_2c : std_logic;
    signal inh_weight_2c : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_2c : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_2d : std_logic;
    signal inh_weight_2d : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_2d : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_2e : std_logic;
    signal inh_weight_2e : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_2e : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_2f : std_logic;
    signal inh_weight_2f : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_2f : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_30 : std_logic;
    signal inh_weight_30 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_30 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_31 : std_logic;
    signal inh_weight_31 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_31 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_32 : std_logic;
    signal inh_weight_32 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_32 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_33 : std_logic;
    signal inh_weight_33 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_33 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_34 : std_logic;
    signal inh_weight_34 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_34 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_35 : std_logic;
    signal inh_weight_35 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_35 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_36 : std_logic;
    signal inh_weight_36 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_36 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_37 : std_logic;
    signal inh_weight_37 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_37 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_38 : std_logic;
    signal inh_weight_38 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_38 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_39 : std_logic;
    signal inh_weight_39 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_39 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_3a : std_logic;
    signal inh_weight_3a : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_3a : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_3b : std_logic;
    signal inh_weight_3b : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_3b : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_3c : std_logic;
    signal inh_weight_3c : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_3c : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_3d : std_logic;
    signal inh_weight_3d : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_3d : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_3e : std_logic;
    signal inh_weight_3e : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_3e : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_3f : std_logic;
    signal inh_weight_3f : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_3f : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_40 : std_logic;
    signal inh_weight_40 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_40 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_41 : std_logic;
    signal inh_weight_41 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_41 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_42 : std_logic;
    signal inh_weight_42 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_42 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_43 : std_logic;
    signal inh_weight_43 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_43 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_44 : std_logic;
    signal inh_weight_44 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_44 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_45 : std_logic;
    signal inh_weight_45 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_45 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_46 : std_logic;
    signal inh_weight_46 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_46 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_47 : std_logic;
    signal inh_weight_47 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_47 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_48 : std_logic;
    signal inh_weight_48 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_48 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_49 : std_logic;
    signal inh_weight_49 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_49 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_4a : std_logic;
    signal inh_weight_4a : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_4a : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_4b : std_logic;
    signal inh_weight_4b : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_4b : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_4c : std_logic;
    signal inh_weight_4c : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_4c : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_4d : std_logic;
    signal inh_weight_4d : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_4d : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_4e : std_logic;
    signal inh_weight_4e : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_4e : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_4f : std_logic;
    signal inh_weight_4f : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_4f : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_50 : std_logic;
    signal inh_weight_50 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_50 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_51 : std_logic;
    signal inh_weight_51 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_51 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_52 : std_logic;
    signal inh_weight_52 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_52 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_53 : std_logic;
    signal inh_weight_53 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_53 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_54 : std_logic;
    signal inh_weight_54 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_54 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_55 : std_logic;
    signal inh_weight_55 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_55 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_56 : std_logic;
    signal inh_weight_56 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_56 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_57 : std_logic;
    signal inh_weight_57 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_57 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_58 : std_logic;
    signal inh_weight_58 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_58 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_59 : std_logic;
    signal inh_weight_59 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_59 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_5a : std_logic;
    signal inh_weight_5a : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_5a : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_5b : std_logic;
    signal inh_weight_5b : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_5b : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_5c : std_logic;
    signal inh_weight_5c : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_5c : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_5d : std_logic;
    signal inh_weight_5d : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_5d : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_5e : std_logic;
    signal inh_weight_5e : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_5e : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_5f : std_logic;
    signal inh_weight_5f : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_5f : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_60 : std_logic;
    signal inh_weight_60 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_60 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_61 : std_logic;
    signal inh_weight_61 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_61 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_62 : std_logic;
    signal inh_weight_62 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_62 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_63 : std_logic;
    signal inh_weight_63 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_63 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_64 : std_logic;
    signal inh_weight_64 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_64 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_65 : std_logic;
    signal inh_weight_65 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_65 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_66 : std_logic;
    signal inh_weight_66 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_66 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_67 : std_logic;
    signal inh_weight_67 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_67 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_68 : std_logic;
    signal inh_weight_68 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_68 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_69 : std_logic;
    signal inh_weight_69 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_69 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_6a : std_logic;
    signal inh_weight_6a : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_6a : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_6b : std_logic;
    signal inh_weight_6b : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_6b : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_6c : std_logic;
    signal inh_weight_6c : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_6c : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_6d : std_logic;
    signal inh_weight_6d : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_6d : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_6e : std_logic;
    signal inh_weight_6e : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_6e : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_6f : std_logic;
    signal inh_weight_6f : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_6f : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_70 : std_logic;
    signal inh_weight_70 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_70 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_71 : std_logic;
    signal inh_weight_71 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_71 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_72 : std_logic;
    signal inh_weight_72 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_72 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_73 : std_logic;
    signal inh_weight_73 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_73 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_74 : std_logic;
    signal inh_weight_74 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_74 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_75 : std_logic;
    signal inh_weight_75 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_75 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_76 : std_logic;
    signal inh_weight_76 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_76 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_77 : std_logic;
    signal inh_weight_77 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_77 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_78 : std_logic;
    signal inh_weight_78 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_78 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_79 : std_logic;
    signal inh_weight_79 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_79 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_7a : std_logic;
    signal inh_weight_7a : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_7a : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_7b : std_logic;
    signal inh_weight_7b : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_7b : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_7c : std_logic;
    signal inh_weight_7c : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_7c : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_7d : std_logic;
    signal inh_weight_7d : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_7d : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_7e : std_logic;
    signal inh_weight_7e : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_7e : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_7f : std_logic;
    signal inh_weight_7f : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_7f : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_80 : std_logic;
    signal inh_weight_80 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_80 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_81 : std_logic;
    signal inh_weight_81 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_81 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_82 : std_logic;
    signal inh_weight_82 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_82 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_83 : std_logic;
    signal inh_weight_83 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_83 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_84 : std_logic;
    signal inh_weight_84 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_84 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_85 : std_logic;
    signal inh_weight_85 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_85 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_86 : std_logic;
    signal inh_weight_86 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_86 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_87 : std_logic;
    signal inh_weight_87 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_87 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_88 : std_logic;
    signal inh_weight_88 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_88 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_89 : std_logic;
    signal inh_weight_89 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_89 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_8a : std_logic;
    signal inh_weight_8a : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_8a : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_8b : std_logic;
    signal inh_weight_8b : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_8b : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_8c : std_logic;
    signal inh_weight_8c : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_8c : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_8d : std_logic;
    signal inh_weight_8d : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_8d : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_8e : std_logic;
    signal inh_weight_8e : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_8e : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_8f : std_logic;
    signal inh_weight_8f : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_8f : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_90 : std_logic;
    signal inh_weight_90 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_90 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_91 : std_logic;
    signal inh_weight_91 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_91 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_92 : std_logic;
    signal inh_weight_92 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_92 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_93 : std_logic;
    signal inh_weight_93 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_93 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_94 : std_logic;
    signal inh_weight_94 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_94 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_95 : std_logic;
    signal inh_weight_95 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_95 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_96 : std_logic;
    signal inh_weight_96 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_96 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_97 : std_logic;
    signal inh_weight_97 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_97 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_98 : std_logic;
    signal inh_weight_98 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_98 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_99 : std_logic;
    signal inh_weight_99 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_99 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_9a : std_logic;
    signal inh_weight_9a : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_9a : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_9b : std_logic;
    signal inh_weight_9b : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_9b : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_9c : std_logic;
    signal inh_weight_9c : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_9c : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_9d : std_logic;
    signal inh_weight_9d : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_9d : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_9e : std_logic;
    signal inh_weight_9e : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_9e : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_9f : std_logic;
    signal inh_weight_9f : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_9f : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_a0 : std_logic;
    signal inh_weight_a0 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_a0 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_a1 : std_logic;
    signal inh_weight_a1 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_a1 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_a2 : std_logic;
    signal inh_weight_a2 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_a2 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_a3 : std_logic;
    signal inh_weight_a3 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_a3 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_a4 : std_logic;
    signal inh_weight_a4 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_a4 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_a5 : std_logic;
    signal inh_weight_a5 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_a5 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_a6 : std_logic;
    signal inh_weight_a6 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_a6 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_a7 : std_logic;
    signal inh_weight_a7 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_a7 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_a8 : std_logic;
    signal inh_weight_a8 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_a8 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_a9 : std_logic;
    signal inh_weight_a9 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_a9 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_aa : std_logic;
    signal inh_weight_aa : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_aa : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ab : std_logic;
    signal inh_weight_ab : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ab : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ac : std_logic;
    signal inh_weight_ac : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ac : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ad : std_logic;
    signal inh_weight_ad : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ad : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ae : std_logic;
    signal inh_weight_ae : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ae : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_af : std_logic;
    signal inh_weight_af : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_af : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_b0 : std_logic;
    signal inh_weight_b0 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_b0 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_b1 : std_logic;
    signal inh_weight_b1 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_b1 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_b2 : std_logic;
    signal inh_weight_b2 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_b2 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_b3 : std_logic;
    signal inh_weight_b3 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_b3 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_b4 : std_logic;
    signal inh_weight_b4 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_b4 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_b5 : std_logic;
    signal inh_weight_b5 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_b5 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_b6 : std_logic;
    signal inh_weight_b6 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_b6 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_b7 : std_logic;
    signal inh_weight_b7 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_b7 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_b8 : std_logic;
    signal inh_weight_b8 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_b8 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_b9 : std_logic;
    signal inh_weight_b9 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_b9 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ba : std_logic;
    signal inh_weight_ba : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ba : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_bb : std_logic;
    signal inh_weight_bb : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_bb : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_bc : std_logic;
    signal inh_weight_bc : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_bc : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_bd : std_logic;
    signal inh_weight_bd : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_bd : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_be : std_logic;
    signal inh_weight_be : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_be : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_bf : std_logic;
    signal inh_weight_bf : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_bf : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_c0 : std_logic;
    signal inh_weight_c0 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_c0 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_c1 : std_logic;
    signal inh_weight_c1 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_c1 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_c2 : std_logic;
    signal inh_weight_c2 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_c2 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_c3 : std_logic;
    signal inh_weight_c3 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_c3 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_c4 : std_logic;
    signal inh_weight_c4 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_c4 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_c5 : std_logic;
    signal inh_weight_c5 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_c5 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_c6 : std_logic;
    signal inh_weight_c6 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_c6 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_c7 : std_logic;
    signal inh_weight_c7 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_c7 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_c8 : std_logic;
    signal inh_weight_c8 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_c8 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_c9 : std_logic;
    signal inh_weight_c9 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_c9 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ca : std_logic;
    signal inh_weight_ca : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ca : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_cb : std_logic;
    signal inh_weight_cb : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_cb : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_cc : std_logic;
    signal inh_weight_cc : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_cc : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_cd : std_logic;
    signal inh_weight_cd : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_cd : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ce : std_logic;
    signal inh_weight_ce : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ce : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_cf : std_logic;
    signal inh_weight_cf : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_cf : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_d0 : std_logic;
    signal inh_weight_d0 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_d0 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_d1 : std_logic;
    signal inh_weight_d1 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_d1 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_d2 : std_logic;
    signal inh_weight_d2 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_d2 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_d3 : std_logic;
    signal inh_weight_d3 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_d3 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_d4 : std_logic;
    signal inh_weight_d4 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_d4 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_d5 : std_logic;
    signal inh_weight_d5 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_d5 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_d6 : std_logic;
    signal inh_weight_d6 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_d6 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_d7 : std_logic;
    signal inh_weight_d7 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_d7 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_d8 : std_logic;
    signal inh_weight_d8 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_d8 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_d9 : std_logic;
    signal inh_weight_d9 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_d9 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_da : std_logic;
    signal inh_weight_da : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_da : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_db : std_logic;
    signal inh_weight_db : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_db : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_dc : std_logic;
    signal inh_weight_dc : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_dc : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_dd : std_logic;
    signal inh_weight_dd : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_dd : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_de : std_logic;
    signal inh_weight_de : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_de : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_df : std_logic;
    signal inh_weight_df : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_df : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_e0 : std_logic;
    signal inh_weight_e0 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_e0 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_e1 : std_logic;
    signal inh_weight_e1 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_e1 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_e2 : std_logic;
    signal inh_weight_e2 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_e2 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_e3 : std_logic;
    signal inh_weight_e3 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_e3 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_e4 : std_logic;
    signal inh_weight_e4 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_e4 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_e5 : std_logic;
    signal inh_weight_e5 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_e5 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_e6 : std_logic;
    signal inh_weight_e6 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_e6 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_e7 : std_logic;
    signal inh_weight_e7 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_e7 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_e8 : std_logic;
    signal inh_weight_e8 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_e8 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_e9 : std_logic;
    signal inh_weight_e9 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_e9 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ea : std_logic;
    signal inh_weight_ea : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ea : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_eb : std_logic;
    signal inh_weight_eb : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_eb : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ec : std_logic;
    signal inh_weight_ec : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ec : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ed : std_logic;
    signal inh_weight_ed : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ed : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ee : std_logic;
    signal inh_weight_ee : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ee : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ef : std_logic;
    signal inh_weight_ef : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ef : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_f0 : std_logic;
    signal inh_weight_f0 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_f0 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_f1 : std_logic;
    signal inh_weight_f1 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_f1 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_f2 : std_logic;
    signal inh_weight_f2 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_f2 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_f3 : std_logic;
    signal inh_weight_f3 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_f3 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_f4 : std_logic;
    signal inh_weight_f4 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_f4 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_f5 : std_logic;
    signal inh_weight_f5 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_f5 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_f6 : std_logic;
    signal inh_weight_f6 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_f6 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_f7 : std_logic;
    signal inh_weight_f7 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_f7 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_f8 : std_logic;
    signal inh_weight_f8 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_f8 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_f9 : std_logic;
    signal inh_weight_f9 : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_f9 : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_fa : std_logic;
    signal inh_weight_fa : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_fa : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_fb : std_logic;
    signal inh_weight_fb : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_fb : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_fc : std_logic;
    signal inh_weight_fc : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_fc : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_fd : std_logic;
    signal inh_weight_fd : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_fd : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_fe : std_logic;
    signal inh_weight_fe : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_fe : std_logic_vector(exc_weights_bit_width-1 downto 0);
    signal neuron_ready_ff : std_logic;
    signal inh_weight_ff : std_logic_vector(inh_weights_bit_width-1 downto 0);
    signal exc_weight_ff : std_logic_vector(exc_weights_bit_width-1 downto 0);

begin

    neurons_ready <= neuron_ready_00 and neuron_ready_01 and neuron_ready_02 and neuron_ready_03 and neuron_ready_04 and neuron_ready_05 and neuron_ready_06 and neuron_ready_07 and neuron_ready_08 and neuron_ready_09 and neuron_ready_0a and neuron_ready_0b and neuron_ready_0c and neuron_ready_0d and neuron_ready_0e and neuron_ready_0f and neuron_ready_10 and neuron_ready_11 and neuron_ready_12 and neuron_ready_13 and neuron_ready_14 and neuron_ready_15 and neuron_ready_16 and neuron_ready_17 and neuron_ready_18 and neuron_ready_19 and neuron_ready_1a and neuron_ready_1b and neuron_ready_1c and neuron_ready_1d and neuron_ready_1e and neuron_ready_1f and neuron_ready_20 and neuron_ready_21 and neuron_ready_22 and neuron_ready_23 and neuron_ready_24 and neuron_ready_25 and neuron_ready_26 and neuron_ready_27 and neuron_ready_28 and neuron_ready_29 and neuron_ready_2a and neuron_ready_2b and neuron_ready_2c and neuron_ready_2d and neuron_ready_2e and neuron_ready_2f and neuron_ready_30 and neuron_ready_31 and neuron_ready_32 and neuron_ready_33 and neuron_ready_34 and neuron_ready_35 and neuron_ready_36 and neuron_ready_37 and neuron_ready_38 and neuron_ready_39 and neuron_ready_3a and neuron_ready_3b and neuron_ready_3c and neuron_ready_3d and neuron_ready_3e and neuron_ready_3f and neuron_ready_40 and neuron_ready_41 and neuron_ready_42 and neuron_ready_43 and neuron_ready_44 and neuron_ready_45 and neuron_ready_46 and neuron_ready_47 and neuron_ready_48 and neuron_ready_49 and neuron_ready_4a and neuron_ready_4b and neuron_ready_4c and neuron_ready_4d and neuron_ready_4e and neuron_ready_4f and neuron_ready_50 and neuron_ready_51 and neuron_ready_52 and neuron_ready_53 and neuron_ready_54 and neuron_ready_55 and neuron_ready_56 and neuron_ready_57 and neuron_ready_58 and neuron_ready_59 and neuron_ready_5a and neuron_ready_5b and neuron_ready_5c and neuron_ready_5d and neuron_ready_5e and neuron_ready_5f and neuron_ready_60 and neuron_ready_61 and neuron_ready_62 and neuron_ready_63 and neuron_ready_64 and neuron_ready_65 and neuron_ready_66 and neuron_ready_67 and neuron_ready_68 and neuron_ready_69 and neuron_ready_6a and neuron_ready_6b and neuron_ready_6c and neuron_ready_6d and neuron_ready_6e and neuron_ready_6f and neuron_ready_70 and neuron_ready_71 and neuron_ready_72 and neuron_ready_73 and neuron_ready_74 and neuron_ready_75 and neuron_ready_76 and neuron_ready_77 and neuron_ready_78 and neuron_ready_79 and neuron_ready_7a and neuron_ready_7b and neuron_ready_7c and neuron_ready_7d and neuron_ready_7e and neuron_ready_7f and neuron_ready_80 and neuron_ready_81 and neuron_ready_82 and neuron_ready_83 and neuron_ready_84 and neuron_ready_85 and neuron_ready_86 and neuron_ready_87 and neuron_ready_88 and neuron_ready_89 and neuron_ready_8a and neuron_ready_8b and neuron_ready_8c and neuron_ready_8d and neuron_ready_8e and neuron_ready_8f and neuron_ready_90 and neuron_ready_91 and neuron_ready_92 and neuron_ready_93 and neuron_ready_94 and neuron_ready_95 and neuron_ready_96 and neuron_ready_97 and neuron_ready_98 and neuron_ready_99 and neuron_ready_9a and neuron_ready_9b and neuron_ready_9c and neuron_ready_9d and neuron_ready_9e and neuron_ready_9f and neuron_ready_a0 and neuron_ready_a1 and neuron_ready_a2 and neuron_ready_a3 and neuron_ready_a4 and neuron_ready_a5 and neuron_ready_a6 and neuron_ready_a7 and neuron_ready_a8 and neuron_ready_a9 and neuron_ready_aa and neuron_ready_ab and neuron_ready_ac and neuron_ready_ad and neuron_ready_ae and neuron_ready_af and neuron_ready_b0 and neuron_ready_b1 and neuron_ready_b2 and neuron_ready_b3 and neuron_ready_b4 and neuron_ready_b5 and neuron_ready_b6 and neuron_ready_b7 and neuron_ready_b8 and neuron_ready_b9 and neuron_ready_ba and neuron_ready_bb and neuron_ready_bc and neuron_ready_bd and neuron_ready_be and neuron_ready_bf and neuron_ready_c0 and neuron_ready_c1 and neuron_ready_c2 and neuron_ready_c3 and neuron_ready_c4 and neuron_ready_c5 and neuron_ready_c6 and neuron_ready_c7 and neuron_ready_c8 and neuron_ready_c9 and neuron_ready_ca and neuron_ready_cb and neuron_ready_cc and neuron_ready_cd and neuron_ready_ce and neuron_ready_cf and neuron_ready_d0 and neuron_ready_d1 and neuron_ready_d2 and neuron_ready_d3 and neuron_ready_d4 and neuron_ready_d5 and neuron_ready_d6 and neuron_ready_d7 and neuron_ready_d8 and neuron_ready_d9 and neuron_ready_da and neuron_ready_db and neuron_ready_dc and neuron_ready_dd and neuron_ready_de and neuron_ready_df and neuron_ready_e0 and neuron_ready_e1 and neuron_ready_e2 and neuron_ready_e3 and neuron_ready_e4 and neuron_ready_e5 and neuron_ready_e6 and neuron_ready_e7 and neuron_ready_e8 and neuron_ready_e9 and neuron_ready_ea and neuron_ready_eb and neuron_ready_ec and neuron_ready_ed and neuron_ready_ee and neuron_ready_ef and neuron_ready_f0 and neuron_ready_f1 and neuron_ready_f2 and neuron_ready_f3 and neuron_ready_f4 and neuron_ready_f5 and neuron_ready_f6 and neuron_ready_f7 and neuron_ready_f8 and neuron_ready_f9 and neuron_ready_fa and neuron_ready_fb and neuron_ready_fc and neuron_ready_fd and neuron_ready_fe and neuron_ready_ff and barrier_ready;


    multi_input_control : multi_input_578_exc_256_inh
        generic map(
            n_exc_inputs => n_exc_inputs,
            n_inh_inputs => n_inh_inputs,
            exc_cnt_bitwidth => exc_cnt_bitwidth,
            inh_cnt_bitwidth => inh_cnt_bitwidth
        )
        port map(
            clk => clk,
            rst_n => rst_n,
            restart => restart,
            start => start,
            exc_spikes => exc_spikes,
            inh_spikes => inh_spikes,
            neurons_ready => neurons_ready,
            exc_cnt => exc_cnt,
            inh_cnt => inh_cnt,
            ready => ready,
            neuron_restart => neuron_restart,
            exc => exc,
            inh => inh,
            out_sample => out_sample,
            exc_spike => exc_spike,
            inh_spike => inh_spike
        );

    neuron_00 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_00,
            inh_weight => signed(inh_weight_00),
            exc_weight => signed(exc_weight_00),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_00,
            out_spike => out_spikes_inst(0)
        );

    neuron_01 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_01,
            inh_weight => signed(inh_weight_01),
            exc_weight => signed(exc_weight_01),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_01,
            out_spike => out_spikes_inst(1)
        );

    neuron_02 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_02,
            inh_weight => signed(inh_weight_02),
            exc_weight => signed(exc_weight_02),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_02,
            out_spike => out_spikes_inst(2)
        );

    neuron_03 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_03,
            inh_weight => signed(inh_weight_03),
            exc_weight => signed(exc_weight_03),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_03,
            out_spike => out_spikes_inst(3)
        );

    neuron_04 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_04,
            inh_weight => signed(inh_weight_04),
            exc_weight => signed(exc_weight_04),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_04,
            out_spike => out_spikes_inst(4)
        );

    neuron_05 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_05,
            inh_weight => signed(inh_weight_05),
            exc_weight => signed(exc_weight_05),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_05,
            out_spike => out_spikes_inst(5)
        );

    neuron_06 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_06,
            inh_weight => signed(inh_weight_06),
            exc_weight => signed(exc_weight_06),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_06,
            out_spike => out_spikes_inst(6)
        );

    neuron_07 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_07,
            inh_weight => signed(inh_weight_07),
            exc_weight => signed(exc_weight_07),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_07,
            out_spike => out_spikes_inst(7)
        );

    neuron_08 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_08,
            inh_weight => signed(inh_weight_08),
            exc_weight => signed(exc_weight_08),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_08,
            out_spike => out_spikes_inst(8)
        );

    neuron_09 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_09,
            inh_weight => signed(inh_weight_09),
            exc_weight => signed(exc_weight_09),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_09,
            out_spike => out_spikes_inst(9)
        );

    neuron_0a : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_0a,
            inh_weight => signed(inh_weight_0a),
            exc_weight => signed(exc_weight_0a),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_0a,
            out_spike => out_spikes_inst(10)
        );

    neuron_0b : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_0b,
            inh_weight => signed(inh_weight_0b),
            exc_weight => signed(exc_weight_0b),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_0b,
            out_spike => out_spikes_inst(11)
        );

    neuron_0c : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_0c,
            inh_weight => signed(inh_weight_0c),
            exc_weight => signed(exc_weight_0c),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_0c,
            out_spike => out_spikes_inst(12)
        );

    neuron_0d : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_0d,
            inh_weight => signed(inh_weight_0d),
            exc_weight => signed(exc_weight_0d),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_0d,
            out_spike => out_spikes_inst(13)
        );

    neuron_0e : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_0e,
            inh_weight => signed(inh_weight_0e),
            exc_weight => signed(exc_weight_0e),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_0e,
            out_spike => out_spikes_inst(14)
        );

    neuron_0f : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_0f,
            inh_weight => signed(inh_weight_0f),
            exc_weight => signed(exc_weight_0f),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_0f,
            out_spike => out_spikes_inst(15)
        );

    neuron_10 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_10,
            inh_weight => signed(inh_weight_10),
            exc_weight => signed(exc_weight_10),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_10,
            out_spike => out_spikes_inst(16)
        );

    neuron_11 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_11,
            inh_weight => signed(inh_weight_11),
            exc_weight => signed(exc_weight_11),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_11,
            out_spike => out_spikes_inst(17)
        );

    neuron_12 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_12,
            inh_weight => signed(inh_weight_12),
            exc_weight => signed(exc_weight_12),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_12,
            out_spike => out_spikes_inst(18)
        );

    neuron_13 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_13,
            inh_weight => signed(inh_weight_13),
            exc_weight => signed(exc_weight_13),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_13,
            out_spike => out_spikes_inst(19)
        );

    neuron_14 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_14,
            inh_weight => signed(inh_weight_14),
            exc_weight => signed(exc_weight_14),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_14,
            out_spike => out_spikes_inst(20)
        );

    neuron_15 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_15,
            inh_weight => signed(inh_weight_15),
            exc_weight => signed(exc_weight_15),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_15,
            out_spike => out_spikes_inst(21)
        );

    neuron_16 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_16,
            inh_weight => signed(inh_weight_16),
            exc_weight => signed(exc_weight_16),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_16,
            out_spike => out_spikes_inst(22)
        );

    neuron_17 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_17,
            inh_weight => signed(inh_weight_17),
            exc_weight => signed(exc_weight_17),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_17,
            out_spike => out_spikes_inst(23)
        );

    neuron_18 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_18,
            inh_weight => signed(inh_weight_18),
            exc_weight => signed(exc_weight_18),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_18,
            out_spike => out_spikes_inst(24)
        );

    neuron_19 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_19,
            inh_weight => signed(inh_weight_19),
            exc_weight => signed(exc_weight_19),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_19,
            out_spike => out_spikes_inst(25)
        );

    neuron_1a : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_1a,
            inh_weight => signed(inh_weight_1a),
            exc_weight => signed(exc_weight_1a),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_1a,
            out_spike => out_spikes_inst(26)
        );

    neuron_1b : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_1b,
            inh_weight => signed(inh_weight_1b),
            exc_weight => signed(exc_weight_1b),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_1b,
            out_spike => out_spikes_inst(27)
        );

    neuron_1c : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_1c,
            inh_weight => signed(inh_weight_1c),
            exc_weight => signed(exc_weight_1c),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_1c,
            out_spike => out_spikes_inst(28)
        );

    neuron_1d : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_1d,
            inh_weight => signed(inh_weight_1d),
            exc_weight => signed(exc_weight_1d),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_1d,
            out_spike => out_spikes_inst(29)
        );

    neuron_1e : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_1e,
            inh_weight => signed(inh_weight_1e),
            exc_weight => signed(exc_weight_1e),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_1e,
            out_spike => out_spikes_inst(30)
        );

    neuron_1f : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_1f,
            inh_weight => signed(inh_weight_1f),
            exc_weight => signed(exc_weight_1f),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_1f,
            out_spike => out_spikes_inst(31)
        );

    neuron_20 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_20,
            inh_weight => signed(inh_weight_20),
            exc_weight => signed(exc_weight_20),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_20,
            out_spike => out_spikes_inst(32)
        );

    neuron_21 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_21,
            inh_weight => signed(inh_weight_21),
            exc_weight => signed(exc_weight_21),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_21,
            out_spike => out_spikes_inst(33)
        );

    neuron_22 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_22,
            inh_weight => signed(inh_weight_22),
            exc_weight => signed(exc_weight_22),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_22,
            out_spike => out_spikes_inst(34)
        );

    neuron_23 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_23,
            inh_weight => signed(inh_weight_23),
            exc_weight => signed(exc_weight_23),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_23,
            out_spike => out_spikes_inst(35)
        );

    neuron_24 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_24,
            inh_weight => signed(inh_weight_24),
            exc_weight => signed(exc_weight_24),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_24,
            out_spike => out_spikes_inst(36)
        );

    neuron_25 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_25,
            inh_weight => signed(inh_weight_25),
            exc_weight => signed(exc_weight_25),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_25,
            out_spike => out_spikes_inst(37)
        );

    neuron_26 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_26,
            inh_weight => signed(inh_weight_26),
            exc_weight => signed(exc_weight_26),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_26,
            out_spike => out_spikes_inst(38)
        );

    neuron_27 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_27,
            inh_weight => signed(inh_weight_27),
            exc_weight => signed(exc_weight_27),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_27,
            out_spike => out_spikes_inst(39)
        );

    neuron_28 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_28,
            inh_weight => signed(inh_weight_28),
            exc_weight => signed(exc_weight_28),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_28,
            out_spike => out_spikes_inst(40)
        );

    neuron_29 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_29,
            inh_weight => signed(inh_weight_29),
            exc_weight => signed(exc_weight_29),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_29,
            out_spike => out_spikes_inst(41)
        );

    neuron_2a : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_2a,
            inh_weight => signed(inh_weight_2a),
            exc_weight => signed(exc_weight_2a),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_2a,
            out_spike => out_spikes_inst(42)
        );

    neuron_2b : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_2b,
            inh_weight => signed(inh_weight_2b),
            exc_weight => signed(exc_weight_2b),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_2b,
            out_spike => out_spikes_inst(43)
        );

    neuron_2c : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_2c,
            inh_weight => signed(inh_weight_2c),
            exc_weight => signed(exc_weight_2c),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_2c,
            out_spike => out_spikes_inst(44)
        );

    neuron_2d : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_2d,
            inh_weight => signed(inh_weight_2d),
            exc_weight => signed(exc_weight_2d),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_2d,
            out_spike => out_spikes_inst(45)
        );

    neuron_2e : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_2e,
            inh_weight => signed(inh_weight_2e),
            exc_weight => signed(exc_weight_2e),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_2e,
            out_spike => out_spikes_inst(46)
        );

    neuron_2f : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_2f,
            inh_weight => signed(inh_weight_2f),
            exc_weight => signed(exc_weight_2f),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_2f,
            out_spike => out_spikes_inst(47)
        );

    neuron_30 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_30,
            inh_weight => signed(inh_weight_30),
            exc_weight => signed(exc_weight_30),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_30,
            out_spike => out_spikes_inst(48)
        );

    neuron_31 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_31,
            inh_weight => signed(inh_weight_31),
            exc_weight => signed(exc_weight_31),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_31,
            out_spike => out_spikes_inst(49)
        );

    neuron_32 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_32,
            inh_weight => signed(inh_weight_32),
            exc_weight => signed(exc_weight_32),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_32,
            out_spike => out_spikes_inst(50)
        );

    neuron_33 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_33,
            inh_weight => signed(inh_weight_33),
            exc_weight => signed(exc_weight_33),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_33,
            out_spike => out_spikes_inst(51)
        );

    neuron_34 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_34,
            inh_weight => signed(inh_weight_34),
            exc_weight => signed(exc_weight_34),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_34,
            out_spike => out_spikes_inst(52)
        );

    neuron_35 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_35,
            inh_weight => signed(inh_weight_35),
            exc_weight => signed(exc_weight_35),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_35,
            out_spike => out_spikes_inst(53)
        );

    neuron_36 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_36,
            inh_weight => signed(inh_weight_36),
            exc_weight => signed(exc_weight_36),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_36,
            out_spike => out_spikes_inst(54)
        );

    neuron_37 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_37,
            inh_weight => signed(inh_weight_37),
            exc_weight => signed(exc_weight_37),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_37,
            out_spike => out_spikes_inst(55)
        );

    neuron_38 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_38,
            inh_weight => signed(inh_weight_38),
            exc_weight => signed(exc_weight_38),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_38,
            out_spike => out_spikes_inst(56)
        );

    neuron_39 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_39,
            inh_weight => signed(inh_weight_39),
            exc_weight => signed(exc_weight_39),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_39,
            out_spike => out_spikes_inst(57)
        );

    neuron_3a : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_3a,
            inh_weight => signed(inh_weight_3a),
            exc_weight => signed(exc_weight_3a),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_3a,
            out_spike => out_spikes_inst(58)
        );

    neuron_3b : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_3b,
            inh_weight => signed(inh_weight_3b),
            exc_weight => signed(exc_weight_3b),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_3b,
            out_spike => out_spikes_inst(59)
        );

    neuron_3c : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_3c,
            inh_weight => signed(inh_weight_3c),
            exc_weight => signed(exc_weight_3c),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_3c,
            out_spike => out_spikes_inst(60)
        );

    neuron_3d : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_3d,
            inh_weight => signed(inh_weight_3d),
            exc_weight => signed(exc_weight_3d),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_3d,
            out_spike => out_spikes_inst(61)
        );

    neuron_3e : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_3e,
            inh_weight => signed(inh_weight_3e),
            exc_weight => signed(exc_weight_3e),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_3e,
            out_spike => out_spikes_inst(62)
        );

    neuron_3f : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_3f,
            inh_weight => signed(inh_weight_3f),
            exc_weight => signed(exc_weight_3f),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_3f,
            out_spike => out_spikes_inst(63)
        );

    neuron_40 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_40,
            inh_weight => signed(inh_weight_40),
            exc_weight => signed(exc_weight_40),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_40,
            out_spike => out_spikes_inst(64)
        );

    neuron_41 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_41,
            inh_weight => signed(inh_weight_41),
            exc_weight => signed(exc_weight_41),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_41,
            out_spike => out_spikes_inst(65)
        );

    neuron_42 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_42,
            inh_weight => signed(inh_weight_42),
            exc_weight => signed(exc_weight_42),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_42,
            out_spike => out_spikes_inst(66)
        );

    neuron_43 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_43,
            inh_weight => signed(inh_weight_43),
            exc_weight => signed(exc_weight_43),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_43,
            out_spike => out_spikes_inst(67)
        );

    neuron_44 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_44,
            inh_weight => signed(inh_weight_44),
            exc_weight => signed(exc_weight_44),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_44,
            out_spike => out_spikes_inst(68)
        );

    neuron_45 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_45,
            inh_weight => signed(inh_weight_45),
            exc_weight => signed(exc_weight_45),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_45,
            out_spike => out_spikes_inst(69)
        );

    neuron_46 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_46,
            inh_weight => signed(inh_weight_46),
            exc_weight => signed(exc_weight_46),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_46,
            out_spike => out_spikes_inst(70)
        );

    neuron_47 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_47,
            inh_weight => signed(inh_weight_47),
            exc_weight => signed(exc_weight_47),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_47,
            out_spike => out_spikes_inst(71)
        );

    neuron_48 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_48,
            inh_weight => signed(inh_weight_48),
            exc_weight => signed(exc_weight_48),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_48,
            out_spike => out_spikes_inst(72)
        );

    neuron_49 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_49,
            inh_weight => signed(inh_weight_49),
            exc_weight => signed(exc_weight_49),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_49,
            out_spike => out_spikes_inst(73)
        );

    neuron_4a : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_4a,
            inh_weight => signed(inh_weight_4a),
            exc_weight => signed(exc_weight_4a),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_4a,
            out_spike => out_spikes_inst(74)
        );

    neuron_4b : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_4b,
            inh_weight => signed(inh_weight_4b),
            exc_weight => signed(exc_weight_4b),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_4b,
            out_spike => out_spikes_inst(75)
        );

    neuron_4c : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_4c,
            inh_weight => signed(inh_weight_4c),
            exc_weight => signed(exc_weight_4c),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_4c,
            out_spike => out_spikes_inst(76)
        );

    neuron_4d : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_4d,
            inh_weight => signed(inh_weight_4d),
            exc_weight => signed(exc_weight_4d),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_4d,
            out_spike => out_spikes_inst(77)
        );

    neuron_4e : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_4e,
            inh_weight => signed(inh_weight_4e),
            exc_weight => signed(exc_weight_4e),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_4e,
            out_spike => out_spikes_inst(78)
        );

    neuron_4f : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_4f,
            inh_weight => signed(inh_weight_4f),
            exc_weight => signed(exc_weight_4f),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_4f,
            out_spike => out_spikes_inst(79)
        );

    neuron_50 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_50,
            inh_weight => signed(inh_weight_50),
            exc_weight => signed(exc_weight_50),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_50,
            out_spike => out_spikes_inst(80)
        );

    neuron_51 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_51,
            inh_weight => signed(inh_weight_51),
            exc_weight => signed(exc_weight_51),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_51,
            out_spike => out_spikes_inst(81)
        );

    neuron_52 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_52,
            inh_weight => signed(inh_weight_52),
            exc_weight => signed(exc_weight_52),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_52,
            out_spike => out_spikes_inst(82)
        );

    neuron_53 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_53,
            inh_weight => signed(inh_weight_53),
            exc_weight => signed(exc_weight_53),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_53,
            out_spike => out_spikes_inst(83)
        );

    neuron_54 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_54,
            inh_weight => signed(inh_weight_54),
            exc_weight => signed(exc_weight_54),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_54,
            out_spike => out_spikes_inst(84)
        );

    neuron_55 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_55,
            inh_weight => signed(inh_weight_55),
            exc_weight => signed(exc_weight_55),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_55,
            out_spike => out_spikes_inst(85)
        );

    neuron_56 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_56,
            inh_weight => signed(inh_weight_56),
            exc_weight => signed(exc_weight_56),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_56,
            out_spike => out_spikes_inst(86)
        );

    neuron_57 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_57,
            inh_weight => signed(inh_weight_57),
            exc_weight => signed(exc_weight_57),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_57,
            out_spike => out_spikes_inst(87)
        );

    neuron_58 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_58,
            inh_weight => signed(inh_weight_58),
            exc_weight => signed(exc_weight_58),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_58,
            out_spike => out_spikes_inst(88)
        );

    neuron_59 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_59,
            inh_weight => signed(inh_weight_59),
            exc_weight => signed(exc_weight_59),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_59,
            out_spike => out_spikes_inst(89)
        );

    neuron_5a : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_5a,
            inh_weight => signed(inh_weight_5a),
            exc_weight => signed(exc_weight_5a),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_5a,
            out_spike => out_spikes_inst(90)
        );

    neuron_5b : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_5b,
            inh_weight => signed(inh_weight_5b),
            exc_weight => signed(exc_weight_5b),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_5b,
            out_spike => out_spikes_inst(91)
        );

    neuron_5c : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_5c,
            inh_weight => signed(inh_weight_5c),
            exc_weight => signed(exc_weight_5c),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_5c,
            out_spike => out_spikes_inst(92)
        );

    neuron_5d : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_5d,
            inh_weight => signed(inh_weight_5d),
            exc_weight => signed(exc_weight_5d),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_5d,
            out_spike => out_spikes_inst(93)
        );

    neuron_5e : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_5e,
            inh_weight => signed(inh_weight_5e),
            exc_weight => signed(exc_weight_5e),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_5e,
            out_spike => out_spikes_inst(94)
        );

    neuron_5f : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_5f,
            inh_weight => signed(inh_weight_5f),
            exc_weight => signed(exc_weight_5f),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_5f,
            out_spike => out_spikes_inst(95)
        );

    neuron_60 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_60,
            inh_weight => signed(inh_weight_60),
            exc_weight => signed(exc_weight_60),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_60,
            out_spike => out_spikes_inst(96)
        );

    neuron_61 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_61,
            inh_weight => signed(inh_weight_61),
            exc_weight => signed(exc_weight_61),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_61,
            out_spike => out_spikes_inst(97)
        );

    neuron_62 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_62,
            inh_weight => signed(inh_weight_62),
            exc_weight => signed(exc_weight_62),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_62,
            out_spike => out_spikes_inst(98)
        );

    neuron_63 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_63,
            inh_weight => signed(inh_weight_63),
            exc_weight => signed(exc_weight_63),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_63,
            out_spike => out_spikes_inst(99)
        );

    neuron_64 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_64,
            inh_weight => signed(inh_weight_64),
            exc_weight => signed(exc_weight_64),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_64,
            out_spike => out_spikes_inst(100)
        );

    neuron_65 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_65,
            inh_weight => signed(inh_weight_65),
            exc_weight => signed(exc_weight_65),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_65,
            out_spike => out_spikes_inst(101)
        );

    neuron_66 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_66,
            inh_weight => signed(inh_weight_66),
            exc_weight => signed(exc_weight_66),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_66,
            out_spike => out_spikes_inst(102)
        );

    neuron_67 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_67,
            inh_weight => signed(inh_weight_67),
            exc_weight => signed(exc_weight_67),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_67,
            out_spike => out_spikes_inst(103)
        );

    neuron_68 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_68,
            inh_weight => signed(inh_weight_68),
            exc_weight => signed(exc_weight_68),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_68,
            out_spike => out_spikes_inst(104)
        );

    neuron_69 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_69,
            inh_weight => signed(inh_weight_69),
            exc_weight => signed(exc_weight_69),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_69,
            out_spike => out_spikes_inst(105)
        );

    neuron_6a : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_6a,
            inh_weight => signed(inh_weight_6a),
            exc_weight => signed(exc_weight_6a),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_6a,
            out_spike => out_spikes_inst(106)
        );

    neuron_6b : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_6b,
            inh_weight => signed(inh_weight_6b),
            exc_weight => signed(exc_weight_6b),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_6b,
            out_spike => out_spikes_inst(107)
        );

    neuron_6c : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_6c,
            inh_weight => signed(inh_weight_6c),
            exc_weight => signed(exc_weight_6c),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_6c,
            out_spike => out_spikes_inst(108)
        );

    neuron_6d : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_6d,
            inh_weight => signed(inh_weight_6d),
            exc_weight => signed(exc_weight_6d),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_6d,
            out_spike => out_spikes_inst(109)
        );

    neuron_6e : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_6e,
            inh_weight => signed(inh_weight_6e),
            exc_weight => signed(exc_weight_6e),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_6e,
            out_spike => out_spikes_inst(110)
        );

    neuron_6f : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_6f,
            inh_weight => signed(inh_weight_6f),
            exc_weight => signed(exc_weight_6f),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_6f,
            out_spike => out_spikes_inst(111)
        );

    neuron_70 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_70,
            inh_weight => signed(inh_weight_70),
            exc_weight => signed(exc_weight_70),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_70,
            out_spike => out_spikes_inst(112)
        );

    neuron_71 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_71,
            inh_weight => signed(inh_weight_71),
            exc_weight => signed(exc_weight_71),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_71,
            out_spike => out_spikes_inst(113)
        );

    neuron_72 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_72,
            inh_weight => signed(inh_weight_72),
            exc_weight => signed(exc_weight_72),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_72,
            out_spike => out_spikes_inst(114)
        );

    neuron_73 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_73,
            inh_weight => signed(inh_weight_73),
            exc_weight => signed(exc_weight_73),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_73,
            out_spike => out_spikes_inst(115)
        );

    neuron_74 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_74,
            inh_weight => signed(inh_weight_74),
            exc_weight => signed(exc_weight_74),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_74,
            out_spike => out_spikes_inst(116)
        );

    neuron_75 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_75,
            inh_weight => signed(inh_weight_75),
            exc_weight => signed(exc_weight_75),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_75,
            out_spike => out_spikes_inst(117)
        );

    neuron_76 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_76,
            inh_weight => signed(inh_weight_76),
            exc_weight => signed(exc_weight_76),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_76,
            out_spike => out_spikes_inst(118)
        );

    neuron_77 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_77,
            inh_weight => signed(inh_weight_77),
            exc_weight => signed(exc_weight_77),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_77,
            out_spike => out_spikes_inst(119)
        );

    neuron_78 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_78,
            inh_weight => signed(inh_weight_78),
            exc_weight => signed(exc_weight_78),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_78,
            out_spike => out_spikes_inst(120)
        );

    neuron_79 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_79,
            inh_weight => signed(inh_weight_79),
            exc_weight => signed(exc_weight_79),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_79,
            out_spike => out_spikes_inst(121)
        );

    neuron_7a : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_7a,
            inh_weight => signed(inh_weight_7a),
            exc_weight => signed(exc_weight_7a),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_7a,
            out_spike => out_spikes_inst(122)
        );

    neuron_7b : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_7b,
            inh_weight => signed(inh_weight_7b),
            exc_weight => signed(exc_weight_7b),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_7b,
            out_spike => out_spikes_inst(123)
        );

    neuron_7c : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_7c,
            inh_weight => signed(inh_weight_7c),
            exc_weight => signed(exc_weight_7c),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_7c,
            out_spike => out_spikes_inst(124)
        );

    neuron_7d : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_7d,
            inh_weight => signed(inh_weight_7d),
            exc_weight => signed(exc_weight_7d),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_7d,
            out_spike => out_spikes_inst(125)
        );

    neuron_7e : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_7e,
            inh_weight => signed(inh_weight_7e),
            exc_weight => signed(exc_weight_7e),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_7e,
            out_spike => out_spikes_inst(126)
        );

    neuron_7f : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_7f,
            inh_weight => signed(inh_weight_7f),
            exc_weight => signed(exc_weight_7f),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_7f,
            out_spike => out_spikes_inst(127)
        );

    neuron_80 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_80,
            inh_weight => signed(inh_weight_80),
            exc_weight => signed(exc_weight_80),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_80,
            out_spike => out_spikes_inst(128)
        );

    neuron_81 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_81,
            inh_weight => signed(inh_weight_81),
            exc_weight => signed(exc_weight_81),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_81,
            out_spike => out_spikes_inst(129)
        );

    neuron_82 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_82,
            inh_weight => signed(inh_weight_82),
            exc_weight => signed(exc_weight_82),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_82,
            out_spike => out_spikes_inst(130)
        );

    neuron_83 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_83,
            inh_weight => signed(inh_weight_83),
            exc_weight => signed(exc_weight_83),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_83,
            out_spike => out_spikes_inst(131)
        );

    neuron_84 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_84,
            inh_weight => signed(inh_weight_84),
            exc_weight => signed(exc_weight_84),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_84,
            out_spike => out_spikes_inst(132)
        );

    neuron_85 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_85,
            inh_weight => signed(inh_weight_85),
            exc_weight => signed(exc_weight_85),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_85,
            out_spike => out_spikes_inst(133)
        );

    neuron_86 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_86,
            inh_weight => signed(inh_weight_86),
            exc_weight => signed(exc_weight_86),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_86,
            out_spike => out_spikes_inst(134)
        );

    neuron_87 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_87,
            inh_weight => signed(inh_weight_87),
            exc_weight => signed(exc_weight_87),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_87,
            out_spike => out_spikes_inst(135)
        );

    neuron_88 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_88,
            inh_weight => signed(inh_weight_88),
            exc_weight => signed(exc_weight_88),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_88,
            out_spike => out_spikes_inst(136)
        );

    neuron_89 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_89,
            inh_weight => signed(inh_weight_89),
            exc_weight => signed(exc_weight_89),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_89,
            out_spike => out_spikes_inst(137)
        );

    neuron_8a : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_8a,
            inh_weight => signed(inh_weight_8a),
            exc_weight => signed(exc_weight_8a),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_8a,
            out_spike => out_spikes_inst(138)
        );

    neuron_8b : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_8b,
            inh_weight => signed(inh_weight_8b),
            exc_weight => signed(exc_weight_8b),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_8b,
            out_spike => out_spikes_inst(139)
        );

    neuron_8c : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_8c,
            inh_weight => signed(inh_weight_8c),
            exc_weight => signed(exc_weight_8c),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_8c,
            out_spike => out_spikes_inst(140)
        );

    neuron_8d : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_8d,
            inh_weight => signed(inh_weight_8d),
            exc_weight => signed(exc_weight_8d),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_8d,
            out_spike => out_spikes_inst(141)
        );

    neuron_8e : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_8e,
            inh_weight => signed(inh_weight_8e),
            exc_weight => signed(exc_weight_8e),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_8e,
            out_spike => out_spikes_inst(142)
        );

    neuron_8f : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_8f,
            inh_weight => signed(inh_weight_8f),
            exc_weight => signed(exc_weight_8f),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_8f,
            out_spike => out_spikes_inst(143)
        );

    neuron_90 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_90,
            inh_weight => signed(inh_weight_90),
            exc_weight => signed(exc_weight_90),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_90,
            out_spike => out_spikes_inst(144)
        );

    neuron_91 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_91,
            inh_weight => signed(inh_weight_91),
            exc_weight => signed(exc_weight_91),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_91,
            out_spike => out_spikes_inst(145)
        );

    neuron_92 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_92,
            inh_weight => signed(inh_weight_92),
            exc_weight => signed(exc_weight_92),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_92,
            out_spike => out_spikes_inst(146)
        );

    neuron_93 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_93,
            inh_weight => signed(inh_weight_93),
            exc_weight => signed(exc_weight_93),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_93,
            out_spike => out_spikes_inst(147)
        );

    neuron_94 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_94,
            inh_weight => signed(inh_weight_94),
            exc_weight => signed(exc_weight_94),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_94,
            out_spike => out_spikes_inst(148)
        );

    neuron_95 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_95,
            inh_weight => signed(inh_weight_95),
            exc_weight => signed(exc_weight_95),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_95,
            out_spike => out_spikes_inst(149)
        );

    neuron_96 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_96,
            inh_weight => signed(inh_weight_96),
            exc_weight => signed(exc_weight_96),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_96,
            out_spike => out_spikes_inst(150)
        );

    neuron_97 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_97,
            inh_weight => signed(inh_weight_97),
            exc_weight => signed(exc_weight_97),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_97,
            out_spike => out_spikes_inst(151)
        );

    neuron_98 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_98,
            inh_weight => signed(inh_weight_98),
            exc_weight => signed(exc_weight_98),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_98,
            out_spike => out_spikes_inst(152)
        );

    neuron_99 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_99,
            inh_weight => signed(inh_weight_99),
            exc_weight => signed(exc_weight_99),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_99,
            out_spike => out_spikes_inst(153)
        );

    neuron_9a : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_9a,
            inh_weight => signed(inh_weight_9a),
            exc_weight => signed(exc_weight_9a),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_9a,
            out_spike => out_spikes_inst(154)
        );

    neuron_9b : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_9b,
            inh_weight => signed(inh_weight_9b),
            exc_weight => signed(exc_weight_9b),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_9b,
            out_spike => out_spikes_inst(155)
        );

    neuron_9c : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_9c,
            inh_weight => signed(inh_weight_9c),
            exc_weight => signed(exc_weight_9c),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_9c,
            out_spike => out_spikes_inst(156)
        );

    neuron_9d : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_9d,
            inh_weight => signed(inh_weight_9d),
            exc_weight => signed(exc_weight_9d),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_9d,
            out_spike => out_spikes_inst(157)
        );

    neuron_9e : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_9e,
            inh_weight => signed(inh_weight_9e),
            exc_weight => signed(exc_weight_9e),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_9e,
            out_spike => out_spikes_inst(158)
        );

    neuron_9f : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_9f,
            inh_weight => signed(inh_weight_9f),
            exc_weight => signed(exc_weight_9f),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_9f,
            out_spike => out_spikes_inst(159)
        );

    neuron_a0 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_a0,
            inh_weight => signed(inh_weight_a0),
            exc_weight => signed(exc_weight_a0),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_a0,
            out_spike => out_spikes_inst(160)
        );

    neuron_a1 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_a1,
            inh_weight => signed(inh_weight_a1),
            exc_weight => signed(exc_weight_a1),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_a1,
            out_spike => out_spikes_inst(161)
        );

    neuron_a2 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_a2,
            inh_weight => signed(inh_weight_a2),
            exc_weight => signed(exc_weight_a2),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_a2,
            out_spike => out_spikes_inst(162)
        );

    neuron_a3 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_a3,
            inh_weight => signed(inh_weight_a3),
            exc_weight => signed(exc_weight_a3),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_a3,
            out_spike => out_spikes_inst(163)
        );

    neuron_a4 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_a4,
            inh_weight => signed(inh_weight_a4),
            exc_weight => signed(exc_weight_a4),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_a4,
            out_spike => out_spikes_inst(164)
        );

    neuron_a5 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_a5,
            inh_weight => signed(inh_weight_a5),
            exc_weight => signed(exc_weight_a5),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_a5,
            out_spike => out_spikes_inst(165)
        );

    neuron_a6 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_a6,
            inh_weight => signed(inh_weight_a6),
            exc_weight => signed(exc_weight_a6),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_a6,
            out_spike => out_spikes_inst(166)
        );

    neuron_a7 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_a7,
            inh_weight => signed(inh_weight_a7),
            exc_weight => signed(exc_weight_a7),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_a7,
            out_spike => out_spikes_inst(167)
        );

    neuron_a8 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_a8,
            inh_weight => signed(inh_weight_a8),
            exc_weight => signed(exc_weight_a8),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_a8,
            out_spike => out_spikes_inst(168)
        );

    neuron_a9 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_a9,
            inh_weight => signed(inh_weight_a9),
            exc_weight => signed(exc_weight_a9),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_a9,
            out_spike => out_spikes_inst(169)
        );

    neuron_aa : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_aa,
            inh_weight => signed(inh_weight_aa),
            exc_weight => signed(exc_weight_aa),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_aa,
            out_spike => out_spikes_inst(170)
        );

    neuron_ab : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ab,
            inh_weight => signed(inh_weight_ab),
            exc_weight => signed(exc_weight_ab),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ab,
            out_spike => out_spikes_inst(171)
        );

    neuron_ac : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ac,
            inh_weight => signed(inh_weight_ac),
            exc_weight => signed(exc_weight_ac),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ac,
            out_spike => out_spikes_inst(172)
        );

    neuron_ad : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ad,
            inh_weight => signed(inh_weight_ad),
            exc_weight => signed(exc_weight_ad),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ad,
            out_spike => out_spikes_inst(173)
        );

    neuron_ae : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ae,
            inh_weight => signed(inh_weight_ae),
            exc_weight => signed(exc_weight_ae),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ae,
            out_spike => out_spikes_inst(174)
        );

    neuron_af : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_af,
            inh_weight => signed(inh_weight_af),
            exc_weight => signed(exc_weight_af),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_af,
            out_spike => out_spikes_inst(175)
        );

    neuron_b0 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_b0,
            inh_weight => signed(inh_weight_b0),
            exc_weight => signed(exc_weight_b0),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_b0,
            out_spike => out_spikes_inst(176)
        );

    neuron_b1 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_b1,
            inh_weight => signed(inh_weight_b1),
            exc_weight => signed(exc_weight_b1),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_b1,
            out_spike => out_spikes_inst(177)
        );

    neuron_b2 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_b2,
            inh_weight => signed(inh_weight_b2),
            exc_weight => signed(exc_weight_b2),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_b2,
            out_spike => out_spikes_inst(178)
        );

    neuron_b3 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_b3,
            inh_weight => signed(inh_weight_b3),
            exc_weight => signed(exc_weight_b3),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_b3,
            out_spike => out_spikes_inst(179)
        );

    neuron_b4 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_b4,
            inh_weight => signed(inh_weight_b4),
            exc_weight => signed(exc_weight_b4),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_b4,
            out_spike => out_spikes_inst(180)
        );

    neuron_b5 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_b5,
            inh_weight => signed(inh_weight_b5),
            exc_weight => signed(exc_weight_b5),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_b5,
            out_spike => out_spikes_inst(181)
        );

    neuron_b6 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_b6,
            inh_weight => signed(inh_weight_b6),
            exc_weight => signed(exc_weight_b6),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_b6,
            out_spike => out_spikes_inst(182)
        );

    neuron_b7 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_b7,
            inh_weight => signed(inh_weight_b7),
            exc_weight => signed(exc_weight_b7),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_b7,
            out_spike => out_spikes_inst(183)
        );

    neuron_b8 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_b8,
            inh_weight => signed(inh_weight_b8),
            exc_weight => signed(exc_weight_b8),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_b8,
            out_spike => out_spikes_inst(184)
        );

    neuron_b9 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_b9,
            inh_weight => signed(inh_weight_b9),
            exc_weight => signed(exc_weight_b9),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_b9,
            out_spike => out_spikes_inst(185)
        );

    neuron_ba : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ba,
            inh_weight => signed(inh_weight_ba),
            exc_weight => signed(exc_weight_ba),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ba,
            out_spike => out_spikes_inst(186)
        );

    neuron_bb : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_bb,
            inh_weight => signed(inh_weight_bb),
            exc_weight => signed(exc_weight_bb),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_bb,
            out_spike => out_spikes_inst(187)
        );

    neuron_bc : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_bc,
            inh_weight => signed(inh_weight_bc),
            exc_weight => signed(exc_weight_bc),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_bc,
            out_spike => out_spikes_inst(188)
        );

    neuron_bd : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_bd,
            inh_weight => signed(inh_weight_bd),
            exc_weight => signed(exc_weight_bd),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_bd,
            out_spike => out_spikes_inst(189)
        );

    neuron_be : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_be,
            inh_weight => signed(inh_weight_be),
            exc_weight => signed(exc_weight_be),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_be,
            out_spike => out_spikes_inst(190)
        );

    neuron_bf : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_bf,
            inh_weight => signed(inh_weight_bf),
            exc_weight => signed(exc_weight_bf),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_bf,
            out_spike => out_spikes_inst(191)
        );

    neuron_c0 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_c0,
            inh_weight => signed(inh_weight_c0),
            exc_weight => signed(exc_weight_c0),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_c0,
            out_spike => out_spikes_inst(192)
        );

    neuron_c1 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_c1,
            inh_weight => signed(inh_weight_c1),
            exc_weight => signed(exc_weight_c1),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_c1,
            out_spike => out_spikes_inst(193)
        );

    neuron_c2 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_c2,
            inh_weight => signed(inh_weight_c2),
            exc_weight => signed(exc_weight_c2),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_c2,
            out_spike => out_spikes_inst(194)
        );

    neuron_c3 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_c3,
            inh_weight => signed(inh_weight_c3),
            exc_weight => signed(exc_weight_c3),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_c3,
            out_spike => out_spikes_inst(195)
        );

    neuron_c4 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_c4,
            inh_weight => signed(inh_weight_c4),
            exc_weight => signed(exc_weight_c4),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_c4,
            out_spike => out_spikes_inst(196)
        );

    neuron_c5 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_c5,
            inh_weight => signed(inh_weight_c5),
            exc_weight => signed(exc_weight_c5),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_c5,
            out_spike => out_spikes_inst(197)
        );

    neuron_c6 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_c6,
            inh_weight => signed(inh_weight_c6),
            exc_weight => signed(exc_weight_c6),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_c6,
            out_spike => out_spikes_inst(198)
        );

    neuron_c7 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_c7,
            inh_weight => signed(inh_weight_c7),
            exc_weight => signed(exc_weight_c7),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_c7,
            out_spike => out_spikes_inst(199)
        );

    neuron_c8 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_c8,
            inh_weight => signed(inh_weight_c8),
            exc_weight => signed(exc_weight_c8),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_c8,
            out_spike => out_spikes_inst(200)
        );

    neuron_c9 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_c9,
            inh_weight => signed(inh_weight_c9),
            exc_weight => signed(exc_weight_c9),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_c9,
            out_spike => out_spikes_inst(201)
        );

    neuron_ca : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ca,
            inh_weight => signed(inh_weight_ca),
            exc_weight => signed(exc_weight_ca),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ca,
            out_spike => out_spikes_inst(202)
        );

    neuron_cb : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_cb,
            inh_weight => signed(inh_weight_cb),
            exc_weight => signed(exc_weight_cb),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_cb,
            out_spike => out_spikes_inst(203)
        );

    neuron_cc : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_cc,
            inh_weight => signed(inh_weight_cc),
            exc_weight => signed(exc_weight_cc),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_cc,
            out_spike => out_spikes_inst(204)
        );

    neuron_cd : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_cd,
            inh_weight => signed(inh_weight_cd),
            exc_weight => signed(exc_weight_cd),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_cd,
            out_spike => out_spikes_inst(205)
        );

    neuron_ce : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ce,
            inh_weight => signed(inh_weight_ce),
            exc_weight => signed(exc_weight_ce),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ce,
            out_spike => out_spikes_inst(206)
        );

    neuron_cf : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_cf,
            inh_weight => signed(inh_weight_cf),
            exc_weight => signed(exc_weight_cf),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_cf,
            out_spike => out_spikes_inst(207)
        );

    neuron_d0 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_d0,
            inh_weight => signed(inh_weight_d0),
            exc_weight => signed(exc_weight_d0),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_d0,
            out_spike => out_spikes_inst(208)
        );

    neuron_d1 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_d1,
            inh_weight => signed(inh_weight_d1),
            exc_weight => signed(exc_weight_d1),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_d1,
            out_spike => out_spikes_inst(209)
        );

    neuron_d2 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_d2,
            inh_weight => signed(inh_weight_d2),
            exc_weight => signed(exc_weight_d2),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_d2,
            out_spike => out_spikes_inst(210)
        );

    neuron_d3 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_d3,
            inh_weight => signed(inh_weight_d3),
            exc_weight => signed(exc_weight_d3),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_d3,
            out_spike => out_spikes_inst(211)
        );

    neuron_d4 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_d4,
            inh_weight => signed(inh_weight_d4),
            exc_weight => signed(exc_weight_d4),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_d4,
            out_spike => out_spikes_inst(212)
        );

    neuron_d5 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_d5,
            inh_weight => signed(inh_weight_d5),
            exc_weight => signed(exc_weight_d5),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_d5,
            out_spike => out_spikes_inst(213)
        );

    neuron_d6 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_d6,
            inh_weight => signed(inh_weight_d6),
            exc_weight => signed(exc_weight_d6),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_d6,
            out_spike => out_spikes_inst(214)
        );

    neuron_d7 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_d7,
            inh_weight => signed(inh_weight_d7),
            exc_weight => signed(exc_weight_d7),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_d7,
            out_spike => out_spikes_inst(215)
        );

    neuron_d8 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_d8,
            inh_weight => signed(inh_weight_d8),
            exc_weight => signed(exc_weight_d8),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_d8,
            out_spike => out_spikes_inst(216)
        );

    neuron_d9 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_d9,
            inh_weight => signed(inh_weight_d9),
            exc_weight => signed(exc_weight_d9),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_d9,
            out_spike => out_spikes_inst(217)
        );

    neuron_da : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_da,
            inh_weight => signed(inh_weight_da),
            exc_weight => signed(exc_weight_da),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_da,
            out_spike => out_spikes_inst(218)
        );

    neuron_db : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_db,
            inh_weight => signed(inh_weight_db),
            exc_weight => signed(exc_weight_db),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_db,
            out_spike => out_spikes_inst(219)
        );

    neuron_dc : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_dc,
            inh_weight => signed(inh_weight_dc),
            exc_weight => signed(exc_weight_dc),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_dc,
            out_spike => out_spikes_inst(220)
        );

    neuron_dd : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_dd,
            inh_weight => signed(inh_weight_dd),
            exc_weight => signed(exc_weight_dd),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_dd,
            out_spike => out_spikes_inst(221)
        );

    neuron_de : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_de,
            inh_weight => signed(inh_weight_de),
            exc_weight => signed(exc_weight_de),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_de,
            out_spike => out_spikes_inst(222)
        );

    neuron_df : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_df,
            inh_weight => signed(inh_weight_df),
            exc_weight => signed(exc_weight_df),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_df,
            out_spike => out_spikes_inst(223)
        );

    neuron_e0 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_e0,
            inh_weight => signed(inh_weight_e0),
            exc_weight => signed(exc_weight_e0),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_e0,
            out_spike => out_spikes_inst(224)
        );

    neuron_e1 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_e1,
            inh_weight => signed(inh_weight_e1),
            exc_weight => signed(exc_weight_e1),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_e1,
            out_spike => out_spikes_inst(225)
        );

    neuron_e2 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_e2,
            inh_weight => signed(inh_weight_e2),
            exc_weight => signed(exc_weight_e2),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_e2,
            out_spike => out_spikes_inst(226)
        );

    neuron_e3 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_e3,
            inh_weight => signed(inh_weight_e3),
            exc_weight => signed(exc_weight_e3),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_e3,
            out_spike => out_spikes_inst(227)
        );

    neuron_e4 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_e4,
            inh_weight => signed(inh_weight_e4),
            exc_weight => signed(exc_weight_e4),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_e4,
            out_spike => out_spikes_inst(228)
        );

    neuron_e5 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_e5,
            inh_weight => signed(inh_weight_e5),
            exc_weight => signed(exc_weight_e5),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_e5,
            out_spike => out_spikes_inst(229)
        );

    neuron_e6 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_e6,
            inh_weight => signed(inh_weight_e6),
            exc_weight => signed(exc_weight_e6),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_e6,
            out_spike => out_spikes_inst(230)
        );

    neuron_e7 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_e7,
            inh_weight => signed(inh_weight_e7),
            exc_weight => signed(exc_weight_e7),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_e7,
            out_spike => out_spikes_inst(231)
        );

    neuron_e8 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_e8,
            inh_weight => signed(inh_weight_e8),
            exc_weight => signed(exc_weight_e8),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_e8,
            out_spike => out_spikes_inst(232)
        );

    neuron_e9 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_e9,
            inh_weight => signed(inh_weight_e9),
            exc_weight => signed(exc_weight_e9),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_e9,
            out_spike => out_spikes_inst(233)
        );

    neuron_ea : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ea,
            inh_weight => signed(inh_weight_ea),
            exc_weight => signed(exc_weight_ea),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ea,
            out_spike => out_spikes_inst(234)
        );

    neuron_eb : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_eb,
            inh_weight => signed(inh_weight_eb),
            exc_weight => signed(exc_weight_eb),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_eb,
            out_spike => out_spikes_inst(235)
        );

    neuron_ec : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ec,
            inh_weight => signed(inh_weight_ec),
            exc_weight => signed(exc_weight_ec),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ec,
            out_spike => out_spikes_inst(236)
        );

    neuron_ed : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ed,
            inh_weight => signed(inh_weight_ed),
            exc_weight => signed(exc_weight_ed),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ed,
            out_spike => out_spikes_inst(237)
        );

    neuron_ee : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ee,
            inh_weight => signed(inh_weight_ee),
            exc_weight => signed(exc_weight_ee),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ee,
            out_spike => out_spikes_inst(238)
        );

    neuron_ef : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ef,
            inh_weight => signed(inh_weight_ef),
            exc_weight => signed(exc_weight_ef),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ef,
            out_spike => out_spikes_inst(239)
        );

    neuron_f0 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_f0,
            inh_weight => signed(inh_weight_f0),
            exc_weight => signed(exc_weight_f0),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_f0,
            out_spike => out_spikes_inst(240)
        );

    neuron_f1 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_f1,
            inh_weight => signed(inh_weight_f1),
            exc_weight => signed(exc_weight_f1),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_f1,
            out_spike => out_spikes_inst(241)
        );

    neuron_f2 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_f2,
            inh_weight => signed(inh_weight_f2),
            exc_weight => signed(exc_weight_f2),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_f2,
            out_spike => out_spikes_inst(242)
        );

    neuron_f3 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_f3,
            inh_weight => signed(inh_weight_f3),
            exc_weight => signed(exc_weight_f3),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_f3,
            out_spike => out_spikes_inst(243)
        );

    neuron_f4 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_f4,
            inh_weight => signed(inh_weight_f4),
            exc_weight => signed(exc_weight_f4),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_f4,
            out_spike => out_spikes_inst(244)
        );

    neuron_f5 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_f5,
            inh_weight => signed(inh_weight_f5),
            exc_weight => signed(exc_weight_f5),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_f5,
            out_spike => out_spikes_inst(245)
        );

    neuron_f6 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_f6,
            inh_weight => signed(inh_weight_f6),
            exc_weight => signed(exc_weight_f6),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_f6,
            out_spike => out_spikes_inst(246)
        );

    neuron_f7 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_f7,
            inh_weight => signed(inh_weight_f7),
            exc_weight => signed(exc_weight_f7),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_f7,
            out_spike => out_spikes_inst(247)
        );

    neuron_f8 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_f8,
            inh_weight => signed(inh_weight_f8),
            exc_weight => signed(exc_weight_f8),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_f8,
            out_spike => out_spikes_inst(248)
        );

    neuron_f9 : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_f9,
            inh_weight => signed(inh_weight_f9),
            exc_weight => signed(exc_weight_f9),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_f9,
            out_spike => out_spikes_inst(249)
        );

    neuron_fa : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_fa,
            inh_weight => signed(inh_weight_fa),
            exc_weight => signed(exc_weight_fa),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_fa,
            out_spike => out_spikes_inst(250)
        );

    neuron_fb : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_fb,
            inh_weight => signed(inh_weight_fb),
            exc_weight => signed(exc_weight_fb),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_fb,
            out_spike => out_spikes_inst(251)
        );

    neuron_fc : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_fc,
            inh_weight => signed(inh_weight_fc),
            exc_weight => signed(exc_weight_fc),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_fc,
            out_spike => out_spikes_inst(252)
        );

    neuron_fd : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_fd,
            inh_weight => signed(inh_weight_fd),
            exc_weight => signed(exc_weight_fd),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_fd,
            out_spike => out_spikes_inst(253)
        );

    neuron_fe : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_fe,
            inh_weight => signed(inh_weight_fe),
            exc_weight => signed(exc_weight_fe),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_fe,
            out_spike => out_spikes_inst(254)
        );

    neuron_ff : neuron_subtractive
        generic map(
            neuron_bit_width => neuron_bit_width,
            inh_weights_bit_width => inh_weights_bit_width,
            exc_weights_bit_width => exc_weights_bit_width,
            shift => shift
        )
        port map(
            v_th => v_th_ff,
            inh_weight => signed(inh_weight_ff),
            exc_weight => signed(exc_weight_ff),
            clk => clk,
            rst_n => rst_n,
            restart => neuron_restart,
            exc => exc,
            inh => inh,
            exc_spike => exc_spike,
            inh_spike => inh_spike,
            neuron_ready => neuron_ready_ff,
            out_spike => out_spikes_inst(255)
        );

    exc_mem : rom_578x256_exclif1
        port map(
            clka => clk,
            addra => exc_addr,
            dout_00 => exc_weight_00,
            dout_01 => exc_weight_01,
            dout_02 => exc_weight_02,
            dout_03 => exc_weight_03,
            dout_04 => exc_weight_04,
            dout_05 => exc_weight_05,
            dout_06 => exc_weight_06,
            dout_07 => exc_weight_07,
            dout_08 => exc_weight_08,
            dout_09 => exc_weight_09,
            dout_0a => exc_weight_0a,
            dout_0b => exc_weight_0b,
            dout_0c => exc_weight_0c,
            dout_0d => exc_weight_0d,
            dout_0e => exc_weight_0e,
            dout_0f => exc_weight_0f,
            dout_10 => exc_weight_10,
            dout_11 => exc_weight_11,
            dout_12 => exc_weight_12,
            dout_13 => exc_weight_13,
            dout_14 => exc_weight_14,
            dout_15 => exc_weight_15,
            dout_16 => exc_weight_16,
            dout_17 => exc_weight_17,
            dout_18 => exc_weight_18,
            dout_19 => exc_weight_19,
            dout_1a => exc_weight_1a,
            dout_1b => exc_weight_1b,
            dout_1c => exc_weight_1c,
            dout_1d => exc_weight_1d,
            dout_1e => exc_weight_1e,
            dout_1f => exc_weight_1f,
            dout_20 => exc_weight_20,
            dout_21 => exc_weight_21,
            dout_22 => exc_weight_22,
            dout_23 => exc_weight_23,
            dout_24 => exc_weight_24,
            dout_25 => exc_weight_25,
            dout_26 => exc_weight_26,
            dout_27 => exc_weight_27,
            dout_28 => exc_weight_28,
            dout_29 => exc_weight_29,
            dout_2a => exc_weight_2a,
            dout_2b => exc_weight_2b,
            dout_2c => exc_weight_2c,
            dout_2d => exc_weight_2d,
            dout_2e => exc_weight_2e,
            dout_2f => exc_weight_2f,
            dout_30 => exc_weight_30,
            dout_31 => exc_weight_31,
            dout_32 => exc_weight_32,
            dout_33 => exc_weight_33,
            dout_34 => exc_weight_34,
            dout_35 => exc_weight_35,
            dout_36 => exc_weight_36,
            dout_37 => exc_weight_37,
            dout_38 => exc_weight_38,
            dout_39 => exc_weight_39,
            dout_3a => exc_weight_3a,
            dout_3b => exc_weight_3b,
            dout_3c => exc_weight_3c,
            dout_3d => exc_weight_3d,
            dout_3e => exc_weight_3e,
            dout_3f => exc_weight_3f,
            dout_40 => exc_weight_40,
            dout_41 => exc_weight_41,
            dout_42 => exc_weight_42,
            dout_43 => exc_weight_43,
            dout_44 => exc_weight_44,
            dout_45 => exc_weight_45,
            dout_46 => exc_weight_46,
            dout_47 => exc_weight_47,
            dout_48 => exc_weight_48,
            dout_49 => exc_weight_49,
            dout_4a => exc_weight_4a,
            dout_4b => exc_weight_4b,
            dout_4c => exc_weight_4c,
            dout_4d => exc_weight_4d,
            dout_4e => exc_weight_4e,
            dout_4f => exc_weight_4f,
            dout_50 => exc_weight_50,
            dout_51 => exc_weight_51,
            dout_52 => exc_weight_52,
            dout_53 => exc_weight_53,
            dout_54 => exc_weight_54,
            dout_55 => exc_weight_55,
            dout_56 => exc_weight_56,
            dout_57 => exc_weight_57,
            dout_58 => exc_weight_58,
            dout_59 => exc_weight_59,
            dout_5a => exc_weight_5a,
            dout_5b => exc_weight_5b,
            dout_5c => exc_weight_5c,
            dout_5d => exc_weight_5d,
            dout_5e => exc_weight_5e,
            dout_5f => exc_weight_5f,
            dout_60 => exc_weight_60,
            dout_61 => exc_weight_61,
            dout_62 => exc_weight_62,
            dout_63 => exc_weight_63,
            dout_64 => exc_weight_64,
            dout_65 => exc_weight_65,
            dout_66 => exc_weight_66,
            dout_67 => exc_weight_67,
            dout_68 => exc_weight_68,
            dout_69 => exc_weight_69,
            dout_6a => exc_weight_6a,
            dout_6b => exc_weight_6b,
            dout_6c => exc_weight_6c,
            dout_6d => exc_weight_6d,
            dout_6e => exc_weight_6e,
            dout_6f => exc_weight_6f,
            dout_70 => exc_weight_70,
            dout_71 => exc_weight_71,
            dout_72 => exc_weight_72,
            dout_73 => exc_weight_73,
            dout_74 => exc_weight_74,
            dout_75 => exc_weight_75,
            dout_76 => exc_weight_76,
            dout_77 => exc_weight_77,
            dout_78 => exc_weight_78,
            dout_79 => exc_weight_79,
            dout_7a => exc_weight_7a,
            dout_7b => exc_weight_7b,
            dout_7c => exc_weight_7c,
            dout_7d => exc_weight_7d,
            dout_7e => exc_weight_7e,
            dout_7f => exc_weight_7f,
            dout_80 => exc_weight_80,
            dout_81 => exc_weight_81,
            dout_82 => exc_weight_82,
            dout_83 => exc_weight_83,
            dout_84 => exc_weight_84,
            dout_85 => exc_weight_85,
            dout_86 => exc_weight_86,
            dout_87 => exc_weight_87,
            dout_88 => exc_weight_88,
            dout_89 => exc_weight_89,
            dout_8a => exc_weight_8a,
            dout_8b => exc_weight_8b,
            dout_8c => exc_weight_8c,
            dout_8d => exc_weight_8d,
            dout_8e => exc_weight_8e,
            dout_8f => exc_weight_8f,
            dout_90 => exc_weight_90,
            dout_91 => exc_weight_91,
            dout_92 => exc_weight_92,
            dout_93 => exc_weight_93,
            dout_94 => exc_weight_94,
            dout_95 => exc_weight_95,
            dout_96 => exc_weight_96,
            dout_97 => exc_weight_97,
            dout_98 => exc_weight_98,
            dout_99 => exc_weight_99,
            dout_9a => exc_weight_9a,
            dout_9b => exc_weight_9b,
            dout_9c => exc_weight_9c,
            dout_9d => exc_weight_9d,
            dout_9e => exc_weight_9e,
            dout_9f => exc_weight_9f,
            dout_a0 => exc_weight_a0,
            dout_a1 => exc_weight_a1,
            dout_a2 => exc_weight_a2,
            dout_a3 => exc_weight_a3,
            dout_a4 => exc_weight_a4,
            dout_a5 => exc_weight_a5,
            dout_a6 => exc_weight_a6,
            dout_a7 => exc_weight_a7,
            dout_a8 => exc_weight_a8,
            dout_a9 => exc_weight_a9,
            dout_aa => exc_weight_aa,
            dout_ab => exc_weight_ab,
            dout_ac => exc_weight_ac,
            dout_ad => exc_weight_ad,
            dout_ae => exc_weight_ae,
            dout_af => exc_weight_af,
            dout_b0 => exc_weight_b0,
            dout_b1 => exc_weight_b1,
            dout_b2 => exc_weight_b2,
            dout_b3 => exc_weight_b3,
            dout_b4 => exc_weight_b4,
            dout_b5 => exc_weight_b5,
            dout_b6 => exc_weight_b6,
            dout_b7 => exc_weight_b7,
            dout_b8 => exc_weight_b8,
            dout_b9 => exc_weight_b9,
            dout_ba => exc_weight_ba,
            dout_bb => exc_weight_bb,
            dout_bc => exc_weight_bc,
            dout_bd => exc_weight_bd,
            dout_be => exc_weight_be,
            dout_bf => exc_weight_bf,
            dout_c0 => exc_weight_c0,
            dout_c1 => exc_weight_c1,
            dout_c2 => exc_weight_c2,
            dout_c3 => exc_weight_c3,
            dout_c4 => exc_weight_c4,
            dout_c5 => exc_weight_c5,
            dout_c6 => exc_weight_c6,
            dout_c7 => exc_weight_c7,
            dout_c8 => exc_weight_c8,
            dout_c9 => exc_weight_c9,
            dout_ca => exc_weight_ca,
            dout_cb => exc_weight_cb,
            dout_cc => exc_weight_cc,
            dout_cd => exc_weight_cd,
            dout_ce => exc_weight_ce,
            dout_cf => exc_weight_cf,
            dout_d0 => exc_weight_d0,
            dout_d1 => exc_weight_d1,
            dout_d2 => exc_weight_d2,
            dout_d3 => exc_weight_d3,
            dout_d4 => exc_weight_d4,
            dout_d5 => exc_weight_d5,
            dout_d6 => exc_weight_d6,
            dout_d7 => exc_weight_d7,
            dout_d8 => exc_weight_d8,
            dout_d9 => exc_weight_d9,
            dout_da => exc_weight_da,
            dout_db => exc_weight_db,
            dout_dc => exc_weight_dc,
            dout_dd => exc_weight_dd,
            dout_de => exc_weight_de,
            dout_df => exc_weight_df,
            dout_e0 => exc_weight_e0,
            dout_e1 => exc_weight_e1,
            dout_e2 => exc_weight_e2,
            dout_e3 => exc_weight_e3,
            dout_e4 => exc_weight_e4,
            dout_e5 => exc_weight_e5,
            dout_e6 => exc_weight_e6,
            dout_e7 => exc_weight_e7,
            dout_e8 => exc_weight_e8,
            dout_e9 => exc_weight_e9,
            dout_ea => exc_weight_ea,
            dout_eb => exc_weight_eb,
            dout_ec => exc_weight_ec,
            dout_ed => exc_weight_ed,
            dout_ee => exc_weight_ee,
            dout_ef => exc_weight_ef,
            dout_f0 => exc_weight_f0,
            dout_f1 => exc_weight_f1,
            dout_f2 => exc_weight_f2,
            dout_f3 => exc_weight_f3,
            dout_f4 => exc_weight_f4,
            dout_f5 => exc_weight_f5,
            dout_f6 => exc_weight_f6,
            dout_f7 => exc_weight_f7,
            dout_f8 => exc_weight_f8,
            dout_f9 => exc_weight_f9,
            dout_fa => exc_weight_fa,
            dout_fb => exc_weight_fb,
            dout_fc => exc_weight_fc,
            dout_fd => exc_weight_fd,
            dout_fe => exc_weight_fe,
            dout_ff => exc_weight_ff
        );

    exc_addr_conv : addr_converter
        generic map(
            N => exc_cnt_bitwidth
        )
        port map(
            addr_in => exc_cnt,
            addr_out => exc_addr
        );

    inh_mem : rom_256x256_inhlif1
        port map(
            clka => clk,
            addra => inh_addr,
            dout_00 => inh_weight_00,
            dout_01 => inh_weight_01,
            dout_02 => inh_weight_02,
            dout_03 => inh_weight_03,
            dout_04 => inh_weight_04,
            dout_05 => inh_weight_05,
            dout_06 => inh_weight_06,
            dout_07 => inh_weight_07,
            dout_08 => inh_weight_08,
            dout_09 => inh_weight_09,
            dout_0a => inh_weight_0a,
            dout_0b => inh_weight_0b,
            dout_0c => inh_weight_0c,
            dout_0d => inh_weight_0d,
            dout_0e => inh_weight_0e,
            dout_0f => inh_weight_0f,
            dout_10 => inh_weight_10,
            dout_11 => inh_weight_11,
            dout_12 => inh_weight_12,
            dout_13 => inh_weight_13,
            dout_14 => inh_weight_14,
            dout_15 => inh_weight_15,
            dout_16 => inh_weight_16,
            dout_17 => inh_weight_17,
            dout_18 => inh_weight_18,
            dout_19 => inh_weight_19,
            dout_1a => inh_weight_1a,
            dout_1b => inh_weight_1b,
            dout_1c => inh_weight_1c,
            dout_1d => inh_weight_1d,
            dout_1e => inh_weight_1e,
            dout_1f => inh_weight_1f,
            dout_20 => inh_weight_20,
            dout_21 => inh_weight_21,
            dout_22 => inh_weight_22,
            dout_23 => inh_weight_23,
            dout_24 => inh_weight_24,
            dout_25 => inh_weight_25,
            dout_26 => inh_weight_26,
            dout_27 => inh_weight_27,
            dout_28 => inh_weight_28,
            dout_29 => inh_weight_29,
            dout_2a => inh_weight_2a,
            dout_2b => inh_weight_2b,
            dout_2c => inh_weight_2c,
            dout_2d => inh_weight_2d,
            dout_2e => inh_weight_2e,
            dout_2f => inh_weight_2f,
            dout_30 => inh_weight_30,
            dout_31 => inh_weight_31,
            dout_32 => inh_weight_32,
            dout_33 => inh_weight_33,
            dout_34 => inh_weight_34,
            dout_35 => inh_weight_35,
            dout_36 => inh_weight_36,
            dout_37 => inh_weight_37,
            dout_38 => inh_weight_38,
            dout_39 => inh_weight_39,
            dout_3a => inh_weight_3a,
            dout_3b => inh_weight_3b,
            dout_3c => inh_weight_3c,
            dout_3d => inh_weight_3d,
            dout_3e => inh_weight_3e,
            dout_3f => inh_weight_3f,
            dout_40 => inh_weight_40,
            dout_41 => inh_weight_41,
            dout_42 => inh_weight_42,
            dout_43 => inh_weight_43,
            dout_44 => inh_weight_44,
            dout_45 => inh_weight_45,
            dout_46 => inh_weight_46,
            dout_47 => inh_weight_47,
            dout_48 => inh_weight_48,
            dout_49 => inh_weight_49,
            dout_4a => inh_weight_4a,
            dout_4b => inh_weight_4b,
            dout_4c => inh_weight_4c,
            dout_4d => inh_weight_4d,
            dout_4e => inh_weight_4e,
            dout_4f => inh_weight_4f,
            dout_50 => inh_weight_50,
            dout_51 => inh_weight_51,
            dout_52 => inh_weight_52,
            dout_53 => inh_weight_53,
            dout_54 => inh_weight_54,
            dout_55 => inh_weight_55,
            dout_56 => inh_weight_56,
            dout_57 => inh_weight_57,
            dout_58 => inh_weight_58,
            dout_59 => inh_weight_59,
            dout_5a => inh_weight_5a,
            dout_5b => inh_weight_5b,
            dout_5c => inh_weight_5c,
            dout_5d => inh_weight_5d,
            dout_5e => inh_weight_5e,
            dout_5f => inh_weight_5f,
            dout_60 => inh_weight_60,
            dout_61 => inh_weight_61,
            dout_62 => inh_weight_62,
            dout_63 => inh_weight_63,
            dout_64 => inh_weight_64,
            dout_65 => inh_weight_65,
            dout_66 => inh_weight_66,
            dout_67 => inh_weight_67,
            dout_68 => inh_weight_68,
            dout_69 => inh_weight_69,
            dout_6a => inh_weight_6a,
            dout_6b => inh_weight_6b,
            dout_6c => inh_weight_6c,
            dout_6d => inh_weight_6d,
            dout_6e => inh_weight_6e,
            dout_6f => inh_weight_6f,
            dout_70 => inh_weight_70,
            dout_71 => inh_weight_71,
            dout_72 => inh_weight_72,
            dout_73 => inh_weight_73,
            dout_74 => inh_weight_74,
            dout_75 => inh_weight_75,
            dout_76 => inh_weight_76,
            dout_77 => inh_weight_77,
            dout_78 => inh_weight_78,
            dout_79 => inh_weight_79,
            dout_7a => inh_weight_7a,
            dout_7b => inh_weight_7b,
            dout_7c => inh_weight_7c,
            dout_7d => inh_weight_7d,
            dout_7e => inh_weight_7e,
            dout_7f => inh_weight_7f,
            dout_80 => inh_weight_80,
            dout_81 => inh_weight_81,
            dout_82 => inh_weight_82,
            dout_83 => inh_weight_83,
            dout_84 => inh_weight_84,
            dout_85 => inh_weight_85,
            dout_86 => inh_weight_86,
            dout_87 => inh_weight_87,
            dout_88 => inh_weight_88,
            dout_89 => inh_weight_89,
            dout_8a => inh_weight_8a,
            dout_8b => inh_weight_8b,
            dout_8c => inh_weight_8c,
            dout_8d => inh_weight_8d,
            dout_8e => inh_weight_8e,
            dout_8f => inh_weight_8f,
            dout_90 => inh_weight_90,
            dout_91 => inh_weight_91,
            dout_92 => inh_weight_92,
            dout_93 => inh_weight_93,
            dout_94 => inh_weight_94,
            dout_95 => inh_weight_95,
            dout_96 => inh_weight_96,
            dout_97 => inh_weight_97,
            dout_98 => inh_weight_98,
            dout_99 => inh_weight_99,
            dout_9a => inh_weight_9a,
            dout_9b => inh_weight_9b,
            dout_9c => inh_weight_9c,
            dout_9d => inh_weight_9d,
            dout_9e => inh_weight_9e,
            dout_9f => inh_weight_9f,
            dout_a0 => inh_weight_a0,
            dout_a1 => inh_weight_a1,
            dout_a2 => inh_weight_a2,
            dout_a3 => inh_weight_a3,
            dout_a4 => inh_weight_a4,
            dout_a5 => inh_weight_a5,
            dout_a6 => inh_weight_a6,
            dout_a7 => inh_weight_a7,
            dout_a8 => inh_weight_a8,
            dout_a9 => inh_weight_a9,
            dout_aa => inh_weight_aa,
            dout_ab => inh_weight_ab,
            dout_ac => inh_weight_ac,
            dout_ad => inh_weight_ad,
            dout_ae => inh_weight_ae,
            dout_af => inh_weight_af,
            dout_b0 => inh_weight_b0,
            dout_b1 => inh_weight_b1,
            dout_b2 => inh_weight_b2,
            dout_b3 => inh_weight_b3,
            dout_b4 => inh_weight_b4,
            dout_b5 => inh_weight_b5,
            dout_b6 => inh_weight_b6,
            dout_b7 => inh_weight_b7,
            dout_b8 => inh_weight_b8,
            dout_b9 => inh_weight_b9,
            dout_ba => inh_weight_ba,
            dout_bb => inh_weight_bb,
            dout_bc => inh_weight_bc,
            dout_bd => inh_weight_bd,
            dout_be => inh_weight_be,
            dout_bf => inh_weight_bf,
            dout_c0 => inh_weight_c0,
            dout_c1 => inh_weight_c1,
            dout_c2 => inh_weight_c2,
            dout_c3 => inh_weight_c3,
            dout_c4 => inh_weight_c4,
            dout_c5 => inh_weight_c5,
            dout_c6 => inh_weight_c6,
            dout_c7 => inh_weight_c7,
            dout_c8 => inh_weight_c8,
            dout_c9 => inh_weight_c9,
            dout_ca => inh_weight_ca,
            dout_cb => inh_weight_cb,
            dout_cc => inh_weight_cc,
            dout_cd => inh_weight_cd,
            dout_ce => inh_weight_ce,
            dout_cf => inh_weight_cf,
            dout_d0 => inh_weight_d0,
            dout_d1 => inh_weight_d1,
            dout_d2 => inh_weight_d2,
            dout_d3 => inh_weight_d3,
            dout_d4 => inh_weight_d4,
            dout_d5 => inh_weight_d5,
            dout_d6 => inh_weight_d6,
            dout_d7 => inh_weight_d7,
            dout_d8 => inh_weight_d8,
            dout_d9 => inh_weight_d9,
            dout_da => inh_weight_da,
            dout_db => inh_weight_db,
            dout_dc => inh_weight_dc,
            dout_dd => inh_weight_dd,
            dout_de => inh_weight_de,
            dout_df => inh_weight_df,
            dout_e0 => inh_weight_e0,
            dout_e1 => inh_weight_e1,
            dout_e2 => inh_weight_e2,
            dout_e3 => inh_weight_e3,
            dout_e4 => inh_weight_e4,
            dout_e5 => inh_weight_e5,
            dout_e6 => inh_weight_e6,
            dout_e7 => inh_weight_e7,
            dout_e8 => inh_weight_e8,
            dout_e9 => inh_weight_e9,
            dout_ea => inh_weight_ea,
            dout_eb => inh_weight_eb,
            dout_ec => inh_weight_ec,
            dout_ed => inh_weight_ed,
            dout_ee => inh_weight_ee,
            dout_ef => inh_weight_ef,
            dout_f0 => inh_weight_f0,
            dout_f1 => inh_weight_f1,
            dout_f2 => inh_weight_f2,
            dout_f3 => inh_weight_f3,
            dout_f4 => inh_weight_f4,
            dout_f5 => inh_weight_f5,
            dout_f6 => inh_weight_f6,
            dout_f7 => inh_weight_f7,
            dout_f8 => inh_weight_f8,
            dout_f9 => inh_weight_f9,
            dout_fa => inh_weight_fa,
            dout_fb => inh_weight_fb,
            dout_fc => inh_weight_fc,
            dout_fd => inh_weight_fd,
            dout_fe => inh_weight_fe,
            dout_ff => inh_weight_ff
        );

    inh_addr_conv : addr_converter
        generic map(
            N => inh_cnt_bitwidth
        )
        port map(
            addr_in => inh_cnt,
            addr_out => inh_addr
        );

    spikes_barrier : barrier
        generic map(
            N => 256
        )
        port map(
            clk => clk,
            rst_n => rst_n,
            restart => restart,
            out_sample => out_sample,
            reg_in => out_spikes_inst,
            ready => barrier_ready,
            reg_out => out_spikes
        );


end architecture behavior;

