# Milestone M4 report
 
**Current state of project:** 
Model: The model is fully trained and functional.
 
Mobile Application: The mobile app now features an image_picker instead of the camera plugin because the image_picker had a shorter response time. Also the application now displays both the name of the shoe and provides a stockX link for the shoe.
 
Web Application: Created a web app using Streamlit. Loaded the model in via pytorch and wrote code to allow the user to upload an image, and have the model output the name of the show, as well as a link to the StockX page. Once the Streamlit app worked locally, created all the necessary files needed to have heroku successfully deploy the app.
 
**Feature changes:**
Our model, which worked well with up to 96% accuracy in a normal scenario, failed abruptly when it came to being in sync with the mobile app. After days of repeated testing and debugging with no avail, we decided to move on with a python web app using the streamlit package and hosting the app on heroku as mentioned in the risk management section of the project proposal.  
 
**Current challenges/bottlenecks:**
Failure of model on the flutter application. This prompted us to go ahead with a web application instead following the risk management procedure mentioned in the project proposal. 
 
**Tasks done:**
1. Allen: Wrote and made diagrams for the majority of the final report. 
 
2. Janishjit:
    Debugging and reconstructing the flutter application. Also conducted research on other better options to demonstrate our model after the failure of the application. 
3. Marc: 
	Wrote a Selenium Python script to search google for a StockX link of each shoe.  The script grabs the first google result and saves the link to a csv.  A few of the shoes gave incorrect links for various reasons, these were parsed by me and fixed manually.
    
4. Zachary: Made and debugged the Streamlit app then deployed it with Heroku
	
    
 
**Resources:**
* Primary Kaggle dataset: https://www.kaggle.com/sebastiaanjohn/sneakers
* Pytorch Mobile flutter packages : https://pub.dev/packages/pytorch_mobile
* How to build a Streamlit web app: https://towardsdatascience.com/create-an-image-classification-web-app-using-pytorch-and-streamlit-f043ddf00c24
* Selenium Documentation
https://selenium-python.readthedocs.io/
