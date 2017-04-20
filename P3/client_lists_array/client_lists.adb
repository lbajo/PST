-- LORENA BAJO REBOLLO

with Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;
with Ada.Text_IO;
with Lower_Layer_UDP;
with Ada.Text_IO;


package body Client_Lists is

	procedure Add_Client (List: in out Client_List_Type; EP: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String) is

		
		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;

		Client_List_Error: Exception;
		NCli: Natural range 1..50:= 1;

	begin	

		while List(NCli).Nick /= ASU.Null_Unbounded_String loop
			if Nick = List(NCli).Nick then 
				raise Client_List_Error;
			end if;
			NCli:= NCli+1;
		end loop;

		while List(NCli).Nick /= ASU.Null_Unbounded_String and then List(NCli).Existe = False loop 
				if EP = List(NCli).Client_EP then
					List(NCli).Nick:= Nick;
					List(NCli).Existe:= True;
				end if;
				NCli:= NCli+1;	
		end loop;
	
		
		while List(NCli).Existe = False loop
			List(NCli).Nick:= Nick;
			List(NCli).Client_EP:= EP;
			List(NCli).Existe := True;
			List(NCli).Total:=List(NCli).Total +1; 
		end loop;
		
	end Add_Client;


	procedure Delete_Client (List: in out Client_List_Type; Nick: in ASU.Unbounded_String) is

		use type ASU.Unbounded_String;
	
		Client_List_Error: Exception;
		NCli: Natural range 1..50:= 1;

	begin

		while List(NCli).Nick /= ASU.Null_Unbounded_String loop
			if List(NCli).Nick = Nick then
				List(NCli).Nick:= ASU.Null_Unbounded_String;
				List(NCli).Client_EP:= null;	
				List(NCli).Existe := False;
			end if;
			NCli:= NCli+1;
		end loop;

	end Delete_Client;


	function Search_Client (List: in Client_List_Type; EP: in LLU.End_Point_Type) return ASU.Unbounded_String is

			use type ASU.Unbounded_String;
			use type LLU.End_Point_Type;
			
		
			Client_List_Error: Exception;
			NCli: Natural range 1..50:= 1;
	begin
	
		while List(NCli).Nick /= ASU.Null_Unbounded_String loop
			if List(NCli).Nick = ASU.Null_Unbounded_String then
				raise Client_List_Error;
				
			elsif EP = List(NCli).Client_EP then
				return List(NCli).Nick;

			end if;
			NCli:= NCli+1;
		end loop;

		raise Client_List_Error;

	end Search_Client;


	procedure Send_To_All(List: in Client_List_Type; P_Buffer: access LLU.Buffer_Type; EP_Not_Send: in LLU.End_Point_Type) is

		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;

		NCli: Natural range 1..50:= 1;
		Client_List_Error: Exception;
	begin 


		if List(NCli).Nick = ASU.Null_Unbounded_String then
			raise Client_List_Error;
		end if;

		while List(NCli).Nick /= ASU.Null_Unbounded_String loop
			
			if List(NCli).Client_EP /= EP_Not_Send then
				LLU.Send(List(NCli).Client_EP, P_Buffer);
			end if;
			NCli:= NCli+1;
		end loop;

	end Send_To_All;


	function List_Image (List: in Client_List_Type) return String is
		
		
		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;

		NCli: Natural range 1..50:= 1;
		Usuario: ASU.Unbounded_String;
		IP: ASU.Unbounded_String;
		Puerto: ASU.Unbounded_String;
		Indice:Natural;	
		Dir: ASU.Unbounded_String;	
		Dir_IP: ASU.Unbounded_String;	
		Long_Dir: Natural;

	begin
		
	
		if List(NCli).Nick = ASU.Null_Unbounded_String then
			Ada.Text_IO.Put_Line("No hay ningún cliente en la lista");	
		end if;

		while List(NCli).Nick /= ASU.Null_Unbounded_String loop

			Dir:= ASU.To_Unbounded_String(LLU.Image(List(NCli).Client_EP));
			Long_Dir:= ASU.Length(Dir);
			Indice:= ASU.Index(Dir, ": ");
			Dir_IP:= ASU.Tail(Dir, Long_Dir-Indice);
			Indice:= ASU.Index(Dir_IP, ",");
			IP:= ASU.Head(Dir_IP, Indice-1);
			Indice:= ASU.Index(Dir, "Port: ");
			Puerto:=ASU.Tail(Dir, Long_Dir-Indice);
			Usuario := IP & ":" & Puerto & " " & ASU.To_String(List(NCli).Nick) & ASCII.LF & Usuario;
			 
			NCli:= NCli+1;

		end loop;

		return ASU.To_String(Usuario);

	end List_Image;

	
	procedure Update_Client (List: in out Client_List_Type; EP: in LLU.End_Point_Type) is
			
		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;
		use type Ada.Calendar.Time;
			
		NCli: Natural range 1..50:= 1;
		Client_List_Error: Exception;	
		Fin: Boolean:=False;

	begin
		
		while List(NCli).Nick /= ASU.Null_Unbounded_String and then Fin= False loop
			if List(NCli).Nick = ASU.Null_Unbounded_String then
				raise Client_List_Error;
				
			elsif EP = List(NCli).Client_EP then
				List(NCli).Hora := Ada.Calendar.Clock;
				Fin:= True;
			else 
				NCli:= NCli+1;
			end if;

		end loop;
		
	end Update_Client;


	procedure Remove_Oldest (List: in out Client_List_Type; EP: out LLU.End_Point_Type; Nick: out ASU.Unbounded_String) is

		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;
		use type Ada.Calendar.Time;
		
		NCli: Natural range 1..50:= 1;
		Client_List_Error: Exception;
		EPMasAntiguo: LLU.End_Point_Type;
		NickMasAntiguo: ASU.Unbounded_String;
		HoraMasAntigua:Ada.Calendar.Time;
	begin


		if List(NCli).Nick = ASU.Null_Unbounded_String then
			raise Client_List_Error;
			
		end if;

		EPMasAntiguo:= List(NCli).Client_EP;
		NickMasAntiguo:= List(NCli).Nick;
		HoraMasAntigua:= List(NCli).Hora;

		NCli := NCli+1;

		while List(NCli).Nick /= ASU.Null_Unbounded_String loop	
			if List(NCli).Hora < HoraMasAntigua then
				NickMasAntiguo:=List(NCli).Nick;
				EPMasAntiguo:=List(NCli).Client_EP;
				HoraMasAntigua:= List(NCli).Hora;
			else 
				NCli:= NCli+1;
			end if;

		end loop;


		Nick:= NickMasAntiguo;
		EP:= EPMasAntiguo;
		Delete_Client(List, NickMasAntiguo);

	end Remove_Oldest;


	function Count (List: in Client_List_Type) return Natural is
		
		use type ASU.Unbounded_String;

		Count: Natural;
		NCli: Natural range 1..50:= 1;
	begin

			Count:= List(NCli).Total;
			Count:= Count +1;

		return Count;

	end Count;


end Client_Lists;
