import numpy as np

from .nod_identifier import NodIdentifier
from .positions import LeftEyebrow, RightEyebrow
from .relative_info import RelativeInfoGatherer


class NodEyebrows(NodIdentifier):
    def __init__(self, moving_threshold: float = 0.20, stillness_threshold: float = 0.15):
        super().__init__(moving_threshold, stillness_threshold)
        self.left_brow = LeftEyebrow()
        self.right_brow = RightEyebrow()
        self.prev_value = 0

    def calc_delta(self, landmark, rel: RelativeInfoGatherer) -> float:
        lb = self.left_brow(landmark, rel)
        rb = self.right_brow(landmark, rel)

        def get_offset(i) -> float:
            return ((lb[i] + rb[i]) / 2) - rel.centre[i]

        brow_av: float = np.linalg.norm(
            np.array(
                [get_offset(i) for i in range(0, 3)]
            )
        )

        delta: float = brow_av - self.prev_value
        self.prev_value = brow_av
        return delta
