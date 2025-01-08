--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with HAL; use HAL;

generic
   with procedure Set_SCL (High : Boolean);
   with procedure Get_SCL (High : out Boolean);
   with procedure Set_SDA (High : Boolean);
   with procedure Get_SDA (High : out Boolean);
package Soft_I2C is

   subtype I2C_Address is HAL.UInt7;

   procedure Initialize;

   procedure Write_Byte
      (Addr    : I2C_Address;
       Command : UInt8;
       Data    : UInt8);

   procedure Read_Byte
      (Addr    : I2C_Address;
       Command : UInt8;
       Data    : out UInt8);

   --  Configuration
   Clock_Stretch_Enabled : Boolean := False;

   --  Status
   NACK : Boolean := False;

end Soft_I2C;