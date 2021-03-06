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

procedure Chat_Client_2 is

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
	IP: ASU.Unbounded_String;
	Server_EP: LLU.End_Point_Type;
	Client_EP_Receive: LLU.End_Point_Type;
	Client_EP_Handler: LLU.End_Point_Type;
	Buffer: aliased LLU.Buffer_Type(1024);
	Mess: CM.Message_Type;
	Acogido: Boolean;
	Expired: Boolean:= False;
	Comentario: ASU.Unbounded_String;
	Usage_Error: Exception;

begin

	if ACL.Argument_Count /= 3 then 
		raise Usage_Error;
	end if;

	Maquina:= ASU.To_Unbounded_String(ACL.Argument(1));
	Puerto:= Integer'Value(ACL.Argument(2));
	Nick:= ASU.To_Unbounded_String(ACL.Argument(3));
	
	IP:= ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Maquina)));
	Server_EP := LLU.Build(ASU.To_String(IP), Puerto);
	LLU.Bind_Any(Client_EP_Receive);
	LLU.Bind_Any(Client_EP_Handler, HP3.Client_Handler'Access);
	LLU.Reset(Buffer);

	if Nick /= "server" then

		Mess:= CM.Init;
		CM.Message_Type'Output(Buffer'Access, Mess);
		LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Receive);
		LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
		ASU.Unbounded_String'Output(Buffer'Access, Nick);
		LLU.Send(Server_EP, Buffer'Access);
		LLU.Reset(Buffer);
		
		LLU.Receive(Client_EP_Receive, Buffer'Access, 10.0, Expired);

		if Expired= False then
				
			Mess:=CM.Message_Type'Input(Buffer'Access);
			if Mess= CM.Welcome then
				Acogido:=Boolean'Input(Buffer'Access);

				if Acogido = False then
					ATI.Put_Line("IGNORED new user " & ASU.To_String(Nick) & ", nick already used");
					LLU.Finalize;
				else
					ATI.Put_Line("Mini-Chat v2.0: Welcome " & ASU.To_String(Nick));
					
					while Comentario /= ".quit" loop
			
						ATI.Put(">> ");						
						LLU.Reset(Buffer);
						Mess:=CM.Writer;
						Comentario:= ASU.To_Unbounded_String(ATI.Get_Line);
						if Comentario = ".quit" then 
							Mess:= CM.Logout;
							CM.Message_Type'Output(Buffer'Access, Mess);
							LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
							LLU.Send(Server_EP, Buffer'Access);
							LLU.Finalize;
						else
							CM.Message_Type'Output(Buffer'Access, Mess);
							LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
							ASU.Unbounded_String'Output(Buffer'Access, Comentario);
							LLU.Send(Server_EP, Buffer'Access);
						
						end if;	
					end loop;
				end if;
			end if;
		
		else
			ATI.Put_Line("Server unreachable");
			LLU.Finalize;
		end if;	
		
	end if;

   LLU.Finalize;

exception
	when Usage_Error => ATI.Put_Line("Introduzca 3 argumentos, por favor"); LLU.Finalize;

end Chat_Client_2;

