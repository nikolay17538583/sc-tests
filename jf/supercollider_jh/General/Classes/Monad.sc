Future {
	var functionSequence, <>finalValue, dispatchCond;
	classvar <>defaultTimeOut=10;

	*getFuncType {
		|f|
		var args = f.def.argNames;
		if(args.size() == 2, {
			if( (args[1] == \return) && (args[0] == \value), {^\returnWithValue})
		});
		if(args.size() == 1, {
			if(f.def.argNames[0] == \return, {^\return}, {^\normal});
		});
		if(f.def.argNames.size() == 0,	{^\normal});
		^\invalid;
	}


	*new { |f| ^super.newCopyArgs(if(f.isKindOf(Function), [f], {[f]} ), nil) }

	dispatch {
		dispatchCond = CondVar();
		fork {
			finalValue = functionSequence.inject(nil, {
				|prev, nextFunc|
				case
				{nextFunc.isKindOf(Function)}  {
					switch(Future.getFuncType(nextFunc),
						\returnWithValue, {
							var cond = CondVar();
							var done = false;
							var result;
							nextFunc.(prev, {|return| result = return; done = true; cond.signalOne; });
							cond.waitFor(Future.defaultTimeOut, {done});
							result;
						},
						\return, {
							var cond = CondVar();
							var done = false;
							var result;
							nextFunc.({|return| result = return; done = true; cond.signalOne; });
							cond.waitFor(Future.defaultTimeOut, {done});
							result;
						},
						\normal, { nextFunc.(prev) },
						{"invalid func".error}
				)}
				{nextFunc.isKindOf(Future)} {nextFunc.value()};
			});
			dispatchCond.signalOne;
		}
	}

	value {
		if(dispatchCond.isNil, {
			this.dispatch()
		});
		dispatchCond.wait({finalValue.isNil.not});
		^finalValue;
	}

	>>= { |f|
		if(Future.getFuncType(f) != \invalid, {functionSequence = functionSequence ++ [f]});
		^this;
	}
}


/*
(
~do_something = {|v| postf("the result is: %\n", v)};

fork {
	~futureA = Future({1})
	>>= (_ + 2)
	>>= {|value, return| postf("waiting for %\n", value); value.wait; return.("hello")}
	>>= (_ + "mum")
	>>= _.split($ )
	>>= {|value, return| "wait for 1".postln; 1.wait; return.(value ++ ["I'm"])}
	>>= (_ ++ ["egg"]);

	"A".warn;
	~futureA.dispatch(); // will dispatch but not wait
	// do something else here...


	"B".warn;
	~futureB = Future(~futureA) >>= _.swap(1,3) >>= {|value, return| 3.wait; return.(value)}; // does not wait
	"C".warn;

	postf("c is %\n", ~futureA.value()); // waits for futureA

	~do_something.(~futureA.value()); // does not wait as already calculated
	"D".warn;

	~futureB.value().postln; // waits for futureB
}
)
*/


/*

Monad {
var <>held;
*new { |v|
^super.newCopyArgs(if(v.isKindOf(Monad),{v.held},{v}) ).prMonadCheck
}
*unhold { |args|
^args.collect{ |a| if(a.isMemberOf(Just), {a.held}, {a}) }
}

getHeld {
^held
}

bind {|f| ^(this >>= f) }
mutate {|f| this >>= f; ^this }
otherwise {|f| ^(this <! f) }
bindMatching {|f| ^(this | f) }
mutateMatching {|f| (this >> f); ^this }

>>= { |f|
^held !? { this.prThenWithHeld(f) } ?? { this.prThenWithNil(f) }
} // then / bind

<! { |f| ^if(this.class == Nothing, {this.prThenWithHeld(f)}, {this}) } // otherwise / else

>> {
|ar|
var funcAr = ar.clump(2).detect({ |a|
if(a[0].isKindOf(Function),
{a[0].value(this.held)}, // for some reason this fails...?
{this.held.isKindOf(a[0])})
});
var func = funcAr[1];
var result = func.value(this.getHeld());
^if(Nothing.isNothing(result), {Nothing()}, {Just(result)})
}

doesNotUnderstand {
|selector ...args|
args.detect(Nothing.isNothingExNil).isNil.not.if( {^Nothing()} );
// if there is a nothing in the args, return nothing
^held !? {   Monad(this.getHeld().perform(selector, *Monad.unhold(args)))   } ?? {   Nothing()   };
}


prMonadCheck {
^if(held.isNil,
{   if(this.class == Nothing, {this}, {Nothing()})   },
{   if(this.class == Just, {this}, {Just(this)})   })
}
prThenWithNil {
|f|
^if(f.isKindOf(Function),
{   if(f.def.argNames.size == 0, {f.()}, {this})   },
{   f !? {Just(f)} ?? {Nothing()}     })
}
prThenWithHeld {
|f|
var is_awaitable = f.def.argNames.includes(\return);

var result = if(is_awaitable, {Awaitable(10, {|return| f.( this.getHeld(), return)} )  }, {f.(this.getHeld())});
^if(result.isKindOf(Monad),
{   result   },
{   if(Nothing.isNothing(result), {Nothing()}, {Just(result)})   })

}

}

Just : Monad {
get {^held}
}

Nothing : Monad {
*isNothing{ |n| ^n.isMemberOf(Nothing) || ( n == Nothing ) || n.isNil }
*isNothingExNil{ |n| ^n.isMemberOf(Nothing) || ( n == Nothing )}
}

AsyncTimeoutError : Error {
errorString { ^"Function.await: timeout." }
}

Awaitable : Monad {
var <>timeout, cond;
*new {
|timeout, func|
^super.newCopyArgs(func, timeout, CondVar());
}
getHeld {
if(held.isKindOf(Function),
{
var res;
var done = false;
held.value({
|result|
res = result;
done=true;
cond.signalOne;
});
if(timeout.isNil,
{ cond.wait({done}) },
{ cond.waitFor(timeout, {done}) });
if(done.not, { AsyncTimeoutError().throw } );
^res.unbubble;
}
)
}
}



*/


































