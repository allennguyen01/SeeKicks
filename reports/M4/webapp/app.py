import streamlit as st
from PIL import Image
from torchvision import models, transforms
import torch
import csv

#load the saved model
ENTIRE_MODEL_PATH = "test3.pt"
model = torch.load(ENTIRE_MODEL_PATH)
model.eval()

#get a list of the label names
with open("labels_only.csv", newline="") as f:
    reader = csv.reader(f)
    labels = list(reader)

#get a list of the links to the stockX site for each shoe
with open("labels_with_links_only.csv", newline="") as f:
    reader = csv.reader(f)
    links = list(reader)

#text for the app
st.title("SeeKicks: a sneaker identifier")
st.markdown("Upload a picture of some sneakers.")
st.markdown("The name will be displayed, as well as a StockX link to purchase the shoe.")

#file uploader
file_up = st.file_uploader("", type=["jpg", "png", "jpeg", "jfif", "webp"])

if file_up is not None:
    #transform image to tensor
    image = Image.open(file_up)
    image = image.convert("RGB")
    xform = transforms.Compose([transforms.Resize((224,224)), transforms.ToTensor()])
    img_tensor = torch.unsqueeze(xform(image), 0)

    with torch.no_grad():
        #turn the output tensor into the proper label
        model_out = model(img_tensor)
        _, shoe_class_tensor = torch.max(model_out, 1)
        shoe_class = shoe_class_tensor.cpu().data.numpy()
    
    #link to the stockX site
    link = "[" + labels[0][int(shoe_class)] + "](" + links[0][int(shoe_class)] + ")"
    st.markdown("### Your shoe is: " + link, unsafe_allow_html=True)

    #display uploaded image
    st.image(image, use_column_width=True)

