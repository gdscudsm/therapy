## Getting Started

Welcome to Digital Therapy Application

## For Frontend Flutter app at the root of the project go inside folder called frontendApp then follow below steps

**Step 1:**

Download or clone this repo by using the link below:

```
git@github.com:gdscudsm/therapy.git
```

**Step 2:**

Go to project root and execute the following command in console to get the required dependencies:

```
flutter pub get
```

**Step 3:**

Go to project root and execute the following command in console to run the application in the phone:

```
flutter run
```

## For Backend, python cloud function go inside folder called backend then follow below steps

> [ main.py][measure] in measure folder have entry points when deployed.

### Measure function:
* ***measure*** function is for measuring the paralysis of the hand at real-time and return the result on the [firebase firestore][firestore] document.


> [main.py][main] and [request_try.py][request] files are for testing cloud functions locally.

### To test the function locally:
1. Run: 
            
        pip install functions-framework

2. Then launch your `hello` function locally from [main.py][main]:

        functions-framework --target hello --debug

3. Open your browser and type: 

        http://192.168.43.236:8080/
        "OUTPUT: You will see `Not known request` message."

### To deploy the function, run:
    gcloud functions deploy NAME --entry-point ENTRY-POINT --runtime RUNTIME TRIGGER [FLAGS...]

[measure]: measure/main.py
[feedback]:feedback/main.py
[main]: main.py
[request]: request_try.py
[requirements]:requirements.txt
[firestore]: https://firebase.google.com/products/firestore
