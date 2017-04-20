-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Command_Line;
with Lower_Layer_UDP;
with Ordered_Maps_G;
with Chat_Messages;
with Handlers_P5;
with Ada.Unchecked_Deallocation;
with Timed_Handlers;
with Debug;
with Pantalla;
with Ada.Calendar;


procedure Chat_Peer_2 is

	package ASU renames Ada.Strings.Unbounded;
	package ATI renames Ada.Text_IO;
	package LLU renames Lower_Layer_UDP;
	package ACL renames Ada.Command_Line;
	package CM renames Chat_Messages;
	package HP5 renames Handlers_P5;
	package TH renames Timed_Handlers;


	use type ASU.Unbounded_String;
	use type LLU.End_Point_Type;
	use type CM.Message_Type;
	use type HP5.Seq_N_T;
	use type Ada.Calendar.Time;

	procedure Free is new Ada.Unchecked_Deallocation (LLU.Buffer_Type, CM.Buffer_A_T);

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


	procedure ActualizarArboles(EP_H_Creat:LLU.End_Point_Type;EP_H_Rsnd: LLU.End_Point_Type; Seq_N:HP5.Seq_N_T ) is

		Mess_IT: HP5.Mess_Id_T;	
		Dest_T: HP5.Destinations_T;
		VT: HP5.Value_T;
		Hora_Ret: Ada.Calendar.Time;
		ARVecinos:HP5.Neighbors.Keys_Array_Type;
	--	Plazo_Retransmision: Duration:=2* Duration(Integer'Value(ACL.Argument(4))) / 1000;
	begin

	--	HP5.Sender_Dests.Print_Map(HP5.Vec_Asent);
	--	HP5.Sender_Buffering.Print_Map(HP5.Mens_Pend);

		--actualizamos buffers
		VT.EP_H_Creat:=EP_H_Creat;
		VT.Seq_N:= Seq_N;
		Mess_IT.EP:= EP_H_Creat;
		Mess_IT.Seq:= Seq_N;
		VT.P_Buffer:= CM.P_Buffer_Main;

		ARVecinos:=HP5.Neighbors.Get_Keys(HP5.Vecinos); 
		--bucle para añadir sender dests
		for i in 1..ARVecinos'Length loop
			if ARVecinos(i)/=null then
				if ARVecinos(i)/= EP_H_Rsnd then 
					Dest_T(i).EP:=ARVecinos(i);
					Dest_T(i).Retries:=0;
				--	ATI.Put_Line("Añadimos a Sender_Dests " &EP_Image(Dest_T(i).EP));
				end if;
			end if;
		end loop;
		
	--	HP5.Sender_Dests.Print_Map(HP5.Vec_Asent);
	--	HP5.Sender_Buffering.Print_Map(HP5.Mens_Pend);

		Hora_Ret:= Ada.Calendar.Clock + HP5.Plazo_Retransmision;
		 
		HP5.Sender_Buffering.Put(HP5.Mens_Pend,Hora_Ret, VT);
	
		HP5.Sender_Dests.Put(HP5.Vec_Asent, Mess_IT,Dest_T);
		
		Timed_Handlers.Set_Timed_Handler(Hora_Ret,HP5.Reenviar'Access);

	end ActualizarArboles;


	Nick: ASU.Unbounded_String;
	Neighbor_Host: ASU.Unbounded_String;
	Neighbor_Host2: ASU.Unbounded_String;
	Port: Integer;
	Neighbor_Port: Integer;
	Neighbor_Port2: Integer;
	Min_Delay:Integer;
	Max_Delay:Integer;
	Fault_Pct:Integer;
	Usage_Error: Exception;
	Porc_Fuera_Rango: Exception;
	Error_De_Retardo: Exception;
	Plazo: Duration;
	Maquina:ASU.Unbounded_String;
	IPMaq:ASU.Unbounded_String;
	IP: ASU.Unbounded_String;
	Peer_EP: LLU.End_Point_Type;
	IP2: ASU.Unbounded_String;
	Peer_EP2: LLU.End_Point_Type;
	EP_R: LLU.End_Point_Type;
	EP_H: LLU.End_Point_Type;
	Expired: Boolean:= False;
	Confirm_Sent: Boolean;
	Mess: CM.Message_Type;
 	EP_H_Creat: LLU.End_Point_Type;
	EP_H_Rsnd:LLU.End_Point_Type;
	EP_R_Creat:LLU.End_Point_Type;
	Text: ASU.Unbounded_String;
	ARVecinos: HP5.Neighbors.Keys_Array_Type;	
	i: Integer:=1;
	Seq_N: HP5.Seq_N_T:=0;
	Success:Boolean:=False;


begin

	if ACL.Argument_Count = 5 then
		Port:= Integer'Value(ACL.Argument(1));
		Nick:= ASU.To_Unbounded_String(ACL.Argument(2));
		Min_Delay:=Integer'Value(ACL.Argument(3));
		Max_Delay:=Integer'Value(ACL.Argument(4));
		Fault_Pct:=Integer'Value(ACL.Argument(5));
	elsif ACL.Argument_Count = 7 then
		Port:= Integer'Value(ACL.Argument(1));
		Nick:= ASU.To_Unbounded_String(ACL.Argument(2));
		Min_Delay:=Integer'Value(ACL.Argument(3));
		Max_Delay:=Integer'Value(ACL.Argument(4));
		Fault_Pct:=Integer'Value(ACL.Argument(5));
		Neighbor_Host:= ASU.To_Unbounded_String(ACL.Argument(6));
		Neighbor_Port:= Integer'Value(ACL.Argument(7));

	elsif ACL.Argument_Count = 9 then
		Port:= Integer'Value(ACL.Argument(1));
		Nick:= ASU.To_Unbounded_String(ACL.Argument(2));
		Min_Delay:=Integer'Value(ACL.Argument(3));
		Max_Delay:=Integer'Value(ACL.Argument(4));
		Fault_Pct:=Integer'Value(ACL.Argument(5));
		Neighbor_Host:= ASU.To_Unbounded_String(ACL.Argument(6));
		Neighbor_Port:= Integer'Value(ACL.Argument(7));
		Neighbor_Host2:= ASU.To_Unbounded_String(ACL.Argument(8));
		Neighbor_Port2:= Integer'Value(ACL.Argument(9));

	else
		raise Usage_Error;
	end if;


	if Fault_Pct < 0 then 
		raise Porc_Fuera_Rango;
	elsif Fault_Pct > 100 then
		raise Porc_Fuera_Rango;
	end if;

	if Max_Delay < Min_Delay then 
		raise Error_De_Retardo;
	end if;

	Maquina:=ASU.To_Unbounded_String(LLU.Get_Host_Name);
	IPMaq:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Maquina)));

	LLU.Set_Faults_Percent(Fault_Pct);
	LLU.Set_Random_Propagation_Delay(Min_Delay, Max_Delay);
--	HP5.Plazo_Retransmision:= 2* Duration(Max_Delay) / 1000;

	if ACL.Argument_Count = 5 then
		EP_H:=LLU.Build(ASU.To_String(IPMaq), Port);
		LLU.Bind_Any(EP_R);
		LLU.Bind(EP_H, HP5.Peer_Handler'Access);
		HP5.Plazo_Retransmision:= 2* Duration(Max_Delay) / 1000;
		Debug.Put_Line("NOT following admission protocol because we have no initial contacts ... ", Pantalla.Verde);
		ATI.Put_Line("Chat_Peer");
		ATI.Put_Line("=========");
		ATI.New_Line(1);
		ATI.Put_Line(ASCII.LF & "Logging into chat with nick: " & ACL.Argument(2));	
		ATI.Put_Line(".h for help");	
		ATI.New_Line(1);



	elsif ACL.Argument_Count = 7 then
		EP_H:=LLU.Build(ASU.To_String(IPMaq), Port);
		IP:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Neighbor_Host)));
		Peer_EP := LLU.Build(ASU.To_String(IP), Neighbor_Port);
		LLU.Bind_Any(EP_R);
		LLU.Bind(EP_H, HP5.Peer_Handler'Access);
		HP5.Plazo_Retransmision:= 2* Duration(Max_Delay) / 1000;
		
		-- PROTOCOLO DE ADMISIÓN --
		Debug.Put_Line("Adding to neighbors " & LLU.To_IP(ACL.Argument(6)) & ":" & ACL.Argument(7), Pantalla.Verde);
		ATI.New_Line(1);
		Debug.Put_Line("Admission protocol started ... ", Pantalla.Verde);

		Mess:= CM.Init;
		EP_H_Creat:= EP_H;
		EP_R_Creat:= EP_R;
		EP_H_Rsnd:= EP_H;
		Seq_N:=Seq_N + 1;
		CM.P_Buffer_Main:= new LLU.Buffer_Type(1024);
		CM.Message_Type'Output(CM.P_Buffer_Main, Mess);
		LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Creat);
		HP5.Seq_N_T'Output(CM.P_Buffer_Main, Seq_N);
		LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Rsnd);
		LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_R_Creat);
		ASU.Unbounded_String'Output(CM.P_Buffer_Main, Nick);

		ARVecinos:=HP5.Neighbors.Get_Keys(HP5.Vecinos);
		HP5.Neighbors.Put(HP5.Vecinos, Peer_EP, Ada.Calendar.Clock, Success ); 
		HP5.Latest_Msgs.Put(HP5.Mensajes, EP_H_Creat, Seq_N, Success );
	--	HP5.Neighbors.Print_Map(HP5.Vecinos); 

		Debug.Put("FLOOD Init ", Pantalla.Amarillo);
		Debug.Put_Line("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & HP5.Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 								EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick), 	Pantalla.Verde);

		--inundación
		ARVecinos:= HP5.Neighbors.Get_Keys(HP5.Vecinos);
		for i in 1..HP5.Neighbors.Map_Length(HP5.Vecinos) loop
			LLU.Send(ARVecinos(i), CM.P_Buffer_Main);
			Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 			
		end loop;

		Debug.Put_Line("     Adding to latest_messages " & EP_Image(EP_H_Creat) & HP5.Seq_N_T'Image(Seq_N),Pantalla.Verde);
		
		ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N);

		CM.P_Buffer_Main:= new LLU.Buffer_Type(1024);
		Plazo:= 0.5 + (6* Duration(Max_Delay)/1000);
		LLU.Receive(EP_R, CM.P_Buffer_Main, Plazo, Expired);

		if Expired = False then
			Mess:=CM.Message_Type'Input(CM.P_Buffer_Main);
			if Mess= CM.Reject then
				EP_H:=LLU.End_Point_Type'Input(CM.P_Buffer_Main);
				Nick:=ASU.Unbounded_String'Input(CM.P_Buffer_Main);
				Free(CM.P_Buffer_Main);
				Debug.Put_Line("Ya hay un usuario con su Nick: " & ASU.To_String(Nick) , Pantalla.Rojo);
				
			end if;

				Mess:= CM.Logout;
				EP_H_Creat:= EP_H;
				EP_R_Creat:= EP_R;
				EP_H_Rsnd:= EP_H;
				Seq_N:=Seq_N+1;
				Confirm_Sent:=False;
				CM.P_Buffer_Main:= new LLU.Buffer_Type(1024);
				CM.Message_Type'Output(CM.P_Buffer_Main, Mess);
				LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Creat);
				HP5.Seq_N_T'Output(CM.P_Buffer_Main, Seq_N);
				LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Rsnd);
				ASU.Unbounded_String'Output(CM.P_Buffer_Main, Nick);
				Boolean'Output(CM.P_Buffer_Main, Confirm_Sent);
				HP5.Latest_Msgs.Put(HP5.Mensajes, EP_H_Creat, Seq_N, Success );

				Debug.Put("FLOOD LOGOUT " , Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat)&" "& HP5.Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd), Pantalla.Verde);

				--inundación
				ARVecinos:= HP5.Neighbors.Get_Keys(HP5.Vecinos);
				for i in 1..HP5.Neighbors.Map_Length(HP5.Vecinos) loop
					LLU.Send(ARVecinos(i), CM.P_Buffer_Main);
					Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 			
				end loop;
				
				Debug.Put_Line("     Adding to latest_messages "& EP_Image(EP_H_Creat) & 											HP5.Seq_N_T'Image(Seq_N),Pantalla.Verde);

				ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N);
	
				delay(HP5.MAX*HP5.Plazo_Retransmision);

				Debug.Put_Line(ASU.To_String(Nick) & ", has intentado entrar con un Nick que ya existe",Pantalla.Rojo);

				LLU.Finalize;
--Debug.Put_Line("LLU",Pantalla.Rojo);
				TH.Finalize;
--Debug.Put_Line("TH",Pantalla.Rojo);

		elsif Expired= True then
	
				Free(CM.P_Buffer_Main);

				Mess:= CM.Confirm;
				EP_H_Creat:= EP_H;
				EP_R_Creat:= EP_R;
				EP_H_Rsnd:= EP_H;
				Seq_N:=Seq_N+1;
				CM.P_Buffer_Main:= new LLU.Buffer_Type(1024);
				CM.Message_Type'Output(CM.P_Buffer_Main, Mess);
				LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Creat);
				HP5.Seq_N_T'Output(CM.P_Buffer_Main, Seq_N);
				LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Rsnd);
				ASU.Unbounded_String'Output(CM.P_Buffer_Main, Nick);
				HP5.Latest_Msgs.Put(HP5.Mensajes, EP_H_Creat, Seq_N, Success );

				Debug.Put("FLOOD CONFIRM ", Pantalla.Amarillo);
				Debug.Put_Line("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & HP5.Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 								EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick), 	Pantalla.Verde);

				--inundación
				ARVecinos:= HP5.Neighbors.Get_Keys(HP5.Vecinos);
				for i in 1..HP5.Neighbors.Map_Length(HP5.Vecinos) loop
					LLU.Send(ARVecinos(i), CM.P_Buffer_Main);
					Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 			
				end loop;
			
				Debug.Put_Line("     Adding to latest_messages " & EP_Image(EP_H_Creat) & 
										HP5.Seq_N_T'Image(Seq_N),Pantalla.Verde);

				ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N);
		
				ATI.New_Line(1);
				Debug.Put_Line("Admission protocol finished. ", Pantalla.Verde);
				ATI.New_Line(1);
				ATI.Put_Line("Chat_Peer");
				ATI.Put_Line("=========");
				ATI.New_Line(1);
				ATI.Put_Line(ASCII.LF & "Logging into chat with nick: " & ACL.Argument(2));	
				ATI.Put_Line(".h for help");
				ATI.New_Line(1);

			end if;


	elsif ACL.Argument_Count = 9 then
		EP_H:=LLU.Build(ASU.To_String(IPMaq), Port);
		IP:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Neighbor_Host)));
		Peer_EP := LLU.Build(ASU.To_String(IP), Neighbor_Port);
		IP2:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Neighbor_Host2)));
		Peer_EP2 := LLU.Build(ASU.To_String(IP), Neighbor_Port2);
		LLU.Bind_Any(EP_R);
		LLU.Bind(EP_H, HP5.Peer_Handler'Access);
		HP5.Plazo_Retransmision:= 2* Duration(Max_Delay) / 1000;

		Debug.Put_Line("Adding to neighbors " & LLU.To_IP(ACL.Argument(6)) & ":" & ACL.Argument(7), Pantalla.Verde);
		Debug.Put_Line("Adding to neighbors " & LLU.To_IP(ACL.Argument(8)) & ":" & ACL.Argument(9), Pantalla.Verde);
		ATI.New_Line(1);		
		Debug.Put_Line("Admission protocol started ... ", Pantalla.Verde);

		Mess:= CM.Init;
		EP_H_Creat:= EP_H;
		EP_R_Creat:= EP_R;
		EP_H_Rsnd:= EP_H;
		Seq_N:= Seq_N+1;
		CM.P_Buffer_Main:= new LLU.Buffer_Type(1024);
		CM.Message_Type'Output(CM.P_Buffer_Main, Mess);
		LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Creat);
		HP5.Seq_N_T'Output(CM.P_Buffer_Main, Seq_N);
		LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Rsnd);
		LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_R_Creat);
		ASU.Unbounded_String'Output(CM.P_Buffer_Main, Nick);

		ARVecinos:=HP5.Neighbors.Get_Keys(HP5.Vecinos);
		HP5.Neighbors.Put(HP5.Vecinos, Peer_EP, Ada.Calendar.Clock, Success );
		HP5.Neighbors.Put(HP5.Vecinos, Peer_EP2, Ada.Calendar.Clock, Success ); 
		HP5.Latest_Msgs.Put(HP5.Mensajes, EP_H_Creat, Seq_N, Success );

		Debug.Put("FLOOD INIT " , Pantalla.Amarillo);
		Debug.Put_Line("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & HP5.Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 								EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick), 	Pantalla.Verde);
		--inundación
		ARVecinos:= HP5.Neighbors.Get_Keys(HP5.Vecinos);
		for i in 1..HP5.Neighbors.Map_Length(HP5.Vecinos) loop
			LLU.Send(ARVecinos(i), CM.P_Buffer_Main);
			Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 			
		end loop;
		
 		Debug.Put_Line("     Adding to latest_messages " & EP_Image(EP_H_Creat) & HP5.Seq_N_T'Image(Seq_N),Pantalla.Verde);

		ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N);
		
		CM.P_Buffer_Main:= new LLU.Buffer_Type(1024);
		Plazo:= 0.5 + (6* Duration(Max_Delay)/1000);
		LLU.Receive(EP_R, CM.P_Buffer_Main, Plazo, Expired);

		if Expired = False then
			Mess:=CM.Message_Type'Input(CM.P_Buffer_Main);
			if Mess= CM.Reject then
				EP_H:=LLU.End_Point_Type'Input(CM.P_Buffer_Main);
				Nick:=ASU.Unbounded_String'Input(CM.P_Buffer_Main);
				Free(CM.P_Buffer_Main);
				Debug.Put_Line("Ya hay un usuario con su Nick: " & ASU.To_String(Nick) , Pantalla.Rojo);
				
			end if;

				Mess:= CM.Logout;
				EP_H_Creat:= EP_H;
				EP_R_Creat:= EP_R;
				EP_H_Rsnd:= EP_H;
				Seq_N:=Seq_N+1;
				Confirm_Sent:=False;
				CM.P_Buffer_Main:= new LLU.Buffer_Type(1024);
				CM.Message_Type'Output(CM.P_Buffer_Main, Mess);
				LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Creat);
				HP5.Seq_N_T'Output(CM.P_Buffer_Main, Seq_N);
				LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Rsnd);
				ASU.Unbounded_String'Output(CM.P_Buffer_Main, Nick);
				Boolean'Output(CM.P_Buffer_Main, Confirm_Sent);
				HP5.Latest_Msgs.Put(HP5.Mensajes, EP_H_Creat, Seq_N, Success );

				Debug.Put("FLOOD LOGOUT " , Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat)&" "& HP5.Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd), Pantalla.Verde);

				--inundación
				ARVecinos:= HP5.Neighbors.Get_Keys(HP5.Vecinos);
				for i in 1..HP5.Neighbors.Map_Length(HP5.Vecinos) loop
					LLU.Send(ARVecinos(i), CM.P_Buffer_Main);
					Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 			
				end loop;
				Debug.Put_Line("     Adding to latest_messages " & EP_Image(EP_H_Creat) & 											HP5.Seq_N_T'Image(Seq_N),Pantalla.Verde);
				
				ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N);
	
				delay(HP5.MAX*HP5.Plazo_Retransmision);

				Debug.Put_Line(ASU.To_String(Nick) & ", has intentado entrar con un Nick que ya existe",Pantalla.Rojo);

				LLU.Finalize;
				TH.Finalize;
	

		elsif Expired= True then
	
				Free(CM.P_Buffer_Main);

				Mess:= CM.Confirm;
				EP_H_Creat:= EP_H;
				EP_R_Creat:= EP_R;
				EP_H_Rsnd:= EP_H;
				Seq_N:=Seq_N+1;
				CM.P_Buffer_Main:= new LLU.Buffer_Type(1024);
				CM.Message_Type'Output(CM.P_Buffer_Main, Mess);
				LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Creat);
				HP5.Seq_N_T'Output(CM.P_Buffer_Main, Seq_N);
				LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Rsnd);
				ASU.Unbounded_String'Output(CM.P_Buffer_Main, Nick);

				Debug.Put("FLOOD CONFIRM ", Pantalla.Amarillo);
				Debug.Put_Line("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & HP5.Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 								EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick), 	Pantalla.Verde);

				--inundación
				ARVecinos:= HP5.Neighbors.Get_Keys(HP5.Vecinos);
				for i in 1..HP5.Neighbors.Map_Length(HP5.Vecinos) loop
					LLU.Send(ARVecinos(i), CM.P_Buffer_Main);
					Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 			
				end loop;

				Debug.Put_Line("     Adding to latest_messages " & EP_Image(EP_H_Creat) &
											HP5.Seq_N_T'Image(Seq_N),Pantalla.Verde);

				ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N);

				ATI.New_Line(1);
				Debug.Put_Line("Admission protocol finished. ", Pantalla.Verde);
				ATI.New_Line(1);
				ATI.Put_Line("Chat_Peer");
				ATI.Put_Line("=========");
				ATI.New_Line(1);
				ATI.Put_Line(ASCII.LF & "Logging into chat with nick: " & ACL.Argument(2));	
				ATI.Put_Line(".h for help");
				ATI.New_Line(1);

			end if;
	end if;

--	HP5.Neighbors.Print_Map(HP5.Vecinos);

	while Text /= ".quit" loop
		Mess:=CM.Writer;	
		Text:= ASU.To_Unbounded_String(ATI.Get_Line);

		if Text = ".quit" then 
			Mess:= CM.Logout;
			EP_H_Creat:= EP_H;
			EP_R_Creat:= EP_R;
			EP_H_Rsnd:= EP_H;
			Seq_N:=Seq_N+1;
			Confirm_Sent:=True;
			CM.P_Buffer_Main:= new LLU.Buffer_Type(1024);
			CM.Message_Type'Output(CM.P_Buffer_Main, Mess);
			LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Creat);
			HP5.Seq_N_T'Output(CM.P_Buffer_Main, Seq_N);
			LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Rsnd);
			ASU.Unbounded_String'Output(CM.P_Buffer_Main, Nick);
			Boolean'Output(CM.P_Buffer_Main, Confirm_Sent);

			HP5.Latest_Msgs.Put(HP5.Mensajes, EP_H_Creat, Seq_N, Success );
						
			Debug.Put("FLOOD LOGOUT " , Pantalla.Amarillo);
			Debug.Put_Line(EP_Image(EP_H_Creat) & " " &HP5.Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd), Pantalla.Verde);
				
				
			--inundación
			ARVecinos:= HP5.Neighbors.Get_Keys(HP5.Vecinos);
		--	HP5.Neighbors.Print_Map(HP5.Vecinos);
			for i in 1..HP5.Neighbors.Map_Length(HP5.Vecinos) loop
				if ARVecinos(i) /= EP_H_Rsnd then
					if ARVecinos(i)/=null then
						LLU.Send(ARVecinos(i), CM.P_Buffer_Main);
						Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 	
					end if;	
				end if;	
			end loop;

			Debug.Put_Line("     Adding to latest_messages " & EP_Image(EP_H_Creat) & HP5.Seq_N_T'Image(Seq_N),Pantalla.Verde);

			ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N);
	
			delay(HP5.MAX*HP5.Plazo_Retransmision);

			ATI.Put_Line(ASU.To_String(Nick) & " ha abandonado el chat");

			LLU.Finalize;
			TH.Finalize;

		elsif Text = ".h" then
			Debug.Put_Line("Comandos que puede usar " , Pantalla.Rojo);
			Debug.Put_Line(".sb     Muestra los elementos almacenados en Sender_Buffering " , Pantalla.Rojo);
			Debug.Put_Line(".sd     Muestra los elementos almacenados en Sender_Dests " , Pantalla.Rojo);
			Debug.Put_Line(".quit   Finaliza el chat " , Pantalla.Rojo);

			
		elsif Text = ".sb" then

			Debug.Put_Line("Elementos almacenados en Sender_Buffering" , Pantalla.Rojo);
			HP5.Sender_Buffering.Print_Map(HP5.Mens_Pend);

		elsif Text = ".sd" then
			
			Debug.Put_Line("Elementos almacenados en Sender_Dests" , Pantalla.Rojo);
			HP5.Sender_Dests.Print_Map(HP5.Vec_Asent);			

		else
			EP_H_Creat:= EP_H;
			EP_R_Creat:= EP_R;
			EP_H_Rsnd:= EP_H;
			Seq_N:=Seq_N+1;
			CM.P_Buffer_Main:= new LLU.Buffer_Type(1024);
			CM.Message_Type'Output(CM.P_Buffer_Main, Mess);
			LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Creat);
			HP5.Seq_N_T'Output(CM.P_Buffer_Main, Seq_N);
			LLU.End_Point_Type'Output(CM.P_Buffer_Main, EP_H_Rsnd);
			ASU.Unbounded_String'Output(CM.P_Buffer_Main, Nick);
			ASU.Unbounded_String'Output(CM.P_Buffer_Main, Text);
			HP5.Latest_Msgs.Put(HP5.Mensajes, EP_H_Creat, Seq_N, Success );
				
			--inundación

			Debug.Put("FLOOD WRITTER ", Pantalla.Amarillo);
			Debug.Put_Line(EP_Image(EP_H_Creat) & " " & HP5.Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd) &" "& ACL.Argument(2) 
											& " " & ASU.To_String(Text), Pantalla.Verde);
		--	HP5.Neighbors.Print_Map(HP5.Vecinos);
			ARVecinos:= HP5.Neighbors.Get_Keys(HP5.Vecinos);
			for i in 1..HP5.Neighbors.Map_Length(HP5.Vecinos) loop
				if ARVecinos(i) /= EP_H_Rsnd then
					if ARVecinos(i)/=null then
						LLU.Send(ARVecinos(i), CM.P_Buffer_Main);
						Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 	
					end if;
				end if;		
			end loop;

			Debug.Put_Line("     Adding to latest_messages " & EP_Image(EP_H_Creat) & HP5.Seq_N_T'Image(Seq_N),Pantalla.Verde);

			ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N);	
			
		end if;	

	end loop;

exception
	when Usage_Error => ATI.Put_Line("Introduzca 5, 7 o 9 argumentos por favor"); LLU.Finalize; TH.Finalize;
	when Porc_Fuera_Rango => ATI.Put_Line("Introduzca un número entre 0 y 100"); LLU.Finalize; TH.Finalize;
	when Error_De_Retardo => ATI.Put_Line("Max_Delay tiene que ser mayor o igual a Min_Delay"); LLU.Finalize; TH.Finalize;
	
end Chat_Peer_2;
