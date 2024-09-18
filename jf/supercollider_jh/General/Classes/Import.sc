Import {
	*new {|path| ^thisProcess.interpreter.compileFile(path).()	}
}