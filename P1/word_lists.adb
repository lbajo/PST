-- LORENA BAJO REBOLLO

with Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;
with Ada.Text_IO;


package body Word_Lists is


-- Si word está en la lista Count=+1, si no, crea una nueva celda con Count=1
	procedure Add_Word (List: in out Word_List_Type; Word: in ASU.Unbounded_String) is

	use type ASU.Unbounded_String;

		P_Aux: Word_List_Type;
		Condicion: Boolean;
	begin
		P_Aux:= List;
		Condicion:= False;

-- Me recorre la lista la primera vez
		if List = null then
			List:= new Cell;
			List.all.Count:= 1;
			List.all.Word:= Word;
			Condicion := True;
		elsif Word = List.all.Word then
			List.all.Count := List.all.Count +1;
			Condicion := True;
		end if;

-- Me recorre la lista después de la primera vez y me va añadiendo celdas
		while Condicion = False loop
			
			if P_Aux.all.Next = null then
				P_Aux.all.Next := new Cell;
				P_Aux.all.Next.all.Count:= 1;
				P_Aux.all.Next.all.Word:= Word;
				Condicion := True;
			
			elsif Word = P_Aux.all.Next.all.Word then
				P_Aux.all.Next.all.Count := P_Aux.all.Next.all.Count +1;
				Condicion := True;
			else 
				P_Aux:= P_Aux.all.Next;
			end if;

		end loop;

	end Add_Word;


-- Si Word está en la lista elimina su celda de la lista y libera la memoria ocupada popr ella (Free), Si no eleva Exception.
	procedure Delete_Word (List: in out Word_List_Type; Word: in ASU.Unbounded_String) is

		procedure Free is new Ada.Unchecked_Deallocation (Cell, Word_List_Type);

		use type ASU.Unbounded_String;
		
		P_Aux: Word_List_Type;
		P_Aux2: Word_List_Type;
		Condicion: Boolean;
		Word_List_Error: Exception;
	begin
		P_Aux:= List;
		Condicion:= False;

		if P_Aux = null then
			raise Word_List_Error;
			
		elsif Word = P_Aux.all.Word then
			List:= P_Aux.all.Next;
			Free(P_Aux);			
			Condicion := True;
			
		end if;

		while Condicion = False loop
			if P_Aux.all.Next = null then
				raise Word_List_Error;
			
			elsif Word = P_Aux.all.Next.all.Word then
				P_Aux2:= P_Aux.all.Next;
				P_Aux.all.Next:= P_Aux2.all.Next;
				Free(P_Aux2);
				Condicion := True;
			else 
				P_Aux:= P_Aux.all.Next;
			end if;

		end loop;

	end Delete_Word;

	   
-- Si word está en la lista, devuelve Count, si no 0
   	procedure Search_Word (List: in Word_List_Type; Word: in ASU.Unbounded_String; Count: out Natural) is
		
		use type ASU.Unbounded_String;

		P_Aux: Word_List_Type;
		Condicion: Boolean;
	begin
		P_Aux:= List;
		Condicion:= False;	
	
		
		while Condicion = False loop
			if P_Aux = null then
				Count :=0;
				Condicion := True;
			
			elsif Word = P_Aux.all.Word then
				Count := P_Aux.all.Count;
				Condicion := True;
			else 
				P_Aux:= P_Aux.all.Next;
			end if;

		end loop;

	end Search_Word;


-- Devuelve la celda de mayor Count, si están con el mismo Count, la primera, si está vacía, exception
 	procedure Max_Word (List: in Word_List_Type; Word: out ASU.Unbounded_String; Count: out Natural) is
		
		use type ASU.Unbounded_String;
		
		P_Aux: Word_List_Type;
		Word_List_Error: Exception;

	begin
		P_Aux:= List;
		Count:= 0;
		
		if P_Aux = null then
			raise Word_List_Error;
		end if;
		
		while P_Aux /= null loop
			if P_Aux.all.Count > Count then
				Count := P_Aux.all.Count;
				Word:= P_Aux.all.Word;
			end if;
			P_Aux:= P_Aux.all.Next;
		end loop;
			
	end Max_Word;


-- Muestra el contenido, en el orden en el que se introdujeron en ella, si está vacía dice No words
	procedure Print_All (List: in Word_List_Type) is
		
		use type ASU.Unbounded_String;
		
		P_Aux: Word_List_Type;
		
	begin
		P_Aux:= List;

		if P_Aux = null then
			Ada.Text_IO.Put_Line("No words");
		else
			while P_Aux /= null loop
				Ada.Text_IO.Put_Line("|" & ASU.To_String(P_Aux.all.Word) & "| - " & Integer'Image(P_Aux.all.Count));
				P_Aux:= P_Aux.all.Next;
			end loop;
		end if;

	end Print_All;



end Word_Lists;

