"""
    This code can be used to record your own video for
    testing purposes, No need to record with 
    your phone and you got a web cam .
"""
import cv2

cap = cv2.VideoCapture(0)
fourcc = cv2.VideoWriter_fourcc(*"XVID")
out = cv2.VideoWriter("test.avi", fourcc, 30.0, (640, 480))

run = True
while run:
    success, vid = cap.read()

    if not success:
        break

    out.write(vid)

    cv2.imshow("Image", vid)
    if cv2.waitKey(1) == ord("q"):
        break

cap.release()
out.release()
cv2.destroyAllWindows()
