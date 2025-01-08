--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with RP.Timer; use RP.Timer;
with Soft_I2C;

package Soft_I2C_RP2040 is

   T : Time;

   procedure Initialize;

   procedure Set_SDA
      (High : Boolean);

   procedure Set_SCL
      (High : Boolean);

   procedure Get_SDA
      (High : out Boolean);

   procedure Get_SCL
      (High : out Boolean);

   package Port is new Soft_I2C
      (Set_SDA => Set_SDA,
       Set_SCL => Set_SCL,
       Get_SDA => Get_SDA,
       Get_SCL => Get_SCL);

end Soft_I2C_RP2040;
