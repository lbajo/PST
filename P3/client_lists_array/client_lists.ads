-- LORENA BAJO REBOLLO
with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Calendar;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.IO_Exceptions;

package Client_Lists is
   package ASU renames Ada.Strings.Unbounded;
   package LLU renames Lower_Layer_UDP;


   type Client_List_Type is private;

   Client_List_Error: exception;

   procedure Add_Client (List: in out Client_List_Type;
                         EP: in LLU.End_Point_Type;
                         Nick: in ASU.Unbounded_String);

   procedure Delete_Client (List: in out Client_List_Type;
                            Nick: in ASU.Unbounded_String);

   function Search_Client (List: in Client_List_Type;
                           EP: in LLU.End_Point_Type)
                          return ASU.Unbounded_String;

   procedure Send_To_All (List: in Client_List_Type;
                          P_Buffer: access LLU.Buffer_Type;
                          EP_Not_Send: in LLU.End_Point_Type);

   function List_Image (List: in Client_List_Type) return String;

   procedure Update_Client (List: in out Client_List_Type;
                            EP: in LLU.End_Point_Type);

   procedure Remove_Oldest (List: in out Client_List_Type; EP: out LLU.End_Point_Type;
                         Nick: out ASU.Unbounded_String);

   function Count (List: in Client_List_Type) return Natural;

private

	type Cliente is record
		Client_EP: LLU.End_Point_Type;
		Nick: ASU.Unbounded_String;
		Hora: Ada.Calendar.Time;
		Existe: Boolean:=False;
		Total: Natural:=0;
	end record;
	
	type Client_List_Type is array (1..50) of Cliente;
   
end Client_Lists;
