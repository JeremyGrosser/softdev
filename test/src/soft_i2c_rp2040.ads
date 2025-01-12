--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with Soft_I2C_Master;
with Soft_I2C_Slave;
with HAL; use HAL;

package Soft_I2C_RP2040 is

   procedure Initialize;

   procedure Set_SDA
      (High : Boolean);

   procedure Set_SCL
      (High : Boolean);

   procedure Get_SDA
      (High : out Boolean);

   procedure Get_SCL
      (High : out Boolean);

   package Port is new Soft_I2C_Master
      (Set_SDA => Set_SDA,
       Set_SCL => Set_SCL,
       Get_SDA => Get_SDA,
       Get_SCL => Get_SCL,
       Clock_Stretch_Enabled => True);

   Slave_Data : UInt8 := 0;

   procedure Slave_Set_SDA
      (High : Boolean);

   procedure Slave_Get_SCL
      (High : out Boolean);

   procedure Slave_Get_SDA
      (High : out Boolean);

   procedure Slave_Write
      (Data : UInt8);

   procedure Slave_Read
      (Data : out UInt8;
       NACK : out Boolean);

   procedure Slave_Interrupt;

   package Slave is new Soft_I2C_Slave
      (Set_SDA => Slave_Set_SDA,
       Write   => Slave_Write,
       Read    => Slave_Read);

end Soft_I2C_RP2040;
