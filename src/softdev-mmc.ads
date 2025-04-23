--
--  Copyright (C) 2024-2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
--  MMC card driver for SPI interfaces
--  This is a low speed compatibility mode supported by most cards.
--
--  Sometimes hardware pinouts use the SD naming convention, rather than SPI.
--  Connect the signals as follows:
--
--    CLK   -> CLK
--    CMD   -> MOSI
--    DAT0  -> MISO
--    DAT1  not connected
--    DAT2  not connected
--    DAT3  -> CS
--
--  I strongly recommend wiring a MOSFET to the card's power supply so that you
--  can power cycle it programmatically after any error. Sometimes cards can
--  get into a weird state that only a power cycle can fix.
--
--  If you need to detect the presence of a card, disable all pullups on CS and
--  interrupt on the rising edge. CS must be reconfigured as an output before
--  calling Initialize. Or, you can just poll Initialize until Has_Error
--  returns False.
--
--  CS, MOSI, MISO, and CLK should all have pullup resistors of approximately
--  10k ohm. Most cards will have weak 50k resistors internally.
--
--  The SPI bus speed should be less than 400 KHz during Initialize. After
--  Initialize, the bus speed may be increased. The maximum speed depends on
--  the card. This driver does not support card speed detection. 10 MHz is
--  usually safe.
--
--  If Has_Error returns True, the only way to reset it is to Initialize again.
--  The card might still work after an error, but I wouldn't count on it.
--
--  Read and Write only support single block operations. Blocks are always 512
--  bytes.
--
--  This driver does not perform any CRC calculation or checking.
--
with HAL; use HAL;

generic
   with procedure SPI_Transfer
      (Data : in out UInt8);
   with procedure Set_CS (High : Boolean);
package Softdev.MMC is
   subtype Block_Data is UInt8_Array (1 .. 512);

   procedure Initialize;

   function Has_Error
      return Boolean;

   function Read
      (Block_Number : UInt64;
       Data : out Block_Data)
       return Boolean;

   function Write
      (Block_Number : UInt64;
       Data : Block_Data)
       return Boolean;

end Softdev.MMC;
