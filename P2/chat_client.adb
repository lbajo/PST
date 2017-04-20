-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Command_Line;
with Lower_Layer_UDP;
with Client_Lists;
with Chat_Messages;


procedure Chat_Client is

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
	Expired : Boolean:= False;
	Mess: CM.Message_Type;
	Comentario: ASU.Unbounded_String;
	Texto: ASU.Unbounded_String;

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
	LLU.Bind_Any(Client_EP);
	LLU.Reset(Buffer);


	if Nick = "reader" then

		Mess:= CM.Init;
		CM.Message_Type'Output(Buffer'Access, Mess);
		LLU.End_Point_Type'Output(Buffer'Access, Client_EP);
		ASU.Unbounded_String'Output(Buffer'Access, Nick);
		LLU.Send(Server_EP, Buffer'Access);
		LLU.Reset(Buffer);
		loop
	
			LLU.Receive(Client_EP, Buffer'Access, 5.0, Expired);

			if not Expired then
			
				Mess:=CM.Message_Type'Input(Buffer'Access);
				Nick:=ASU.Unbounded_String'Input(Buffer'Access);
				Texto:= ASU.Unbounded_String'Input(Buffer'Access);

				if Mess = CM.Server then
					ATI.Put_Line(ASU.To_String(Nick) & ": " & ASU.To_String(Texto));
				end if;
			end if;	
		end loop;

	else

		Mess:= CM.Init;
		CM.Message_Type'Output(Buffer'Access, Mess);
		LLU.End_Point_Type'Output(Buffer'Access, Client_EP);
		ASU.Unbounded_String'Output(Buffer'Access, Nick);
		LLU.Send(Server_EP, Buffer'Access);
		LLU.Reset(Buffer);

		while Comentario /= ".quit" loop
			
			LLU.Reset(Buffer);
			Mess:=CM.Writer;
			ATI.Put("Message: ");
			Comentario:= ASU.To_Unbounded_String(ATI.Get_Line);
			CM.Message_Type'Output(Buffer'Access, Mess);
			LLU.End_Point_Type'Output(Buffer'Access, Client_EP);
			ASU.Unbounded_String'Output(Buffer'Access, Comentario);
			LLU.Send(Server_EP, Buffer'Access);
			
		end loop;		
	end if;

	LLU.Finalize;

end Chat_Client; 
