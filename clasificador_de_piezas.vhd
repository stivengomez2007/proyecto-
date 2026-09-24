library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clasificador_de_piezas is
    port (
        CLOCK_50   : in  std_logic;
        BUTTON     : in  std_logic_vector(2 downto 0);
        SW         : in  std_logic_vector(9 downto 0);
        LEDG       : out std_logic_vector(9 downto 0);
        HEX0       : out std_logic_vector(6 downto 0);
        HEX1       : out std_logic_vector(6 downto 0);
        HEX2       : out std_logic_vector(6 downto 0);
        HEX3       : out std_logic_vector(6 downto 0)
    );
end entity clasificador_de_piezas;

architecture Structural of clasificador_de_piezas is

 
    component seleccionadordefrecuenciaw
        port (
            clk       : in  std_logic;
            sel_vel   : in  std_logic_vector(1 downto 0);
            clk_linea : out std_logic
        );
    end component;

    component sorter_control
        port (
            SW   : in  std_logic_vector(3 downto 0);
            LEDG : out std_logic_vector(3 downto 0)
        );
    end component;

    component decoder7segw
        port (
            c : in  std_logic_vector(3 downto 0);
            s : out std_logic_vector(6 downto 0)
        );
    end component;

   
    signal clk_linea_int      : std_logic;
    signal sw_clasificador    : std_logic_vector(3 downto 0);
    signal btn_presencia_prev : std_logic := '1';

  
    signal clk_1sec_count     : integer range 0 to 50000000 := 0;
    signal sec0, min0         : integer range 0 to 9 := 0;
    signal sec1, min1         : integer range 0 to 9 := 0;

    
    signal ult_sec0, ult_sec1 : integer range 0 to 9 := 0;
    signal ult_min0, ult_min1 : integer range 0 to 9 := 0;

    
    signal led_color_int      : std_logic_vector(1 downto 0) := "00";
    signal led_tamano_int     : std_logic_vector(1 downto 0) := "00";

    
    type matriz_conteo is array (0 to 2, 0 to 2) of integer range 0 to 9;
    signal reg_piezas : matriz_conteo := ((0,0,0), (0,0,0), (0,0,0));
    signal cnt_rojo, cnt_verde, cnt_azul, cnt_total : integer range 0 to 9 := 0;

    
    signal hex0_bcd, hex1_bcd, hex2_bcd, hex3_bcd : std_logic_vector(3 downto 0);

begin

    
    LEDG(9)          <= clk_linea_int;
    LEDG(7 downto 6) <= led_tamano_int;
    LEDG(5 downto 4) <= led_color_int;

    
    U_Control_Velocidad: seleccionadordefrecuenciaw 
        port map (
            clk       => CLOCK_50, 
            sel_vel   => SW(1 downto 0), 
            clk_linea => clk_linea_int
        );
    
    
    sw_clasificador <= SW(5 downto 2);
    U_Clasificador_Salida: sorter_control 
        port map (
            SW   => sw_clasificador, 
            LEDG => LEDG(3 downto 0)
        );

    
    process(CLOCK_50, BUTTON(0))
    begin
        if BUTTON(0) = '0' then
            clk_1sec_count <= 0;
            sec0 <= 0; sec1 <= 0; min0 <= 0; min1 <= 0;
        elsif rising_edge(CLOCK_50) then
            if clk_1sec_count = 49999999 then
                clk_1sec_count <= 0;
                if sec0 = 9 then
                    sec0 <= 0;
                    if sec1 = 5 then
                        sec1 <= 0;
                        if min0 = 9 then
                            min0 <= 0;
                            if min1 < 9 then min1 <= min1 + 1; end if;
                        else
                            min0 <= min0 + 1;
                        end if;
                    else
                        sec1 <= sec1 + 1;
                    end if;
                else
                    sec0 <= sec0 + 1;
                end if;
            else
                clk_1sec_count <= clk_1sec_count + 1;
            end if;
        end if;
    end process;

   
    process(CLOCK_50, BUTTON(0))
        variable col_idx, tam_idx : integer range 0 to 2;
        variable es_valido        : boolean;
    begin
        if BUTTON(0) = '0' then
            reg_piezas <= ((0,0,0), (0,0,0), (0,0,0));
            cnt_rojo <= 0; cnt_verde <= 0; cnt_azul <= 0; cnt_total <= 0;
            ult_sec0 <= 0; ult_sec1 <= 0; ult_min0 <= 0; ult_min1 <= 0;
            led_color_int <= "00"; led_tamano_int <= "00";
            btn_presencia_prev <= '1';
        elsif rising_edge(CLOCK_50) then
            if (BUTTON(1) = '0' and btn_presencia_prev = '1') then
                es_valido := true;
                
                led_color_int  <= SW(3 downto 2);
                led_tamano_int <= SW(5 downto 4);

                ult_sec0 <= sec0; ult_sec1 <= sec1;
                ult_min0 <= min0; ult_min1 <= min1;

                case SW(3 downto 2) is
                    when "01"   => col_idx := 0;
                    when "11"   => col_idx := 1;
                    when "10"   => col_idx := 2;
                    when others => es_valido := false;
                end case;

                case SW(5 downto 4) is
                    when "01"   => tam_idx := 0;
                    when "10"   => tam_idx := 1;
                    when "11"   => tam_idx := 2;
                    when others => es_valido := false;
                end case;

                if es_valido then
                    if reg_piezas(col_idx, tam_idx) < 9 then 
                        reg_piezas(col_idx, tam_idx) <= reg_piezas(col_idx, tam_idx) + 1; 
                    end if;
                    
                    if col_idx = 0 and cnt_rojo < 9 then cnt_rojo <= cnt_rojo + 1;
                    elsif col_idx = 1 and cnt_verde < 9 then cnt_verde <= cnt_verde + 1;
                    elsif col_idx = 2 and cnt_azul < 9 then cnt_azul <= cnt_azul + 1; 
                    end if;
                    
                    if cnt_total < 9 then cnt_total <= cnt_total + 1; end if;
                end if;
            end if;
            btn_presencia_prev <= BUTTON(1);
        end if;
    end process;

   
    process(SW(9 downto 6), cnt_rojo, cnt_verde, cnt_azul, cnt_total, reg_piezas, 
            sec0, sec1, min0, min1, ult_sec0, ult_sec1, ult_min0, ult_min1)
    begin
        case SW(9 downto 8) is

            when "01" => 
                hex3_bcd <= "1111"; 
                hex2_bcd <= std_logic_vector(to_unsigned(reg_piezas(0, 0), 4));
                hex1_bcd <= std_logic_vector(to_unsigned(reg_piezas(0, 1), 4));
                hex0_bcd <= std_logic_vector(to_unsigned(reg_piezas(0, 2), 4));

            when "10" => 
                hex3_bcd <= "1111"; 
                hex2_bcd <= std_logic_vector(to_unsigned(reg_piezas(1, 0), 4));
                hex1_bcd <= std_logic_vector(to_unsigned(reg_piezas(1, 1), 4));
                hex0_bcd <= std_logic_vector(to_unsigned(reg_piezas(1, 2), 4));

            when "11" => -- HISTÓRICO DE PIEZAS AZULES (G, M, P)
                hex3_bcd <= "1111"; 
                hex2_bcd <= std_logic_vector(to_unsigned(reg_piezas(2, 0), 4));
                hex1_bcd <= std_logic_vector(to_unsigned(reg_piezas(2, 1), 4));
                hex0_bcd <= std_logic_vector(to_unsigned(reg_piezas(2, 2), 4));

            when others => 
                case SW(7 downto 6) is
                    when "00" => 
                        hex3_bcd <= std_logic_vector(to_unsigned(cnt_total, 4));
                        hex2_bcd <= std_logic_vector(to_unsigned(cnt_azul, 4));
                        hex1_bcd <= std_logic_vector(to_unsigned(cnt_verde, 4));
                        hex0_bcd <= std_logic_vector(to_unsigned(cnt_rojo, 4));

                    when "01" => 
                        hex3_bcd <= std_logic_vector(to_unsigned(ult_min1, 4));
                        hex2_bcd <= std_logic_vector(to_unsigned(ult_min0, 4));
                        hex1_bcd <= std_logic_vector(to_unsigned(ult_sec1, 4));
                        hex0_bcd <= std_logic_vector(to_unsigned(ult_sec0, 4));

                    when "10" => 
                        hex3_bcd <= std_logic_vector(to_unsigned(min1, 4));
                        hex2_bcd <= std_logic_vector(to_unsigned(min0, 4));
                        hex1_bcd <= std_logic_vector(to_unsigned(sec1, 4));
                        hex0_bcd <= std_logic_vector(to_unsigned(sec0, 4));

                    when others =>
                        hex3_bcd <= "0000"; hex2_bcd <= "0000"; hex1_bcd <= "0000"; hex0_bcd <= "0000";
                end case;
        end case;
    end process;

    
    U_Dec0: decoder7segw port map (c => hex0_bcd, s => HEX0);
    U_Dec1: decoder7segw port map (c => hex1_bcd, s => HEX1);
    U_Dec2: decoder7segw port map (c => hex2_bcd, s => HEX2);
    U_Dec3: decoder7segw port map (c => hex3_bcd, s => HEX3);

end architecture Structural;