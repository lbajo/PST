-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Chat_Messages;
with Lower_Layer_UDP;

package Handlers_P3 is
   package LLU renames Lower_Layer_UDP;



   procedure Client_Handler (From    : in     LLU.End_Point_Type;
                             To      : in     LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type);

end Handlers_P3;
