--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with Board; use Board;
with Chests.Ring_Buffers;
with HAL;

procedure Uart_Echo_Rp2040 is
   package Byte_Buffers is new Chests.Ring_Buffers
      (Element_Type  => HAL.UInt8,
       Capacity      => 8);
   use Byte_Buffers;

   Next_Poll : Time;
   Buffer : Byte_Buffers.Ring_Buffer;
   Data : HAL.UInt8;
begin
   Board.Initialize;
   Next_Poll := Clock;
   loop
      if Clock >= Next_Poll then
         UART_0.Poll;
         Next_Poll := Next_Poll + Poll_Interval;
      end if;

      if not Is_Full (Buffer) and then UART_0.Data_Ready then
         UART_0.Read (Data);
         Append (Buffer, Data);
      end if;

      if not Is_Empty (Buffer) and then UART_0.Ready_To_Send then
         UART_0.Write (First_Element (Buffer));
         Delete_First (Buffer);
      end if;
   end loop;
end Uart_Echo_Rp2040;
