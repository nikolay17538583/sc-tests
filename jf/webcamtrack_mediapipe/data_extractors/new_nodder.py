import time
from enum import Enum
from typing import List

from .relative_info import RelativeInfoGatherer


class State(Enum):
    Before = 0
    Nodding = 1

    def __int__(self):
        return self.value


class NewNodder:
    def __init__(self):
        self.cur_state: State = State.Before
        self.triggered: bool = False
        self.prev_tilt = 0
        self.start_time_of_current_state: float = time.perf_counter()
        self.i = 0
        self.ii = 0

    def calc_delta(self, landmark, rel: RelativeInfoGatherer) -> float:
        t = (landmark[8].z - landmark[0].z) * rel.scale
        delta = (t - self.prev_tilt) * 10
        self.prev_tilt = t
        self.i += delta  # integrate
        self.ii += self.i
        return delta

    def reset_integrals(self):
        self.i = 0
        self.ii = 0

    def reset(self, delta: float = 0.1):
        print("resetting ", self.cur_state, self.i, self.ii)
        self.start_time_of_current_state = time.perf_counter()
        self.cur_state: State = State.Before
        self.reset_integrals()

    def advance(self):
        self.start_time_of_current_state = time.perf_counter()
        old_state = self.cur_state
        match self.cur_state:
            case State.Before:
                self.cur_state = State.Nodding
            case State.Nodding:
                # print("\t\t\t\tGOT A NOD", self.i, self.ii)
                self.cur_state = State.Before
                self.triggered = True
                self.reset()

        # print("old state: ", old_state, " new state: ", self.cur_state, self.i, self.ii)

    def is_still(self, delta: float):
        return -2.5 < delta < 2.5

    def moving_up(self, delta: float):
        return 3 < self.i

    def moving_down(self, delta: float):
        return -3 > self.i

    def from_before(self, delta: float, t: float):
        if self.i > 4 and 0.5 < t:
            self.advance()
        elif t < 2:
            pass  # tick time
        else:
            self.reset_integrals()

    def looking_for_nod(self, delta: float, t: float):
        if self.i < 2 and 0.25 < t and self.ii > 10: # i and ii and the same - 
            self.advance()
        elif t < 5:  # max dur of nod
            pass
        else:
            self.reset()

    def track_state(self, delta: float) -> List[float]:
        self.triggered = False
        time_spent_here = time.perf_counter() - self.start_time_of_current_state
        match self.cur_state:
            case State.Before:
                self.from_before(delta, time_spent_here)

            case State.Nodding:
                self.looking_for_nod(delta, time_spent_here)

        return [int(self.cur_state) / 2, float(self.triggered)]

    def __call__(self, landmark, rel: RelativeInfoGatherer):
        return self.track_state(self.calc_delta(landmark, rel))
