// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:signatureapp/constant_image/image.dart';
import 'package:signatureapp/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Signature Controller
  SignatureController signatureController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 3,
    exportBackgroundColor: Colors.white,
  );

//  -------------------------------------------  Variable initializing part ----------------------------------------------------------------
  Uint8List? exportedImage;
  int pixelWidthHeight = 96;
  String currentImage = "";
  String? onSelected;
  final List<String> nameList = <String>[
    "16 X 16",
    "24 X 24",
    "36 X 36 ",
    "48 X 48",
    "64 X 64",
    "96 X 96",
    "128 X 128",
  ];
//  Creating a database of Signature Name
  final databaseref = FirebaseDatabase.instance
      .ref('Signature on ${DateFormat('dd-MM-yyyy').format(DateTime.now())}');

  String imageUrl = "";

  //  -------------------------------------------  FUnctions Initializing part ----------------------------------------------------------------
//  Uploading image to Firebase
  void uploadSignature(Uint8List imageFile) async {
    currentImage = currentImage.replaceAll('/', '');
    String uniquenamedb =
        "Signed Image at ${DateFormat('kk:mm:ss').format(DateTime.now())} Image Name : ${currentImage.substring(22, currentImage.length - 4).toUpperCase()}";

    String uniquename =
        "${currentImage.substring(22, currentImage.length - 4).toUpperCase()} / ${currentImage.substring(22)}";
    Reference referenceroot = FirebaseStorage.instance.ref();
    Reference referenceDirImage =
        referenceroot.child(currentImage.substring(12, 22));
    Reference referenceImageToUpload = referenceDirImage.child(uniquename);

    try {
      await referenceImageToUpload.putData(imageFile);
      imageUrl = await referenceImageToUpload.getDownloadURL();
      // ignore: empty_catches
    } catch (e) {}
    databaseref.child(uniquenamedb).set({"Signed Image ": imageUrl.toString()});
  }

//  Very First Random Image
  @override
  void initState() {
    super.initState();
    Random random = Random();
    currentImage = imageArrar[random.nextInt(imageArrar.length)];
  }

// ------------------------------ Build Function --------------------------------
  @override
  Widget build(BuildContext context) {
    //  Random Image after 1st has choosen
    void randomImage() {
      setState(() {
        Random random = Random();
        currentImage = imageArrar[random.nextInt(imageArrar.length)];
      });
    }

    return Scaffold(
      //  AppBar
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Signature App"),
        actions: [
          DropdownButton<String>(
            icon: const Icon(
              Icons.settings,
              color: Colors.black,
            ),
            onChanged: (value) {
              setState(() {
                onSelected = value!;
                onSelected = onSelected?.substring(0, 3);
                pixelWidthHeight = int.parse(onSelected!);
              });
            }, // Function to handle onChanged event
            items: nameList.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(
            width: 20,
          ),
        ],
      ),

      //  Body
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            //  random Image
            Image.asset(
              currentImage.isNotEmpty ? currentImage : b,
              height: 300,
              fit: BoxFit.contain,
            ),
            const Divider(),
            const SizedBox(
              height: 20,
            ),
            //  Sign Pad
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Signature(
                controller: signatureController,
                height: 250,
                width: MediaQuery.of(context).size.width,
                backgroundColor: Colors.black12,
              ),
            ),
            const SizedBox(
              height: 15,
            ),

            //  Buttons

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                //  Clear Button
                ElevatedButton(
                    style: const ButtonStyle(
                        elevation: MaterialStatePropertyAll(.7)),
                    onPressed: () {
                      signatureController.clear();
                    },
                    child: const Text('Reset')),

                //  Submit Button
                ElevatedButton(
                    onPressed: () => signatureController.isNotEmpty
                        ? showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                shadowColor: Colors.grey,
                                title: Text(
                                  "Do you want to submit",
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                actions: [
                                  //  Submit -> No
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("No")),

                                  //  Submit -> Yes
                                  TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        //  Export image from Signpad
                                        exportedImage =
                                            await signatureController
                                                .toPngBytes();
                                        setState(() {});

                                        //  Uploading image
                                        exportedImage =
                                            await FlutterImageCompress
                                                .compressWithList(
                                          exportedImage!,
                                          quality: 98,
                                          format: CompressFormat.png,
                                          minWidth: pixelWidthHeight,
                                          minHeight: pixelWidthHeight,
                                        );
                                        uploadSignature(exportedImage!);

                                        //  Clearing Sign Pad
                                        signatureController.clear();

                                        //  Message of Successful Submitted
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                backgroundColor: Colors.green,
                                                content: Center(
                                                    child: Text(
                                                        '!!!  Submitted  !!!'))));

                                        //  Random Image
                                        randomImage();
                                      },
                                      child: const Text("Yes")),
                                ],
                              );
                            },
                          )

                        //  Sign Pad is Empty
                        : ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                backgroundColor: Colors.red,
                                content: Center(
                                    child: Text(
                                        '!!!  Please Sign over Portion  !!!')))),
                    child: const Text('Submit'))
              ],
            ),
            const SizedBox(
              height: 25,
            )
          ],
        ),
      ),
    );
  }
}
