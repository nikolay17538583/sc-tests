JHImport {
	*new { |path|
		^thisProcess.interpreter.compileFile(path).();
	}
}


