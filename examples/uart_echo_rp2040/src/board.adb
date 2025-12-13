--
--  Copyright (C) 2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with RP.GPIO; use RP.GPIO;
with RP.Timer;
with RP.Clock;

package body Board is

   TXD : GPIO_Point := (Pin => 0);
   RXD : GPIO_Point := (Pin => 1);

   function Clock
      return Time
   is
   begin
      return Time (RP.Timer.Clock);
   end Clock;

   procedure Set_TXD
      (High : Boolean)
   is
   begin
      if High then
         RP.GPIO.Set (TXD);
      else
         RP.GPIO.Clear (TXD);
      end if;
   end Set_TXD;

   procedure Get_RXD
      (High : out Boolean)
   is
   begin
      High := RP.GPIO.Set (RXD);
   end Get_RXD;

   procedure Initialize is
   begin
      RP.Clock.Initialize (12_000_000);
      RP.GPIO.Configure (TXD, Output, Pull_Down);
      RP.GPIO.Configure (RXD, Input, Pull_Down);
   end Initialize;

end Board;
