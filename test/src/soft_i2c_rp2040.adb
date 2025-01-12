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
with RP_Interrupts;
with RP.Timer; use RP.Timer;
with System;

package body Soft_I2C_RP2040 is
   SDA_Pin  : constant := 0;
   SCL_Pin  : constant := 1;
   Slave_SDA : constant := 2;
   Slave_SCL : constant := 3;
   SDA_Mask : constant UInt32 := Shift_Left (1, SDA_Pin);
   SCL_Mask : constant UInt32 := Shift_Left (1, SCL_Pin);
   Slave_SDA_Mask : constant UInt32 := Shift_Left (1, Slave_SDA);
   Slave_SCL_Mask : constant UInt32 := Shift_Left (1, Slave_SCL);

   --  Skip the SVD record types for timing critical registers
   SIO_BASE : constant := 16#D000_0000#;
   GPIO_IN : UInt32
      with Import, Volatile_Full_Access, Address => System'To_Address (SIO_BASE + 16#004#);
   GPIO_OE_SET : UInt32
      with Import, Volatile_Full_Access, Address => System'To_Address (SIO_BASE + 16#024#);
   GPIO_OE_CLR : UInt32
      with Import, Volatile_Full_Access, Address => System'To_Address (SIO_BASE + 16#028#);

   IO_BANK0_BASE : constant := 16#4001_4000#;
   INTR0 : UInt32
      with Import, Volatile_Full_Access, Address => System'To_Address (IO_BANK0_BASE + 16#0F0#);

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
      PADS_BANK0_Periph.GPIO2.OD := False;
      PADS_BANK0_Periph.GPIO3.OD := False;
      --  input enable on
      PADS_BANK0_Periph.GPIO0.IE := True;
      PADS_BANK0_Periph.GPIO1.IE := True;
      PADS_BANK0_Periph.GPIO2.IE := True;
      PADS_BANK0_Periph.GPIO3.IE := True;

      --  function select
      IO_BANK0_Periph.GPIO0_CTRL.FUNCSEL := sio_0;
      IO_BANK0_Periph.GPIO1_CTRL.FUNCSEL := sio_1;
      IO_BANK0_Periph.GPIO2_CTRL.FUNCSEL := sio_2;
      IO_BANK0_Periph.GPIO3_CTRL.FUNCSEL := sio_3;

      IO_BANK0_Periph.PROC0_INTE0 :=
         (GPIO2_EDGE_HIGH  => True,
          GPIO2_EDGE_LOW   => True,
          GPIO3_EDGE_HIGH  => True,
          GPIO3_EDGE_LOW   => True,
          others           => False);

      GPIO_OE_CLR := SDA_Mask or SCL_Mask or Slave_SDA_Mask or Slave_SCL_Mask;
      SIO_Periph.GPIO_OUT_CLR.GPIO_OUT_CLR := UInt30 (SDA_Mask or SCL_Mask or Slave_SDA_Mask or Slave_SCL_Mask);

      Slave.Initialize;
      Slave.Address := 16#19#;
      Port.Initialize;

      RP_Interrupts.Attach_Handler (Slave_Interrupt'Access, 13, RP_Interrupts.Interrupt_Priority'Last);
   end Initialize;

   --  Timing in Microseconds
   --
   --  This will depend a lot on how long your I/O operations take and what
   --  your peripheral supports. The following implementation is pretty close
   --  to I2C Standard Mode (100 KHz) on RP2040.
   --
   --  Without delays, we can do about 1.6 MHz I2C here. More than fast enough.
   SCL_Hold : constant := 5;
   SDA_Hold : constant := 1;

   procedure Set_SDA
      (High : Boolean)
   is
   begin
      if High then
         GPIO_OE_CLR := SDA_Mask;
      else
         GPIO_OE_SET := SDA_Mask;
      end if;
      RP.Timer.Busy_Wait_Until (RP.Timer.Clock + SDA_Hold);
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
      --  RP.Timer.Busy_Wait_Until (RP.Timer.Clock + SDA_Hold);
      High := (GPIO_IN and SDA_Mask) /= 0;
   end Get_SDA;

   procedure Get_SCL
      (High : out Boolean)
   is
   begin
      High := (GPIO_IN and SCL_Mask) /= 0;
   end Get_SCL;

   procedure Slave_Write
      (Data : UInt8)
   is
   begin
      Slave_Data := Data;
   end Slave_Write;

   procedure Slave_Read
      (Data : out UInt8;
       NACK : out Boolean)
   is
   begin
      NACK := False;
      Data := Slave_Data;
   end Slave_Read;

   procedure Slave_Set_SDA
      (High : Boolean)
   is
   begin
      if High then
         GPIO_OE_CLR := Slave_SDA_Mask;
      else
         GPIO_OE_SET := Slave_SDA_Mask;
      end if;
      RP.Timer.Busy_Wait_Until (RP.Timer.Clock + SDA_Hold);
   end Slave_Set_SDA;

   procedure Slave_Get_SCL
      (High : out Boolean)
   is
   begin
      High := (GPIO_IN and Slave_SCL_Mask) /= 0;
   end Slave_Get_SCL;

   procedure Slave_Get_SDA
      (High : out Boolean)
   is
   begin
      High := (GPIO_IN and Slave_SDA_Mask) /= 0;
   end Slave_Get_SDA;

   procedure Slave_Interrupt is
      SCL, SDA : Boolean;
   begin
      INTR0 := 16#FFFF_FFFF#; --  write to clear
      Slave_Get_SCL (SCL);
      Slave_Get_SDA (SDA);
      Slave.Interrupt (SDA => SDA, SCL => SCL);
   end Slave_Interrupt;

end Soft_I2C_RP2040;
