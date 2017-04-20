-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Chat_Messages;
with Ordered_Maps_G;
with Maps_Protector_G;
with Lower_Layer_UDP;
with Ada.Calendar;
with Time_String;
with Gnat.Calendar.Time_IO;
with Ada.Command_Line;
with Debug;
with Pantalla;
with Maps_G;
with Timed_Handlers;
with Ordered_Maps_Protector_G;
with Ada.Unchecked_Deallocation;


package Handlers_P5 is

	package LLU renames Lower_Layer_UDP;
  	package ASU renames Ada.Strings.Unbounded;
	package CM renames Chat_Messages;
  	package ATI renames Ada.Text_IO;
	package ACL renames Ada.Command_Line;
	package TH renames Timed_Handlers;

	use type LLU.End_Point_Type;
	use type ASU.Unbounded_String;
	use type Ada.Calendar.Time;

	type Seq_N_T is mod Integer'Last;

-- NP_Sender_Dests
	type Mess_Id_T is record
		EP: LLU.End_Point_Type;
		Seq: Seq_N_T;
	end record;
	type Destination_T is record
		EP: LLU.End_Point_Type := null;
		Retries : Natural := 0;
	end record;
	type Destinations_T is array (1..10) of Destination_T;


-- NP_Sender_Buffering
	type Buffer_A_T is access LLU.Buffer_Type;

	type Value_T is record
		EP_H_Creat: LLU.End_Point_Type;
		Seq_N: Seq_N_T;
		P_Buffer: CM.Buffer_A_T;
	end record;

	procedure Free is new Ada.Unchecked_Deallocation (LLU.Buffer_Type, CM.Buffer_A_T);
 
	function Image_3 (T: Ada.Calendar.Time) return String;

	function Igual_AC (T1:Ada.Calendar.Time; T2:Ada.Calendar.Time) return Boolean;

	function Menor_AC (T1:Ada.Calendar.Time; T2:Ada.Calendar.Time) return Boolean;

	function EP_Image (EP:LLU.End_Point_Type) return String;

	function "=" (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean;

	function "<" (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean;

	function ">" (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean;

	function RE_Image (M:Mess_Id_T) return String;
	
	function AR_Image (D:Destinations_T) return String;
	
	function Value_Image (V:Value_T) return String;
	
	procedure Reenviar (Hora: Ada.Calendar.Time);


	package NP_Sender_Dests is new Ordered_Maps_G (Mess_Id_T, 
						Destinations_T,
 						"=",
 						"<", 
						RE_Image, 
						AR_Image);

	package NP_Sender_Buffering is new Ordered_Maps_G (Ada.Calendar.Time, 
							Value_T,
							Igual_AC,
							Menor_AC,
							Image_3,
							Value_Image);


	package Sender_Dests is new Ordered_Maps_Protector_G (NP_Sender_Dests);
	package Sender_Buffering is new Ordered_Maps_Protector_G(NP_Sender_Buffering);


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
	


	Vecinos:Neighbors.Prot_Map;
	Mensajes : Latest_Msgs.Prot_Map;
	Vec_Asent: Sender_Dests.Prot_Map;
	Mens_Pend: Sender_Buffering.Prot_Map;

	EP_H:LLU.End_Point_Type;
	Nick:ASU.Unbounded_String;
	Port: Integer:=Integer'Value(ACL.Argument(1));
	Max_Delay:Integer:=Integer'Value(ACL.Argument(4));
	Fault_Pct: Integer:= Integer'Value(ACL.Argument(5));
	Plazo_Retransmision:Duration;--:=2* Duration(Max_Delay) / 1000;
	MAX: Integer:= 10 + (Fault_Pct/10)**2;
	

	
  procedure Peer_Handler (From     : in     LLU.End_Point_Type;
                           To       : in     LLU.End_Point_Type;
                           P_Buffer : access LLU.Buffer_Type);

end Handlers_P5;
