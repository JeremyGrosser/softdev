with Ada.Containers.Vectors;
with Ada.Wide_Wide_Text_IO;
with Ada.Text_IO; use Ada.Text_IO;
with Generic_Hex_Format;
with HAL; use HAL;

with Soft_I2C_Master;
with Soft_I2C_Slave;

procedure Slave_Test is
   package Hex_Format_8 is new Generic_Hex_Format (UInt8, Shift_Right);
   use Hex_Format_8;

   type Signals is record
      SDA, SCL : Boolean := True;
   end record;

   Last_Bus : Signals := (SDA => False, SCL => False);
   Bus      : Signals := (SDA => True, SCL => True);
   Counter  : UInt8 := 0;

   procedure Interrupt;

   procedure Master_Set_SDA
      (High : Boolean)
   is
   begin
      Bus.SDA := High;
      Interrupt;
   end Master_Set_SDA;

   procedure Master_Set_SCL
      (High : Boolean)
   is
   begin
      Bus.SCL := High;
      Interrupt;
   end Master_Set_SCL;

   procedure Master_Get_SDA
      (High : out Boolean)
   is
   begin
      High := Bus.SDA;
      Interrupt;
   end Master_Get_SDA;

   procedure Master_Get_SCL
      (High : out Boolean)
   is
   begin
      High := Bus.SCL;
      Interrupt;
   end Master_Get_SCL;

   procedure Slave_Set_SDA
      (High : Boolean)
   is
   begin
      if Bus.SDA then
         Bus.SDA := High;
         Interrupt;
      end if;
   end Slave_Set_SDA;

   package UInt8_Vectors is new Ada.Containers.Vectors (Positive, UInt8);
   use UInt8_Vectors;
   Slave_Data : UInt8_Vectors.Vector;

   procedure Slave_Write
      (Data : UInt8)
   is
   begin
      Append (Slave_Data, Data);
   end Slave_Write;

   procedure Slave_Read
      (Data : out UInt8;
       NACK : out Boolean)
   is
   begin
      Data := Counter;
      Counter := Counter + 1;
      NACK := False;
   end Slave_Read;

   package Master is new Soft_I2C_Master
      (Set_SDA => Master_Set_SDA,
       Set_SCL => Master_Set_SCL,
       Get_SDA => Master_Get_SDA,
       Get_SCL => Master_Get_SCL);

   package Slave is new Soft_I2C_Slave
      (Set_SDA => Slave_Set_SDA,
       Write   => Slave_Write,
       Read    => Slave_Read);

   package Boolean_Vectors is new Ada.Containers.Vectors (Positive, Boolean);
   use Boolean_Vectors;
   SDA_States, SCL_States : Boolean_Vectors.Vector;

   procedure Interrupt is
   begin
      if Bus /= Last_Bus then
         Append (SDA_States, Bus.SDA);
         Append (SCL_States, Bus.SCL);
         Slave.Interrupt (SCL => Bus.SCL, SDA => Bus.SDA);
         Append (SDA_States, Bus.SDA);
         Append (SCL_States, Bus.SCL);
      end if;
      Last_Bus := Bus;
   end Interrupt;
begin
   Master.Initialize;
   Slave.Initialize;
   Slave.Address := 16#51#;
   Interrupt;

   Master.Write
      (Addr => Slave.Address,
       Data => UInt8_Array'(1 => 16#42#),
       Stop => True);
   Put_Line ("Master Write NACK=" & Master.NACK'Image);

   for I in 1 .. 100 loop
      Interrupt;
   end loop;

   Put ("SDA=");
   for State of SDA_States loop
      if State then
         Ada.Wide_Wide_Text_IO.Put ('‾');
      else
         Put ('_');
      end if;
   end loop;
   New_Line;

   Put ("SCL=");
   for State of SCL_States loop
      if State then
         Ada.Wide_Wide_Text_IO.Put ('‾');
      else
         Put ('_');
      end if;
   end loop;
   New_Line;

   Put ("DAT=");
   for D of Slave_Data loop
      Put (Hex (D));
      Put (' ');
   end loop;
   New_Line;
end Slave_Test;
