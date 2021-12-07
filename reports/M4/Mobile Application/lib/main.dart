import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pytorch_mobile/pytorch_mobile.dart';
import 'package:pytorch_mobile/model.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Model _imageModel;

  String _imagePrediction;
  String _url;
  File _image;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  //load your model
  Future loadModel() async {
    String pathImageModel = "assets/models/final_jit_model.pt";
    try {
      _imageModel = await PyTorchMobile.loadModel(pathImageModel);
    } on PlatformException {
      print("Wrong Platform");
    }
  }

  //run an image model
  Future runImageModel() async {
    File image = await ImagePicker.pickImage(
        source: (Platform.isIOS ? ImageSource.gallery : ImageSource.camera),
        maxHeight: 224,
        maxWidth: 224);
    _imagePrediction = await _imageModel.getImagePrediction(image, 224, 224, "assets/labels/labels_with_hyphen_only.csv");
    _url = await _imageModel.getImagePrediction(image, 224, 224, "assets/labels/labels_with_links_only.csv");

    setState(() {
      _image = image;
    });
  }

  void _launchURL() async =>
      await canLaunch(_url) ? await launch(_url) : throw 'Could not launch $_url';


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('TEAM LAMBEOSAURUS',
          style: GoogleFonts.raleway(
            textStyle: TextStyle(color: Colors.black, letterSpacing: .5),
          ),
          textAlign: TextAlign.center,
        ),
          backgroundColor: Colors.lightBlue[100],),
        backgroundColor: Colors.lightBlue[50],
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null ? Text('No image selected.') : Image.file(_image),
            Center(
              child: Visibility(
                visible: _imagePrediction != null,
                child: Text(_imagePrediction),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: runImageModel,
                child: Icon(Icons.add_a_photo),
              ),
            ),
            Visibility(
              visible: _imagePrediction != null,
                child: ElevatedButton(
                  child: Text('StockX'),
                  onPressed: _launchURL,
                ),
            ),
          ],
        ),
      ),
    );
  }
}
