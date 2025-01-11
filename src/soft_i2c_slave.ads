--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with HAL; use HAL;

generic
   with procedure Set_SDA (High : Boolean);
   with procedure Write (Data : UInt8);
   with procedure Read (Data : out UInt8);
package Soft_I2C_Slave is

   Address : UInt7 := 16#50#;

   procedure Initialize;

   procedure SCL_Rising
      (SDA_High : Boolean);

end Soft_I2C_Slave;
