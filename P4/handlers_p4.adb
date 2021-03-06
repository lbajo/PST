--LORENA BAJO REBOLLO

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
with Ada.Exceptions;

package body Handlers_P4 is

	
   function Image_3 (T: Ada.Calendar.Time) return String is
  	 begin
     		return Gnat.Calendar.Time_IO.Image(T, "%T.%i");
  	 end Image_3;

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


   procedure Peer_Handler (From    : in     LLU.End_Point_Type;
                           To      : in     LLU.End_Point_Type;
                           P_Buffer: access LLU.Buffer_Type) is

	use type ASU.Unbounded_String;
	use type LLU.End_Point_Type;
	use type CM.Message_Type;
	use type Seq_N_T;


   begin

	Maquina:=ASU.To_Unbounded_String(LLU.Get_Host_Name);
	IPMaq:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Maquina)));
	EP_H:=LLU.Build(ASU.To_String(IPMaq), Port);

	Mess:=CM.Message_Type'Input(P_Buffer);
	if Mess= CM.Init then
		EP_H_Creat:= LLU.End_Point_Type'Input(P_Buffer);
		Seq_N:=Seq_N_T'Input(P_Buffer);
		EP_H_Rsnd:=LLU.End_Point_Type'Input(P_Buffer);
		EP_R_Creat:=LLU.End_Point_Type'Input(P_Buffer);
		Nick:=ASU.Unbounded_String'Input(P_Buffer);

		
		Latest_Msgs.Get(Mensajes,EP_H_Creat, NumSeq, Success);

	
		if Success= False then
		
			Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success );

			if ACL.Argument(2) = Nick then 
				Mess:= CM.Reject;
				CM.Message_Type'Output(P_Buffer, Mess);
				LLU.End_Point_Type'Output(P_Buffer, EP_H);
				ASU.Unbounded_String'Output(P_Buffer, Nick);
				LLU.Send(EP_R_Creat, P_Buffer);
				ATI.Put_Line("Han intentado introducirse con su Nick, Reject enviado");
			else

				Mess:= CM.Init;
				CM.Message_Type'Output(P_Buffer, Mess);
				LLU.End_Point_Type'Output(P_Buffer, EP_H_Creat);
				Seq_N_T'Output(P_Buffer, Seq_N);
				LLU.End_Point_Type'Output(P_Buffer, EP_H_Rsnd);
				LLU.End_Point_Type'Output(P_Buffer, EP_R_Creat);
				ASU.Unbounded_String'Output(P_Buffer, Nick);
				Debug.Put("RCV INIT ", Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) & EP_Image(EP_H_Rsnd) & " ... " 
											& ASU.To_String(Nick), 	Pantalla.Verde);

				if EP_H_Creat = EP_H_Rsnd then
					Neighbors.Put(Vecinos, EP_H_Creat, Ada.Calendar.Clock, Success );
					Debug.Put_Line("Adding to neighbors " & EP_Image(EP_H_Creat), Pantalla.Verde );
				elsif EP_H_Creat /= EP_H_Rsnd then
					ATI.Put_Line("Vecino nuevo no veciino");
				end if;
				Debug.Put_Line("Adding to latest_mesages " & EP_Image(EP_H_Creat) & Seq_N_T'Image(Seq_N), Pantalla.Verde );
				Debug.Put("     FLOOD Init ", Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N)& ASU.To_String(IPMaq) & " ... " & 													ASU.To_String(Nick), Pantalla.Verde);

				ARVecinos:= Neighbors.Get_Keys(Vecinos);
				for i in 1..Neighbors.Map_Length(Vecinos) loop
					if ARVecinos(i) /= EP_H_Rsnd then
						if ARVecinos(i)/=null then
							LLU.Send(ARVecinos(i), P_Buffer);
							Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
						end if;
					end if;
				end loop;
			end if;

			else
	
			if Seq_N > NumSeq then
	
			Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success );

			if ACL.Argument(2) = Nick then 
				Mess:= CM.Reject;
		
				CM.Message_Type'Output(P_Buffer, Mess);
				LLU.End_Point_Type'Output(P_Buffer, EP_H);
				ASU.Unbounded_String'Output(P_Buffer, Nick);
				LLU.Send(EP_R_Creat, P_Buffer);
				ATI.Put_Line("Nick repetido, expulsado");
			else
				Mess:= CM.Init;
				CM.Message_Type'Output(P_Buffer, Mess);
				LLU.End_Point_Type'Output(P_Buffer, EP_H_Creat);
				Seq_N_T'Output(P_Buffer, Seq_N);
				LLU.End_Point_Type'Output(P_Buffer, EP_H_Rsnd);
				LLU.End_Point_Type'Output(P_Buffer, EP_R_Creat);
				ASU.Unbounded_String'Output(P_Buffer, Nick);
				Debug.Put("RCV INIT ", Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) & EP_Image(EP_H_Rsnd) & " ... " 
											& ASU.To_String(Nick), 	Pantalla.Verde);


				if EP_H_Creat = EP_H_Rsnd then
					Neighbors.Put(Vecinos, EP_H_Creat, Ada.Calendar.Clock, Success );
					Debug.Put_Line("Adding to neighbors " & EP_Image(EP_H_Creat), Pantalla.Verde );
				elsif EP_H_Creat /= EP_H_Rsnd then
					ATI.Put_Line("Vecino nuevo no veciino");
				end if;
				Debug.Put_Line("Adding to latest_mesages " & EP_Image(EP_H_Creat) & Seq_N_T'Image(Seq_N), Pantalla.Verde );
				Debug.Put("     FLOOD Init ", Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N)& ASU.To_String(IPMaq) & " ... " & 													ASU.To_String(Nick), Pantalla.Verde);

				ARVecinos:= Neighbors.Get_Keys(Vecinos);
				for i in 1..Neighbors.Map_Length(Vecinos) loop
					if ARVecinos(i) /= EP_H_Rsnd then
						if ARVecinos(i)/=null then
							LLU.Send(ARVecinos(i), P_Buffer);
							Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
						end if;
					end if;
				end loop;
			end if;
			
			end if; 

		end if;

	elsif Mess= CM.Confirm then
		EP_H_Creat:= LLU.End_Point_Type'Input(P_Buffer);
		Seq_N:=Seq_N_T'Input(P_Buffer);
		EP_H_Rsnd:=LLU.End_Point_Type'Input(P_Buffer);
		Nick:=ASU.Unbounded_String'Input(P_Buffer);

		Latest_Msgs.Get(Mensajes,EP_H_Creat, NumSeq, Success);
		if Success = False then
			Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success );
			Mess:= CM.Confirm;
			CM.Message_Type'Output(P_Buffer, Mess);
			LLU.End_Point_Type'Output(P_Buffer, EP_H_Creat);
			Seq_N_T'Output(P_Buffer, Seq_N);
			LLU.End_Point_Type'Output(P_Buffer, EP_H_Rsnd);
			ASU.Unbounded_String'Output(P_Buffer, Nick);
			Debug.Put("RCV CONFIRM ", Pantalla.Amarillo);
			Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &  EP_Image(EP_H_Rsnd) & " ... " 
											& ASU.To_String(Nick), 	Pantalla.Verde);
			ATI.Put_Line(ASCII.LF & ASU.To_String(Nick) & " joins the chat ");		
			
			Debug.Put_Line("     Adding to latest_mesages " & EP_Image(EP_H_Creat) & Seq_N_T'Image(Seq_N), Pantalla.Verde );
			Debug.Put("     FLOOD Confirm ", Pantalla.Amarillo);
			Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N)& ASU.To_String(IPMaq) & " ... " 
										& ASU.To_String(Nick), Pantalla.Verde);
			ARVecinos:= Neighbors.Get_Keys(Vecinos);
			for i in 1..Neighbors.Map_Length(Vecinos) loop
				if ARVecinos(i) /= EP_H_Rsnd then
					LLU.Send(ARVecinos(i), P_Buffer);
					Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
				end if;
			end loop;
		else
			if NumSeq< Seq_N then
				Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success );
				Mess:= CM.Confirm;
				CM.Message_Type'Output(P_Buffer, Mess);
				LLU.End_Point_Type'Output(P_Buffer, EP_H_Creat);
				Seq_N_T'Output(P_Buffer, Seq_N);
				LLU.End_Point_Type'Output(P_Buffer, EP_H_Rsnd);
				ASU.Unbounded_String'Output(P_Buffer, Nick);
				Debug.Put("RCV CONFIRM ", Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &  EP_Image(EP_H_Rsnd) & " ... " 
											& ASU.To_String(Nick), 	Pantalla.Verde);
				ATI.Put_Line(ASCII.LF & ASU.To_String(Nick) & " joins the chat ");		
			
				Debug.Put_Line("     Adding to latest_mesages " & EP_Image(EP_H_Creat) & Seq_N_T'Image(Seq_N), 														Pantalla.Verde );
				Debug.Put("     FLOOD Confirm ", Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N)& ASU.To_String(IPMaq) & " ... " 
										& ASU.To_String(Nick), Pantalla.Verde);
				ARVecinos:= Neighbors.Get_Keys(Vecinos);
				for i in 1..Neighbors.Map_Length(Vecinos) loop
					if ARVecinos(i) /= EP_H_Rsnd then
						LLU.Send(ARVecinos(i), P_Buffer);
						Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
					end if;
				end loop;
			end if;

		end if;

	elsif Mess= CM.Writer then
		EP_H_Creat:= LLU.End_Point_Type'Input(P_Buffer);
		Seq_N:=Seq_N_T'Input(P_Buffer);
		EP_H_Rsnd:=LLU.End_Point_Type'Input(P_Buffer);
		Nick:=ASU.Unbounded_String'Input(P_Buffer);
		Text:= ASU.Unbounded_String'Input(P_Buffer);
	
		Latest_Msgs.Get(Mensajes,EP_H_Creat, NumSeq, Success);
		if Success= False then
			Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success );
			Mess:= CM.Writer;
			CM.Message_Type'Output(P_Buffer, Mess);
			LLU.End_Point_Type'Output(P_Buffer, EP_H_Creat);
			Seq_N_T'Output(P_Buffer, Seq_N);
			LLU.End_Point_Type'Output(P_Buffer, EP_H_Rsnd);
			ASU.Unbounded_String'Output(P_Buffer, Nick);
			ASU.Unbounded_String'Output(P_Buffer, Text);
			Debug.Put("RCV WRITTER ", Pantalla.Amarillo);
			Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &  EP_Image(EP_H_Rsnd)&" " & ASU.To_String(Nick)   												&" " & ASU.To_String(Text), Pantalla.Verde);
			ATI.Put_Line(ASCII.LF & ASU.To_String(Nick) & ": " & ASU.To_String(Text));

			Debug.Put_Line("Adding to latest_messages " & EP_Image(EP_H_Creat) & Seq_N_T'Image(Seq_N),Pantalla.Verde);
			Debug.Put("     FLOOD WRITTER ", Pantalla.Amarillo);
			Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd) &" " & 
									ASU.To_String(Nick)&" " & ASU.To_String(Text), Pantalla.Verde);
			ARVecinos:= Neighbors.Get_Keys(Vecinos);
				for i in 1..Neighbors.Map_Length(Vecinos) loop
					if ARVecinos(i) /= EP_H_Rsnd then
						LLU.Send(ARVecinos(i), P_Buffer);
						Debug.Put_Line("     Send to: " &EP_Image(ARVecinos(i)) , Pantalla.Verde); 

					end if;
				end loop;
		else
			if NumSeq< Seq_N then
				Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success );
				Mess:= CM.Writer;
				CM.Message_Type'Output(P_Buffer, Mess);
				LLU.End_Point_Type'Output(P_Buffer, EP_H_Creat);
				Seq_N_T'Output(P_Buffer, Seq_N);
				LLU.End_Point_Type'Output(P_Buffer, EP_H_Rsnd);
				ASU.Unbounded_String'Output(P_Buffer, Nick);
				ASU.Unbounded_String'Output(P_Buffer, Text);

				Debug.Put("RCV WRITTER ", Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &  EP_Image(EP_H_Rsnd)&" " & 									ASU.To_String(Nick)&" " & ASU.To_String(Text), Pantalla.Verde);

				ATI.Put_Line(ASCII.LF & ASU.To_String(Nick) & ": " & ASU.To_String(Text));

				Debug.Put_Line("Adding to latest_messages " & EP_Image(EP_H_Creat) & Seq_N_T'Image(Seq_N),Pantalla.Verde);
				Debug.Put("     FLOOD WRITTER ", Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N)& EP_Image(EP_H_Rsnd) &" " & 
									ASU.To_String(Nick)&" " & ASU.To_String(Text), Pantalla.Verde);
				ARVecinos:= Neighbors.Get_Keys(Vecinos);
				for i in 1..Neighbors.Map_Length(Vecinos) loop
					if ARVecinos(i) /= EP_H_Rsnd then
						LLU.Send(ARVecinos(i), P_Buffer);
						Debug.Put_Line("     Send to: " &EP_Image(ARVecinos(i)) , Pantalla.Verde); 

					end if;
				end loop;
			end if;
		end if;


	elsif Mess= CM.Logout then 
		EP_H_Creat:= LLU.End_Point_Type'Input(P_Buffer);
		Seq_N:=Seq_N_T'Input(P_Buffer);
		EP_H_Rsnd:=LLU.End_Point_Type'Input(P_Buffer);
		Nick:=ASU.Unbounded_String'Input(P_Buffer);
		Confirm_Sent:= Boolean'Input(P_Buffer);

		Latest_Msgs.Get(Mensajes,EP_H_Creat, NumSeq, Success);
		if Success = False then
			--IGNORAMOS EL MENSAJE
			ATI.Put("");	
		else
			if NumSeq< Seq_N then

				Latest_Msgs.Put(Mensajes, EP_H_Creat,Seq_N, Success );
				Mess:= CM.Logout;
				CM.Message_Type'Output(P_Buffer, Mess);
				LLU.End_Point_Type'Output(P_Buffer, EP_H_Creat);
				Seq_N_T'Output(P_Buffer, Seq_N);
				LLU.End_Point_Type'Output(P_Buffer, EP_H_Rsnd);
				ASU.Unbounded_String'Output(P_Buffer, Nick);
				Boolean'Output(P_Buffer, Confirm_Sent);
				Debug.Put("RCV LOGOUT ", Pantalla.Amarillo);
				Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &  EP_Image(EP_H_Rsnd)&" " & 									ASU.To_String(Nick), Pantalla.Verde);

				ARVecinos:= Neighbors.Get_Keys(Vecinos);
				for i in 1..Neighbors.Map_Length(Vecinos) loop
					if ARVecinos(i) /= EP_H_Rsnd then
						LLU.Send(ARVecinos(i), P_Buffer);
						Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 

					end if;
				end loop;
	
			if EP_H_Creat= EP_H_Rsnd then
				Neighbors.Delete(Vecinos, EP_H_Creat, Success );
			end if;
			Latest_Msgs.Delete(Mensajes, EP_H_Creat, Success );
			ATI.Put_Line(ASCII.LF & ASU.To_String(Nick) & " leaves the chat");
			end if;
	
		end if;
		
	end if;

   end Peer_Handler;


end Handlers_P4;
