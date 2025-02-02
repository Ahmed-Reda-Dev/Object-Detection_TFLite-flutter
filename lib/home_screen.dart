import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  bool loading = true;
  File? image;
  List? _output;
  final picker = ImagePicker();

  pickImage() async {
    var pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        image = File(pickedImage.path);
      });
      classifyImage(image!);
    }
  }

  pickCameraImage() async {
    var pickedImage = await picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        image = File(pickedImage.path);
      });
      classifyImage(image!);
    }
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      loading = false;
      _output = output;
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/models/detect.tflite',
      labels: 'assets/models/labelmap.txt',
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedTextKit(
          repeatForever: true,
          animatedTexts: [
            ColorizeAnimatedText(
              'Object Detection',
              textStyle: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              colors: [
                const Color.fromRGBO(5, 242, 246, 1),
                const Color.fromRGBO(84, 46, 146, 0.82),
              ],
              speed: const Duration(milliseconds: 200),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              image != null
                  ? Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.file(image!),
                    )
                  : const SizedBox(
                      height: 250,
                      child: Image(
                        image: AssetImage('assets/pic.png'),
                      ),
                    ),
              const SizedBox(height: 40),
              _output != null
                  ? Column(
                      children: _output != null
                          ? _output!.map((res) {
                              return Text(
                                "${res["label"]}: ${(100 * res["confidence"]).toStringAsFixed(3)} %",
                                style: const TextStyle(
                                  fontSize: 20.0,
                                ),
                              );
                            }).toList()
                          : [],
                    )
                  : Container(),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: pickCameraImage,
                    child: const Icon(
                      Icons.camera,
                      color: Color.fromRGBO(5, 242, 246, 0.82),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: pickImage,
                    child: const Icon(
                      Icons.image,
                      color: Color.fromRGBO(5, 242, 246, 0.82),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
