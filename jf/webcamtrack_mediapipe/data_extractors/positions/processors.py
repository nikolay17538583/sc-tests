import mediapipe.python.solutions.face_mesh_connections as fmc

from .base import PositionsBase


class Forehead(PositionsBase):
    def __init__(self, debug: bool = False):
        super().__init__([10], debug)


class BottomLip(PositionsBase):
    def __init__(self, debug: bool = False):
        super().__init__([15], debug)


class TopLip(PositionsBase):
    def __init__(self, debug: bool = False):
        super().__init__([12], debug)


class LeftEyebrow(PositionsBase):
    def __init__(self, debug: bool = False):
        super().__init__([e[0] for e in fmc.FACEMESH_LEFT_EYEBROW], debug)


class RightEyebrow(PositionsBase):
    def __init__(self, debug: bool = False):
        super().__init__([e[0] for e in fmc.FACEMESH_RIGHT_EYEBROW], debug)


class LeftEye(PositionsBase):
    def __init__(self, debug: bool = False):
        super().__init__([e[0] for e in fmc.FACEMESH_LEFT_EYE], debug)


class RightEye(PositionsBase):
    def __init__(self, debug: bool = False):
        super().__init__([e[0] for e in fmc.FACEMESH_RIGHT_EYE], debug)


class Nose(PositionsBase):
    def __init__(self, debug: bool = False):
        super().__init__([1, 4, 5], debug)
