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

		if Nick /= "reader" then
			while P_Aux /= null loop
				if Nick = P_Aux.all.Nick then
					raise Client_List_Error;
				end if;
				P_aux:= P_aux.all.Next;
			end loop;
	
		end if;

		P_Aux:=List.P_First;
		
		while P_Aux /= null and then Existe = False loop
			if EP = P_Aux.all.Client_EP then
				P_Aux.all.Nick:= Nick;
				Existe:= True;
			end if;
				P_aux:= P_aux.all.Next;

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
		Word_List_Error: Exception;

	begin

		P_Aux:=List.P_First;

		if P_Aux = null then
			raise Word_List_Error;
			
		elsif Nick = P_Aux.all.Nick then
			List.P_First:= P_Aux.all.Next;
			Free(P_Aux);			
			Existe := True;
			
		end if;

		while Existe = False loop
			if P_Aux.all.Next = null then
				raise Word_List_Error;
			
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


	procedure Send_To_Readers(List: in Client_List_Type; P_Buffer: access LLU.Buffer_Type) is

		use type ASU.Unbounded_String;
		P_Aux: Cell_A;
		Existe: Boolean := False;
		Client_List_Error: Exception;

	begin 

		P_Aux:=List.P_First;

		if P_Aux = null then
			raise Client_List_Error;
		end if;

		while P_Aux /= null loop
			
			if P_Aux.all.Nick= "reader" then

				LLU.Send(P_Aux.all.Client_EP, P_Buffer);
			end if;
			P_Aux:= P_Aux.all.Next;
		end loop;

	end Send_To_Readers;


	function List_Image (List: in Client_List_Type) return String is
		
		
		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;

		P_Aux: Cell_A;
		Usuarios: ASU.Unbounded_String;
		
	begin
		
		P_Aux:= List.P_First;
	
		if P_Aux = null then
			Ada.Text_IO.Put_Line("No hay ningún cliente en la lista");	
		end if;

		while P_Aux /= null loop
			
			Usuarios:=LLU.Image(P_Aux.all.Client_EP) & P_Aux.all.Nick & " ASCII.LF " ;
			P_Aux:= P_Aux.all.Next;

		end loop;

		return ASU.To_String(Usuarios);

	end List_Image;


end Client_Lists;
