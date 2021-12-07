# Milestone M1 report

**Current state of project:** 
Model: The model is not yet functional.  We are working on creating the integer labels for each type of sneaker based on the folder the image is in.  We have a majority of the code to test and train the model, but the dataset is not ready to be inserted into the model.

Mobile Application: Used the inbuilt Flutter camera plugin to create a basic camera application.

Flask Backend: Most of our team members do not have much experience with app and web development so we are trying to familiarize ourselves with using a backend like Flask and how we will integrate the backend with our Flutter frontend. 

**Feature changes:**
We are currently working with a Kaggle dataset that emulates the original idea of a scrapped dataset. We decided to go with a premade dataset to help get an early start on model creation, testing and debugging.

**Current challenges/bottlenecks:**
If we need more images in the dataset, we have to find a way to scrape more images while ensuring there are no duplicates with the Kaggle dataset we used. Alternatively, we can perform data augmentation on the Kaggle dataset. This allows us to create more samples with the dataset we already have.

We are struggling to train on the 8GB dataset (size is partially due to images being high definition) efficiently using Google Colab so we are planning to make a shrunken dataset of a handful of shoes to do most of the basic model debugging and testing, then moving to the large dataset when we are close to a final model.

**Tasks done:**
1. Allen:
	* Did preliminary research on the ML model and app development
	* Worked with Marc on the basic ML model on Google Colab 
	* Mounted a Kaggle dataset using the Kaggle API. 
2. Janishjit:
	Created a basic mobile application using Flutter UI. The application functions as a basic camera which clicks and stores images.
3. Marc:
	Familiarized with the project and our goals.  Worked with Allen to create the basic model skeleton and mount the dataset effectively.
4. Zachary:
	Worked on writing the code to run the model, like replacing the fc layer and making the test, train, etc. functions

**Resources:**
* Primary Kaggle dataset: https://www.kaggle.com/sebastiaanjohn/sneakers
* Camera application cookbook: https://flutter.dev/docs/cookbook/plugins/picture-using-camera
