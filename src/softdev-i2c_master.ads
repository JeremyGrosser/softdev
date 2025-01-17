--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
pragma Style_Checks ("M120");
with HAL; use HAL;

generic
   with procedure Set_SCL (High : Boolean);
   with procedure Get_SCL (High : out Boolean);
   with procedure Set_SDA (High : Boolean);
   with procedure Get_SDA (High : out Boolean);
   --  When High = True, the output driver is disabled and the pin left floating
   --  When High = False, the output driver is enabled and the pin is pulled low (open-drain)
   --  Never drive the pin high.
   --  Never use internal pull-up resistors.

   Clock_Stretch_Enabled : Boolean := False;
package Softdev.I2C_Master is

   subtype I2C_Address is HAL.UInt7;

   procedure Initialize;

   procedure Write
      (Addr : I2C_Address;
       Data : UInt8_Array;
       Stop : Boolean := True);

   procedure Read
      (Addr : I2C_Address;
       Data : out UInt8_Array;
       Stop : Boolean := True);

   --  Status
   NACK : Boolean := False;

end Softdev.I2C_Master;
