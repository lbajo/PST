-- LORENA BAJO REBOLLO

with Ada.Text_IO;
with Ada.Unchecked_Deallocation;

package body Maps_G is

   procedure Free is new Ada.Unchecked_Deallocation (Cell, Cell_A);


   procedure Get (M       : Map;
                  Key     : in  Key_Type;
                  Value   : out Value_Type;
                  Success : out Boolean) is
      P_Aux : Cell_A;

   begin
      P_Aux := M.P_First;
      Success := False;
      while not Success and P_Aux /= null Loop
         if P_Aux.Key = Key then
            Value := P_Aux.Value;
            Success := True;
         end if;
         P_Aux := P_Aux.Next;
      end loop;
   end Get;


   procedure Put (M     : in out Map;
                  Key   : Key_Type;
                  Value : Value_Type; 
		  Success: out Boolean) is
      P_Aux : Cell_A;
  
   begin

      -- Si ya existe Key, cambiamos su Value
      P_Aux := M.P_First;
      Success:= False;

      while not Success and P_Aux /= null loop
         if P_Aux.Key = Key then
            P_Aux.Value := Value;
	    Success:= True;
         end if;
         P_Aux := P_Aux.Next;
      end loop;

      -- Si no hemos encontrado Key añadimos al principio
-- Si M.Length es menor que el max_length
      if not Success then
	   if M.Length < Max_Length then
		if M.P_First = null then
			M.P_First := new Cell'(Key, Value, null, M.P_First);	
			M.Length := M.Length + 1;
		else
			P_Aux:=M.P_First;
			M.P_First := new Cell'(Key, Value, null, M.P_First);
			P_Aux.Ant:= M.P_First; 
			M.Length := M.Length + 1;
			Success:= True;
		end if;
		
	   end if;

        end if;
   end Put;


   procedure Delete (M      : in out Map;
                     Key     : in  Key_Type;
                     Success : out Boolean) is
      P_Aux  : Cell_A;
--Revisar el delete
   begin
      Success := False;
      P_Aux  := M.P_First;
	while not Success and P_Aux /= null  loop
        	if P_Aux.Key = Key then
             	 	Success := True;
           	 	M.Length := M.Length - 1;
	 	 	 if P_Aux.Next /= null then --con esto creo que ya lo he solucionado si se mete está bien
-- Ada.Text_IO.Put_Line ("no soy nulo");
         			 if P_Aux.Ant /= null then
                			 P_Aux.Ant.Next := P_Aux.Next;
                			 P_Aux.Next.Ant:= P_Aux.Ant; --Esta es la que falla en el delete de los mensajes(izq)
-- Ada.Text_IO.Put_Line ("lo he hecho bien");
           			 end if;
			  end if;
          		  if M.P_First = P_Aux then
               			M.P_First := M.P_First.Next;
         		  end if;
         
		   	  Free (P_Aux);
        	  else
           	     	P_Aux := P_Aux.Next;
        	 end if;

      end loop;

   end Delete;


   function Get_Keys (M : Map) return Keys_Array_Type is

	P_Aux: Cell_A;
	K_Array: Keys_Array_Type;
	L: Natural:= 1;

   begin
	P_Aux := M.P_First;

	while P_Aux /= null loop
		K_Array(L):= P_Aux.all.Key;
		P_Aux := P_Aux.Next;
		L:= L+1;
	end loop;

	while L <= Max_Length loop
		K_Array(L):= Null_Key;
		L:= L+1;

	end loop;
	

	return K_Array;

   end Get_Keys;

   function Get_Values (M : Map) return Values_Array_Type is

	P_Aux: Cell_A;
	V_Array: Values_Array_Type;
	L: Natural:= 1;
	
   begin

	P_Aux := M.P_First;

	while P_Aux /= null loop
		V_Array(L):= P_Aux.all.Value;
		P_Aux := P_Aux.Next;
		L:= L+1;
	end loop;

	while L <= Max_Length loop
		V_Array(L):= Null_Value;
		L:= L+1;

	end loop;

	return V_Array;

   end Get_Values;

   function Map_Length (M : Map) return Natural is

   begin

      return M.Length;

   end Map_Length;



   procedure Print_Map (M : Map) is

      P_Aux : Cell_A;

   begin
      P_Aux := M.P_First;

      Ada.Text_IO.Put_Line ("Map");
      Ada.Text_IO.Put_Line ("===");

      while P_Aux /= null loop
         Ada.Text_IO.Put_Line (Key_To_String(P_Aux.Key) & " " &
                                 VAlue_To_String(P_Aux.Value));
         P_Aux := P_Aux.Next;
      end loop;
   end Print_Map;

end Maps_G;
