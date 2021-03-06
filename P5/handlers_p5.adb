--LORENA BAJO REBOLLO

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
with Ada.Exceptions;

package body Handlers_P5 is

	-- Imagen del ada calendar

	 function Image_3 (T: Ada.Calendar.Time) return String is
  	 begin
     		return Gnat.Calendar.Time_IO.Image(T, "%T.%i");

  	 end Image_3;

	--Comparar ada calendar

	function Igual_AC (T1: Ada.Calendar.Time; T2:Ada.Calendar.Time) return boolean is
		Cond: Boolean:= False;
	begin
		if Image_3(T1)=Image_3(T2) then
			Cond:= True;
		else
			Cond:= False;
		end if;
			return Cond;
	end Igual_AC;

	function Menor_AC (T1: Ada.Calendar.Time; T2:Ada.Calendar.Time) return boolean is
		Cond: Boolean:= False;
	begin
		if Image_3(T1)<Image_3(T2) then
			Cond:= True;
		else
			Cond:= False;
		end if;
			return Cond;
	end Menor_AC;

	-- Devuelve la imagen de los EP

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

	-- Función igual 

	function "=" (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean is 

		Cond: Boolean:=False;
	begin

		if LLU.Image(M1.EP) = LLU.Image(M2.EP) then
			if  M1.Seq = M2.Seq then
				Cond := True;	
			end if;
		else 
			Cond:= False;
		end if;
		
		return Cond;
	end;

	-- Función menor

	function "<" (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean is 

		Cond: Boolean:=False;
	begin
		if LLU.Image(M1.EP) < LLU.Image(M2.EP) then 
			Cond:= True;	
	
		elsif  LLU.Image(M1.EP) = LLU.Image(M2.EP) and M1.Seq < M2.Seq then
			Cond:=True;
		else
			Cond:= False;
		end if;

		return Cond;
	end;

	function ">" (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean is 

		Cond: Boolean:=False;
	begin
		if LLU.Image(M1.EP) > LLU.Image(M2.EP) then 
			Cond:= True;	
	
		elsif  LLU.Image(M1.EP) = LLU.Image(M2.EP) and M1.Seq > M2.Seq then
			Cond:=True;
		else
			Cond:= False;
		end if;

		return Cond;
	end;

	-- Mess_Id_T devuelve String

	function RE_Image (M:Mess_Id_T) return String is

		Re_Key: ASU.Unbounded_String;
	begin

		Re_Key:= ASU.To_Unbounded_String(EP_Image(M.EP) & " " & Seq_N_T'Image(M.Seq));

		return ASU.To_String(Re_Key);
	end RE_Image;


	-- Destination_t devuelve String

	function AR_Image (D:Destinations_T) return String is

 	 	 Ar_Value: ASU.Unbounded_String;

	begin
  	 	Ar_Value := Ar_Value & "[ ";
	
		for i in 1..10 loop
     	  		if D(i).EP /= null then
        	 		Ar_Value:= Ar_Value & EP_Image(D(i).EP) & " -" &Natural'Image(D(i).Retries);
    			else
        			Ar_Value := Ar_Value & "null - 0 ";
	 		end if;
   		end loop;

  		 Ar_Value := Ar_Value & " ]";

  		return ASU.To_String(Ar_Value);

	end AR_Image;
	-- Value_T devuelve String
	
	function Value_Image (V:Value_T) return String is
	
		I_Value: ASU.Unbounded_String;
	begin

		I_Value:= ASU.To_Unbounded_String(EP_Image(V.EP_H_Creat) & " " & Seq_N_T'Image(V.Seq_N));

		return ASU.To_String(I_Value);

	end Value_Image;

	--Creación del mensaje Init

	procedure Init(EP_H_Creat:LLU.End_Point_Type; Seq_N: in  Seq_N_T; 
				EP_H_Rsnd: in LLU.End_Point_Type; EP_R_Creat:LLU.End_Point_Type;  Nick:ASU.Unbounded_String) is

		Mess: CM.Message_Type; 
	begin

		Mess:= CM.Init;
		CM.P_Buffer_Handler:= new LLU.Buffer_Type(1024);
		CM.Message_Type'Output(CM.P_Buffer_Handler, Mess);
		LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H_Creat);
		Seq_N_T'Output(CM.P_Buffer_Handler, Seq_N);
		LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H_Rsnd);
		LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_R_Creat);
		ASU.Unbounded_String'Output(CM.P_Buffer_Handler, Nick);

	end Init;

	--Creación del mensaje Confirm

	procedure Confirm( EP_H_Creat:LLU.End_Point_Type; Seq_N:Seq_N_T; EP_H_Rsnd: in LLU.End_Point_Type; 													Nick:ASU.Unbounded_String) is
		Mess: CM.Message_Type;
	begin
			Mess:= CM.Confirm;
			CM.P_Buffer_Handler:= new LLU.Buffer_Type(1024);
			CM.Message_Type'Output(CM.P_Buffer_Handler, Mess);
			LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H_Creat);
			Seq_N_T'Output(CM.P_Buffer_Handler, Seq_N);
			LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H_Rsnd);
			ASU.Unbounded_String'Output(CM.P_Buffer_Handler, Nick);
			

	end Confirm;

	--Creación del mensaje Writer
	
	procedure Writer (EP_H_Creat:LLU.End_Point_Type;Seq_N:Seq_N_T; EP_H_Rsnd: in out LLU.End_Point_Type; 										Nick:ASU.Unbounded_String; Text: ASU.Unbounded_String) is

		Mess: CM.Message_Type;
	begin

		Mess:= CM.Writer;
		CM.P_Buffer_Handler:= new LLU.Buffer_Type(1024);
		CM.Message_Type'Output(CM.P_Buffer_Handler, Mess);
		LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H_Creat);
		Seq_N_T'Output(CM.P_Buffer_Handler, Seq_N);
		LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H_Rsnd);
		ASU.Unbounded_String'Output(CM.P_Buffer_Handler, Nick);
		ASU.Unbounded_String'Output(CM.P_Buffer_Handler, Text);

	end Writer;

	--Creación del mensaje Logout

	procedure Logout(EP_H_Creat:LLU.End_Point_Type; Seq_N:Seq_N_T; EP_H_Rsnd: in out LLU.End_Point_Type; 										Nick:ASU.Unbounded_String; Confirm_Sent:Boolean) is

		Mess: CM.Message_Type;
	begin
		Mess:= CM.Logout;
		CM.P_Buffer_Handler:= new LLU.Buffer_Type(1024);
		CM.Message_Type'Output(CM.P_Buffer_Handler, Mess);
		LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H_Creat);
		Seq_N_T'Output(CM.P_Buffer_Handler, Seq_N);
		LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H_Rsnd);
		ASU.Unbounded_String'Output(CM.P_Buffer_Handler, Nick);
		Boolean'Output(CM.P_Buffer_Handler, Confirm_Sent);
		
	end Logout;

	-- Crea y envía los ACKs

	procedure Ack (EP_H_ACKer:in out LLU.End_Point_Type; EP_H_Creat:LLU.End_Point_Type; EP_H_Rsnd: LLU.End_Point_Type; Seq_N:Seq_N_T) is

		Mess: CM.Message_Type;
	begin
		Mess:= CM.Ack;
		EP_H_ACKer:=EP_H;
		CM.P_Buffer_Handler:= new LLU.Buffer_Type(1024);
		CM.Message_Type'Output(CM.P_Buffer_Handler, Mess);
		LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H_ACKer);
		LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H_Creat);
		Seq_N_T'Output(CM.P_Buffer_Handler, Seq_N);
		LLU.Send(EP_H_Rsnd, CM.P_Buffer_Handler);
		Free(CM.P_Buffer_Handler);

	end Ack;


	-- Actualizamos Sender_Dest y Sender_Buffering

	procedure ActualizarArboles(EP_H_Creat:LLU.End_Point_Type;EP_H_Rsnd: LLU.End_Point_Type; Seq_N:Seq_N_T ) is

		Mess_IT: Mess_Id_T;
		Dest_T: Destinations_T;
		VT: Value_T;
		Hora_Ret: Ada.Calendar.Time;
		ARVecinos:Neighbors.Keys_Array_Type;

	begin

	--	Debug.Put_Line("Actualizar arboles" & EP_Image(EP_H_Creat) & EP_Image(EP_H_Rsnd), Pantalla.Rojo);
	
		--actualizamos buffers
			--asignamos a sender buffering y sender dest los camppos recibidos	
			--sender buffering		
			VT.EP_H_Creat:=EP_H_Creat;
			VT.Seq_N:= Seq_N;
			VT.P_Buffer:=  CM.P_Buffer_Handler;
			--CM.P_Buffer_Main:=null;
			--sender dest
			Mess_IT.EP:= EP_H_Creat;
			Mess_IT.Seq:= Seq_N;
			ARVecinos:=Neighbors.Get_Keys(Vecinos);

		--	Sender_Dests.Print_Map(Vec_Asent);
			--creamos sender dest		
			--le pasamos a sender dest los end points de todos los vecinos salvo del que me lo ha enviado 

			ARVecinos:=Neighbors.Get_Keys(Vecinos);
			for i in 1..ARVecinos'Length loop
				if ARVecinos(i)/=null then --mete bien los vecinos
					if ARVecinos(i)/= EP_H_Rsnd then 
						Dest_T(i).EP:=ARVecinos(i);
						Dest_T(i).Retries:=0;
				--	ATI.Put_Line("Añadimos a Sender_Dests " &EP_Image(Dest_T(i).EP));
					end if; 
				end if;
			end loop;
		
				
			--actualizamos sender dests/buffering y programamos su retransmisión
		--	Sender_Buffering.Print_Map(Mens_Pend);
		--	Sender_Dests.Print_Map(Vec_Asent);
			Hora_Ret:= Ada.Calendar.Clock + Plazo_Retransmision;
			Sender_Buffering.Put(Mens_Pend,Hora_Ret, VT);
			Sender_Dests.Put(Vec_Asent, Mess_IT,Dest_T);
			Timed_Handlers.Set_Timed_Handler(Hora_Ret, Reenviar'Access);

	end ActualizarArboles;


	--Inundación

	procedure Inundar(EP_H_Rsnd:LLU.End_Point_Type) is

		ARVecinos:Neighbors.Keys_Array_Type;
	begin
--Debug.Put_Line("R "&EP_Image(EP_H_Rsnd) &" C "& EP_Image(EP_H_Creat), Pantalla.rOJO);

		ARVecinos:= Neighbors.Get_Keys(Vecinos);
		for i in 1..Neighbors.Map_Length(Vecinos) loop
			if ARVecinos(i) /= EP_H_Rsnd then
				if ARVecinos(i)/=null then
					LLU.Send(ARVecinos(i), CM.P_Buffer_Handler);
					Debug.Put_Line("     Send to: " & EP_Image(ARVecinos(i)) , Pantalla.Verde); 
				end if;
			end if;
		end loop;

	end Inundar;

	-- Envía los paquetes y también programa su retransmisión futura

	procedure Reenviar (Hora: in Ada.Calendar.Time) is
		
		Mess_IT: Mess_Id_T;
		Dest_T: Destinations_T;
		VT: Value_T;
		Success: Boolean:= False;
		Hora_Ret: Ada.Calendar.Time;
	--	Plazo_Retransmision:Duration;
			
	begin
--Debug.Put_Line("reenviar", Pantalla.Rojo);
	--	Plazo_Retransmision:=2* Duration(Max_Delay) / 1000;

		--Buscamos elem corresp en Sender Buffering (Clave:Hora de retransmisión)
		Sender_Buffering.Get(Mens_Pend, Hora, VT, Success);
		-- Hay que borrar dicho elemento porque la hora ya no vale
		Sender_Buffering.Delete(Mens_Pend, Hora, Success);

		if Success = True then

			--Con SB buscamos en SD para obtener array Destinations
			Mess_IT.EP:= VT.EP_H_Creat;
			Mess_IT.Seq:=VT.Seq_N;
			Mess_IT:=(Mess_IT.EP, Mess_IT.Seq);
			Sender_Dests.Get(Vec_Asent, Mess_IT, Dest_T, Success);

			-- Enviamos a loS ep no nulos y sumamos un reintento
			for i in 1..10 loop
				if Dest_T(i).Retries < MAX then

				  if Dest_T(i).EP /= null then

					LLU.Send(Dest_T(i).EP, VT.P_Buffer);				
					Dest_T(i).Retries:= Dest_T(i).Retries +1;

					Debug.Put_Line("     Send to: " & EP_Image(Dest_T(i).EP) & 
									"   Nº de retrans: " &  Integer'Image(Dest_T(i).Retries) 										& "   Seq: " & Seq_N_T'Image(Mess_IT.Seq), Pantalla.Magenta); 

				-- Si llegamos a max no retransmitimos más
					if Dest_T(i).Retries= MAX then 
						Dest_T(i).EP:= null;
					end if;

				   end if;
				end if;
			end loop;

		--	Sender_Dests.Print_Map(Vec_Asent);
		--	Sender_Buffering.Print_Map(Mens_Pend);

			--Programamos el Set_Timed_Handler
			Hora_Ret:= Ada.Calendar.Clock+ Plazo_Retransmision;
			Sender_Buffering.Put(Mens_Pend, Hora_Ret, VT);
			Sender_Dests.Put(Vec_Asent,Mess_IT,Dest_T);
			TH.Set_Timed_Handler(Hora_Ret, Reenviar'Access);

		else
			Sender_Dests.Delete(Vec_Asent,Mess_IT,Success);
	
		end if;

	end Reenviar;


   procedure Peer_Handler (From    : in     LLU.End_Point_Type;
                           To      : in     LLU.End_Point_Type;
                           P_Buffer: access LLU.Buffer_Type) is

	use type ASU.Unbounded_String;
	use type LLU.End_Point_Type;
	use type CM.Message_Type;

		Mess: CM.Message_Type;
		EP_H_Rsnd:LLU.End_Point_Type;
		EP_R_Creat:LLU.End_Point_Type;
		EP_H_ACKer:LLU.End_Point_Type;
		EP_H_Creat: LLU.End_Point_Type;
		Seq_N:Seq_N_T:=0;
		NumSeq:Seq_N_T:=0;
		Maquina:ASU.Unbounded_String;
		IPMaq:ASU.Unbounded_String;
		Text: ASU.Unbounded_String;
		Mess_IT: Mess_Id_T;
		Dest_T: Destinations_T;
		Confirm_Sent: Boolean;
		Success:Boolean:=False;
		More_Dests: Boolean;

   begin

	Maquina:=ASU.To_Unbounded_String(LLU.Get_Host_Name);
	IPMaq:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Maquina)));
	Port:= Integer'Value(ACL.Argument(1));
	EP_H:=LLU.Build(ASU.To_String(IPMaq), Port);
	Mess:=CM.Message_Type'Input(P_Buffer);

	if Mess= CM.Init then

		EP_H_Creat:= LLU.End_Point_Type'Input(P_Buffer);
		Seq_N:=Seq_N_T'Input(P_Buffer);
		EP_H_Rsnd:=LLU.End_Point_Type'Input(P_Buffer);
		EP_R_Creat:=LLU.End_Point_Type'Input(P_Buffer);
		Nick:=ASU.Unbounded_String'Input(P_Buffer);
				
		Latest_Msgs.Get(Mensajes,EP_H_Creat, NumSeq, Success);
		if EP_h_Creat=EP_H then ATI.Put("");
		else
		if EP_H_Creat = EP_H_Rsnd then
			Neighbors.Put(Vecinos, EP_H_Creat, Ada.Calendar.Clock, Success );
		end if;
		if ACL.Argument(2) = Nick then 
				Mess:= CM.Reject;
				CM.P_Buffer_Handler:= new LLU.Buffer_Type(1024);
				CM.Message_Type'Output(CM.P_Buffer_Handler, Mess);
				LLU.End_Point_Type'Output(CM.P_Buffer_Handler, EP_H);
				ASU.Unbounded_String'Output(CM.P_Buffer_Handler, Nick);
				LLU.Send(EP_R_Creat, CM.P_Buffer_Handler);
				Free(CM.P_Buffer_Handler);
				Debug.Put_Line("Han intentado introducirse con su Nick, Reject enviado", Pantalla.Rojo);
		end if;

		if Success = False or Seq_N = NumSeq + 1 then
			Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success);

			Ack (EP_H_ACKer, EP_H_Creat,EP_H_Rsnd, Seq_N);	
			
			Debug.Put("RCV INIT ", Pantalla.Azul);
			Debug.Put_Line("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 				EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick), 	Pantalla.Azul_Claro);

			Debug.Put_Line("     Adding to neighbors " & EP_Image(EP_H_Creat), Pantalla.Verde );

			Init(EP_H_Creat, Seq_N, EP_H, EP_R_Creat, Nick);

			Debug.Put_Line("     Adding to latest_mesages " & EP_Image(EP_H_Creat) & Seq_N_T'Image(Seq_N), 									Pantalla.Verde );

			Debug.Put("FLOOD INIT ", Pantalla.Amarillo);
				Debug.Put_Line("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 								EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick), 	Pantalla.Verde);
			Inundar(EP_H_Rsnd);

			ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N );

			Debug.Put("Send ACK ", Pantalla.Amarillo);
			Debug.Put_Line("EP_Creat " &EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) & " EP_H_Acker " 
						& EP_Image(EP_H_Acker) & " To: " & EP_Image(EP_H_Rsnd), 	Pantalla.Verde);



		elsif Seq_N <= NumSeq then --el mensaje ya ha sido visto anteriormente
			Ack (EP_H_ACKer, EP_H_Creat,EP_H_Rsnd, Seq_N);
			Debug.Put("RCV Init visto anteriormente  --> ", Pantalla.Azul);
			Debug.Put("Send ACK ", Pantalla.Amarillo);
			Debug.Put_Line("EP_Creat " &EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) & " EP_H_Acker " 
						& EP_Image(EP_H_Acker) & " To: " & EP_Image(EP_H_Rsnd), 	Pantalla.Verde);
		
		elsif Seq_N > NumSeq + 1 then   --el que entra es mayor que el que debería (desorden)
			Debug.Put("RCV INIT ", Pantalla.Azul);
			Debug.Put("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 							EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick)& "--> ", Pantalla.Azul_Claro);
			Debug.Put_Line("Mensaje demasiado nuevo. Ignorar", Pantalla.Verde);
		
			end if;  end if;


	elsif Mess= CM.Confirm then

		EP_H_Creat:= LLU.End_Point_Type'Input(P_Buffer);
		Seq_N:=Seq_N_T'Input(P_Buffer);
		EP_H_Rsnd:=LLU.End_Point_Type'Input(P_Buffer);
		Nick:=ASU.Unbounded_String'Input(P_Buffer);

		if EP_h_Creat=EP_H then ATI.Put("");
		else
		Latest_Msgs.Get(Mensajes,EP_H_Creat, NumSeq, Success);
		if Success = False or Seq_N = NumSeq + 1 then
			Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success );

			Ack (EP_H_ACKer, EP_H_Creat,EP_H_Rsnd, Seq_N);
			
			Confirm(EP_H_Creat, Seq_N, EP_H, Nick);

			Debug.Put("RCV CONFIRM ", Pantalla.Azul);
			Debug.Put_Line("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 								EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick), Pantalla.Azul_Claro);

			Debug.Put_Line("     Adding to latest_mesages " & EP_Image(EP_H_Creat) & Seq_N_T'Image(Seq_N), Pantalla.Verde );
			
			Debug.Put("FLOOD CONFIRM ", Pantalla.Amarillo);
			Debug.Put_Line("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 								EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick), 	Pantalla.Verde);
			Inundar(EP_H_Rsnd);

			ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N );

			Debug.Put("Send ACK ", Pantalla.Amarillo);
			Debug.Put_Line("EP_Creat " &EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) & " EP_H_Acker " 
						& EP_Image(EP_H_Acker) & " To: " & EP_Image(EP_H_Rsnd), 	Pantalla.Verde);

			ATI.Put_Line(ASCII.LF & ASU.To_String(Nick) & " joins the chat ");	
					
			
		elsif Seq_N <= NumSeq then
			Ack (EP_H_ACKer, EP_H_Creat,EP_H_Rsnd, Seq_N);
			Debug.Put("RCV Confirm visto anteriormente  --> ", Pantalla.Azul);
			Debug.Put("Send ACK ", Pantalla.Amarillo);
			Debug.Put_Line("EP_Creat " &EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) & " EP_H_Acker " 
						& EP_Image(EP_H_Acker) & " To: " & EP_Image(EP_H_Rsnd), 	Pantalla.Verde);
		elsif Seq_N > NumSeq + 1 then 
			Debug.Put("RCV CONFIRM ", Pantalla.Azul);
			Debug.Put("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 					EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick)& " --> ", 	Pantalla.Azul_Claro);
			Debug.Put_Line("Mensaje demasiado nuevo. Ignorar", Pantalla.Verde); 
		end if;end if;

	elsif Mess= CM.Ack then
		
--busco el elem corresp al mens que asiete en la tabla sender dests el ack y obtengo el array dest_T
		EP_H_ACKer:=LLU.End_Point_Type'Input(P_Buffer);
		EP_H_Creat:= LLU.End_Point_Type'Input(P_Buffer);
		Seq_N:=Seq_N_T'Input(P_Buffer);
		Mess_IT.EP:= EP_H_Creat;
		Mess_IT.Seq:= Seq_N;
		Sender_Dests.Get(Vec_Asent, Mess_IT, Dest_T, Success);
--Ponnemos a null el ep que envia el ack
		for i in 1..10 loop
			if Dest_T(i).EP = EP_H_ACKer then
				Dest_T(i).EP:= null;
				Dest_T(i).Retries:=0;
			end if;
		end loop;

		More_Dests := False;
		for i in 1..10 loop
			if Dest_T(i).EP /= null and Dest_T(i).Retries < MAX then
				-- hay más destinos pendientes
				More_Dests := True;
			end if;
		end loop;

		if More_Dests then
			Sender_Dests.Put(Vec_Asent,Mess_IT, Dest_T);
		else
			--Borramos ya que no quedan EP a los que enviar
			Sender_Dests.Delete(Vec_Asent, Mess_IT, Success);
		end if;

		Debug.Put("RCV ACK ", Pantalla.Azul);
		Debug.Put_Line("EP_Creat " &EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &  " EP_ACKer "& EP_Image(EP_H_ACKer), 														 Pantalla.Azul_Claro);	
	elsif Mess= CM.Writer then
--Neighbors.Print_Map(Vecinos);

		EP_H_Creat:= LLU.End_Point_Type'Input(P_Buffer);
		Seq_N:=Seq_N_T'Input(P_Buffer);
		EP_H_Rsnd:=LLU.End_Point_Type'Input(P_Buffer);
		Nick:=ASU.Unbounded_String'Input(P_Buffer);
		Text:= ASU.Unbounded_String'Input(P_Buffer);

		if EP_H_Creat =EP_H then ATI.Put("");
		else
		Latest_Msgs.Get(Mensajes,EP_H_Creat, NumSeq, Success);
		if Success = False or Seq_N = NumSeq + 1 then
			Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success );

			Ack (EP_H_ACKer, EP_H_Creat,EP_H_Rsnd, Seq_N);
	
			Writer (EP_H_Creat,Seq_N,EP_H,Nick, Text);
	
			Debug.Put("RCV WRITTER ", Pantalla.Azul);
			Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &  EP_Image(EP_H_Rsnd)&" "& ASU.To_String(Nick)   												&" " & ASU.To_String(Text),Pantalla.Azul_Claro);

			Debug.Put_Line("     Adding to latest_messages " & EP_Image(EP_H_Creat) & Seq_N_T'Image(Seq_N),Pantalla.Verde);
			
			Debug.Put("FLOOD WRITTER ", Pantalla.Amarillo);
			Debug.Put_Line(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &  EP_Image(EP_H_Rsnd)&" " & 									ASU.To_String(Nick)&" " & ASU.To_String(Text), Pantalla.Verde);
			Inundar(EP_H_Rsnd);

			ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N );

			Debug.Put("Send ACK ", Pantalla.Amarillo);
			Debug.Put_Line("EP_Creat " &EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) & " EP_H_Acker " 
						& EP_Image(EP_H_Acker) & " To: " & EP_Image(EP_H_Rsnd), 	Pantalla.Verde);
	
			ATI.Put_Line(ASCII.LF & ASU.To_String(Nick) & ": " & ASU.To_String(Text));
	

		elsif Seq_N <= NumSeq then
			Ack (EP_H_ACKer, EP_H_Creat,EP_H_Rsnd, Seq_N);
			Debug.Put("RCV Writter visto anteriormente  --> ", Pantalla.Azul);
			Debug.Put("Send ACK ", Pantalla.Amarillo);
			Debug.Put_Line("EP_Creat " &EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) & " EP_H_Acker " 
						& EP_Image(EP_H_Acker) & " To: " & EP_Image(EP_H_Rsnd), 	Pantalla.Verde);
		elsif Seq_N > NumSeq + 1 then  
			Debug.Put("RCV WRITTER ", Pantalla.Azul);
			Debug.Put(EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &  EP_Image(EP_H_Rsnd)&" " & 								ASU.To_String(Nick)&" " & ASU.To_String(Text)& " -->", Pantalla.Azul_Claro);
			Debug.Put_Line("Mensaje demasiado nuevo. Ignorar", Pantalla.Verde);

		end if;end if;


	elsif Mess= CM.Logout then

		EP_H_Creat:= LLU.End_Point_Type'Input(P_Buffer);
		Seq_N:=Seq_N_T'Input(P_Buffer);
		EP_H_Rsnd:=LLU.End_Point_Type'Input(P_Buffer);
		Nick:=ASU.Unbounded_String'Input(P_Buffer);
		Confirm_Sent:= Boolean'Input(P_Buffer);

		if EP_H_Creat=EP_H then ATI.Put("");
		else
		if EP_H_Creat= EP_H_Rsnd then 

			Neighbors.Delete(Vecinos, EP_H_Creat, Success);	
		end if;

		Latest_Msgs.Get(Mensajes,EP_H_Creat, NumSeq, Success);
		
		if Success = False or Seq_N = NumSeq + 1 then
--Debug.Put_Line(" CASO 1 S FALSO Y S+1",Pantalla.rojo);
			Latest_Msgs.Put(Mensajes, EP_H_Creat,Seq_N, Success );
			Ack (EP_H_ACKer, EP_H_Creat,EP_H_Rsnd, Seq_N);

			Logout(EP_H_Creat, Seq_N, EP_H, Nick, Confirm_Sent);

			Debug.Put("RCV LOGOUT ", Pantalla.Azul);
			Debug.Put_Line("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 								EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick), Pantalla.Azul_Claro);

			Debug.Put_Line("     Neighbor deleted " & EP_Image(EP_H_Creat),Pantalla.Verde);


			Debug.Put_Line("     Latest_Msgs deleted " & EP_Image(EP_H_Creat) &" "& Seq_N_T'Image(Seq_N) ,Pantalla.Verde);

			Debug.Put("FLOOD LOGOUT ", Pantalla.Amarillo);
			Debug.Put_Line("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 								EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick), 	Pantalla.Verde);
			Inundar(EP_H_Rsnd);

			ActualizarArboles(EP_H_Creat,EP_H_Rsnd, Seq_N );

			Debug.Put("Send ACK ", Pantalla.Amarillo);
			Debug.Put_Line("EP_Creat " &EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) & " EP_H_Acker " 
						& EP_Image(EP_H_Acker) & " To: " & EP_Image(EP_H_Rsnd), 	Pantalla.Verde);

			ATI.Put_Line(ASCII.LF & ASU.To_String(Nick) & " leaves the chat");

		elsif Success =True and EP_H_Creat= EP_H_Rsnd then
			Latest_Msgs.Delete(Mensajes, EP_H_Creat, Success );
	

		elsif Seq_N <= NumSeq then
--Debug.Put_Line(" CASO VISTO ANTERIORMENTE EP_h_rsND"& EP_Image(EP_H_RSND),Pantalla.rojo);
			Ack (EP_H_ACKer,EP_H_Creat,EP_H_Rsnd, Seq_N);

			Debug.Put("RCV Logout visto anteriormente  --> ", Pantalla.Azul);
			Debug.Put("Send ACK ", Pantalla.Amarillo);
			Debug.Put_Line("EP_Creat " &EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) & " EP_H_Acker " 
						& EP_Image(EP_H_Acker) & " To: " & EP_Image(EP_H_Rsnd), 	Pantalla.Verde);

		elsif Seq_N > NumSeq + 1 then 
--Debug.Put_Line(" CASO DEMASIADO NUEVO E IGNORAR",Pantalla.rojo);
			Debug.Put("RCV LOGOUT ", Pantalla.Azul);
			Debug.Put("EP_H_Creat " & EP_Image(EP_H_Creat) & " " & Seq_N_T'Image(Seq_N) &" EP_H_Rsnd " & 								EP_Image(EP_H_Rsnd) & " ... " & ASU.To_String(Nick)&" --> ", Pantalla.Azul_Claro);
			Debug.Put_Line("Mensaje demasiado nuevo. Ignorar", Pantalla.Verde);

		end if;end if;
	end if;

   end Peer_Handler;

end Handlers_P5;
