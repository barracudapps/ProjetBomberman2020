functor
import
   Application
   GUI at './gui.ozf'
   Property
   OS
   System  % provides System.{show,showInfo,print,printInfo}
   Browser % provides Browser.browse
define
   G
   InitPlayers = {NewCell nil}
   Walls = {NewCell nil}
   FoodList = {NewCell nil}
   Bomblist = {NewCell nil}
   Star = {NewCell nil}
   {Property.put 'print.width' 1000}
   {Property.put 'print.depth' 1000}

   %Default Values
   HEIGHT   = ({OS.rand} mod 12) + 8
   WIDTH    = ({OS.rand} mod 20) + 8
   Args = {Application.getArgs
	   record(
	      height(single char:&h type:int default:HEIGHT)
	      width(single char:&w type:int default:WIDTH)
	      )}

   % Key press events
   Handler = proc {$ Key} local OldPos in
			     case Key of 'ï\x9C\x80' % Up
			     then {MovePlayer up @InitPlayers.1}
			     [] 'z' % Up
			     then {MovePlayer up @InitPlayers.2.1}
			     [] 'ï\x9C\x81' % Down
			     then {MovePlayer down @InitPlayers.1}
			     [] 's' % Down
			     then {MovePlayer down @InitPlayers.2.1}
			     [] 'ï\x9C\x82' % Left
			     then {MovePlayer left @InitPlayers.1}
			     [] 'q' % Left
			     then {MovePlayer left @InitPlayers.2.1}
			     [] 'ï\x9C\x83' % Right
			     then {MovePlayer right @InitPlayers.1}
			     [] 'd' % Right
			     then {MovePlayer right @InitPlayers.2.1}
			     [] '\x1B' % ESC
			     then {Application.exit 0}
			     [] '\r' % Bomb ENTER
			     then {@InitPlayers.1 getValue('pos' OldPos)}
				{G reset(OldPos.x OldPos.y)}
				{@InitPlayers.1 placeBomb()}
			     [] 'a' % Bomb
			     then {@InitPlayers.2.1 getValue('pos' OldPos)}
				{G reset(OldPos.x OldPos.y)}
				{@InitPlayers.2.1 placeBomb()}
			     else skip
			     end
			     % {System.show keyboard(Key)}
			  end
	     end

   % Bomberman Object
   class BMan
      attr name power pos score
      meth init(Name)
	 name := Name
	 score := 0
	 power := 1
	 pos := {IteratePlace}
	 {Wait @pos}
      end
      meth getValue(Value X)
	 case Value of 'name' then X = @name
	 [] 'power' then X = @power
	 [] 'pos' then X = @pos
	 [] 'score' then X = @score
	 [] 'type' then X = 'Bomberman'
	 else skip
	 end
      end
      meth move(NewPos Dir)
	 pos := NewPos
	 {G movePlayer(@name @pos.x @pos.y Dir)}
      end
      meth placeBomb()
	 {G bomb(@name @power @pos.x @pos.y)}
	 {AddBomb {New Bomb init(@name @power @pos)}}
	 power := 1
	 {G power(@name @power)}
      end
      meth eat()
	 if @power > 3 then skip
	 else power := @power + 1
	    {G power(@name @power)}
	 end
      end
      meth point()
	 score := @score + 1
	 {G score(@name @score)}
      end
      meth star()
	 score := @score + 5
	 {G score(@name @score)}
      end
      meth stupid()
	 power := 1
	 {G power(@name @power)}
	 if @score > 1 then
	    score := @score - 1
	    {G score(@name @score)}
	 else skip
	 end
      end
   end

   % Bomb Object
   class Bomb
      attr power pos name
      meth init(BName Pow Pos)
	 name := BName
	 power := Pow
	 pos := Pos
	 {System.showInfo @power#'-power bomb placed at ('#@pos.x#','#@pos.y#') by '#BName#''}
      end
      meth getValue(Value X)
	 case Value of 'name' then X = @name
	 [] 'power' then X = @power
	 [] 'pos' then X = @pos
	 [] 'type' then X = 'Bomb'
	 else skip
	 end
      end
   end

   % Wall Object
   class Wall
      attr pos
      meth init(Pos)
	 pos := Pos
      end
      meth getValue(Value X)
	 case Value of 'pos' then X = @pos
	 [] 'type' then X = 'Wall'
	 else skip
	 end
      end
   end

   proc {AddBomb Bomb}
      Bomblist := Bomb|@Bomblist
      thread {Delay {OS.rand} mod 20000 + 3000}{Explosion Bomb} end
   end

   proc {AddFood Pos}
      FoodList := Pos|@FoodList
   end

   proc{Explosion Bomb} Pos Power BMan LLock RLock TLock BLock
      fun{CheckWalls X Y} IsFree
	 proc{Wall W} WallPos in
	    {W getValue('pos' WallPos)}
	    if WallPos.x == X andthen WallPos.y == Y then IsFree := false
	    else skip
	    end
	 end
      in
	 IsFree = {NewCell true}
	 {List.forAll @Walls Wall}
	 @IsFree
      end

      proc{CheckBMan Pos2Check} BMan1Name BMan2Name BMan1 BMan2 BMan1Pos BMan2Pos in
	 BMan1 = @InitPlayers.1
	 BMan2 = @InitPlayers.2.1
	 {BMan1 getValue('name' BMan1Name)}
	 {BMan1 getValue('pos' BMan1Pos)}
	 {BMan2 getValue('name' BMan2Name)}
	 {BMan2 getValue('pos' BMan2Pos)}
	 if BMan1Pos.x == Pos2Check.x andthen BMan1Pos.y == Pos2Check.y then
	    {BMan2 point()}
	    if BMan1Name == BMan then
	       {BMan1 stupid()}
	    else skip
	    end
	 elseif BMan2Pos.x == Pos2Check.x andthen BMan2Pos.y == Pos2Check.y then
	    {BMan1 point()}
	    if BMan2Name == BMan then
	       {BMan2 stupid()}
	    else skip
	    end
	 end
      end

      proc{CheckPosStage Stage}
	 if @LLock == false then
	    if {CheckWalls Pos.x-Stage Pos.y} == false then
	       LLock := true
	    elseif {IsFree Pos.x-Stage Pos.y} then
	       {CheckItem nil pos(x:Pos.x-Stage y:Pos.y)}
	       if @Star == nil then skip
	       elseif @Star.x == Pos.x-Stage andthen @Star.y == Pos.y then Star := nil
	       else skip
	       end
	    else {CheckBMan pos(x:Pos.x-Stage y:Pos.y)}
	    end
	 else skip
	 end
	 if @RLock == false then
	    if {CheckWalls Pos.x+Stage Pos.y} == false then
	       RLock := true
	    elseif {IsFree Pos.x+Stage Pos.y} then
	       {CheckItem nil pos(x:Pos.x+Stage y:Pos.y)}
	       if @Star == nil then skip
	       elseif @Star.x == Pos.x+Stage andthen @Star.y == Pos.y then Star := nil
	       else skip
	       end
	    else {CheckBMan pos(x:Pos.x+Stage y:Pos.y)}
	    end
	 else skip
	 end
	 if @TLock == false then
	    if {CheckWalls Pos.x Pos.y-Stage} == false then
	       TLock := true
	    elseif {IsFree Pos.x Pos.y-Stage} then
	       {CheckItem nil pos(x:Pos.x y:Pos.y-Stage)}
	       if @Star == nil then skip
	       elseif @Star.x == Pos.x andthen @Star.y == Pos.y-Stage then Star := nil
	       else skip
	       end
	    else {CheckBMan pos(x:Pos.x y:Pos.y-Stage)}
	    end
	 else skip
	 end
	 if @BLock == false then
	    if {CheckWalls Pos.x Pos.y+Stage} == false then
	       BLock := true
	    elseif {IsFree Pos.x Pos.y+Stage} then
	       {CheckItem nil pos(x:Pos.x y:Pos.y+Stage)}
	       if @Star == nil then skip
	       elseif @Star.x == Pos.x andthen @Star.y == Pos.y+Stage then Star := nil
	       else skip
	       end
	    else {CheckBMan pos(x:Pos.x y:Pos.y+Stage)}
	    end
	 else skip
	 end
      end

      proc{Delete}
	 proc{Check List Head}
	    case List of nil then skip
	    [] H|T then
	       local ObjPos in
		  {H getValue('pos' ObjPos)}
		  if ObjPos.x == Pos.x andthen ObjPos.y == Pos.y then
		     case Head of nil then Bomblist := T
		     else Bomblist := Head|T
		     end
		  else
		     case Head of nil then {Check T H}
		     else {Check T Head|H}
		     end
		  end
	       end
	    else skip
	    end
	 end
      in
	 {Check @Bomblist nil}
      end
   in
      LLock = {NewCell false}
      RLock = {NewCell false}
      TLock = {NewCell false}
      BLock = {NewCell false}
      {Bomb getValue('pos' Pos)}
      {Bomb getValue('power' Power)}
      {Bomb getValue('name' BMan)}
      {G img('fireCenter1' Pos.x Pos.y)}

      {CheckPosStage 0}
      {CheckPosStage 1}
      {Delay 150}
      if Pos.x > 1 andthen @LLock == false then
	 {G img('fireTD1' Pos.x - 1 Pos.y)}
	 thread
	    {Delay 600}
	    {G reset(Pos.x-1 Pos.y)}
	    {CheckPos pos(x:Pos.x-1 y:Pos.y)}
	 end
      else skip end
      if Pos.x < HEIGHT andthen @RLock == false then
	 {G img('fireTD1' Pos.x + 1 Pos.y)}
	 thread
	    {Delay 600}
	    {G reset(Pos.x+1 Pos.y)}
	    {CheckPos pos(x:Pos.x+1 y:Pos.y)}
	 end
      else skip end
      if Pos.y > 1 andthen @TLock == false then
	 {G img('fireLR1' Pos.x Pos.y - 1)}
	 thread
	    {Delay 600}
	    {G reset(Pos.x Pos.y-1)}
	    {CheckPos pos(x:Pos.x y:Pos.y-1)}
	 end
      else skip end
      if Pos.y < WIDTH andthen @BLock == false then
	 {G img('fireLR1' Pos.x Pos.y + 1)}
	 thread
	    {Delay 600}
	    {G reset(Pos.x Pos.y+1)}
	    {CheckPos pos(x:Pos.x y:Pos.y+1)}
	 end
      else skip end

      if Power > 1 then
	 {CheckPosStage 2}
	 {Delay 150}
	 if Pos.x > 2 andthen @LLock == false then
	    {G img('fireTD1' Pos.x - 2 Pos.y)}
	    thread
	       {Delay 500}
	       {G reset(Pos.x-2 Pos.y)}
	       {CheckPos pos(x:Pos.x-2 y:Pos.y)}
	    end
	 else skip end
	 if Pos.x < HEIGHT - 1 andthen @RLock == false then
	    {G img('fireTD1' Pos.x + 2 Pos.y)}
	    thread
	       {Delay 500}
	       {G reset(Pos.x+2 Pos.y)}
	       {CheckPos pos(x:Pos.x+2 y:Pos.y)}
	    end
	 else skip end
	 if Pos.y > 2 andthen @TLock == false then
	    {G img('fireLR1' Pos.x Pos.y - 2)}
	    thread
	       {Delay 500}
	       {G reset(Pos.x Pos.y-2)}
	       {CheckPos pos(x:Pos.x y:Pos.y-2)}
	    end
	 else skip end
	 if Pos.y < WIDTH  - 1 andthen @BLock == false then
	    {G img('fireLR1' Pos.x Pos.y + 2)}
	    thread
	       {Delay 500}
	       {G reset(Pos.x Pos.y+2)}
	       {CheckPos pos(x:Pos.x y:Pos.y+2)}
	    end
	 else skip end

	 if Power > 2 then
	    {CheckPosStage 3}
	    {Delay 150}
	    if Pos.x > 3 andthen @LLock == false then
	       {G img('fireTD1' Pos.x - 3 Pos.y)}
	       thread
		  {Delay 400}
		  {G reset(Pos.x-3 Pos.y)}
		  {CheckPos pos(x:Pos.x-3 y:Pos.y)}
	       end
	    else skip end
	    if Pos.x < HEIGHT - 2 andthen @RLock == false then
	       {G img('fireTD1' Pos.x + 3 Pos.y)}
	       thread
		  {Delay 400}
		  {G reset(Pos.x+3 Pos.y)}
		  {CheckPos pos(x:Pos.x+3 y:Pos.y)}
	       end
	    else skip end
	    if Pos.y > 3 andthen @TLock == false then
	       {G img('fireLR1' Pos.x Pos.y - 3)}
	       thread
		  {Delay 400}
		  {G reset(Pos.x Pos.y-3)}
		  {CheckPos pos(x:Pos.x y:Pos.y-3)}
	       end
	    else skip end
	    if Pos.y < WIDTH  - 2 andthen @BLock == false then
	       {G img('fireLR1' Pos.x Pos.y + 3)}
	       thread
		  {Delay 400}
		  {G reset(Pos.x Pos.y+3)}
		  {CheckPos pos(x:Pos.x y:Pos.y+3)}
	       end
	    else skip end

	    if Power > 3 then
	       {CheckPosStage 4}
	       {Delay 150}
	       if Pos.x > 4 andthen @LLock == false then
		  {G img('fireTD1' Pos.x - 4 Pos.y)}
		  thread
		     {Delay 300}
		     {G reset(Pos.x-4 Pos.y)}
		     {CheckPos pos(x:Pos.x-4 y:Pos.y)}
		  end
	       else skip end
	       if Pos.x < HEIGHT - 3 andthen @RLock == false then
		  {G img('fireTD1' Pos.x + 4 Pos.y)}
		  thread
		     {Delay 300}
		     {G reset(Pos.x+4 Pos.y)}
		     {CheckPos pos(x:Pos.x+4 y:Pos.y)}
		  end
	       else skip end
	       if Pos.y > 4 andthen @TLock == false then
		  {G img('fireLR1' Pos.x Pos.y - 4)}
		  thread
		     {Delay 300}
		     {G reset(Pos.x Pos.y-4)}
		     {CheckPos pos(x:Pos.x y:Pos.y-4)}
		  end
	       else skip end
	       if Pos.y < WIDTH  - 3 andthen @BLock == false then
		  {G img('fireLR1' Pos.x Pos.y + 4)}
		  thread
		     {Delay 300}
		     {G reset(Pos.x Pos.y+4)}
		     {CheckPos pos(x:Pos.x y:Pos.y+4)}
		  end
	       else skip end
	    else skip
	    end
	 else skip
	 end
      else skip
      end
      {Delay 100}
      {G reset(Pos.x Pos.y)}
      {Delete}
      {CheckPos pos(x:Pos.x y:Pos.y)}
   end

   fun{IsFree X Y}
      fun{TestFree X Y List}
	 case List of nil then true
	 [] H|T then
	    local Pos in
	       {H getValue('pos' Pos)}
	       if Pos.x == X andthen Pos.y == Y then false
	       else {TestFree X Y T}
	       end
	    end
	 end
      end
   in
      if {TestFree X Y @Walls} == true then
	 if {TestFree X Y @InitPlayers} == true then true
	 else false
	 end
      else false
      end
   end

   fun{IteratePlace}
      fun{Iterate X Y}
	 if {IsFree X Y} then pos(x:X y:Y)
	 else {Iterate (({OS.rand} mod HEIGHT) + 1) (({OS.rand} mod WIDTH) + 1)}
	 end
      end
   in
      {Iterate (({OS.rand} mod HEIGHT) + 1) (({OS.rand} mod WIDTH) + 1)}
   end

   proc{SpawnFood} Pos Time
   in
      Time = {OS.rand} mod 30000 + 2000
      {Delay Time}
      Pos = {IteratePlace}
      {AddFood Pos}
      {G img('food' Pos.x Pos.y)}
      thread
	 {Delay ({OS.rand} mod 50000 + 1000)}
	 {CheckItem nil Pos}
	 {G reset(Pos.x Pos.y)}
	 {CheckPos Pos}
      end
      {System.showInfo 'Food appeared at ('#Pos.x#','#Pos.y#')'}
      {SpawnFood}
   end

   proc{SpawnStar} Pos Time
   in
      Time = {OS.rand} mod 360000 + 30000
      {Delay Time}
      Pos = {IteratePlace}
      Star := pos(x:Pos.x y:Pos.y)
      {G img('star' Pos.x Pos.y)}
      {System.showInfo 'Star appeared at ('#Pos.x#','#Pos.y#')'}
      {Delay 20000}
      {G reset(Pos.x Pos.y)}
      {CheckPos Pos}
      Star := nil
      {SpawnStar}
   end

   proc{MovePlayer Dir Player}
      local OldPos Free NewPos in
	 NewPos = {NewCell nil}
	 case Dir of up then
	    {Player getValue('pos' OldPos)}
	    {G reset(OldPos.x OldPos.y)}
	    if OldPos.x == 1 then skip
	    else
	       NewPos := pos(x:OldPos.x-1 y:OldPos.y)
	       Free = {IsFree @NewPos.x @NewPos.y}
	       if Free then {Player move(pos(x:@NewPos.x y:@NewPos.y) up)}
	       else skip
	       end
	    end
	 [] down then
	    {Player getValue('pos' OldPos)}
	    {G reset(OldPos.x OldPos.y)}
	    if OldPos.x == HEIGHT then skip
	    else
	       NewPos := pos(x:OldPos.x+1 y:OldPos.y)
	       Free = {IsFree @NewPos.x @NewPos.y}
	       if Free then {Player move(pos(x:@NewPos.x y:@NewPos.y) down)}
	       else skip
	       end
	    end
	 [] left then
	    {Player getValue('pos' OldPos)}
	    {G reset(OldPos.x OldPos.y)}
	    if OldPos.y == 1 then skip
	    else
	       NewPos := pos(x:OldPos.x y:OldPos.y-1)
	       Free = {IsFree @NewPos.x @NewPos.y}
	       if Free then {Player move(pos(x:@NewPos.x y:@NewPos.y) left)}
	       else skip
	       end
	    end
	 [] right then
	    {Player getValue('pos' OldPos)}
	    {G reset(OldPos.x OldPos.y)}
	    if OldPos.y == WIDTH then skip
	    else
	       NewPos := pos(x:OldPos.x y:OldPos.y+1)
	       Free = {IsFree @NewPos.x @NewPos.y}
	       if Free then {Player move(pos(x:@NewPos.x y:@NewPos.y) right)}
	       else skip
	       end
	    end
	 else skip
	 end
	 {CheckPos OldPos}
	 {CheckItem Player @NewPos}
	 if @Star == nil then skip
	 elseif @Star.x == @NewPos.x andthen @Star.y == @NewPos.y then
	    {System.showInfo 'SUPERPOWER'}
	    {Player star()}
	    Star := nil
	 else skip
	 end
      end
   end

   proc{CheckPos OldPos}
      proc{Check Obj}
	 local Pos Type in
	    {Obj getValue('pos' Pos)}
	    if Pos.x == OldPos.x andthen Pos.y == OldPos.y then {Obj getValue('type' Type)}
	       if Type == 'Bomb' then
		  local Power Name in
		     {Obj getValue('power' Power)}
		     {Obj getValue('name' Name)}
		     {G bomb(Name Power Pos.x Pos.y)}
		  end
	       else
		  local Name in
		     {Obj getValue('name' Name)}
		     {G player(Name Pos.x Pos.y)}
		  end
	       end
	    else skip
	    end
	 end
      end
   in
      {List.forAll @InitPlayers Check}
      case @Bomblist of nil then skip
      else {List.forAll @Bomblist Check}
      end
   end

   proc{CheckItem Player Pos}
      proc{Check Player List Head}
	 case List of nil then skip
	 [] H|T then
	    if H.x == Pos.x andthen H.y == Pos.y then
	       case Player of nil then skip
	       else
		  local Name in
		     {Player getValue('name' Name)}
		     {Player eat()}
		     {System.showInfo Name#' ate food...'}
		  end
	       end
	       case Head of nil then FoodList := T
	       else FoodList := Head|T
	       end
	    else
	       case Head of nil then {Check Player T H}
	       else {Check Player T Head|H}
	       end
	    end
	 else skip
	 end
      end
   in
      {Check Player @FoodList nil}
   end

   % Creation of players
   % locks and threads
   proc {God} Name1 Name2 Mod
      fun {Spawn Names}
	 case Names of nil then nil
	 [] H|T then {New BMan init(H)}|{Spawn T}
	 end
      end
      proc {Place Player}
	 local Name Pos in
	    {Player getValue('name' Name)}
	    {Player getValue('pos' Pos)}
	    {System.showInfo Name#' spawned at ('#Pos.x#','#Pos.y#')'}
	    {G player(Name Pos.x Pos.y)}
	 end
      end
   in
      Name1 = {GUI.getText '(BLUE) Write player 1\'s name:'}
      Name2 = {GUI.getText '(RED)  Write player 2\'s name:'}
      {System.showInfo 'Saving names...'}
      {GUI.showKeys}

      if Name1 == Name2 then {GUI.initPNames Name1|Name2#'2'|nil}
      else {GUI.initPNames Name1|Name2|nil}
      end      % Init the GUI
      {System.showInfo 'Map creation...'}
      G = {GUI.create init(h:Args.height w:Args.width handler:Handler)}
      Mod = {OS.rand} mod (HEIGHT + WIDTH) + HEIGHT

      for N in 1..Mod do
	 local Pos in
	    Pos = {IteratePlace}
	    Walls := {New Wall init(pos(x:Pos.x y:Pos.y))}|@Walls
	    {G img('Wall' Pos.x Pos.y)}
	 end
      end
      {System.showInfo 'Walls built'}
      if Name1 == Name2 then InitPlayers := {Spawn Name1|Name2#'2'|nil}
      else InitPlayers := {Spawn Name1|Name2|nil}
      end

      {List.forAll @InitPlayers Place}
      {System.showInfo 'Let\'s play !'}
   end
   {System.showInfo '**************************'}
   {System.showInfo '* WELCOME IN BOMBERMAN ! *'}
   {System.showInfo '**************************'}

   {System.showInfo 'Initializing players...'}
   {God}
   thread {SpawnFood} end
   thread {SpawnStar} end
end
