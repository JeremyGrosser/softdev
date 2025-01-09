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
with HAL; use HAL;

package body Soft_I2C_RP2040 is
   --  SDA_Pin  : constant := 0;
   --  SCL_Pin  : constant := 1;
   SDA_Mask : constant UInt30 := 2#01#;
   SCL_Mask : constant UInt30 := 2#10#;

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

      SIO_Periph.GPIO_OE_CLR.GPIO_OE_CLR := SDA_Mask or SCL_Mask;
      SIO_Periph.GPIO_OUT_CLR.GPIO_OUT_CLR := SDA_Mask or SCL_Mask;

      Timer.Enable;
   end Initialize;

   SDA_Hold : constant := 10;
   SCL_Hold : constant := 10;

   procedure Set_SDA
      (High : Boolean)
   is
   begin
      T := Clock;
      T := T + SDA_Hold;
      Timer.Delay_Until (T);

      if High then
         SIO_Periph.GPIO_OE_CLR.GPIO_OE_CLR := SDA_Mask;
      else
         SIO_Periph.GPIO_OE_SET.GPIO_OE_SET := SDA_Mask;
      end if;

      T := T + SDA_Hold;
      Timer.Delay_Until (T);
   end Set_SDA;

   procedure Set_SCL
      (High : Boolean)
   is
   begin
      T := Clock;
      T := T + SCL_Hold;
      Timer.Delay_Until (T);

      if High then
         SIO_Periph.GPIO_OE_CLR.GPIO_OE_CLR := SCL_Mask;
      else
         SIO_Periph.GPIO_OE_SET.GPIO_OE_SET := SCL_Mask;
      end if;

      T := T + SCL_Hold;
      Timer.Delay_Until (T);
   end Set_SCL;

   procedure Get_SDA
      (High : out Boolean)
   is
   begin
      High := (SIO_Periph.GPIO_IN.GPIO_IN and SDA_Mask) /= 0;
   end Get_SDA;

   procedure Get_SCL
      (High : out Boolean)
   is
   begin
      High := (SIO_Periph.GPIO_IN.GPIO_IN and SCL_Mask) /= 0;
   end Get_SCL;

end Soft_I2C_RP2040;
