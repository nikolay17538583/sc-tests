from typing import List

from .positions import Nose
from .util import get_scale_factor


class RelativeInfoGatherer:
    def __init__(self, iris_distance: float = 6):
        self.scale: float = 0
        self.iris_distance: float = iris_distance
        self.centre: List[float] = [0, 0, 0]

        self.nose = Nose()

    def __call__(self, landmark) -> None:
        self.scale = float(get_scale_factor(landmark, self.iris_distance))
        self.centre = self.nose(landmark, self)

    def get_scale(self) -> float:
        return self.scale

    def get_centre(self) -> List[float]:
        return self.centre
