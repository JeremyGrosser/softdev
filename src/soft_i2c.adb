--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
package body Soft_I2C is

   procedure Release_Bus is
   begin
      Set_SCL (True);
      Set_SDA (True);
   end Release_Bus;

   procedure Initialize is
   begin
      Release_Bus;
   end Initialize;

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

   procedure ACK is
      DAT : Boolean;
   begin
      Set_SDA (True);
      Clock_High;
      Get_SDA (DAT);
      Set_SCL (False);
      if DAT then
         NACK := True;
      end if;
   end ACK;

   procedure Send
      (Data : UInt8)
   is
      D : UInt8 := Data;
   begin
      for I in 1 .. 8 loop
         Set_SDA ((D and 16#80#) /= 0);
         Clock;
         D := Shift_Left (D, 1);
      end loop;
      ACK;
   end Send;

   procedure Release_Data is
   begin
      Set_SDA (True);
   end Release_Data;

   type I2C_Mode is (Read, Write);

   procedure Set_Mode
      (Addr : I2C_Address;
       Mode : I2C_Mode)
   is
      Data : UInt8 := Shift_Left (UInt8 (Addr), 1);
   begin
      if Mode = Read then
         Data := Data or 1;
      end if;
      Send (Data);
      Release_Data;
   end Set_Mode;

   procedure Clock_In
      (Data : out UInt8)
   is
      High : Boolean;
   begin
      Data := 0;
      for I in 0 .. 7 loop
         Data := Shift_Left (Data, 1);
         Get_SDA (High);
         if High then
            Data := Data or 1;
         end if;
         Clock;
      end loop;
      ACK;
   end Clock_In;

   procedure Write_Byte
      (Addr    : I2C_Address;
       Command : UInt8;
       Data    : UInt8)
   is
   begin
      Start_Condition;
      Set_Mode (Addr, Write);
      Start_Condition;
      Send (Command);
      Send (Data);
      Stop_Condition;
   end Write_Byte;

   procedure Read_Byte
      (Addr    : I2C_Address;
       Command : UInt8;
       Data    : out UInt8)
   is
   begin
      Start_Condition;
      Set_Mode (Addr, Write);
      Send (Command);

      --  Repeated Start
      Release_Bus;
      Start_Condition;

      Set_Mode (Addr, Read);
      Clock_In (Data);
      Stop_Condition;
   end Read_Byte;

end Soft_I2C;
