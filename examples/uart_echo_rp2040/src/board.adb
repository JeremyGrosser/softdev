with RP.GPIO; use RP.GPIO;
with RP.Timer;
with RP.Clock;

package body Board is

   TXD : GPIO_Point := (Pin => 0);
   RXD : GPIO_Point := (Pin => 1);
   LED : GPIO_Point := (Pin => 25);

   function Clock
      return Time
   is (Time (RP.Timer.Clock));

   procedure Set_LED
      (High : Boolean)
   is
   begin
      if High then
         LED.Set;
      else
         LED.Clear;
      end if;
   end Set_LED;

   procedure Set_TXD
      (High : Boolean)
   is
   begin
      if High then
         TXD.Set;
      else
         TXD.Clear;
      end if;
   end Set_TXD;

   procedure Get_RXD
      (High : out Boolean)
   is
   begin
      High := RXD.Set;
   end Get_RXD;

   procedure Initialize is
   begin
      RP.Clock.Initialize (12_000_000);
      LED.Configure (Output);
      TXD.Configure (Output, Pull_Down);
      RXD.Configure (Input, Pull_Down);
   end Initialize;

end Board;
