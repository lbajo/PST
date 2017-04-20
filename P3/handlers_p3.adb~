with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Chat_Messages;

package body Handlers_P3 is

   package ASU renames Ada.Strings.Unbounded;
   package CM renames Chat_Messages;
   package ATI renames Ada.Text_IO;

   procedure Client_Handler (From: in     LLU.End_Point_Type;
                             To : in     LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type) is

	Nick: ASU.Unbounded_String;
	Mess: CM.Message_Type;
	Comentario: ASU.Unbounded_String;
	
   begin
	
	Mess:=CM.Message_Type'Input(P_Buffer);
	Nick:=ASU.Unbounded_String'Input(P_Buffer);
	Comentario:= ASU.Unbounded_String'Input(P_Buffer);
	ATI.Put_Line(ASCII.LF & ASU.To_String(Nick) & ": " & ASU.To_String(Comentario));
	ATI.Put(">> ");						

   end Client_Handler;

end Handlers_P3;
