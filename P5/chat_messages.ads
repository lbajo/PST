-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Lower_Layer_UDP;

package Chat_Messages is

type Message_Type is (Init, Reject, Confirm, Writer, Logout, Ack);

type Buffer_A_T is access Lower_Layer_UDP.Buffer_Type;

	P_Buffer_Main:Buffer_A_T;
	P_Buffer_Handler:Buffer_A_T;

end Chat_Messages;
