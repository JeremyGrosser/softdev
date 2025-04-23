--
--  Copyright (C) 2024-2025 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--

package body Softdev.MMC is

   Error : Integer := Integer'Last;
   SDHC  : Boolean := False;

   function Has_Error
      return Boolean
   is (Error >= 0);

   procedure SPI_Read
      (Data : out UInt8)
   is
   begin
      Data := 16#FF#;
      SPI_Transfer (Data);
   end SPI_Read;

   procedure SPI_Read_32
      (Data : out UInt32)
   is
      X : UInt8;
   begin
      Data := 0;
      for I in 1 .. 4 loop
         SPI_Read (X);
         Data := Shift_Left (Data, 8) or UInt32 (X);
      end loop;
   end SPI_Read_32;

   procedure SPI_Write
      (Data : UInt8)
   is
      X : UInt8 := Data;
   begin
      SPI_Transfer (X);
   end SPI_Write;

   procedure Sync
      (Token : UInt8 := 16#FF#)
   is
      Data : UInt8;
   begin
      loop
         Data := 16#FF#;
         SPI_Transfer (Data);
         exit when Data = Token;
      end loop;
   end Sync;

   procedure Send_Command
      (Cmd  : UInt8;
       Arg  : UInt32;
       CRC  : UInt8;
       R1   : out UInt8)
   is
   begin
      Sync;
      SPI_Write (16#40# or Cmd);
      SPI_Write (UInt8 (Shift_Right (Arg, 24) and 16#FF#));
      SPI_Write (UInt8 (Shift_Right (Arg, 16) and 16#FF#));
      SPI_Write (UInt8 (Shift_Right (Arg, 8) and 16#FF#));
      SPI_Write (UInt8 (Arg and 16#FF#));
      SPI_Write (CRC);
      for I in 1 .. 4 loop
         SPI_Read (R1);
         exit when R1 /= 16#FF#;
      end loop;
   end Send_Command;

   procedure GO_IDLE is
      R1 : UInt8;
   begin
      Set_CS (True);
      for I in 1 .. 16 loop
         SPI_Write (16#FF#);
      end loop;
      Set_CS (False);
      Send_Command (0, 0, 16#95#, R1);
      Set_CS (True);
      if R1 /= 1 then
         Error := 0;
      end if;
   end GO_IDLE;

   procedure SEND_OP_COND is
      R1 : UInt8;
   begin
      Set_CS (False);
      Send_Command (1, 0, 16#F9#, R1);
      if R1 /= 1 then
         Error := 1;
      end if;
      Set_CS (True);
   end SEND_OP_COND;

   procedure SEND_IF_COND is
      R1 : UInt8;
      R7 : UInt8_Array (1 .. 4);
   begin
      Set_CS (False);
      Send_Command (8, 16#0000_01AA#, 16#87#, R1);

      if R1 /= 1 then
         Error := 8;
      end if;

      for I in R7'Range loop
         SPI_Read (R7 (I));
      end loop;
      if R7 /= (16#00#, 16#00#, 16#01#, 16#AA#) then
         Error := 8;
      end if;
      Set_CS (True);
   end SEND_IF_COND;

   procedure SD_SEND_OP_COND is
      R1 : UInt8;
      R3 : UInt32 := 0;
   begin
      for I in 1 .. 500 loop
         Set_CS (False);
         Send_Command (55, 0, 16#65#, R1);
         Set_CS (True);

         if R1 = 1 then
            Set_CS (False);
            --  HCS=1, XPC=1, S18R=0,
            Send_Command (41, 16#4010_0000#, 16#77#, R1);
            SPI_Read_32 (R3);
            Set_CS (True);

            case R1 is
               when 0 =>
                  --  Card init done
                  return;
               when 1 =>
                  --  Card is not ready, retry
                  null;
               when others =>
                  --  R1=5 might mean this is a very old card.
                  Error := 41;
                  return;
            end case;
         elsif R1 = 5 then
            --  V1 MMC card, ACMD41 not supported
            SEND_OP_COND;
            return;
         else
            Error := 55;
         end if;
      end loop;
      Error := 41;
   end SD_SEND_OP_COND;

   procedure SET_BLOCKLEN is
      R1 : UInt8;
   begin
      Set_CS (False);
      Send_Command (16, 512, 16#55#, R1);
      if R1 /= 0 then
         Error := 16;
      end if;
      Set_CS (True);
   end SET_BLOCKLEN;

   procedure READ_OCR is
      R1  : UInt8;
      OCR : UInt32 := 0;
   begin
      Set_CS (False);
      Send_Command (58, 0, 16#55#, R1);
      if R1 /= 0 then
         Error := 58;
      else
         SPI_Read_32 (OCR);
         SDHC := (OCR and 16#C000_0000#) = 16#C000_0000#;
         --  If the CCS bit and Card Power Up Status bits are set then this is
         --  an SDHC card
      end if;
      Set_CS (True);
   end READ_OCR;

   procedure Initialize is
   begin
      Error := -1;

      GO_IDLE;
      if Has_Error then
         return;
      end if;

      SEND_IF_COND;
      if Has_Error then
         return;
      end if;

      SD_SEND_OP_COND;
      if Has_Error then
         return;
      end if;

      READ_OCR;
      if Has_Error then
         return;
      end if;

      SET_BLOCKLEN;
      if Has_Error then
         return;
      end if;
   end Initialize;

   procedure Wait_For_Idle is
      R1, R2 : UInt8;
   begin
      Set_CS (False);
      loop
         Send_Command (13, 0, 16#0D#, R1);
         SPI_Read (R2);
         exit when R1 = 0 and then R2 = 0;
      end loop;
      Set_CS (True);
   end Wait_For_Idle;

   function Block_Offset
      (Addr : UInt64)
      return UInt32
   is (if SDHC then UInt32 (Addr) else UInt32 (Addr * 512));

   function Read
      (Block_Number : UInt64;
       Data : out Block_Data)
       return Boolean
   is
      R1 : UInt8;
   begin
      Set_CS (False);
      Send_Command (17, Block_Offset (Block_Number), 16#55#, R1);
      if R1 = 0 then
         Sync (16#FE#);
         for I in Data'Range loop
            SPI_Read (Data (I));
         end loop;
         SPI_Read (R1); --  CRC16
         SPI_Read (R1); --  CRC16
         Sync;
      else
         Error := 17;
      end if;
      Set_CS (True);
      return not Has_Error;
   end Read;

   function Write
      (Block_Number : UInt64;
       Data : Block_Data)
       return Boolean
   is
      R1 : UInt8;
   begin
      Set_CS (False);
      Send_Command (24, Block_Offset (Block_Number), 16#55#, R1);
      if R1 = 0 then
         Sync;
         SPI_Write (16#FE#); --  Start block
         for D of Data loop
            SPI_Write (D);
         end loop;
         SPI_Write (16#DE#); --  CRC16
         SPI_Write (16#AD#);
         SPI_Read (R1);
         Wait_For_Idle;
      else
         Error := 24;
      end if;
      Set_CS (True);
      return not Has_Error;
   end Write;

end Softdev.MMC;
