--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with Softdev.UART;

package Board is

   type Time is mod 2 ** 64;
   Ticks_Per_Second : constant Time := 1_000_000;
   Baud_Rate      : constant := 9600;
   Oversample     : constant := 4;
   Poll_Interval  : constant Time :=
      (Ticks_Per_Second / Baud_Rate) / Oversample;

   function Clock
      return Time;

   procedure Set_TXD
      (High : Boolean);

   procedure Get_RXD
      (High : out Boolean);

   package UART_0 is new Softdev.UART
      (Set_TXD    => Set_TXD,
       Get_RXD    => Get_RXD,
       Oversample => Oversample);

   procedure Initialize;

end Board;
