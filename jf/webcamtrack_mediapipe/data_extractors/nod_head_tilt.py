from .nod_identifier import NodIdentifier
from .relative_info import RelativeInfoGatherer


class NodHeadTilt(NodIdentifier):
    def __init__(self, moving_threshold: float = 0.10, stillness_threshold: float = 0.6):
        super().__init__(moving_threshold, stillness_threshold)
        self.prev_tilt = 0

    def calc_delta(self, landmark, rel: RelativeInfoGatherer) -> float:
        t = (landmark[8].z - landmark[0].z) * rel.scale
        delta = t - self.prev_tilt
        self.prev_tilt = t
        return delta
