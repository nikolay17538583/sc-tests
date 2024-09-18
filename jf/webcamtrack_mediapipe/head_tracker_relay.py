from pythonosc import udp_client

import types_for_project as tp


class HeadTrackerRelay:
    def __init__(self,
                 ip: str,
                 port: int,
                 relative_info_gatherer: tp.RelativeInfoGatherer,
                 addr_func_pair: tp.DataExtractorList):
        self.socket = udp_client.SimpleUDPClient(ip, port)
        self.addr_func_pair = addr_func_pair
        self.relative_info_gatherer = relative_info_gatherer

    def __call__(self, landmark):
        self.relative_info_gatherer(landmark)
        for p in self.addr_func_pair:
            self.socket.send_message(p[0], p[1](landmark, self.relative_info_gatherer))
