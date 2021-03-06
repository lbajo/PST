-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Chat_Messages;
with Maps_G;
with Maps_Protector_G;
with Lower_Layer_UDP;
with Ada.Calendar;
with Time_String;
with Gnat.Calendar.Time_IO;
with Ada.Command_Line;
with Debug;
with Pantalla;


package Handlers_P4 is

	package LLU renames Lower_Layer_UDP;
  	package ASU renames Ada.Strings.Unbounded;
	package CM renames Chat_Messages;
  	package ATI renames Ada.Text_IO;
	package ACL renames Ada.Command_Line;
 
	function Image_3 (T: Ada.Calendar.Time) return String;

	type Seq_N_T is mod Integer'Last;


  	

	package NP_Neighbors is new Maps_G(LLU.End_Point_Type, 
					Ada.Calendar.Time,
 					null,
 					Ada.Calendar.Time_of(1995,12,20), 
					10,
					LLU."=", 
					LLU.Image, 
					Image_3);

	package NP_Latest_Msgs is new Maps_G(LLU.End_Point_Type, 
					Seq_N_T,
 					null,
 					0, 
					50,
					LLU."=", 
					LLU.Image, 
					Seq_N_T'Image); 


	package Neighbors is new Maps_Protector_G (NP_Neighbors);
	package Latest_Msgs is new Maps_Protector_G (NP_Latest_Msgs);


	Mess: CM.Message_Type;
 	EP_H_Creat: LLU.End_Point_Type;
	Seq_N:Seq_N_T;
	Port: Integer;
	EP_H_Rsnd:LLU.End_Point_Type;
	EP_R_Creat:LLU.End_Point_Type;
	EP_R:LLU.End_Point_Type;
	EP_H:LLU.End_Point_Type;
	Nick:ASU.Unbounded_String;
	Text: ASU.Unbounded_String;
	Confirm_Sent: Boolean;
	Success: Boolean;
	Vecinos:Neighbors.Prot_Map;
	Mensajes : Latest_Msgs.Prot_Map;
	Maquina:ASU.Unbounded_String;
	IPMaq:ASU.Unbounded_String;
	ARVecinos: Neighbors.Keys_Array_Type;
	NumSeq: Seq_N_T:=1;
	Ex: exception;
	

  procedure Peer_Handler (From     : in     LLU.End_Point_Type;
                           To       : in     LLU.End_Point_Type;
                           P_Buffer : access LLU.Buffer_Type);

end Handlers_P4;
