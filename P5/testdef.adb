-- LORENA BAJO REBOLLO

with Lower_Layer_UDP;
with Ada.Calendar;
with Ada.Strings.Unbounded;
with Maps_g;
with Maps_protector_g;
with Gnat.Calendar;
with Gnat.Calendar.Time_IO;
with chat_messages;
with ordered_maps_g;
with Ordered_maps_protector_G;
with Ada.Text_IO;

procedure testdef is

	package LLU renames Lower_Layer_UDP;
	package C_IO renames Gnat.Calendar.Time_IO;
	package ASU renames Ada.Strings.Unbounded;
	package CM renames Chat_Messages;

	use type Ada.Calendar.Time;
 	use type ASU.Unbounded_String;
	use type LLU.End_Point_Type;


	type Seq_N_T is mod Integer'Last;

-- NP_Sender_Dests
	type Mess_Id_T is record
		EP: LLU.End_Point_Type;
		Seq: Seq_N_T;
	end record;
	type Destination_T is record
		EP: LLU.End_Point_Type := null;
		Retries : Natural := 0;
	end record;
	type Destinations_T is array (1..10) of Destination_T;

-- NP_Sender_Buffering
	type Buffer_A_T is access LLU.Buffer_Type;

	type Value_T is record
		EP_H_Creat: LLU.End_Point_Type;
		Seq_N: Seq_N_T;
		P_Buffer: CM.Buffer_A_T;
	end record;

-- Función igual 

	function FIgual (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean is 

		Cond: Boolean:=False;
	begin

		if LLU.Image(M1.EP) = LLU.Image(M2.EP) then
			if  M1.Seq = M2.Seq then
				Cond := True;	
				
			end if;
		else 
			Cond:= False;
		end if;
		
		return Cond;
	end;


	-- Función menor

	function FMenor (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean is 

		Cond: Boolean:=False;
	begin
		if LLU.Image(M1.EP) < LLU.Image(M2.EP) then 
			Cond:= True;	
	
		elsif  LLU.Image(M1.EP) = LLU.Image(M2.EP) and M1.Seq < M2.Seq then
			Cond:=True;
		else
			Cond:= False;
		end if;

		return Cond;
	end;

	-- Función mayor

	function FMAYOR (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean is 

		Cond: Boolean:=False;
	begin
		if LLU.Image(M1.EP) > LLU.Image(M2.EP) then 
			Cond:= True;	
	
		elsif  LLU.Image(M1.EP) = LLU.Image(M2.EP) and M1.Seq > M2.Seq then
			Cond:=True;
		else
			Cond:= False;
		end if;

		return Cond;
	end;



	function EP_Image (EP:LLU.End_Point_Type) return String is
			
		use type ASU.Unbounded_String;
		use type LLU.End_Point_Type;

		Usuario: ASU.Unbounded_String;
		IP: ASU.Unbounded_String;
		Puerto: ASU.Unbounded_String;
		Indice:Natural;	
		Dir: ASU.Unbounded_String;	
		Dir_IP: ASU.Unbounded_String;	
		Long_Dir: Natural;
		
	begin
			Dir:= ASU.To_Unbounded_String(LLU.Image(EP));
			Long_Dir:= ASU.Length(Dir);
			Indice:= ASU.Index(Dir, ": ");
			Dir_IP:= ASU.Tail(Dir, Long_Dir-Indice);
			Indice:= ASU.Index(Dir_IP, ",");
			IP:= ASU.Head(Dir_IP, Indice-1);
			Indice:= ASU.Index(Dir, "Port: ");
			Puerto:=ASU.Tail(Dir, Long_Dir-Indice-5);
			Usuario := IP & ":" & Puerto;
			
		return ASU.To_String(Usuario);

	end EP_Image;

-- Mess_Id_T devuelve String

	function RE_Image (M:Mess_Id_T) return String is

		Re_Key: ASU.Unbounded_String;
	begin

		Re_Key:= ASU.To_Unbounded_String(EP_Image(M.EP) & " " & Seq_N_T'Image(M.Seq));

		return ASU.To_String(Re_Key);
	end RE_Image;

-- Destinations_t devuelve String

--	function AR_Image (D:Destinations_T) return String is
	
--		Ar_Value: ASU.Unbounded_String;

--	begin
--		for i in 1..10 loop 
--			Ar_Value:= Ar_Value & ASU.To_Unbounded_String(EP_Image(D(i).EP) & " " & Natural'Image(D(i).Retries));
--		end loop;

	--	return ASU.To_String(Ar_Value);

--	end AR_Image;

	function AR_Image (D:Destinations_T) return String is

 	  Ar_Value: ASU.Unbounded_String;

	begin

  	 Ar_Value := Ar_Value & "[ ";
	
  	 for i in 1..10 loop
     	  if D(i).EP /= null then
        	 Ar_Value:= Ar_Value & EP_Image(D(i).EP) & " -" &Natural'Image(D(i).Retries);
    	  else
        	 Ar_Value := Ar_Value & "null - 0 ";
	  end if;
   	end loop;

  		 Ar_Value := Ar_Value & " ]";
   return ASU.To_String(Ar_Value);

end AR_Image;

-- Imagen del ada calendar

	 function Image_3 (T: Ada.Calendar.Time) return String is
  	 begin
     		return Gnat.Calendar.Time_IO.Image(T, "%T.%i");
  	 end Image_3;
-- Comparar ada calendar

	function Igual_AC (T1: Ada.Calendar.Time; T2:Ada.Calendar.Time) return boolean is
		Cond: Boolean:= False;
	begin
		if Image_3(T1)=Image_3(T2) then
			Cond:= True;
		else
			Cond:= False;
		end if;
			return Cond;
	end Igual_AC;

	function Menor_AC (T1: Ada.Calendar.Time; T2:Ada.Calendar.Time) return boolean is
		Cond: Boolean:= False;
	begin
		if Image_3(T1)<Image_3(T2) then
			Cond:= True;
		else
			Cond:= False;
		end if;
			return Cond;
	end Menor_AC;

-- Value_T devuelve String
	
	function Value_Image (V:Value_T) return String is
	
		I_Value: ASU.Unbounded_String;
	begin

		I_Value:= ASU.To_Unbounded_String(EP_Image(V.EP_H_Creat) & " " & Seq_N_T'Image(V.Seq_N));

		return ASU.To_String(I_Value);

	end Value_Image;

	function vacio (array_neighbors: Destinations_T) return Boolean is 
	vacio: Boolean := True ;
	i:integer:=1;
	 begin 
	while i <= 10 and  vacio loop	
	 if array_neighbors(i).EP /= null then
	 	vacio := False ;
	  end if ;
	i:=i+1;	
	end loop;
	 	return vacio ;
	end vacio;

	package NP_Sender_Dests is new Ordered_Maps_G (Mess_Id_T, 
						Destinations_T,
 						FIgual,
 						FMenor, 
						RE_Image, 
						AR_Image);

	package NP_Sender_Buffering is new Ordered_Maps_G (Ada.Calendar.Time, 
							Value_T,
							Igual_AC,
							Menor_AC,
							Image_3,
							Value_Image);


	package Sender_Dests is new Ordered_Maps_Protector_G (NP_Sender_Dests);
	package Sender_Buffering is new Ordered_Maps_Protector_G(NP_Sender_Buffering);



Ep1: LLU.End_Point_Type;
Ep2: LLU.End_Point_Type;

Success: Boolean;

Time1:Ada.calendar.Time; 
Vec_Asent: Sender_Dests.Prot_Map;
Mens_Pend: Sender_Buffering.Prot_Map;
Seq_N:Seq_N_T:= 0;

M1,M2: Mess_Id_T;
D1,D2: Destinations_T;
V1: Value_T;
Igual:Boolean;
Menor:Boolean;
Mayor:Boolean;
Vacia:boolean;


begin

	TIme1:= Ada.Calendar.Clock;	
	Ep1:= LLU.Build("127.0.0.1", 9001);
	Ep2:= LLU.Build("127.0.0.1", 9001);
	

M1.EP:= Ep1;
M1.Seq:= 1;	

M2.Ep:= EP2;
M2.Seq:= 2;

D1(1).EP:= EP1;
D1(1).Retries:=0;

Ada.Text_IO.Put_Line(Re_Image(M1));
Ada.Text_IO.Put_Line(Re_Image(M2));
Ada.Text_IO.Put_Line(AR_Image(D1));

Ada.Text_IO.Put_Line("Igual");
Igual:=FIgual(M1,M2);
Ada.Text_IO.Put_Line(Boolean'Image(Igual));

Ada.Text_IO.Put_Line("Menor");
Menor:=FMenor(M1,M2);
Ada.Text_IO.Put_Line(Boolean'Image(Menor));

Ada.Text_IO.Put_Line("Mayor");
Mayor:=FMAYOR(M1,M2);
Ada.Text_IO.Put_Line(Boolean'Image(Mayor));
Ada.Text_IO.Put_Line("vACIO");
Vacia:=Vacio(D1);
Ada.Text_IO.Put_Line(Boolean'Image(Vacia));

Ada.Text_IO.Put_Line("GET SENDER DESTS");

Sender_Dests.GEt(Vec_Asent,M1,D1,Success);
Sender_Dests.Print_Map(VEc_Asent); 

Ada.Text_IO.Put_Line("PUT SENDER DESTS");
Sender_Dests.Put(Vec_Asent,M1,D1);
Sender_Dests.Put(VEc_Asent,M2,D1);
Ada.Text_IO.Put_Line("GET SENDER DESTS");

Sender_Dests.GEt(Vec_Asent,M1,D1,Success);
Sender_Dests.Print_Map(VEc_Asent); 


Sender_Dests.Print_Map(VEc_Asent); 

Ada.Text_IO.Put_Line("DELETE SENDER DESTS");

Sender_Dests.Delete(Vec_Asent,M2,Success);

Sender_Dests.Print_Map(Vec_Asent);

V1.Ep_H_Creat:= Ep2;

V1.Seq_N:= SEq_N+5;

Ada.Text_IO.Put_Line("PUT SENDER BUFFERING");

Sender_Buffering.Put(Mens_Pend,Time1, V1);

Sender_Buffering.Print_Map(Mens_pend);

end testdef;
