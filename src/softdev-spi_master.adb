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
         Set_SCK (False);
         Get_MISO (Bit);
         Data := Shift_Left (Data, 1);
         if Bit then
            Data := Data or 1;
         end if;
      end loop;
   end Transfer;
end Softdev.SPI_Master;
