JHCheckUDPListeningPort {
	*new { |netaddr|
		thisProcess.openUDPPort(netaddr.port).not.if({
			format("Could not open udp port : %\n Here is a list of potentially offending applications: \n %",
				netaddr,
				format("lsof | grep %", netaddr.port).unixCmdGetStdOut
			).throw;
			Server.killAll;
		});
	}
}