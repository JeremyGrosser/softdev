--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with HAL; use HAL;

--  8N1 UART, LSB first, idle high
generic
   with procedure Set_TXD (High : Boolean);
   with procedure Get_RXD (High : out Boolean);
   Oversample : Positive := 4; --  minimum 3x
package Softdev.UART is

   function Ready_To_Send
      return Boolean;

   function Data_Ready
      return Boolean;

   procedure Write
      (Data : UInt8)
   with Pre => Ready_To_Send;

   procedure Read
      (Data : out UInt8)
   with Pre => Data_Ready;

   procedure Poll;
   --  Called every ((1.0 / Baud_Rate) / Oversample) Seconds

end Softdev.UART;
