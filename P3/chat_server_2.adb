-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Command_Line;
with Lower_Layer_UDP;
with Client_Lists;
with Chat_Messages;
with Handlers_P3;

procedure Chat_Server_2 is

	package ASU renames Ada.Strings.Unbounded;
	package ATI renames Ada.Text_IO;
	package LLU renames Lower_Layer_UDP;
	package ACL renames Ada.Command_Line;
	package CL renames Client_Lists;
	package CM renames Chat_Messages;
	package HP3 renames Handlers_P3;

	use type ASU.Unbounded_String;
	use type LLU.End_Point_Type;
	use type CM.Message_Type;

	Nick: ASU.Unbounded_String;
	Maquina: ASU.Unbounded_String;
	Puerto: Integer;
	NMaxClientes: Natural;
	IP: ASU.Unbounded_String;
	Server_EP: LLU.End_Point_Type;
	Client_EP_Receive: LLU.End_Point_Type;
	Client_EP_Handler: LLU.End_Point_Type;
	Buffer: aliased LLU.Buffer_Type(1024);
	Expired : Boolean;
	Mess: CM.Message_Type;
	Comentario: ASU.Unbounded_String;
	List: CL.Client_List_Type;
	EPDelete: LLU.End_Point_Type;
	NickDelete: ASU.Unbounded_String;
	NickNuevo: ASU.Unbounded_String;
	NickEntrante: ASU.Unbounded_String;
	TotalClientes: Natural;
	Client_List_Error: Exception;
	Usage_Error: Exception;
	Ex: Exception;
	Num_Client_Error: Exception;
	Acogida: Boolean;

begin

	if ACL.Argument_Count/= 2 then 
		raise Usage_Error;
	end if;

	Puerto:= Integer'Value(Ada.Command_Line.Argument(1));
	NMaxClientes:= Natural'Value(Ada.Command_Line.Argument(2)); 

	
	if NMaxClientes > 50 or NMaxClientes < 2 then
		raise Num_Client_Error;		
	end if;
	

		 
	
	Maquina:= ASU.To_Unbounded_String(LLU.Get_Host_Name);
	IP:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Maquina)));
	Server_EP := LLU.Build(ASU.To_String(IP), Puerto);
	LLU.Bind (Server_EP);

	loop

		LLU.Reset(Buffer);
		LLU.Receive (Server_EP, Buffer'Access, 1000.0, Expired);

      		if Expired then
         		ATI.Put_Line ("Plazo expirado, vuelvo a intentarlo");
			LLU.Finalize;
      		else
   			Mess:=CM.Message_Type'Input(Buffer'Access);

			if Mess= CM.Init then
				
				Client_EP_Receive:= LLU.End_Point_Type'Input(Buffer'Access);
				Client_EP_Handler:= LLU.End_Point_Type'Input(Buffer'Access);
				Nick:=ASU.Unbounded_String'Input(Buffer'Access);
				NickNuevo:=Nick;
				begin

					TotalClientes:=CL.Count(List);
					if TotalClientes >= NMaxClientes then 
						CL.Remove_Oldest(List, EPDelete, NickDelete);
						Comentario:= ASU.To_Unbounded_String(ASU.To_String(NickDelete) 
										& " banned for being idle too long");
						Nick:= ASU.To_Unbounded_String("Server");
					--Cuando un nombre envía un LOGOUT luego si se quiere introducir un nombre igual no le deja
					
						LLU.Reset (Buffer);
						Mess:=CM.Server;
						CM.Message_Type'Output(Buffer'Access, Mess);
						ASU.Unbounded_String'Output(Buffer'Access, Nick);
						ASU.Unbounded_String'Output(Buffer'Access, Comentario); 
						CL.Add_Client(List, Client_EP_Handler, NickNuevo);
						CL.Update_Client(List, Client_EP_Handler);
						ATI.Put_Line("INIT received from " & ASU.To_String(NickNuevo) & " : ACCEPTED");
						Acogida:= True;		

						if TotalClientes /= 0 then
							CL.Send_To_All(List, Buffer'Access, Client_EP_Handler);
						end if;
					else
         					CL.Add_Client(List, Client_EP_Handler, Nick);
						CL.Update_Client(List, Client_EP_Handler);
						ATI.Put_Line("INIT received from " & ASU.To_String(Nick) & " : ACCEPTED");
						Acogida:= True;
					end if;
				exception
  				   when Ex:others =>
					ATI.Put_Line (Ada.Exceptions.Exception_Name(Ex) & Ada.Exceptions.Exception_Message(Ex));
      					ATI.Put_Line ("INIT received from " & ASU.To_String(Nick) 
											& " : IGNORED. nick already used");
					Acogida := False;
				end;
         			
				LLU.Reset (Buffer);
				Mess:=CM.Welcome;
				CM.Message_Type'Output(Buffer'Access, Mess);
				Boolean'Output(Buffer'Access, Acogida);
				LLU.Send(Client_EP_Receive, Buffer'Access);

				if TotalClientes >= NMaxClientes then 
					Comentario:= ASU.To_Unbounded_String(ASU.To_String(NickNuevo) & " joins the chat");
				else
					Comentario:= ASU.To_Unbounded_String(ASU.To_String(Nick) & " joins the chat");
				end if;

				Nick:= ASU.To_Unbounded_String("Server");
				LLU.Reset (Buffer);
				Mess:=CM.Server;
				CM.Message_Type'Output(Buffer'Access, Mess);
				ASU.Unbounded_String'Output(Buffer'Access, Nick);
				ASU.Unbounded_String'Output(Buffer'Access, Comentario); 
				CL.Send_To_All(List, Buffer'Access, Client_EP_Handler);
				
			
			elsif Mess= CM.Writer then 
				Client_EP_Handler:= LLU.End_Point_Type'Input(Buffer'Access);
				Comentario:=ASU.Unbounded_String'Input(Buffer'Access);
	
					begin
					
						Nick:=CL.Search_Client(List, Client_EP_Handler);
						NickNuevo:=Nick;
					
						if TotalClientes >= NMaxClientes then 
							ATI.Put_Line("WRITER received from " & ASU.To_String(NickNuevo) & ": " 
												& ASU.To_String(Comentario));
						else
							ATI.Put_Line("WRITER received from " & ASU.To_String(Nick) & ": " 
												& ASU.To_String(Comentario));
						end if;

					exception
  				  		 when Ex:others =>
							ATI.Put("");
					end;
				
					LLU.Reset (Buffer);
					Mess:=CM.Server;
					CM.Message_Type'Output(Buffer'Access, Mess);
					NickNuevo:=Nick;

					if TotalClientes >= NMaxClientes then 
						ASU.Unbounded_String'Output(Buffer'Access, NickNuevo);
					else
						ASU.Unbounded_String'Output(Buffer'Access, Nick);
					end if;

					ASU.Unbounded_String'Output(Buffer'Access, Comentario);
					CL.Send_To_All(List, Buffer'Access, Client_EP_Handler);
					CL.Update_Client(List, Client_EP_Handler);

			elsif Mess= CM.Logout then
				Client_EP_Handler:= LLU.End_Point_Type'Input(Buffer'Access);

				begin
					Nick:=CL.Search_Client(List, Client_EP_Handler);
					CL.Delete_Client(List, Nick);
					ATI.Put_Line("LOGOUT received from " & ASU.To_String(Nick));
				exception
  				  	 when Ex:others =>
						ATI.Put("");
				end;
				LLU.Reset (Buffer);
				Mess:=CM.Server;

				if TotalClientes >= NMaxClientes then 
					Comentario := ASU.To_String(NickNuevo) & ASU.To_Unbounded_String(" leaves the chat"); 
				else
					Comentario := ASU.To_String(Nick) & ASU.To_Unbounded_String(" leaves the chat"); 
					
				end if;

				Nick:= ASU.To_Unbounded_String("Server");
				CM.Message_Type'Output(Buffer'Access, Mess);
				ASU.Unbounded_String'Output(Buffer'Access, Nick);
				ASU.Unbounded_String'Output(Buffer'Access, Comentario); 
				TotalClientes:=CL.Count(List);
				if TotalClientes >= 2 then
					CL.Send_To_All(List, Buffer'Access, Client_EP_Handler);
				end if;

			end if;
      		end if;
	end loop;

exception

	when Usage_Error => ATI.Put_Line("Introduzca 3 argumentos, por favor"); LLU.Finalize;
	when Num_Client_Error => ATI.Put_Line("Introduzca un número máximo de clientes entre 2 y 50"); LLU.Finalize;

end Chat_Server_2;

