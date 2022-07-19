functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   OS
   Application
   System
export
   Create
   GetText
   ShowKeys
   InitPNames
define
   PNames

   fun {NewActive Class Init}
      Obj = {New Class Init}
      P
   in
      thread S in
	 {NewPort S P}
	 for M in S do {Obj M} end
      end
      proc {$ M} {Send P M} end
   end

   class Gui
      attr grid
	 scorea scoreb powera powerb
	 playera playerb bg
      meth init(h:H w:W handler:Handler <= proc {$ K} skip end)
	 CD = {OS.getCWD}
	 Grid ScoreA ScoreB PowerA PowerB
	 Window = {QTk.build td(
				grid(handle:Grid bg:white)
				td(lr(label(text:@PNames.1) label(text:"Score: ") label(text:"0" handle:ScoreA) label(text:"Power: ") label(text:"1" handle:PowerA))
				   lr(label(text:@PNames.2.1) label(text:"Score: ") label(text:"0" handle:ScoreB) label(text:"Power: ") label(text:"1" handle:PowerB))
				   button(text:"Quit" action:proc {$} {Application.exit 0} end)
				  )
				)}
      in
	 {Window bind(event:"<KeyPress>" args:[atom('A')] action:Handler)}
	 {Window show}
	 for I in 1..H-1 do
	    {Grid configure(lrline column:1 columnspan:W+W-1 row:I*2 sticky:we)}
	 end
	 for I in 1..W-1 do
	    {Grid configure(tdline  row:1 rowspan:H+H-1 column:I*2 sticky:ns)}
	 end
	 for I in 1..W do
	    {Grid columnconfigure(I+I-1 minsize:43)}
	 end
	 for I in 1..H do
	    {Grid rowconfigure(I+I-1 minsize:43)}
	 end
	 grid := Grid
	 scorea := ScoreA
	 scoreb := ScoreB
	 powera := PowerA
	 powerb := PowerB
	 playera :=  {QTk.newImage photo(file:CD#'/blueB1.gif')}
	 playerb := {QTk.newImage photo(file:CD#'/redB1.gif')}
	 bg := {QTk.newImage photo(file:CD#'/white.gif')}
      end

      meth player(Name X Y) Img in
	 if Name == @PNames.1 then
	    Img = @playera
	 else
	    Img = @playerb
	 end
	 {@grid configure(label(image:Img borderwidth:0) row:X+X-1 column:Y+Y-1)}
      end

      meth movePlayer(Name X Y Dir) Img in
	 if Name == @PNames.1 then
	    case Dir of up then Img = {QTk.newImage photo(file:{OS.getCWD}#'/blueT1.gif')}
	    [] down then Img = {QTk.newImage photo(file:{OS.getCWD}#'/blueB1.gif')}
	    [] left then Img = {QTk.newImage photo(file:{OS.getCWD}#'/blueL1.gif')}
	    else Img = {QTk.newImage photo(file:{OS.getCWD}#'/blueR1.gif')}
	    end
	 else
	    case Dir of up then Img = {QTk.newImage photo(file:{OS.getCWD}#'/redT1.gif')}
	    [] down then Img = {QTk.newImage photo(file:{OS.getCWD}#'/redB1.gif')}
	    [] left then Img = {QTk.newImage photo(file:{OS.getCWD}#'/redL1.gif')}
	    else Img = {QTk.newImage photo(file:{OS.getCWD}#'/redR1.gif')}
	    end
	 end
	 {@grid configure(label(image:Img borderwidth:0) row:X+X-1 column:Y+Y-1)}
      end

      meth score(Name X) S in
	 if Name == @PNames.1 then
	    S = @scorea
	 else
	    S = @scoreb
	 end
	 {S set(""#X)}
      end

      meth power(Name X) S in
	 {System.showInfo 'Powering'}
	 if Name == @PNames.1 then
	    S = @powera
	 else
	    S = @powerb
	 end
	 {S set(""#X)}
      end

      meth bomb(Name Level X Y) Img in
	 if Name == @PNames.1 then
	    Img = {QTk.newImage photo(file:{OS.getCWD}#'/bombB'#Level#'.gif')}
	 else
	    Img = {QTk.newImage photo(file:{OS.getCWD}#'/bombR'#Level#'.gif')}
	 end
	 {@grid configure(label(image:Img borderwidth:0) row:X+X-1 column:Y+Y-1)}
      end

      meth img(ImgPath X Y)
	 {@grid configure(label(image:{QTk.newImage photo(file:{OS.getCWD}#'/'#ImgPath#'.gif')} borderwidth:0) row:X+X-1 column:Y+Y-1)}
      end

      meth reset(X Y)
	 {@grid configure(label(image:@bg borderwidth:0) row:X+X-1 column:Y+Y-1)}
      end
   end

   % Text entry from reference book
   fun {GetText A} H T D W in
      D = td(lr(label(text:A) entry(handle:H))
	     button(text:"Ok"
		    action:proc {$} T = {H get($)} {W close} end))
      W = {QTk.build D}
      {W show} {W wait}
      T
   end

   proc {ShowKeys} W in
      W = {QTk.build
          lr(label(text:"RED PLAYER") newline
            label(text:"Place bomb:")
            button(text:"A" glue:we) empty empty newline
            label(text:"Direction:")
            empty button(text:"Z" glue:we) empty newline
            empty button(text:"Q" glue:we) button(text:"S" glue:we) button(text:"D" glue:we) newline

            label(text:"BLUE PLAYER") newline
            label(text:"Place bomb:")
            empty empty button(text:"ENTER" glue:we) newline
            label(text:"Direction:")
            empty button(text:"UP" glue:we) empty newline
            empty button(text:"LEFT" glue:we) button(text:"DOWN" glue:we) button(text:"RIGHT" glue:we))}
      {W show} {W wait}
   end

   fun {Create Init}
      {NewActive Gui Init}
   end

   proc {InitPNames Names}
      PNames = {NewCell nil}
      PNames := Names
   end
end
