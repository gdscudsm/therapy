from random import randint
import time
import cv2
import mediapipe as mp
import math
import numpy as np
import datetime
from google.cloud import firestore


class HandDetector:
    """
    Finds Hands using the mediapipe library. Exports the landmarks
    in pixel format. Adds extra functionalities like finding how
    many hands are on screen or the distance of the hand from the screen.
    """

    def __init__(self, mode=False, maxHands=7, model_complexity=0, detectionCon=0.5, minTrackCon=0.5):
        """
        :param mode: In static mode, detection is done on each image, this is slower
        :param maxHands: Maximum number of hands to detect
        :param detectionCon: Minimum Detection Confidence 
        :param minTrackCon: Minimum Tracking Confidence
        """
        self.mode = mode
        self.maxHands = maxHands
        self.detectionCon = detectionCon
        self.minTrackCon = minTrackCon
        self.model_complexity = model_complexity

        self.mpHands = mp.solutions.hands
        self.hands = self.mpHands.Hands(static_image_mode=self.mode, max_num_hands=self.maxHands,
                                        model_complexity=self.model_complexity, min_detection_confidence=self.detectionCon,
                                        min_tracking_confidence=self.minTrackCon)
        self.mpDraw = mp.solutions.drawing_utils
        self.tipIds = [4, 8, 12, 16, 20]
        self.fingers = []
        self.lmList = []
        self.x = [300, 245, 200, 170, 145, 130, 112,
                  103, 93, 87, 80, 75, 70, 67, 62, 59, 57]
        self.y = [20, 25, 30, 35, 40, 45, 50, 55,
                  60, 65, 70, 75, 80, 85, 90, 95, 100]
        self.A, self.B, self.C = np.polyfit(self.x, self.y, 2)

    def findHands(self, img, draw=True, flipType=True):
        """
        Finds hands in a BGR image.
        :param img: Image to find the hands in.
        :param draw: Flag to draw the output on the image.
        :return: Image with or without drawings
        """
        imgRGB = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        self.results = self.hands.process(imgRGB)
        allHands = []
        h, w, c = img.shape
        if self.results.multi_hand_landmarks:
            for handType, handLms in zip(self.results.multi_handedness, self.results.multi_hand_landmarks):
                myHand = {}

                mylmList = []
                xList = []
                yList = []
                for id, lm in enumerate(handLms.landmark):
                    px, py = int(lm.x * w), int(lm.y * h)
                    mylmList.append([px, py])
                    xList.append(px)
                    yList.append(py)

                # bound box
                xmin, xmax = min(xList), max(xList)
                ymin, ymax = min(yList), max(yList)
                boxW, boxH = xmax - xmin, ymax - ymin
                bbox = xmin, ymin, boxW, boxH
                cx, cy = bbox[0] + (bbox[2] // 2), \
                    bbox[1] + (bbox[3] // 2)

                myHand["lmList"] = mylmList
                myHand["bbox"] = bbox
                myHand["center"] = (cx, cy)

                if flipType:
                    if handType.classification[0].label == "Right":
                        myHand["type"] = "Left"
                    else:
                        myHand["type"] = "Right"
                else:
                    myHand["type"] = handType.classification[0].label
                allHands.append(myHand)

                # draw
                if draw:
                    self.mpDraw.draw_landmarks(img, handLms,
                                               self.mpHands.HAND_CONNECTIONS)
                    cv2.rectangle(img, (bbox[0] - 20, bbox[1] - 20),
                                  (bbox[0] + bbox[2] + 20,
                                   bbox[1] + bbox[3] + 20),
                                  (255, 0, 255), 2)
                    cv2.putText(img, myHand["type"], (bbox[0] - 30, bbox[1] - 30), cv2.FONT_HERSHEY_PLAIN,
                                2, (255, 0, 255), 2)
        if draw:
            return allHands, img
        else:
            return allHands

    def findDistanceCM(self, p1, p2):
        """
        Find the distance from the screen based on two landmarks.
        :param p1: Point1
        :param p2: Point2
        :return: Distance of the hand from the screen
        """

        x1, y1 = p1
        x2, y2 = p2
        length = math.hypot(x2 - x1, y2 - y1)
        return round(self.A*length**2 + self.B*length + self.C, 2)

    def getCoordinate(self, landmark_index, img=None, draw=False):
        """
        Get the coordinate of a landmark based on its
        index numbers.
        :param landmark_index: Index of the landmark
        """
        x, y = landmark_index
        if draw:
            cv2.circle(img, (x, y), 7, (255, 255, 255), cv2.FILLED)
            return (x, y), img
        else:
            return (x, y)

    def howManyHands(self, hand: list):
        """
        Getting how many hands are on the screen. Default maximum number is 7
        :param hand: first object returned on findHands() function
        """
        return len(hand)


class Exercise:
    def __init__(self, initial0=None, initial12=None, center=None, change=None):
        self.initial0 = initial0
        self.initial12 = initial12
        self.change = change
        self.side_value = 120
        self.uploader = 0
        self.upload_avr = []
        self.avr_left_controller = None
        self.avr_right_controller = None
        self.average_change = 0
        self.score_list = []
        self.start_time = None
        self.side_done = False
        self.keys = {
            0: "bad",
            1: "trying",
            2: "nice",
            3: "very good"
        }

    def fluctuation(self, new, old):
        return (abs(new[0] - old[0]) + abs(new[1] - old[1])) // 2

    def handSeenWell(self, index0, index12):
        if abs(index12[1] - index0[1]) <= 15:
            return False
        return True

    def wristSideToSide(self, index0, index12, dista):
        if self.handSeenWell(index0, index12):
            if dista > 100:
                self.side_value = 100
            elif dista > 50 and dista < 100:
                self.side_value = 120
            else:
                self.side_value = 160

            if self.initial0 == None and self.initial12 == None:
                self.initial0 = index0[0]
                self.initial12 = index12[0]

            # The hand is on the same position and not moving the whole hand
            if index0[0] in list(range(self.initial0 - 20, self.initial0 + 21)):

                self.change = abs(self.initial12 - index12[0])

                if len(self.upload_avr) >= 5:
                    self.uploader = sum(
                        self.upload_avr) // (len(self.upload_avr) - 1)

                    self.upload_avr = []

                    return self.keys[self.uploader]

                elif len(self.score_list) >= 3:
                    score = round(
                        ((sum(self.score_list) // len(self.score_list)) / 160) * 100, 3)
                    self.score_list = []
                    return score

                # Going Right side
                if index12[0] > self.initial12:

                    # Appending to array of 5 movements
                    if self.avr_right_controller != None:
                        self.upload_avr.append(self.avr_right_controller)
                        self.score_list.append(self.average_change)
                        self.avr_right_controller = None
                        self.average_change = 0
                        self.side_done = False

                    # Checking how far
                    if self.change >= 5 and self.change <= 20:
                        if self.start_time == None and self.side_done == False:
                            self.start_time = time.time()

                        if self.avr_left_controller == None:
                            self.avr_left_controller = 0

                        elif self.avr_left_controller <= 0:
                            self.avr_left_controller = 0

                        if self.average_change <= self.change:
                            self.average_change = self.change
                        elif self.change + 5 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif self.change > 20 and self.change <= self.side_value - 40:
                        if self.avr_left_controller == None:
                            self.avr_left_controller = 1
                            self.average_change = self.change
                        elif self.avr_left_controller <= 1:
                            self.avr_left_controller = 1
                            self.average_change = self.change

                        if self.average_change <= self.change:
                            self.average_change = self.change
                        elif self.change + 5 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif self.change > self.side_value - 40 and self.change <= self.side_value:
                        if self.avr_left_controller == None:
                            self.avr_left_controller = 2
                            self.average_change = self.change
                        elif self.avr_left_controller <= 2:
                            self.avr_left_controller = 2
                            self.average_change = self.change

                        if self.average_change <= self.change:
                            self.average_change = self.change
                        elif self.change + 5 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif self.change > self.side_value:
                        if self.avr_left_controller == None:
                            self.avr_left_controller = 3
                            self.average_change = self.change
                        elif self.avr_left_controller <= 3:
                            self.avr_left_controller = 3
                            self.average_change = self.change

                        if self.average_change <= self.change:
                            self.average_change = self.change
                        elif self.change + 5 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                # Going Left side
                elif index12[0] < self.initial12:

                    # Appending to array of 5 movements
                    if self.avr_left_controller != None:
                        self.upload_avr.append(self.avr_left_controller)
                        self.score_list.append(self.average_change)
                        self.avr_left_controller = None
                        self.average_change = 0
                        self.side_done = False

                    # Checking how far
                    if self.change >= 5 and self.change <= 20:
                        if self.start_time == None and self.side_done == False:
                            self.start_time = time.time()

                        if self.avr_right_controller == None:
                            self.avr_right_controller = 0
                        elif self.avr_right_controller <= 0:
                            self.avr_right_controller = 0

                        if self.average_change <= self.change:
                            self.average_change = self.change
                        elif self.change + 5 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif self.change > 20 and self.change <= self.side_value - 40:
                        if self.avr_right_controller == None:
                            self.avr_right_controller = 1
                        elif self.avr_right_controller <= 1:
                            self.avr_right_controller = 1

                        if self.average_change <= self.change:
                            self.average_change = self.change
                        elif self.change + 5 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif self.change > self.side_value - 40 and self.change <= self.side_value:
                        if self.avr_right_controller == None:
                            self.avr_right_controller = 2
                        elif self.avr_right_controller <= 2:
                            self.avr_right_controller = 2

                        if self.average_change <= self.change:
                            self.average_change = self.change
                        elif self.change + 5 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif self.change > self.side_value:
                        if self.avr_right_controller == None:
                            self.avr_right_controller = 3
                        elif self.avr_right_controller <= 3:
                            self.avr_right_controller = 3

                        if self.average_change <= self.change:
                            self.average_change = self.change
                        elif self.change + 5 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

            else:
                self.initial0, self.initial12 = None, None
                self.start_time = None
                self.side_done = True
                end_time = 0
                return "Whole hand movement"

        else:
            return "Hand position"

    def checkUpAndDown(self, index4, index8, index12, index16, index20):
        if index4[1] < index8[1] and index8[1] < index12[1] and index12[1] < index16[1] and index16[1] < index20[1]:
            return True
        return False

    def wristUpAndDown(self, index0, index4, index8, index12, index16, index20, handType):

        dista = abs(index0[0] - index12[0])

        if self.checkUpAndDown(index4, index8, index12, index16, index20):

            if handType == "Right":
                if len(self.upload_avr) >= 5:
                    self.uploader = sum(
                        self.upload_avr) // (len(self.upload_avr) - 1)

                    self.upload_avr = []

                    return self.keys[self.uploader]

                elif len(self.score_list) >= 3:
                    score = round(
                        ((sum(self.score_list) // len(self.score_list)) / 200) * 100, 3)
                    self.score_list = []
                    return score

                if index12[0] > index0[0]:

                    # Appending to array of 5 movements
                    if self.avr_right_controller != None:
                        self.upload_avr.append(self.avr_right_controller)
                        self.score_list.append(self.average_change)
                        self.avr_right_controller = None
                        self.average_change = 0
                        self.side_done = False

                    # Checking how far
                    if dista > 6 and dista <= 100:
                        if self.start_time == None and self.side_done == False:
                            self.start_time = time.time()

                        if self.avr_left_controller == None:
                            self.avr_left_controller = 0
                        elif self.avr_left_controller <= 0:
                            self.avr_left_controller = 0

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 100 and dista <= 150:
                        if self.avr_left_controller == None:
                            self.avr_left_controller = 1
                        elif self.avr_left_controller <= 1:
                            self.avr_left_controller = 1

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 150 and dista <= 200:
                        if self.avr_left_controller == None:
                            self.avr_left_controller = 2
                        elif self.avr_left_controller <= 2:
                            self.avr_left_controller = 2

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 200:
                        if self.avr_left_controller == None:
                            self.avr_left_controller = 3
                        elif self.avr_left_controller <= 3:
                            self.avr_left_controller = 3

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                elif index12[0] < index0[0]:
                    # Appending to array of 5 movements
                    if self.avr_left_controller != None:
                        self.upload_avr.append(self.avr_left_controller)
                        self.score_list.append(self.average_change)
                        self.avr_left_controller = None
                        self.average_change = 0
                        self.side_done = False

                    # Checking how far
                    if dista > 6 and dista <= 100:
                        if self.start_time == None and self.side_done == False:
                            self.start_time = time.time()

                        if self.avr_right_controller == None:
                            self.avr_right_controller = 0
                        elif self.avr_right_controller <= 0:
                            self.avr_right_controller = 0

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 100 and dista <= 150:
                        if self.avr_right_controller == None:
                            self.avr_right_controller = 1
                        elif self.avr_right_controller <= 1:
                            self.avr_right_controller = 1

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 150 and dista <= 200:
                        if self.avr_right_controller == None:
                            self.avr_right_controller = 2
                        elif self.avr_right_controller <= 2:
                            self.avr_right_controller = 2

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 200:
                        if self.avr_right_controller == None:
                            self.avr_right_controller = 3
                        elif self.avr_right_controller <= 3:
                            self.avr_right_controller = 3

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

            elif handType == "Left":
                if len(self.upload_avr) >= 5:
                    self.uploader = sum(
                        self.upload_avr) // (len(self.upload_avr) - 1)

                    self.upload_avr = []

                    return self.keys[self.uploader]

                elif len(self.score_list) >= 3:
                    score = round(
                        ((sum(self.score_list) // len(self.score_list)) / 200) * 100, 3)
                    self.score_list = []
                    return score

                if index12[0] > index0[0]:
                    # Appending to array of 5 movements
                    if self.avr_left_controller != None:
                        self.upload_avr.append(self.avr_left_controller)
                        self.score_list.append(self.average_change)
                        self.avr_left_controller = None
                        self.average_change = 0
                        self.side_done = False

                    # Checking how far
                    if dista > 6 and dista <= 100:
                        if self.start_time == None and self.side_done == False:
                            self.start_time = time.time()

                        if self.avr_right_controller == None:
                            self.avr_right_controller = 0
                        elif self.avr_right_controller <= 0:
                            self.avr_right_controller = 0

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 100 and dista <= 150:
                        if self.avr_right_controller == None:
                            self.avr_right_controller = 1
                        elif self.avr_right_controller <= 1:
                            self.avr_right_controller = 1

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 150 and dista <= 200:
                        if self.avr_right_controller == None:
                            self.avr_right_controller = 2
                        elif self.avr_right_controller <= 2:
                            self.avr_right_controller = 2

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 200:
                        if self.avr_right_controller == None:
                            self.avr_right_controller = 3
                        elif self.avr_right_controller <= 3:
                            self.avr_right_controller = 3

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                elif index12[0] < index0[0]:
                    # Appending to array of 5 movements
                    if self.avr_right_controller != None:
                        self.upload_avr.append(self.avr_right_controller)
                        self.score_list.append(self.average_change)
                        self.avr_right_controller = None
                        self.average_change = 0
                        self.side_done = False

                    # Checking how far
                    if dista > 6 and dista <= 100:
                        if self.start_time == None and self.side_done == False:
                            self.start_time = time.time()

                        if self.avr_left_controller == None:
                            self.avr_left_controller = 0
                        elif self.avr_left_controller <= 0:
                            self.avr_left_controller = 0

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 100 and dista <= 150:
                        if self.avr_left_controller == None:
                            self.avr_left_controller = 1
                        elif self.avr_left_controller <= 1:
                            self.avr_left_controller = 1

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 150 and dista <= 200:
                        if self.avr_left_controller == None:
                            self.avr_left_controller = 2
                        elif self.avr_left_controller <= 2:
                            self.avr_left_controller = 2

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

                    elif dista > 200:
                        if self.avr_left_controller == None:
                            self.avr_left_controller = 3
                        elif self.avr_left_controller <= 3:
                            self.avr_left_controller = 3

                        if self.average_change <= dista:
                            self.average_change = dista
                        elif dista + 10 < self.average_change:
                            if self.start_time != None:
                                end_time = time.time()
                                if end_time - self.start_time > 1:
                                    final_time = round(
                                        end_time - self.start_time, 3), "time"
                                else:
                                    final_time = "time"
                                self.start_time = None
                                self.side_done = True
                                end_time = 0
                                return final_time

        else:
            return "Hand position"


def averaging(a_list):
    return round((sum(a_list) / (len(a_list) - 1)) / 0.0319962, 5)


def updateLiveComments(error, message, uid):
    db = firestore.Client()
    doc_ref = db.document(
        f"users/{uid}/liveComments/{str(datetime.date.today())}")

    doc = doc_ref.get()
    if doc.exists:
        doc_ref.set({
            u"error": error,
            u"message": message
        }, merge=True)
    else:
        db.document(f"users/{uid}/liveComments/{str(datetime.date.today())}").set({
            u"error": error,
            u"message": message
        })


def updateResults(uid, score, time, exercise):
    db = firestore.Client()
    doc_ref = db.document(
        f"users/{uid}/liveComments/{str(datetime.date.today())}")

    doc = doc_ref.get()
    if doc.exists:
        if exercise == "wristSideToSide":
            doc_ref.set({
                exercise: {u"score": score,
                        u"time": time}
            })
        elif exercise == "wristUpAndDown":
            doc_ref.update({
                exercise: {u"score": score,
                           u"time": time}
            })


def nextExercise(uid, delete=False):
    db = firestore.Client()
    doc_ref = db.collection(u"users").document(uid)

    if delete:  # Delete means end of the day's exercise
        new_date = datetime.datetime.now(
            tz=datetime.timezone.utc) + datetime.timedelta(days=1)
        doc_ref.update({
            u"nextExercise": new_date.replace(hour=randint(12, 16)),
            u"exer": firestore.DELETE_FIELD
        })

    else:
        doc = doc_ref.get()
        if doc.exists:
            doc_ref.set({"exer": firestore.Increment(1)}, merge=True)
        else:
            data = {"exer": 1}
            db.collection(u"users").document(uid).set(data)


def errorPosting(error, the_type, uid):
    if error == "Hand position" and the_type != error:
        errors = {
            "type": error,
            "message": "Please, position your hand as instructed."
        }
        message = "none"
        the_type = error
        # print(errors["message"])
        updateLiveComments(
            errors, message, uid)

    elif error == "Whole hand movement" and the_type != error:
        errors = {
            "type": error,
            "message": "Please try not to move your whole hand. Return your hand to initial position."
        }
        message = "none"
        the_type = error
        # print(errors["message"])
        updateLiveComments(
            errors, message, uid)
        time.sleep(5)
        errors = {
            "type": "none",
            "message": "none"
        }
        message = "Proceed with exercise."
        updateLiveComments(
            errors, message, uid)
        # print(message)
        time.sleep(2)

    elif error == "bad":
        errors = {
            "type": "none",
            "message": "none"
        }
        message = "Try your best to push your hand."
        updateLiveComments(
            errors, message, uid)
        # print(message)

    elif error == "trying":
        errors = {
            "type": "none",
            "message": "none"
        }
        message = "Good, keep trying hard."
        updateLiveComments(
            errors, message, uid)
        # print(message)

    elif error == "nice":
        errors = {
            "type": "none",
            "message": "none"
        }
        message = "Very nice, now push a little bit more."
        updateLiveComments(
            errors, message, uid)
        # print(message)

    elif error == "very good":
        errors = {
            "type": "none",
            "message": "none"
        }
        message = "You are doing very good."
        updateLiveComments(
            errors, message, uid)
        # print(message)

    return the_type


def uploadPostPone(uid):
    db = firestore.Client()
    doc_ref = db.collection(u"users").document(uid)
    doc = doc_ref.get()
    if doc.exists:
        doc_ref.update({u"postPoned": firestore.Increment(1)})


def the_average(score):
    if len(score) <= 0:
        return 0
    return sum(score) // len(score)


def getExercise(uid):
    db = firestore.Client()
    doc_ref = db.collection(u"users").document(uid)
    doc = doc_ref.get()
    if doc.exists:
        try:
            return int(doc.get("exer"))
        except:
            data = doc.to_dict()
            data["exer"] = 0
            db.collection(u"users").document(uid).set(data)
            return 0
    else:
        data = {"exer": 0}
        db.collection(u"users").document(uid).set(data)
        return 0


def getHandType(uid):
    db = firestore.Client()
    doc_ref = db.collection(u"users").document(uid)
    doc = doc_ref.get()
    if doc.exists:
        try:
            return doc.get("paralysedHand")
        except:
            return None


def feedback(request):
    if request.method == "POST":
        request_data = request.get_json()
        response = {}

        cap = cv2.VideoCapture(request_data["source"])  # video stream
        detector = HandDetector(detectionCon=0.8, maxHands=3)
        exercise = Exercise()
        run = True
        the_type = ""
        light_issue, post_pone = 0, 0
        score = []
        the_time = []
        exer = getExercise(request_data["uid"])
        hand_type = getHandType(request_data["uid"])
        started = False
        start = time.time()
        while run:
            success, img = cap.read()
            if success:
                if started == False:
                    error = {
                        "type": "none",
                        "message": "none"
                    }
                    message = "Start the exercise."
                    updateLiveComments(error, message, request_data["uid"])
                    time.sleep(2)
                    started = True
                hands, img = detector.findHands(img, True)
                if hands:
                    if the_type == "No hands":
                        error = {
                            "type": "none",
                            "message": "none"
                        }
                        message = "Proceed with the exercise."
                        the_type = ""
                        updateLiveComments(
                            error, message, request_data["uid"])
                    if light_issue < 5:
                        if detector.howManyHands(hands) > 1:
                            for i in hands:
                                if i["type"] == hand_type:
                                    hand = i
                        elif detector.howManyHands(hands) == 1:
                            hand = hands[0]

                        lmList = hand["lmList"]
                        handType = hand["type"]

                        if exer == 0:
                            dista = detector.findDistanceCM(
                                lmList[5], lmList[17])

                            the_message = exercise.wristSideToSide(
                                lmList[0], lmList[12], dista)

                            if the_message == "Whole hand movement":
                                light_issue += 1
                            elif type(the_message) == float:
                                score.append(the_message)
                            elif type(the_message) == tuple:
                                the_time.append(the_message[0])

                            the_type = errorPosting(
                                the_message, the_type, request_data["uid"])
                            end = time.time()

                            if end - start >= 60:
                                error = {
                                    "type": "none",
                                    "message": "none"
                                }
                                message = "This exercise is over. Get ready for another exercise."
                                updateLiveComments(
                                    error, message, request_data["uid"])
                                nextExercise(request_data["uid"])
                                time.sleep(2)
                                updateResults(request_data["uid"], the_average(score), round(
                                    sum(the_time) / len(the_time), 3), "wristSideToSide")
                                response["message"] = message
                                run = False
                                return response

                        elif exer == 1:
                            the_message = exercise.wristUpAndDown(
                                lmList[0], lmList[4], lmList[8], lmList[12], lmList[16], lmList[20], handType)

                            if the_message == "Whole hand movement":
                                light_issue += 1
                            elif type(the_message) == float:
                                score.append(the_message)
                            elif type(the_message) == tuple:
                                the_time.append(the_message[0])

                            the_type = errorPosting(
                                the_message, the_type, request_data["uid"])
                            end = time.time()

                            if end - start >= 60:
                                error = {
                                    "type": "none",
                                    "message": "none"
                                }
                                message = "Congratulation for today's exercise, let's meet again tomorrow."
                                response["message"] = message
                                run = False
                                updateLiveComments(
                                    error, message, request_data["uid"])
                                nextExercise(request_data["uid"], True)
                                time.sleep(2)
                                updateResults(request_data["uid"], the_average(score), round(
                                    sum(the_time) / len(the_time), 3), "wristUpAndDown")
                                return response

                        else:
                            return f"Unknown exercise requested: {exer}", 404
                    else:
                        if post_pone < 3:
                            error = {
                                "type": "Insufficient light",
                                "message": "Please make sure you are on a place with sufficient light and then start again, and trying not to move your whole hand. just move your wrist"
                            }
                            message = "none"
                            updateLiveComments(
                                error, message, request_data["uid"])
                            light_issue = 0
                            post_pone += 1
                        else:
                            error = {
                                "type": "Postponed exercise",
                                "message": "The exercise is postponed because of light issues on your area, This can cause poor exercising and measurement results so let's meet tomorrow."
                            }
                            message = "none"
                            print(error["message"])
                            updateLiveComments(
                                error, message, request_data["uid"])
                            uploadPostPone(request_data['uid'])
                            response["message"] = error["message"]
                            run = False
                            return response

                else:
                    if the_type != "No hands":
                        error = {
                            "type": "No hands",
                            "message": "There is no any hands, Make sure you put the affected hand on the screen."
                        }
                        message = "none"
                        the_type = "No hands"
                        print(error["message"])
                        updateLiveComments(
                            error, message, request_data["uid"])

            else:
                error = {
                    "type": "Stream failure",
                    "message": "Failed to initialize the stream."
                }
                message = "none"
                updateLiveComments(
                    error, message, request_data["uid"])
                response["message"] = "Failed to initialize the stream"
                run = False
                return response

    else:
        return "Unknown request", 404
