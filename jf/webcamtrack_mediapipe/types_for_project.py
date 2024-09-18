from typing import List, Tuple, Callable, Any, TypeAlias

import numpy as np

OSCAddr: TypeAlias = str
OSCData: TypeAlias = List[float] | float | np.array

Landmarks: TypeAlias = Any

CVImage: TypeAlias = Any

RelativeInfoGatherer: TypeAlias = Callable[[Landmarks], None]
DataExtractor: TypeAlias = Callable[[Landmarks, RelativeInfoGatherer], OSCData]

DataExtractorList: TypeAlias = List[Tuple[OSCAddr, DataExtractor]]

LandmarkRelay: TypeAlias = Callable[[Landmarks], None]
VideoProcessor: TypeAlias = Callable[[CVImage, Landmarks], bool]
