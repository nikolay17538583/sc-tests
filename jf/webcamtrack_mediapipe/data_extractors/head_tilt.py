from .relative_info import RelativeInfoGatherer


class HeadTilt:
    def __init__(self):
        pass

    def __call__(self, landmark, rel: RelativeInfoGatherer):
        return (landmark[8].z - landmark[0].z) * rel.get_scale()
