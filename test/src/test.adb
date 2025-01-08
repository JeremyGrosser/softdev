--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
pragma Style_Checks ("M120");
with Ada.Text_IO;
with Generic_Hex_Format;
with HAL; use HAL;
with RP.Clock;
with RP.Timer; use RP.Timer;

with Soft_I2C_RP2040; use Soft_I2C_RP2040;

procedure Test is
   package Hex_Format_8 is new Generic_Hex_Format (UInt8, Shift_Right);
   use Hex_Format_8;

   MPU_Addr       : constant Port.I2C_Address := 2#110_1000#;
   SMPLRT_DIV     : constant UInt8 := 16#19#;
   CONFIG         : constant UInt8 := 16#1A#;
   GYRO_CONFIG    : constant UInt8 := 16#1B#;
   ACCEL_CONFIG   : constant UInt8 := 16#1C#;
   PWR_MGMT_1     : constant UInt8 := 16#6B#;

   Gyro_Data  : UInt8_Array (16#43# .. 16#48#);
   Accel_Data : UInt8_Array (16#3B# .. 16#40#);
begin
   RP.Clock.Initialize (12_000_000);
   Soft_I2C_RP2040.Initialize;

   T := Clock;
   Port.Write_Byte (MPU_Addr, PWR_MGMT_1, 16#80#); --  device reset

   T := Clock + Milliseconds (100);
   Port.Write_Byte (MPU_Addr, PWR_MGMT_1, 16#03#); --  clksel = z gyro

   T := Clock;
   Port.Write_Byte (MPU_Addr, SMPLRT_DIV, 16#00#);

   T := Clock + Milliseconds (15);
   Port.Write_Byte (MPU_Addr, CONFIG, 16#00#); --  disable fsync, acc bw 260 Hz, gyro bw 256 Hz

   T := Clock;
   Port.Write_Byte (MPU_Addr, GYRO_CONFIG, 2#000_11_000#); --  +/- 2000deg/s gyro limit

   T := Clock;
   Port.Write_Byte (MPU_Addr, ACCEL_CONFIG, 2#000_11_000#); --  +/- 16g accel limit

   loop
      T := Clock;
      for I in Gyro_Data'Range loop
         Port.Read_Byte (MPU_Addr, UInt8 (I), Gyro_Data (I));
      end loop;

      for I in Accel_Data'Range loop
         Port.Read_Byte (MPU_Addr, UInt8 (I), Accel_Data (I));
      end loop;

      Ada.Text_IO.Put ("Gyro:");
      for D of Gyro_Data loop
         Ada.Text_IO.Put (Hex (D));
         Ada.Text_IO.Put (' ');
      end loop;

      Ada.Text_IO.Put (" Accel:");
      for D of Accel_Data loop
         Ada.Text_IO.Put (Hex (D));
         Ada.Text_IO.Put (' ');
      end loop;

      Ada.Text_IO.New_Line;
      --  Data := (1, 2, 3, 4);
      --  Data := (others => 16#FF#);
      --  for I in Data'Range loop
      --     T := Clock;
      --     I2C.Read_Byte (Addr, UInt8 (I), Data (I));
      --  end loop;
      --  Print (Data);
   end loop;
end Test;
