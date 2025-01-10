--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
pragma Style_Checks ("M120");
with RP2040_SVD.RESETS; use RP2040_SVD.RESETS;
with RP2040_SVD.SIO; use RP2040_SVD.SIO;
with RP2040_SVD.PADS_BANK0; use RP2040_SVD.PADS_BANK0;
with RP2040_SVD.IO_BANK0; use RP2040_SVD.IO_BANK0;
with RP.Timer; use RP.Timer;
with HAL; use HAL;
with System;

package body Soft_I2C_RP2040 is
   SDA_Pin  : constant := 0;
   SCL_Pin  : constant := 1;
   SDA_Mask : constant UInt32 := Shift_Left (1, SDA_Pin);
   SCL_Mask : constant UInt32 := Shift_Left (1, SCL_Pin);

   --  Skip the SVD record types for timing critical registers
   SIO_BASE : constant := 16#D000_0000#;
   GPIO_IN : UInt32
      with Import, Volatile_Full_Access, Address => System'To_Address (SIO_BASE + 16#004#);
   GPIO_OE_SET : UInt32
      with Import, Volatile_Full_Access, Address => System'To_Address (SIO_BASE + 16#024#);
   GPIO_OE_CLR : UInt32
      with Import, Volatile_Full_Access, Address => System'To_Address (SIO_BASE + 16#028#);

   procedure Initialize is
   begin
      RESETS_Periph.RESET.io_bank0 := False;
      RESETS_Periph.RESET.pads_bank0 := False;
      loop
         exit when RESETS_Periph.RESET_DONE.io_bank0 and then
                   RESETS_Periph.RESET_DONE.pads_bank0;
      end loop;

      --  output disable off
      PADS_BANK0_Periph.GPIO0.OD := False;
      PADS_BANK0_Periph.GPIO1.OD := False;
      --  input enable on
      PADS_BANK0_Periph.GPIO0.IE := True;
      PADS_BANK0_Periph.GPIO1.IE := True;

      --  function select
      IO_BANK0_Periph.GPIO0_CTRL.FUNCSEL := sio_0;
      IO_BANK0_Periph.GPIO1_CTRL.FUNCSEL := sio_1;

      GPIO_OE_CLR := SDA_Mask or SCL_Mask;
      SIO_Periph.GPIO_OUT_CLR.GPIO_OUT_CLR := UInt30 (SDA_Mask or SCL_Mask);
   end Initialize;

   --  Timing in Microseconds
   --
   --  This will depend a lot on how long your I/O operations take and what
   --  your peripheral supports. The following implementation is pretty close
   --  to I2C Standard Mode (100 KHz) on RP2040.
   --
   --  Without delays, we can do about 1.6 MHz I2C here. More than fast enough.
   SCL_Hold : constant := 5;

   procedure Set_SDA
      (High : Boolean)
   is
   begin
      if High then
         GPIO_OE_CLR := SDA_Mask;
      else
         GPIO_OE_SET := SDA_Mask;
      end if;
   end Set_SDA;

   procedure Set_SCL
      (High : Boolean)
   is
   begin
      if High then
         GPIO_OE_CLR := SCL_Mask;
      else
         GPIO_OE_SET := SCL_Mask;
      end if;
      RP.Timer.Busy_Wait_Until (RP.Timer.Clock + SCL_Hold);
   end Set_SCL;

   procedure Get_SDA
      (High : out Boolean)
   is
   begin
      High := (GPIO_IN and SDA_Mask) /= 0;
   end Get_SDA;

   procedure Get_SCL
      (High : out Boolean)
   is
   begin
      High := (GPIO_IN and SCL_Mask) /= 0;
   end Get_SCL;

end Soft_I2C_RP2040;
