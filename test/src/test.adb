--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
pragma Style_Checks ("M120");
with Ada.Text_IO; use Ada.Text_IO;
with Generic_Hex_Format;
with HAL; use HAL;
with RP.Clock;

with Soft_I2C_RP2040; use Soft_I2C_RP2040;

procedure Test is
   package Hex_Format_8 is new Generic_Hex_Format (UInt8, Shift_Right);
   use Hex_Format_8;

   Counter : UInt8 := 16#55#;

   procedure Test_EEPROM is
      --  CAT24C32F
      NOR_Addr : constant Port.I2C_Address := 2#1010_000#;
      Page     : constant UInt8_Array (1 .. 2) := (16#00#, 16#00#);
      Data     : UInt8_Array (1 .. 4);
   begin
      Put_Line ("Addr 0x" & Hex (Page (1)) & Hex (Page (2)));
      Put ("EEPROM Write:");
      for I in Data'Range loop
         Data (I) := Counter;
         Put (' ');
         Put (Hex (Data (I)));
         Counter := Counter + 1;
      end loop;
      Port.Write (NOR_Addr, Page & Data);
      New_Line;

      Put_Line ("EEPROM Read:");
      loop
         Port.Write (NOR_Addr, Page, Stop => False);
         exit when not Port.NACK;
         Put_Line ("NACK");
      end loop;
      Put ("ACK ");

      Put ("         ");
      Port.Read (NOR_Addr, Data);
      for D of Data loop
         Put (' ');
         Put (Hex (D));
      end loop;
      New_Line;
      Put_Line ("-------------------------");
   end Test_EEPROM;

   procedure Test_Slave is
      Addr : constant UInt7 := 16#19#;
      Data : constant UInt8_Array (1 .. 1) := (1 => Counter);
   begin
      Slave_Data := 0;
      Port.Write (Addr, Data, Stop => True);
      Ada.Text_IO.Put_Line ("Slave_Data (expect " & Hex (Counter) & ") = 0x" & Hex (Slave_Data));
      Counter := Counter + 1;
   end Test_Slave;

begin
   RP.Clock.Initialize (12_000_000);
   Soft_I2C_RP2040.Initialize;

   loop
      --  Test_EEPROM;
      Test_Slave;
   end loop;
end Test;
