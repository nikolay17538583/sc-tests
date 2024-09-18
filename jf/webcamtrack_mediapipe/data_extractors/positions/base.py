from typing import List

from ..util import average_3d_pos


class PositionsBase:
    def __init__(self, indexes: List[int], debug: bool = False):
        self.debug = debug
        self.indexes = indexes
        self.min: List[float] = [0, 0, 0]
        self.max: List[float] = [0, 0, 0]

    def __call__(self, landmark, rel) -> List[float]:
        result: List[float] = [d * rel.get_scale() * 0.01 for d in average_3d_pos(landmark, self.indexes)]
        if self.debug:
            print(result)

        self.min = [min(m, r) for m, r in zip(self.min, result)]
        self.max = [max(m, r) for m, r in zip(self.max, result)]

        result = [(r - mi) / (ma - mi) for r, mi, ma in zip(result, self.min, self.max)]

        return result
