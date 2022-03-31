# Hand paralysis rehabilitation with Computer Vision Technology

> [ main.py][measure] in measure folder and [main.py][feedback] in feedack folder have entry points when deployed.

### You have to choose either:
* ***measure*** function for measuring the paralysis of the hand at real-time and read the result on the [firebase firestore][firestore] document.
* ***feedback*** function for receiving real-time feedback about the performance of the hand on the exercises on [firebase firestore][firestore] document..

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