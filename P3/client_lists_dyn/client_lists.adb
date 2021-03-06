-- LORENA BAJO REBOLLO

with Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;
with Ada.Text_IO;
with Lower_Layer_UDP;


package body Client_Lists is


	procedure Add_Client (List: in out Client_List_Type; EP: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String) is

		
		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;
		P_Aux: Cell_A;
		Existe: Boolean:=False;
		Client_List_Error: Exception;
		
	begin	
	
		P_Aux:=List.P_First;

		while P_Aux /= null loop
			if Nick = P_Aux.all.Nick then
				raise Client_List_Error;
			end if;
			P_aux:= P_aux.all.Next;
		end loop;
	
		P_Aux:=List.P_First;
		
		while P_Aux /= null and then Existe = False loop
			if EP = P_Aux.all.Client_EP then
				P_Aux.all.Nick:= Nick;
				Existe:= True;
			end if;
			P_Aux:= P_Aux.all.Next;

		end loop;
	
		if Existe = False then
			P_Aux:= new Cell;
			P_Aux.all.Nick:= Nick;
			P_Aux.all.Client_EP:= EP;
			P_Aux.all.Next:= List.P_First;
			List.P_First:=P_Aux;
			List.Total:=List.Total +1; 

		end if;
		
	end Add_Client;


	procedure Delete_Client (List: in out Client_List_Type; Nick: in ASU.Unbounded_String) is

		procedure Free is new Ada.Unchecked_Deallocation (Cell, Cell_A);

		use type ASU.Unbounded_String;
		
		P_Aux: Cell_A;
		P_Aux2: Cell_A;
		Existe: Boolean:=False;
		Client_List_Error: Exception;

	begin

		P_Aux:=List.P_First;

		if P_Aux = null then
			raise Client_List_Error;
			
		elsif Nick = P_Aux.all.Nick then
			List.P_First:= P_Aux.all.Next;
			Free(P_Aux);			
			Existe := True;
			
		end if;

		while Existe = False loop
			if P_Aux.all.Next = null then
				raise Client_List_Error;
			
			elsif Nick = P_Aux.all.Next.all.Nick then
				P_Aux2:= P_Aux.all.Next;
				P_Aux.all.Next:= P_Aux2.all.Next;
				Free(P_Aux2);
				List.Total:= List.Total-1;
				Existe := True;
			else 
				P_Aux:= P_Aux.all.Next;
			end if;

		end loop;

	end Delete_Client;


	function Search_Client (List: in Client_List_Type; EP: in LLU.End_Point_Type) return ASU.Unbounded_String is

			use type ASU.Unbounded_String;
			use type LLU.End_Point_Type;
			
			P_Aux: Cell_A;
			Client_List_Error: Exception;

	begin
			
		P_Aux:=List.P_First;	
	
		while P_Aux /= null loop
			if P_Aux = null then
				raise Client_List_Error;
				
			elsif EP = P_Aux.all.Client_EP then
				return P_Aux.all.Nick;
			else 
				P_Aux:= P_Aux.all.Next;
			end if;

		end loop;
		raise Client_List_Error;

	end Search_Client;


	procedure Send_To_All(List: in Client_List_Type; P_Buffer: access LLU.Buffer_Type; EP_Not_Send: in LLU.End_Point_Type) is

		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;

		P_Aux: Cell_A;
		Existe: Boolean := False;
		Client_List_Error: Exception;

	begin 

		P_Aux:=List.P_First;

		if P_Aux = null then
			raise Client_List_Error;
		end if;

		while P_Aux /= null loop
			
			if P_Aux.all.Client_EP /= EP_Not_Send then
				LLU.Send(P_Aux.all.Client_EP, P_Buffer);
			end if;
			P_Aux:= P_Aux.all.Next;
		end loop;

	end Send_To_All;


	function List_Image (List: in Client_List_Type) return String is
		
		
		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;

		P_Aux: Cell_A;
		Usuario: ASU.Unbounded_String;
		IP: ASU.Unbounded_String;
		Puerto: ASU.Unbounded_String;
		Indice:Natural;	
		Dir: ASU.Unbounded_String;	
		Dir_IP: ASU.Unbounded_String;	
		Long_Dir: Natural;
		
	begin
		
		P_Aux:= List.P_First;
	
		if P_Aux = null then
			Ada.Text_IO.Put_Line("No hay ningún cliente en la lista");	
		end if;

		while P_Aux /= null loop

			Dir:= ASU.To_Unbounded_String(LLU.Image(P_Aux.all.Client_EP));
			Long_Dir:= ASU.Length(Dir);
			Indice:= ASU.Index(Dir, ": ");
			Dir_IP:= ASU.Tail(Dir, Long_Dir-Indice);
			Indice:= ASU.Index(Dir_IP, ",");
			IP:= ASU.Head(Dir_IP, Indice-1);
			Indice:= ASU.Index(Dir, "Port: ");
			Puerto:=ASU.Tail(Dir, Long_Dir-Indice);
			Usuario := IP & ":" & Puerto & " " & ASU.To_String(P_Aux.Nick) & ASCII.LF & Usuario;
			 
			P_Aux:= P_Aux.all.Next;

		end loop;

		return ASU.To_String(Usuario);

	end List_Image;

	
	procedure Update_Client (List: in out Client_List_Type; EP: in LLU.End_Point_Type) is
			
		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;
		use type Ada.Calendar.Time;
			
		P_Aux: Cell_A;
		Client_List_Error: Exception;	
		Fin: Boolean:=False;

	begin
		P_Aux:= List.P_First;
		
		while P_Aux /= null and then Fin= False loop
			if P_Aux = null then
				raise Client_List_Error;
				
			elsif EP = P_Aux.all.Client_EP then
				P_Aux.all.Hora := Ada.Calendar.Clock;
				Fin:= True;
			else 
				P_Aux:= P_Aux.all.Next;
			end if;

		end loop;
		
	end Update_Client;


	procedure Remove_Oldest (List: in out Client_List_Type; EP: out LLU.End_Point_Type; Nick: out ASU.Unbounded_String) is

		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;
		use type Ada.Calendar.Time;
		
		P_Aux: Cell_A;
		Client_List_Error: Exception;
		EPMasAntiguo: LLU.End_Point_Type;
		NickMasAntiguo: ASU.Unbounded_String;
		HoraMasAntigua:Ada.Calendar.Time;

	begin

		P_Aux:=List.P_First;

		if P_Aux = null then
			raise Client_List_Error;
			
		end if;

		EPMasAntiguo:= P_Aux.all.Client_EP;
		NickMasAntiguo:= P_Aux.all.Nick;
		HoraMasAntigua:= P_Aux.all.Hora;

		P_Aux:= P_Aux.all.Next;

		while P_Aux /= null loop	
			if P_Aux.all.Hora < HoraMasAntigua then
				NickMasAntiguo:=P_Aux.all.Nick;
				EPMasAntiguo:= P_Aux.all.Client_EP;
				HoraMasAntigua:= P_Aux.all.Hora;
			else 
				P_Aux:= P_Aux.all.Next;
			end if;

		end loop;


		Nick:= NickMasAntiguo;
		EP:= EPMasAntiguo;
		Delete_Client(List, NickMasAntiguo);

	end Remove_Oldest;

  
	function Count (List: in Client_List_Type) return Natural is
		
		use type ASU.Unbounded_String;

		Count: Natural;
	begin
		Count:= List.Total;
		return Count;

	end Count;


end Client_Lists;
