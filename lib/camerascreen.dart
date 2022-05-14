// import 'dart:html';
// import 'dart:ui';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
//import 'package:manual_camera/camera.dart';
//import 'package:manual_camera/camera_image.dart';
import 'main.dart';
import 'package:themed/themed.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_editor/image_editor.dart';
import 'iso_settings.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

List<double> colormatrix = defaultColorMatrix;

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  double _miniso = 0.5;
  double _maxiso = 3.2;
  double _currentiso = 1;

  CameraController? controller;
  bool _isCameraInitialized = false;
  bool _isRearCameraSelected = true;

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }

    cameraController
        .getMinExposureOffset()
        .then((value) => _minAvailableExposureOffset = value);

    cameraController
        .getMaxExposureOffset()
        .then((value) => _maxAvailableExposureOffset = value);
  }

  Future<Uint8List?> takePicture(double brightness) async {
    final CameraController? cameraController = controller;
    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    try {
      XFile file = await cameraController.takePicture();
      final path = file.path;
      final bytes = await File(path).readAsBytes();
      final editorOption = ImageEditorOption();
      editorOption.addOption(ColorOption.brightness(brightness));
      final newimage = await ImageEditor.editImage(
          image: bytes, imageEditorOption: editorOption);
      return newimage;
    } on CameraException catch (e) {
      print('Error occured while taking picture: $e');
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    onNewCameraSelected(cameras[0]);
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: IconButton(
          icon: Icon(Icons.camera),
          color: Colors.white,
          iconSize:MediaQuery.of(context).size.width / 5.5,
          onPressed: () async {
            Uint8List? rawImage = await takePicture(_currentiso);

            int currentUnix = DateTime.now().millisecondsSinceEpoch;
            if (rawImage == null) {
              const snackBar = SnackBar(
                content: Text('Something went wrong! Try again'),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);

              print("hello");
            } else {
              final result = await ImageGallerySaver.saveImage(rawImage,
                  name: "${currentUnix}");
              print(result);
              const snackBar = SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Pick clicked !! Saved in Gallery'),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          },
        ),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _isCameraInitialized
                ? Container(
              height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: AspectRatio(
                    aspectRatio: 1/controller!.value.aspectRatio,
                    child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                            Iso_settings().makecolormatrix(_currentiso)),
                        child: controller!.buildPreview()),
                  ),
                )
                : Container(),
            Positioned(
              bottom: 0,
              child: Container(
                height: MediaQuery.of(context).size.height / 3,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height / 7.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      "Exposer :",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        Expanded(
                          child: Slider(
                              activeColor: Colors.white,
                              inactiveColor: Colors.grey,
                              min: _minAvailableExposureOffset,
                              max: _maxAvailableExposureOffset,
                              value: _currentExposureOffset,
                              onChanged: (value) async {
                                setState(() {
                                  print(value);
                                  _currentExposureOffset = value;
                                });
                                await controller!.setExposureOffset(value);
                              }),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _currentExposureOffset.toStringAsFixed(1) + 'x',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height / 4.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      "Iso :",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        Expanded(
                          child: Slider(
                              activeColor: Colors.white,
                              inactiveColor: Colors.grey,
                              min: _miniso,
                              max: _maxiso,
                              value: _currentiso,
                              onChanged: (value) {
                                setState(() {
                                  print(value);
                                  _currentiso = value;
                                });
                              }),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                Iso_settings()
                                    .rangeconv(_currentiso)
                                    .toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios_rounded),
                )),
            Positioned(
                bottom: MediaQuery.of(context).size.width / 10,
                right:MediaQuery.of(context).size.width / 6,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isCameraInitialized = false;
                    });
                    onNewCameraSelected(
                      cameras[_isRearCameraSelected ? 0 : 1],
                    );
                    setState(() {
                      _isRearCameraSelected = !_isRearCameraSelected;
                    });
                  },
                  icon: FaIcon(FontAwesomeIcons.arrowsRotate,size: 50,color: Colors.white,),
                )),
          ],
        )
        //
        );
  }
}
