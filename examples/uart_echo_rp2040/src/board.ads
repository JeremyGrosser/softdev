with Softdev.UART;

package Board is

   type Time is mod 2 ** 64;
   Ticks_Per_Second : constant Time := 1_000_000;

   function Clock
      return Time;

   procedure Set_LED
      (High : Boolean);

   procedure Set_TXD
      (High : Boolean);

   procedure Get_RXD
      (High : out Boolean);

   package UART_0 is new Softdev.UART
      (Set_TXD => Set_TXD,
       Get_RXD => Get_RXD);

   procedure Initialize;

end Board;
