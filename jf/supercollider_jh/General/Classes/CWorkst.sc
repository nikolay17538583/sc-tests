Velocity : Point {}
Agent {
    var <position, velocity;

	*new { | position, velocity |
		^super.newCopyArgs(position ? Point(), velocity ? Velocity());
    }

    update { | dt |
        position = position + velocity * dt;
    }
}