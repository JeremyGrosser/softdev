--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with HAL; use HAL;
generic
   with procedure Set_SCK (High : Boolean);
   with procedure Set_MOSI (High : Boolean);
   with procedure Get_MISO (High : out Boolean);
package Softdev.SPI_Master is
   --  SPI Mode 0
   --  Data out on SCK rising
   --  Data in on SCK falling
   procedure Transfer
      (Data : in out UInt8);
end Softdev.SPI_Master;
