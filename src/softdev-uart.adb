--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
package body Softdev.UART is

   Data_Bits  : constant := 8;
   Stop_Bits  : constant := 1;

   subtype Phase_Count is Natural; --  mod Oversample
   Phase       : Phase_Count := 0;
   TX_Phase    : constant Phase_Count := 0;
   RX_Phase    : Phase_Count := 0;
   Half_Phase  : constant Phase_Count := Phase_Count (Oversample / 2);

   TX_Buffer : UInt8 := 0; --  Data to send
   TX_Bits   : UInt8 := 0; --  Bits remaining to send
   TX_Count  : UInt8 := 0; --  Bit clock of TX

   RX_Buffer : UInt8 := 0; --  Data received
   RX_Bits   : UInt8 := 0; --  Bits received
   RX_Count  : UInt8 := 0; --  Bit clock of RX

   function Ready_To_Send
      return Boolean
   is (TX_Bits = 0);

   function Data_Ready
      return Boolean
   is (RX_Bits >= 8);

   procedure Write
      (Data : UInt8)
   is
   begin
      TX_Buffer := Data;
      TX_Bits := 8;
   end Write;

   procedure Read
      (Data : out UInt8)
   is
   begin
      Data := RX_Buffer;
      RX_Bits := 0;
   end Read;

   procedure Poll is
      RX : Boolean;
   begin
      if Phase = TX_Phase then
         if TX_Bits > 0 then
            case TX_Count is
               when 0 =>
                  --  START
                  Set_TXD (False);
               when 1 .. Data_Bits =>
                  Set_TXD ((TX_Buffer and 1) /= 0);
                  TX_Buffer := Shift_Right (TX_Buffer, 1);
                  TX_Bits := TX_Bits - 1;
               when Data_Bits + 1 =>
                  --  STOP
                  Set_TXD (True);
               when others =>
                  null;
            end case;

            TX_Count := TX_Count + 1;
            if TX_Count > (Data_Bits + Stop_Bits) then
               TX_Count := 0;
            end if;
         else
            Set_TXD (True);
         end if;
      end if;

      if RX_Count = 0 then
         Get_RXD (RX);
         if not RX then
            --  START
            RX_Count := RX_Count + 1;
            --  RX samples 0.5 bits after the falling edge of START
            RX_Phase := (Phase + Half_Phase) mod Oversample;
         end if;
      elsif Phase = RX_Phase and then RX_Bits < Data_Bits then
         Get_RXD (RX);
         case RX_Count is
            when 1 =>
               if RX then --  RX transitioned during START: FRAMING ERROR
                  RX_Count := 0;
               else
                  RX_Count := RX_Count + 1;
               end if;
            when 2 .. Data_Bits + 1 =>
               --  START + 1.5, 2.5, 3.5...
               RX_Buffer := Shift_Right (RX_Buffer, 1);
               if RX then
                  RX_Buffer := RX_Buffer or 16#80#;
               end if;
               RX_Bits := RX_Bits + 1;
               RX_Count := RX_Count + 1;
            when Data_Bits + 2 =>
               --  Wait for STOP
               if RX then
                  RX_Count := 0;
               end if;
            when others =>
               null;
         end case;
      end if;

      Phase := (Phase + 1) mod Oversample;
   end Poll;

end Softdev.UART;
