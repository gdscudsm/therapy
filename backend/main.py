
def hello(request):
    if request.method == "POST":
        request_data = request.get_json()
        response = {}
        # return request_data
        exercise = request_data["exercise"]
        if request_data["source"]:
            response["stream"] = "Up and running"
            if exercise == "WRISTSIDETOSIDE":
                response["feedback"] = "Very good"
            else:
                response["feedback"] = "No exercise specified"
        else:
            response["stream"] = "I dont get any stream"
            response["feedback"] = "No stream found"
        return response
    else:
        if request.args:
            data = request.args["name"]
            # name = request.args["name"]
            return data
        else:
            return "Not known request", 404


def updateExercise(request):
    from google.cloud import firestore
    import google.auth
    import datetime

    if request.method == "POST":
        request_data = request.get_json()

        credentials, project = google.auth.default()
        db = firestore.Client(project=project, credentials=credentials)

        uid = request_data["uid"]
        doc_ref = db.document(
            f"users/{uid}/measureComments/{str(datetime.date.today())}")

        doc_ref.set({
            u"Error": {"type": "No hand",
                       "message": "Make sure there is hands on the screen"},
            u"message": "none"
        }, merge=True)
        return "Successful", 200

    else:
        return "unknown request"
