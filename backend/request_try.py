import requests

cloud_function_url = "https://bucketRegion-projectId.cloudfunctions.net/functionName"
stream_url = "rtmp://url-domain/live/stream-key"
user_uid = ""  # Firebase Firestore's user id

response = requests.post(cloud_function_url,
                         json={"source": stream_url,
                               "uid": user_uid})

print(response.text)
