+Object {
	|> { |f| ^f.(this) 	}
	<| { |f|
		^if(f.isKindOf(Function),
			{ {|...i| this.( f.(*i) )} },
			{ this.(f) })
	}


	*|> {|f| ^f.(*this) }
	<|* {|f|
		^if(f.isKindOf(Function),
			{ {|i| this.( f.(*i) )} },
			{ this.(*f) })
	}


}