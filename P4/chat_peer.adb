-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Command_Line;
with Lower_Layer_UDP;
with Maps_G;
with Chat_Messages;
with Handlers_P4;
with Debug;
with Pantalla;
with Ada.Calendar;


procedure Chat_Peer is
	

	package ASU renames Ada.Strings.Unbounded;
	package ATI renames Ada.Text_IO;
	package LLU renames Lower_Layer_UDP;
	package ACL renames Ada.Command_Line;
	package CM renames Chat_Messages;
	package HP4 renames Handlers_P4;

	type Seq_N_T is mod Integer'Last;

	use type ASU.Unbounded_String;
	use type LLU.End_Point_Type;
	use type CM.Message_Type;
	use type Seq_N_T;


	Maquina:ASU.Unbounded_String;
	IPMaq:ASU.Unbounded_String;
	IP: ASU.Unbounded_String;
	Peer_EP: LLU.End_Point_Type;
	IP2: ASU.Unbounded_String;
	Peer_EP2: LLU.End_Point_Type;
	EP_R: LLU.End_Point_Type;
	EP_H: LLU.End_Point_Type;
	Nick: ASU.Unbounded_String;
	Neighbor_Host: ASU.Unbounded_String;
	Neighbor_Host2: ASU.Unbounded_String;
	Port: Integer;
	Neighbor_Port: Integer;
	Neighbor_Port2: Integer;
	Usage_Error: Exception;
	Buffer: aliased LLU.Buffer_Type(1024);
	Seq_N:Seq_N_T:=0;
	Expired: Boolean:= False;
	Confirm_Sent: Boolean;
	Mess: CM.Message_Type;
 	EP_H_Creat: LLU.End_Point_Type;
	EP_H_Rsnd:LLU.End_Point_Type;
	EP_R_Creat:LLU.End_Point_Type;
	Text: ASU.Unbounded_String;
	ARVecinos: HP4.Neighbors.Keys_Array_Type;

	function EP_Image (EP:LLU.End_Point_Type) return String is
			
		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;

		Usuario: ASU.Unbounded_String;
		IP: ASU.Unbounded_String;
		Puerto: ASU.Unbounded_String;
		Indice:Natural;	
		Dir: ASU.Unbounded_String;	
		Dir_IP: ASU.Unbounded_String;	
		Long_Dir: Natural;
		
	begin
			Dir:= ASU.To_Unbounded_String(LLU.Image(EP));
			Long_Dir:= ASU.Length(Dir);
			Indice:= ASU.Index(Dir, ": ");
			Dir_IP:= ASU.Tail(Dir, Long_Dir-Indice);
			Indice:= ASU.Index(Dir_IP, ",");
			IP:= ASU.Head(Dir_IP, Indice-1);
			Indice:= ASU.Index(Dir, "Port: ");
			Puerto:=ASU.Tail(Dir, Long_Dir-Indice-5);
			Usuario := IP & ":" & Puerto;
			
		return ASU.To_String(Usuario);

	end EP_Image;

begin

	if ACL.Argument_Count = 2 then
		Port:= Integer'Value(ACL.Argument(1));
		Nick:= ASU.To_Unbounded_String(ACL.Argument(2));
	elsif ACL.Argument_Count = 4 then
		Port:= Integer'Value(ACL.Argument(1));
		Nick:= ASU.To_Unbounded_String(ACL.Argument(2));
		Neighbor_Host:= ASU.To_Unbounded_String(ACL.Argument(3));
		Neighbor_Port:= Integer'Value(ACL.Argument(4));

	elsif ACL.Argument_Count = 6 then
		Port:= Integer'Value(ACL.Argument(1));
		Nick:= ASU.To_Unbounded_String(ACL.Argument(2));
		Neighbor_Host:= ASU.To_Unbounded_String(ACL.Argument(3));
		Neighbor_Port:= Integer'Value(ACL.Argument(4));
		Neighbor_Host2:= ASU.To_Unbounded_String(ACL.Argument(5));
		Neighbor_Port2:= Integer'Value(ACL.Argument(6));

	else
		raise Usage_Error;
	end if;

	Maquina:=ASU.To_Unbounded_String(LLU.Get_Host_Name);
	IPMaq:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Maquina)));

	if ACL.Argument_Count = 2 then
		EP_H:=LLU.Build(ASU.To_String(IPMaq), Port);
		LLU.Bind_Any(EP_R);
		LLU.Bind(EP_H, Handlers_P4.Peer_Handler'Access);
		LLU.Reset(Buffer);
		Debug.Put_Line("NOT following admission protocol because we have no initial contacts ... ", Pantalla.Verde);
		ATI.Put_Line("Chat_Peer");
		ATI.Put_Line("=========");
		ATI.New_Line(1);
		ATI.Put_Line(ASCII.LF & "Logging into chat with nick: " & ACL.Argument(2));	
		ATI.Put_Line(".h for help");	

		while Text /= ".quit" loop
					LLU.Reset(Buffer);
					Mess:=CM.Writer;
					Text:= ASU.To_Unbounded_String(ATI.Get_Line);

					if Text = ".quit" then 
						Mess:= CM.Logout;
						EP_H_Creat:= EP_H;
						EP_R_Creat:= EP_R;
						EP_H_Rsnd:= EP_H;
						Seq_N:=Seq_N + 1;
						Confirm_Sent:=True;
						CM.Message_Type'Output(Buffer'Access, Mess);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
						Seq_N_T'Output(Buffer'Access, Seq_N);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
						ASU.Unbounded_String'Output(Buffer'Access, Nick);
						Boolean'Output(Buffer'Access, Confirm_Sent);
						Debug.Put("FLOOD LOGOUT " , Pantalla.Amarillo);
						Debug.Put_Line(EP_Image(EP_H_Creat) & " " &Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd) 
								, Pantalla.Verde);
	
						ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
						for i in 1..10 loop
							if ARVecinos(i)/=null then
								LLU.Send(ARVecinos(i), Buffer'Access);
							end if;	
							Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
						end loop;

						LLU.Finalize;
					else
						Mess:= CM.Writer;
						EP_H_Creat:= EP_H;
						EP_R_Creat:= EP_R;
						EP_H_Rsnd:= EP_H;
						Seq_N:=Seq_N + 1;
						CM.Message_Type'Output(Buffer'Access, Mess);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
						Seq_N_T'Output(Buffer'Access, Seq_N);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
						ASU.Unbounded_String'Output(Buffer'Access, Nick);
						ASU.Unbounded_String'Output(Buffer'Access, Text);

						ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);

						for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop
	
							if ARVecinos(i)/=null then
								LLU.Send(ARVecinos(i), Buffer'Access);
							end if;
							Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
						end loop;

						Debug.Put_Line("Adding to latest_messages " & ASU.To_String(IPMaq) & ":" & ACL.Argument(1) 												& " " & Seq_N_T'Image(Seq_N),Pantalla.Verde);
						Debug.Put("FLOOD WRITTER ", Pantalla.Amarillo);
						Debug.Put_Line(EP_Image(EP_H_Creat) & " " &Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd) 
								& " " & ACL.Argument(2) & " " & ASU.To_String(Text), Pantalla.Verde);
					end if;	
				end loop;

		
	elsif ACL.Argument_Count = 4 then
		EP_H:=LLU.Build(ASU.To_String(IPMaq), Port);
		IP:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Neighbor_Host)));
		Peer_EP := LLU.Build(ASU.To_String(IP), Neighbor_Port);
		LLU.Bind_Any(EP_R);
		LLU.Bind(EP_H, HP4.Peer_Handler'Access);
		LLU.Reset(Buffer);

		Debug.Put_Line("Adding to neighbors " & LLU.To_IP(ACL.Argument(3)) & ":" & ACL.Argument(4), Pantalla.Verde );
		ATI.New_Line(1);
		Debug.Put_Line("Admission protocol started ... ", Pantalla.Verde);

		Mess:= CM.Init;
		EP_H_Creat:= EP_H;
		EP_R_Creat:= EP_R;
		EP_H_Rsnd:= EP_H;
		Seq_N:=Seq_N + 1;
		CM.Message_Type'Output(Buffer'Access, Mess);
		LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
		Seq_N_T'Output(Buffer'Access, Seq_N);
		LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
		LLU.End_Point_Type'Output(Buffer'Access, EP_R_Creat);
		ASU.Unbounded_String'Output(Buffer'Access, Nick);

		HP4.Neighbors.Put(HP4.Vecinos, Peer_EP, Ada.Calendar.Clock, HP4.Success ); 
		HP4.Latest_Msgs.Put(HP4.Mensajes, Peer_EP, HP4.Seq_N, HP4.Success );

		Debug.Put_Line("Adding to latest_messages " & ASU.To_String(IPMaq) & ":" & ACL.Argument(1) & " " & Seq_N_T'Image(Seq_N), 															Pantalla.Verde);
		Debug.Put("FLOOD INIT " , Pantalla.Amarillo);
		Debug.Put_Line( ASU.To_String(IPMaq) & ":" & ACL.Argument(1) & " " & Seq_N_T'Image(Seq_N) & " "& ASU.To_String(IPMaq) & ":" &  									ACL.Argument(1) & " ... " & ACL.Argument(2), Pantalla.Verde);

		ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
		for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop
			LLU.Send(ARVecinos(i), Buffer'Access);
			Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
		end loop;
		LLU.Reset(Buffer);

		LLU.Receive(EP_R, Buffer'Access, 2.0, Expired);

		if Expired = False then
			Mess:=CM.Message_Type'Input(Buffer'Access);
	
				ATI.Put_Line("Nick repetido, inténtelo de nuevo");
				Mess:= CM.Logout;
				Confirm_Sent:=False;
				EP_H_Creat:= EP_H;
				EP_H_Rsnd:= EP_H;
				Seq_N:=Seq_N + 1;
				CM.Message_Type'Output(Buffer'Access, Mess);
				LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
				Seq_N_T'Output(Buffer'Access, Seq_N);
				LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
				ASU.Unbounded_String'Output(Buffer'Access, Nick);
				Boolean'Output(Buffer'Access, Confirm_Sent);

				Debug.Put("FLOOD LOGOUT " , Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " &Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd), Pantalla.Verde);
				 
				ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
				for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop

					LLU.Send(ARVecinos(i), Buffer'Access);
					Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
				end loop;

				LLU.Reset(Buffer);
				LLU.Finalize;

				
		elsif Expired=True then
				Mess:= CM.Confirm;
				EP_H_Creat:= EP_H;
				EP_R_Creat:= EP_R;
				EP_H_Rsnd:= EP_H;
				Seq_N:=Seq_N+1;
				CM.Message_Type'Output(Buffer'Access, Mess);
				LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
				Seq_N_T'Output(Buffer'Access, Seq_N);
				LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
				ASU.Unbounded_String'Output(Buffer'Access, Nick);

				Debug.Put_Line("Adding to latest_messages " & ASU.To_String(IPMaq) & ":" & ACL.Argument(1) & " " & 													Seq_N_T'Image(Seq_N), Pantalla.Verde);
				Debug.Put("FLOOD CONFIRM " , Pantalla.Amarillo);
				Debug.Put_Line( ASU.To_String(IPMaq) & ":" & ACL.Argument(1) & " " & Seq_N_T'Image(Seq_N) & " "& 						ASU.To_String(IPMaq) & ":" &  ACL.Argument(1) & " ... " & ACL.Argument(2), Pantalla.Verde);

				ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
				for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop
					LLU.Send(ARVecinos(i), Buffer'Access);
					Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
				end loop;
				LLU.Reset(Buffer);

				ATI.New_Line(1);
				Debug.Put_Line("Admission protocol finished. ", Pantalla.Verde);
				ATI.New_Line(1);
				ATI.Put_Line("Chat_Peer");
				ATI.Put_Line("=========");
				ATI.New_Line(1);
				ATI.Put_Line(ASCII.LF & "Logging into chat with nick: " & ACL.Argument(2));	
				ATI.Put_Line(".h for help");

				while Text /= ".quit" loop
					LLU.Reset(Buffer);
					Mess:=CM.Writer;
					Text:= ASU.To_Unbounded_String(ATI.Get_Line);

					if Text = ".quit" then 
						Mess:= CM.Logout;
						EP_H_Creat:= EP_H;
						EP_R_Creat:= EP_R;
						EP_H_Rsnd:= EP_H;
						Seq_N:=Seq_N+1;
						Confirm_Sent:=True;
						CM.Message_Type'Output(Buffer'Access, Mess);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
						Seq_N_T'Output(Buffer'Access, Seq_N);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
						ASU.Unbounded_String'Output(Buffer'Access, Nick);
						Boolean'Output(Buffer'Access, Confirm_Sent);
						
						Debug.Put("FLOOD LOGOUT " , Pantalla.Amarillo);
						Debug.Put_Line(EP_Image(EP_H_Creat) & " " &Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd) 
								, Pantalla.Verde);

						ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
						for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop
							if ARVecinos(i)/=null then
							LLU.Send(ARVecinos(i), Buffer'Access);
							Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							end if;
						end loop;

						
						LLU.Finalize;
					else
						EP_H_Creat:= EP_H;
						EP_R_Creat:= EP_R;
						EP_H_Rsnd:= EP_H;
						Seq_N:=Seq_N+1;
						CM.Message_Type'Output(Buffer'Access, Mess);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
						Seq_N_T'Output(Buffer'Access, Seq_N);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
						ASU.Unbounded_String'Output(Buffer'Access, Nick);
						ASU.Unbounded_String'Output(Buffer'Access, Text);
						Debug.Put_Line("Adding to latest_messages " & ASU.To_String(IPMaq) & ":" & ACL.Argument(1) 												& " " & Seq_N_T'Image(Seq_N),Pantalla.Verde);
						Debug.Put("FLOOD WRITTER ", Pantalla.Amarillo);
						Debug.Put_Line(EP_Image(EP_H_Creat) & " " &Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd) 
								& " " & ACL.Argument(2) & " " & ASU.To_String(Text), Pantalla.Verde);

						ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
						for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop
							LLU.Send(ARVecinos(i), Buffer'Access);
							Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
						end loop;	
					end if;	
				end loop;
		end if;
		

	elsif ACL.Argument_Count = 6 then
		EP_H:=LLU.Build(ASU.To_String(IPMaq), Port);
		IP:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Neighbor_Host)));
		Peer_EP := LLU.Build(ASU.To_String(IP), Neighbor_Port);
		IP2:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Neighbor_Host2)));
		Peer_EP2 := LLU.Build(ASU.To_String(IP), Neighbor_Port2);
		LLU.Bind_Any(EP_R);
		LLU.Bind(EP_H, HP4.Peer_Handler'Access);
		LLU.Reset(Buffer);

		Debug.Put_Line("Adding to neighbors " & LLU.To_IP(ACL.Argument(3)) & ":" & ACL.Argument(4), Pantalla.Verde );
		Debug.Put_Line("Adding to neighbors " & LLU.To_IP(ACL.Argument(5)) & ":" & ACL.Argument(6), Pantalla.Verde );
		ATI.New_Line(1);		
		Debug.Put_Line("Admission protocol started ... ", Pantalla.Verde);
		EP_H_Creat:= EP_H;
		EP_R_Creat:= EP_R;
		EP_H_Rsnd:= EP_H;
		Seq_N:= Seq_N+1;
		Mess:= CM.Init;
		CM.Message_Type'Output(Buffer'Access, Mess);
		LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
		Seq_N_T'Output(Buffer'Access, Seq_N);
		LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
		LLU.End_Point_Type'Output(Buffer'Access, EP_R_Creat);
		ASU.Unbounded_String'Output(Buffer'Access, Nick);

		HP4.Neighbors.Put(HP4.Vecinos, Peer_EP, Ada.Calendar.Clock, HP4.Success ); 
		HP4.Neighbors.Put(HP4.Vecinos, Peer_EP2, Ada.Calendar.Clock, HP4.Success );

		Debug.Put_Line("Adding to latest_messages " & ASU.To_String(IPMaq) & ":" & ACL.Argument(1) & " "
											 & Seq_N_T'Image(Seq_N), Pantalla.Verde);
		Debug.Put("FLOOD INIT " , Pantalla.Amarillo);
		Debug.Put_Line( ASU.To_String(IPMaq) & ":" & ACL.Argument(1) & " " & Seq_N_T'Image(Seq_N) & ASU.To_String(IPMaq) & ":" & 										ACL.Argument(1) & " ... " & ACL.Argument(2), Pantalla.Verde);
 
		ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
		for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop
			LLU.Send(ARVecinos(i), Buffer'Access);
			Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
		end loop;
		
		LLU.Reset(Buffer);
		ATI.New_Line(1);
		
		LLU.Receive(EP_R, Buffer'Access, 2.0, Expired);

		if Expired = False then
			Mess:=CM.Message_Type'Input(Buffer'Access);
		
				Mess:= CM.Logout;
				EP_H_Creat:= EP_H;
				EP_R_Creat:= EP_R;
				EP_H_Rsnd:= EP_H;
				Seq_N:=Seq_N+1;
				Confirm_Sent:=False;
				CM.Message_Type'Output(Buffer'Access, Mess);
				LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
				Seq_N_T'Output(Buffer'Access, Seq_N);
				LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
				ASU.Unbounded_String'Output(Buffer'Access, Nick);
				Boolean'Output(Buffer'Access, Confirm_Sent);

				Debug.Put("FLOOD LOGOUT " , Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " &Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd), Pantalla.Verde);

				ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
				for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop
					LLU.Send(ARVecinos(i), Buffer'Access);
					Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
				end loop;

				LLU.Reset(Buffer);
				LLU.Finalize;

		elsif Expired= True then	
				Mess:= CM.Confirm;
				EP_H_Creat:= EP_H;
				EP_R_Creat:= EP_R;
				EP_H_Rsnd:= EP_H;
				Seq_N:=Seq_N+1;
				CM.Message_Type'Output(Buffer'Access, Mess);
				LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
				Seq_N_T'Output(Buffer'Access, Seq_N);
				LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
				ASU.Unbounded_String'Output(Buffer'Access, Nick);

				Debug.Put_Line("Adding to latest_messages " & ASU.To_String(IPMaq) & ":" & ACL.Argument(1) & " " & 													Seq_N_T'Image(Seq_N), Pantalla.Verde);
				Debug.Put("FLOOD CONFIRM " , Pantalla.Amarillo);
				Debug.Put_Line( ASU.To_String(IPMaq) & ":" & ACL.Argument(1) & " " & Seq_N_T'Image(Seq_N) & " "& 						ASU.To_String(IPMaq) & ":" &  ACL.Argument(1) & " ... " & ACL.Argument(2), Pantalla.Verde);

				ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
				for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop
					LLU.Send(ARVecinos(i), Buffer'Access);
					Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
				end loop;				

				LLU.Reset(Buffer);

				ATI.New_Line(1);
				Debug.Put_Line("Admission protocol finished. ", Pantalla.Verde);
				ATI.New_Line(1);
				ATI.Put_Line("Chat_Peer");
				ATI.Put_Line("=========");
				ATI.New_Line(1);
				ATI.Put_Line(ASCII.LF & "Logging into chat with nick: " & ACL.Argument(2));	
				ATI.Put_Line(".h for help");

				while Text /= ".quit" loop
					LLU.Reset(Buffer);
					Mess:=CM.Writer;
					Text:= ASU.To_Unbounded_String(ATI.Get_Line);

					if Text = ".quit" then 
						Mess:= CM.Logout;
						EP_H_Creat:= EP_H;
						EP_R_Creat:= EP_R;
						EP_H_Rsnd:= EP_H;
						Seq_N:=Seq_N+1;
						Confirm_Sent:=True;
						CM.Message_Type'Output(Buffer'Access, Mess);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
						Seq_N_T'Output(Buffer'Access, Seq_N);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
						ASU.Unbounded_String'Output(Buffer'Access, Nick);
						Boolean'Output(Buffer'Access, Confirm_Sent);
						
						Debug.Put("FLOOD LOGOUT " , Pantalla.Amarillo);
						Debug.Put_Line(EP_Image(EP_H_Creat) & " " &Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd), 															Pantalla.Verde);
						
						ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
						for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop
							LLU.Send(ARVecinos(i), Buffer'Access);
							Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
						end loop;
						LLU.Finalize;
					else
						EP_H_Creat:= EP_H;
						EP_R_Creat:= EP_R;
						EP_H_Rsnd:= EP_H;
						Seq_N:=Seq_N+1;
						CM.Message_Type'Output(Buffer'Access, Mess);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
						Seq_N_T'Output(Buffer'Access, Seq_N);
						LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
						ASU.Unbounded_String'Output(Buffer'Access, Nick);
						ASU.Unbounded_String'Output(Buffer'Access, Text);
						
						ARVecinos:= HP4.Neighbors.Get_Keys(HP4.Vecinos);
						for i in 1..HP4.Neighbors.Map_Length(HP4.Vecinos) loop
							LLU.Send(ARVecinos(i), Buffer'Access);
							Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
							
						end loop;

						Debug.Put_Line("Adding to latest_messages " & ASU.To_String(IPMaq) & ":" & ACL.Argument(1) 												& " " & Seq_N_T'Image(Seq_N),Pantalla.Verde);
						Debug.Put("FLOOD WRITTER ", Pantalla.Amarillo);
						Debug.Put_Line(EP_Image(EP_H_Creat) & " " &Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd) 
								& " " & ACL.Argument(2) & " " & ASU.To_String(Text), Pantalla.Verde);
					end if;	
				end loop;
			end if;
	end if;
	
  LLU.Finalize;

exception
	when Usage_Error => ATI.Put_Line("Introduzca 2, 4 o 6 argumentos por favor"); LLU.Finalize;

end Chat_Peer;
