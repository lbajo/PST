-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Command_Line;
with Word_Lists;

procedure Words is
	

	package ASU renames Ada.Strings.Unbounded;
	package ATI renames Ada.Text_IO;
	package ACL renames Ada.Command_Line;
	package WL renames Word_Lists;

	use type ASU.Unbounded_String;


	Word: ASU.Unbounded_String;
	Count: Natural;
	List: WL.Word_List_Type;
	Usage_Error: Exception;

	procedure Lista_Palabras (List: in out WL.Word_List_Type; File_Name: in ASU.Unbounded_String) is

		File: ATI.File_Type;
		Line: ASU.Unbounded_String;
		Word: ASU.Unbounded_String;
		Finish: Boolean; -- Final del fichero
		Finish_Line: Boolean;
		Long_Line: Natural;
		Long_Word: Natural;
		Indice: Natural; --Me devuelve la posición en la que se encuentra el espacio en la línea
		

	begin
		ATI.Open(File, ATI.In_File, ASU.To_String(File_Name));
		Finish := False;
		Finish_Line:= False;

		while not Finish loop
			begin
				Line := ASU.To_Unbounded_String(ATI.Get_Line(File));
				Long_Line:= ASU.Length(Line);
				Finish_Line:= False;

				while not Finish_Line loop
					Indice:= ASU.Index(Line, " ");
					if Indice = 0 then
						Finish_Line:= True;	

						if Long_Line /= 0 then
							WL.Add_Word(List, Line);
						end if;
					else
						Word:= ASU.Head(Line, Indice-1);
						Line:= ASU.Tail(Line, Long_Line-Indice);
						Long_Line:= ASU.Length(Line);
						Long_Word:= ASU.Length(Word);

						if Long_Word /= 0 then
							WL.Add_Word(List, Word);
						end if;

					end if;
				end loop;
	
			exception
				when Ada.IO_Exceptions.End_Error =>
				Finish := True;
			end;
		end loop;
		ATI.Close(File);
		
	end Lista_Palabras;


	procedure Modo_Interactivo (List: in out WL.Word_List_Type) is
		
		Num: Natural;
		Palabra:ASU.Unbounded_String;
		C: Natural; -- Contador de las veces que aparece la palabra
		Condicion: Boolean:= True;

	begin
		

		while Condicion loop

			ATI.New_Line(1);
			ATI.Put_Line("Options");
			ATI.Put_Line("1 Add word");
			ATI.Put_Line("2 Delete word");
			ATI.Put_Line("3 Search word");
			ATI.Put_Line("4 Show all word");
			ATI.Put_Line("5 Quit");
			ATI.New_Line(1);
			ATI.Put("Your option? ");
			Num:= Natural'Value(ATI.Get_Line);
			ATI.New_Line(1);

			case Num is 
				when 1 =>
					ATI.Put("Word? ");	
					Palabra:= ASU.To_Unbounded_String(ATI.Get_Line);
					WL.Add_Word(List, Palabra);
					ATI.Put_Line("Word | " & ASU.To_String(Palabra) & " | added " );
				when 2 =>
					ATI.Put("Word? ");	
					Palabra:= ASU.To_Unbounded_String(ATI.Get_Line);
					WL.Delete_Word(List, Palabra);
					ATI.Put_Line("| " & ASU.To_String(Palabra) & " | deleted " );
				when 3  =>
					ATI.Put("Word? ");	
					Palabra:= ASU.To_Unbounded_String(ATI.Get_Line);
					WL.Search_Word(List, Palabra, C);
					ATI.Put_Line("|" & ASU.To_String(Palabra) & "| - " & Integer'Image(C));
				when 4 =>
					WL.Print_All(List);
				when 5 =>
					WL.Max_Word(List, Word, Count);
					ATI.Put_Line("The most frequent word: |" & ASU.To_String(Word) & "| - " & Integer'Image(Count));
					Condicion:= False;
				when others =>
					ATI.Put_Line("Opción incorrecta"); 
				end case;
	
		end loop;
		
	end Modo_Interactivo;


begin

		if ACL.Argument_Count = 1 then
			ATI.New_Line(1);
			Lista_Palabras(List, ASU.To_Unbounded_String(ACL.Argument(1)));
			WL.Max_Word(List, Word, Count);
			ATI.Put_Line("The most frequent word: |" & ASU.To_String(Word) & "| - " & Integer'Image(Count));

		elsif ACL.Argument_Count=2 and then ACL.Argument(1)= "-l" then  
			ATI.New_Line(1);
			Lista_Palabras(List, ASU.To_Unbounded_String(ACL.Argument(2)));
			WL.Print_All(List);
			WL.Max_Word(List, Word, Count);
			ATI.New_Line(1);
			ATI.Put_Line("The most frequent word: |" & ASU.To_String(Word) & "| - " & Integer'Image(Count));


		elsif ACL.Argument_Count=2 and then ACL.Argument(1)= "-i" then
			Lista_Palabras(List, ASU.To_Unbounded_String(ACL.Argument(2)));
			Modo_Interactivo(List);

		elsif ACL.Argument_Count=3 then
			if (ACL.Argument(1)= "-i" and then ACL.Argument(2)= "-l") or 
								(ACL.Argument(1)= "-l" and then ACL.Argument(2)= "-i") then
				ATI.New_Line(1);
				Lista_Palabras(List, ASU.To_Unbounded_String(ACL.Argument(3)));
				WL.Print_All(List);
				WL.Max_Word(List, Word, Count);
				Modo_Interactivo(List);

			else
				raise Usage_Error;
			end if;

		else
			raise Usage_Error;
		end if;


exception
			when Ada.IO_Exceptions.Name_Error =>
				ATI.Put_Line("No existe el fichero");		

end Words;
