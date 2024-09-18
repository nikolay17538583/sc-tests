import time
from typing import List

from .relative_info import RelativeInfoGatherer


class NodIdentifier:
    def __init__(self, moving_threshold: float = 0.25, stillness_threshold: float = 0.25):
        self.cur_state: int = 0
        self.triggered: bool = False
        self.moving_threshold: float = moving_threshold
        self.stillness_threshold: float = stillness_threshold
        self.start_time_of_current_state: float = time.perf_counter()

        self.reset_time()
        self.reset_state()

    def advance_state(self):
        self.cur_state += 1
        self.start_time_of_current_state = time.perf_counter()
        print(self.cur_state)
        if self.cur_state > 4:
            print("\t\tGot a Nod!!!!")
            self.triggered = True
            self.cur_state = 0

    def reset_state(self):
        self.cur_state = 0

    def reset_time(self):
        self.start_time_of_current_state = time.perf_counter()

    def state0(self, delta: float, time_spent_here: float) -> None:
        # advance if still - before nod
        if (-self.stillness_threshold < delta < self.stillness_threshold) and (0.0 < time_spent_here):
            self.cur_state = 1

    def state1(self, delta: float, time_spent_here: float) -> None:
        # advance if moving upwards for at least some time - upward
        if self.moving_threshold < delta and (0.1 < time_spent_here):
            self.advance_state()
        # continue stillness
        elif -self.stillness_threshold < delta < self.stillness_threshold:
            pass
        else:
            self.reset_state()

    def state2(self, delta: float, time_spent_here: float) -> None:
        # advance if still - peak of nod
        if (-self.stillness_threshold < delta < self.stillness_threshold) and (0.1 < time_spent_here < 2):
            self.advance_state()
        # continue moving upwards
        elif (delta > self.moving_threshold) and (time_spent_here < 2):
            pass
        else:
            self.reset_state()
            self.reset_time()

    def state3(self, delta: float, time_spent_here: float) -> None:
        # advance if moving down for within range
        if (delta < -self.moving_threshold) and (0.1 < time_spent_here < 2.0):
            self.advance_state()
        # continue wait at peak
        elif (-self.stillness_threshold < delta < self.stillness_threshold) and (time_spent_here < 1.5):
            pass
        else:
            self.reset_state()
            self.reset_time()

    def state4(self, delta: float, time_spent_here: float) -> None:
        # floor of nod
        if -self.stillness_threshold < delta < self.stillness_threshold:
            self.advance_state()
        elif time_spent_here < 0.75:
            pass
        else:
            self.reset_state()
            self.reset_time()

    def track_state(self, delta: float) -> List[float]:
        self.triggered = False
        time_spent_here = time.perf_counter() - self.start_time_of_current_state
        match self.cur_state:
            case 0:
                self.state0(delta, time_spent_here)
            case 1:
                self.state1(delta, time_spent_here)
            case 2:
                self.state2(delta, time_spent_here)
            case 3:
                self.state3(delta, time_spent_here)
            case 4:
                self.state4(delta, time_spent_here)
            case _:
                self.reset_state()
                self.reset_time()

        return [self.cur_state / 5, float(self.triggered)]

    def calc_delta(self, landmark, rel: RelativeInfoGatherer) -> float:
        pass

    def __call__(self, landmark, rel: RelativeInfoGatherer):
        return self.track_state(self.calc_delta(landmark, rel))
