--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
package body Softdev.SPI_Master is
   procedure Transfer
      (Data : in out UInt8)
   is
      Bit : Boolean;
   begin
      for I in 0 .. 7 loop
         Bit := (Data and 16#80#) /= 0;
         Set_MOSI (Bit);
         Set_SCK (True);
         Get_MISO (Bit);
         Set_SCK (False);
         Data := Shift_Left (Data, 1);
         if Bit then
            Data := Data or 1;
         end if;
      end loop;
   end Transfer;
end Softdev.SPI_Master;
