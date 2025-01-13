--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
package body Softdev.I2C_Master is

   procedure Release_Bus is
   begin
      Set_SCL (True);
      Set_SDA (True);
   end Release_Bus;

   procedure Start_Condition is
   begin
      NACK := False;
      Set_SDA (False);
      Set_SCL (False);
   end Start_Condition;

   procedure Stop_Condition is
   begin
      Set_SDA (False);
      Release_Bus;
   end Stop_Condition;

   procedure Clock_High is
      CLK : Boolean;
   begin
      Set_SCL (True);
      if Clock_Stretch_Enabled then
         loop
            --  If the target doesn't release SCL after a while, try forcing it.
            for I in 1 .. 1000 loop
               Get_SCL (CLK);
               if CLK then
                  return;
               end if;
            end loop;
            Set_SCL (False);
            Set_SCL (True);
         end loop;
      end if;
   end Clock_High;

   procedure Clock is
   begin
      Clock_High;
      Set_SCL (False);
   end Clock;

   procedure Read_ACK
      (Last_Byte : Boolean)
   is
   begin
      Set_SDA (Last_Byte);
      Clock_High;
      Get_SDA (NACK);
      Set_SCL (False);
   end Read_ACK;

   procedure Clock_Out
      (Data : UInt8)
   is
      D : UInt8 := Data;
   begin
      for I in 1 .. 8 loop
         Set_SDA ((D and 16#80#) /= 0);
         Clock;
         D := Shift_Left (D, 1);
      end loop;
      Read_ACK (True);
   end Clock_Out;

   procedure Clock_In
      (Data : out UInt8;
       Last_Byte : Boolean)
   is
      High : Boolean;
   begin
      Set_SDA (True);
      Data := 0;
      for I in 0 .. 7 loop
         Data := Shift_Left (Data, 1);
         Get_SDA (High);
         if High then
            Data := Data or 1;
         end if;
         Clock;
      end loop;
      Read_ACK (Last_Byte);
   end Clock_In;

   type I2C_Mode is (Read, Write);

   procedure Send_Address
      (Addr : I2C_Address;
       Mode : I2C_Mode)
   is
      Data : UInt8 := Shift_Left (UInt8 (Addr), 1);
   begin
      if Mode = Read then
         Data := Data or 1;
      end if;
      Clock_Out (Data);
      Set_SDA (True);
   end Send_Address;

   procedure Initialize is
   begin
      Release_Bus;
   end Initialize;

   procedure End_Transaction
      (Stop : Boolean)
   is
   begin
      if Stop then
         Stop_Condition;
      else
         Release_Bus;
      end if;
   end End_Transaction;

   procedure Write
      (Addr : I2C_Address;
       Data : UInt8_Array;
       Stop : Boolean := True)
   is
   begin
      Start_Condition;
      Send_Address (Addr, Write);
      if NACK then
         Stop_Condition;
      else
         for I in Data'Range loop
            Clock_Out (Data (I));
            exit when NACK;
         end loop;
         End_Transaction (Stop);
      end if;
   end Write;

   procedure Read
      (Addr : I2C_Address;
       Data : out UInt8_Array;
       Stop : Boolean := True)
   is
   begin
      Start_Condition;
      Send_Address (Addr, Read);
      if NACK then
         Stop_Condition;
      else
         for I in Data'Range loop
            Clock_In (Data (I), I = Data'Last);
         end loop;
         End_Transaction (Stop);
      end if;
   end Read;

end Softdev.I2C_Master;
