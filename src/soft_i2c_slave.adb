--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
package body Soft_I2C_Slave is
   type State_Type is
      (Idle,            --  Waiting for start condition
       Start,           --  Start condition detected
       Receive_Address, --  Receiving address bits
       Ack_Address,     --  Acknowledging address
       Read_Data,       --  Master reading from slave
       Write_Data,      --  Master writing to slave
       Ack_Data);       --  Acknowledging data byte

   Current_State  : State_Type := Idle;
   Bit_Count      : Natural := 0;
   Data_Reg       : UInt8 := 0;
   Is_Read        : Boolean := False;
   NACK           : Boolean := False;

   Last_SCL : Boolean := False;
   Last_SDA : Boolean := False;

   procedure Initialize is
   begin
      Current_State := Idle;
      Bit_Count := 0;
      Data_Reg := 0;
      Is_Read := False;
      NACK := False;
      Last_SCL := False;
      Last_SDA := False;
   end Initialize;

   procedure SCL_Rising
      (SDA : Boolean)
   is
   begin
      case Current_State is
         when Start =>
            Current_State := Receive_Address;
            Bit_Count := 0;
            Data_Reg := 0;
         when Receive_Address =>
            Data_Reg := Shift_Left (Data_Reg, 1);
            if SDA then
               Data_Reg := Data_Reg or 1;
            end if;

            Bit_Count := Bit_Count + 1;
            if Bit_Count = 8 then
               Is_Read := (Data_Reg and 1) = 1;
               if UInt7 (Shift_Right (Data_Reg, 1) and 16#7F#) = Address then
                  Current_State := Ack_Address;
               else
                  Current_State := Idle;
               end if;
            end if;
         when Write_Data =>
            Data_Reg := Shift_Left (Data_Reg, 1);
            if SDA then
               Data_Reg := Data_Reg or 1;
            end if;

            Bit_Count := Bit_Count + 1;
            if Bit_Count = 8 then
               Current_State := Ack_Data;
               Write (Data_Reg);
            end if;
         when Read_Data =>
            --  Next bit should already be on SDA line
            Bit_Count := Bit_Count + 1;
            if Bit_Count = 8 then
               Current_State := Ack_Data;
            end if;
         when others =>
            null;
      end case;
   end SCL_Rising;

   procedure SCL_Falling
      (SDA : Boolean)
   is
   begin
      case Current_State is
         when Ack_Address =>
            --  Pull SDA low to acknowledge
            Set_SDA (False);
            if Is_Read then
               Current_State := Read_Data;
               Bit_Count := 0;
               Read (Data_Reg, NACK);
               --  Put first bit on line
               Set_SDA ((Data_Reg and 16#80#) /= 0);
            else
               Current_State := Write_Data;
               Bit_Count := 0;
            end if;
         when Ack_Data =>
            if Is_Read then
               --  Check if master acknowledged
               if not SDA then
                  if NACK then
                     Current_State := Idle;
                  else
                     --  More data requested
                     Current_State := Read_Data;
                     Bit_Count := 0;
                     Read (Data_Reg, NACK);
                     --  Put first bit on line
                     Set_SDA ((Data_Reg and 16#80#) /= 0);
                  end if;
               else
                  Current_State := Idle;
               end if;
            else
               --  Acknowledge received data
               Set_SDA (False);
               Current_State := Write_Data;
               Bit_Count := 0;
            end if;
         when Read_Data =>
            if Bit_Count < 8 then
               --  Put next bit on line
               Set_SDA ((Shift_Left (Data_Reg, Bit_Count) and 16#80#) /= 0);
            end if;
         when others =>
            null;
      end case;
   end SCL_Falling;

   procedure Interrupt
      (SCL, SDA : Boolean)
   is
   begin
      if SCL and then Last_SDA and then not SDA then
         --  Start
         Set_SDA (True); --  Release SDA in case this is a repeated start
         Current_State := Start;
         Bit_Count := 0;
         Data_Reg := 0;
      elsif SCL and then not Last_SDA and then SDA then
         --  Stop
         Current_State := Idle;
      elsif not Last_SCL and then SCL then
         SCL_Rising (SDA);
      elsif Last_SCL and then not SCL then
         SCL_Falling (SDA);
      end if;

      Last_SCL := SCL;
      Last_SDA := SDA;
   end Interrupt;

end Soft_I2C_Slave;
