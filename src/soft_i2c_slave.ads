--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with HAL; use HAL;

generic
   with procedure Set_SDA (High : Boolean);
   --  When High = False the pin is pulled low (open-drain). When High = True,
   --  the pin is left floating and the output driver is disabled.

   with procedure Write (Data : UInt8);
   --  Called for each byte the master writes to our address

   with procedure Read (Data : out UInt8; NACK : out Boolean);
   --  Set NACK = True when there is no more data for the master to read.
package Soft_I2C_Slave is

   Address : UInt7 := 16#50#;

   procedure Initialize;

   type Logic_Level is (High, Low);

   procedure Interrupt
      (SCL, SDA : Logic_Level);
   --  Called for the Rising and Falling edges of SDA and SCL.

end Soft_I2C_Slave;
