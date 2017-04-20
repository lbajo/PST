-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Command_Line;
with Lower_Layer_UDP;
with Client_Lists;
with Chat_Messages;


procedure Chat_Server is

	package ASU renames Ada.Strings.Unbounded;
	package ATI renames Ada.Text_IO;
	package LLU renames Lower_Layer_UDP;
	package ACL renames Ada.Command_Line;
	package CL renames Client_Lists;
	package CM renames Chat_Messages;

	use type ASU.Unbounded_String;
	use type LLU.End_Point_Type;
	use type CM.Message_Type;

	Nick: ASU.Unbounded_String;
	Maquina: ASU.Unbounded_String;
	Puerto: Integer;
	IP: ASU.Unbounded_String;
	Server_EP: LLU.End_Point_Type;
	Client_EP: LLU.End_Point_Type;
	Buffer: aliased LLU.Buffer_Type(1024);
	Expired : Boolean;
	Mess: CM.Message_Type;
	Comentario: ASU.Unbounded_String;
	List: CL.Client_List_Type; 
	Texto: ASU.Unbounded_String;
	Client_List_Error: Exception;
	Usage_Error: Exception;
	Ex: Exception;


begin 
	
	if ACL.Argument_Count/= 1 then 
		raise Usage_Error;
	end if;

	List.P_First:= null;
	List.Total:= 0;

	Puerto:= Integer'Value(Ada.Command_Line.Argument(1));

	Maquina:= ASU.To_Unbounded_String(LLU.Get_Host_Name);
	IP:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Maquina)));
	Server_EP := LLU.Build(ASU.To_String(IP), Puerto);
	LLU.Bind (Server_EP);

	loop

		LLU.Reset(Buffer);
		LLU.Receive (Server_EP, Buffer'Access, 1000.0, Expired);

      		if Expired then
         		ATI.Put_Line ("Plazo expirado, vuelvo a intentarlo");
      		else
   			Mess:=CM.Message_Type'Input(Buffer'Access);

			if Mess= CM.Init then
				
				Client_EP:= LLU.End_Point_Type'Input(Buffer'Access);
				Nick:=ASU.Unbounded_String'Input(Buffer'Access);
				begin
         				CL.Add_Client(List, Client_EP, Nick);
					ATI.Put_Line("INIT received from " & ASU.To_String(Nick));
				exception
  				   when Ex:others =>
      					ATI.Put_Line ("INIT received from " & ASU.To_String(Nick) & ". IGNORED, nick already used");
				end;
         			
				LLU.Reset (Buffer);

				if Nick /= "reader" then
					Mess:=CM.Server;
					CM.Message_Type'Output(Buffer'Access, Mess);
					Texto:= ASU.To_Unbounded_String(ASU.To_String(Nick) & " joins the chat");
					Nick:= ASU.To_Unbounded_String("Server");
					ASU.Unbounded_String'Output(Buffer'Access, Nick);
					ASU.Unbounded_String'Output(Buffer'Access, Texto); 
					CL.Send_To_Readers(List, Buffer'Access);
				end if;

			else 
				
				Client_EP:= LLU.End_Point_Type'Input(Buffer'Access);
				Comentario:=ASU.Unbounded_String'Input(Buffer'Access);
	
				if Comentario /= ".quit" then
					begin
						Nick:=CL.Search_Client(List, Client_EP);
					ATI.Put_Line("WRITER received from " & ASU.To_String(Nick) & ": " & ASU.To_String(Comentario));
					exception
  				  		 when Ex:others =>
							ATI.Put("");
					end;
				
					LLU.Reset (Buffer);
					Mess:=CM.Server;
					CM.Message_Type'Output(Buffer'Access, Mess);
					ASU.Unbounded_String'Output(Buffer'Access, Nick);
					ASU.Unbounded_String'Output(Buffer'Access, Comentario);
					CL.Send_To_Readers(List, Buffer'Access);
				end if;

			end if;
      		end if;
	end loop;


end Chat_Server;
