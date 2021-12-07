# Milestone M3 report
 
**Current state of project:** 
Model: The model is fully trained and functional.
 
Mobile Application: The mobile application now includes the pytorch mobile plugin. The current version of the model runs the image taken by the camera and transfers it to the model. The model returns the name of the shoe which is then displayed on the application.
 
**Feature changes:**
We have decided to go with the pytorch mobile package instead of the REST API. We chose to go with the same because of a lack of backend experience and lack of time for getting a grasp of the same. The pytorch mobile package seemed to be more optimized so we started setting up our application for the same.
 
**Current challenges/bottlenecks:**
The challenges we need to tackle in the coming week is to finish testing the application and to make sure it works with the StockX website.
 
**Tasks done:**
1. Allen: 
    Worked on improving the accuracy of the PyTorch model by experimenting with the parameters of the SGD optimizer, StepLR scheduler, and DataLoader.       
2. Janishjit:
    Researched on different methods of linking the model to the flutter application, including creating a flask REST API, flutter tflite package, or the flutter pytorch mobile package. Finalized and set up the application with the pytorch mobile package.
3. Marc:
    Researched expanding the dataset, to assist in accuracy improvements.  Created the csv lookup table used in the application.  Assisted in debugging issues with the dart plugins and development.
4. Zachary:
	Fully trained the model with the optimized parameters and full dataset until it converged, then saved the model as a .pt file so it can be used with the app.
    
 
**Resources:**
* Primary Kaggle dataset: https://www.kaggle.com/sebastiaanjohn/sneakers
* Camera application cookbook: https://flutter.dev/docs/cookbook/plugins/picture-using-camera
* Pytorch Mobile flutter packages : https://pub.dev/packages/pytorch_mobile
