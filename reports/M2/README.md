# Milestone M2 report
 
**Current state of project:** 
Model: The code for the model is complete. We need to work on remodeling the dataset which removes any problematic files and increasing the number of images present.
 
Mobile Application: Redesigned the mobile application on flutter. It is still currently a basic camera application. Alternatively, we have found useful camera vision libraries on flutter that could directly use a Tensorflow Lite Model which would eliminate the requirement to create a larger backend framework.
 
Flask Backend: Learning to make a Python REST API with Flask. In the preliminary stages of making an Python REST API that works with our ML model and the Flutter application. 
 
**Feature changes:**
No feature changes as of April 10, 2021.
 
**Current challenges/bottlenecks:**
The accuracy of our model is lower than we’d like. We will try training it with different optimizers and schedulers, and possibly add more data
 
**Tasks done:**
1. Allen:
    Learned and familiarized with constructing a Python REST API using Flask. 
2. Janishjit:
    Worked on creating a more final version of the camera application. Also did some research on available camera vision libraries which would be useful when we want to mount the final model on the application.
3. Marc:
    Worked to get the model working on google colab.  Began research on converting the pytorch model to tensorflow using ONNX, in order to make the backend of the app easier to program.
4. Zachary:
    Got the model fully functional by debugging the model and cleaning up the dataset. The Kaggle dataset contained images that could not be opened, created code that deleted them. Also created smaller datasets to test on, and optimized the model
 
**Resources:**
* Primary Kaggle dataset: https://www.kaggle.com/sebastiaanjohn/sneakers
* Camera application cookbook: https://flutter.dev/docs/cookbook/plugins/picture-using-camera
* Cameravision with realtime detection repository (for reference): https://github.com/shaqian/flutter_realtime_detection.git
