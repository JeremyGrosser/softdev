--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
package body Soft_I2C_Slave is

   type Bus_State is (Idle, Start_Condition, Address_Match_Write, Address_Match_Read, Address_Miss, Stop_Condition);
   State : Bus_State := Idle;

   In_Data, Out_Data   : UInt8 := 0;
   In_Count, Out_Count : Natural := 0;

   procedure Initialize is
   begin
      null;
   end Initialize;

   procedure Shift_In
      (SDA_High : Boolean)
   is
   begin
      In_Data := Shift_Left (In_Data, 1);
      if SDA_High then
         In_Data := In_Data or 1;
      end if;
      In_Count := In_Count + 1;
   end Shift_In;

   procedure Shift_Out is
   begin
      Set_SDA ((Out_Data and 16#80#) /= 0);
      Out_Data := Shift_Right (Out_Data, 1);
      Out_Count := Out_Count + 1;
   end Shift_Out;

   procedure SCL_Rising
      (SDA_High : Boolean)
   is
      Write_Address : constant UInt8 := Shift_Left (UInt8 (Address), 1);
      Read_Address  : constant UInt8 := Write_Address or 1;
   begin
      case State is
         when Idle =>
            if SDA_High = False then
               State := Start_Condition;
            end if;
         when Start_Condition =>
            Shift_In (SDA_High);
            if In_Count = 8 then
               if In_Data = Write_Address then
                  State := Address_Match_Write;
               elsif In_Data = Read_Address then
                  State := Address_Match_Read;
               else
                  State := Address_Miss;
               end if;
               In_Count := 0;
            end if;
         when Address_Match_Write =>
            Shift_In (SDA_High);
            if In_Count = 8 then
               Write (In_Data);
               In_Count := 0;
            end if;
         when Address_Match_Read =>
            if Out_Count = 0 then
               Read (Out_Data);
            end if;
            Shift_Out;
            if Out_Count = 8 then
               Out_Count := 0;
            end if;
         when Address_Miss =>
            In_Count := In_Count + 1;
            if In_Count = 8 and then not SDA_High then
               State := Stop_Condition;
            end if;
            In_Count := 0;
         when Stop_Condition =>
            if SDA_High then
               State := Idle;
            end if;
      end case;
   end SCL_Rising;

end Soft_I2C_Slave;
