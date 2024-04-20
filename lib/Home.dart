import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';

  @override
  void initState() {
    super.initState();
    initializeCamera();
    loadModel();
  }

  initializeCamera() async {
    WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await cameraController!.initialize();
    if (mounted) {
      setState(() {});
    }
    cameraController!.startImageStream((imageStream) {
      setState(() {
        cameraImage = imageStream;
        runModel();
      });
    });
  }

  runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      if (predictions != null && predictions.isNotEmpty) {
        setState(() {
          output = predictions[0]['label'];
        });
      }
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Live Facial Emotion Detection'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Facial Emotion Detection'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              ),
            ),
          ),
          Text(
            output,
            style: TextStyle(
              fontSize: 35,
              color: const Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
