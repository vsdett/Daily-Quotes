import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:toast/toast.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

// Main start of the app
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(MyApp());
}

// Setting App name and home
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Motivation Quotes',
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<MainPage> {
  late String quote,owner,imglink;
  bool working = false;
  final grey = Colors.blueGrey[800];
  ScreenshotController screenshotController=new ScreenshotController();

  @override
  void initState() {
    super.initState();
    screenshotController = ScreenshotController();
    quote = "";
    owner = "";
    imglink = "";
    getQuote();
  }

  // Get a random Quote from the API
  // Get a random Quote from the API
  getQuote() async {
    try {
      setState(() {
        working = true;
        quote = imglink = owner = "";
      });
      var response = await http.post(
          Uri.parse('http://api.forismatic.com/api/1.0/'),
          body: {"method": "getQuote", "format": "json", "lang": "en"}
      );
      var res = jsonDecode(response.body);
      if (res == null || !res.containsKey("quoteText")) {
        throw Exception("Invalid API Response");
      }
      setState(() {
        owner = res["quoteAuthor"]?.toString()?.trim() ?? "Unknown Author";
        quote = res["quoteText"]?.replaceAll("â", " ") ?? "Default quote.";
        getImg(owner); // Fetch image
      });
    } catch (e) {
      offline();
    }
  }

// Get image of the quote author, using Wikipedia API
  getImg(String name) async {
    try {
      var response = await http.get(
          Uri.parse(
              "https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrlimit=1&prop=pageimages%7Cextracts&pithumbsize=400&gsrsearch=" +
                  Uri.encodeComponent(name) +
                  "&format=json"
          )
      );
      var res = json.decode(response.body);
      var pages = res["query"]?["pages"];
      if (pages != null) {
        var firstPage = pages[pages.keys.first];
        setState(() {
          imglink = firstPage?["thumbnail"]?["source"] ?? "";
        });
      } else {
        imglink = ""; // Fallback to default
      }
    } catch (e) {
      setState(() => imglink = "");
    } finally {
      setState(() => working = false);
    }
  }


  // If it is offline, show a fixed Quote
  offline() {
    setState(() {
      owner = "Janet Fitch";
      quote = "The phoenix must burn to emerge";
      imglink = "";
      working = false;
    });
  }

  // When copy button clicked, copy the quote to clipboard
  copyQuote() async {
    await Clipboard.setData(ClipboardData(text: quote + "\n- " + owner));
    Toast.show("Copied",duration: Toast.lengthShort);
  }

  // When share button clicked, share a text and screenshot of the quote
  shareQuote() async {
    try {
      // Capture the screenshot
      final imageFile = await screenshotController.capture();

      if (imageFile == null) {
        throw Exception("Failed to capture screenshot.");
      }

      // Get the application's document directory
      final directory = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory('${directory.path}/screenshots');

      // Ensure the directory exists
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      // Save the file in the screenshots directory
      final filePath =
          '${screenshotsDir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(imageFile);

      // Share the screenshot and text
      Share.shareFiles([file.path], text: quote);
    } catch (e) {
      // Print or handle the error
      print("Error sharing quote: $e");
      Toast.show("Error sharing quote. Please try again.",
          duration: Toast.lengthShort);
    }
  }


  // Get image of the quote author, using Wikipedia API


  // Choose to show the loaded image from the API or the offline one
  Widget drawImg() {
    if (imglink.isEmpty) {
      return Image.asset("img/offline.jpg", fit: BoxFit.cover);
    } else {
      return Image.network(imglink, fit: BoxFit.cover);
    }
  }

  // Main build function
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grey,
      body: Screenshot(
        controller: screenshotController,
        child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: <Widget>[
              drawImg(),
              Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.6, 1],
                      colors: [
                        grey!.withOpacity(0.8), // Equivalent to alpha 200 (out of 255)
                        grey!.withOpacity(0.86), // Equivalent to alpha 220
                        grey!.withOpacity(1.0),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                              text: quote.isNotEmpty ? '“ ' : "",
                              style: TextStyle(
                                  fontFamily: "Ic",
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 30),
                              children: [
                                TextSpan(
                                    text: quote.isNotEmpty ? quote : "",
                                    style: TextStyle(
                                        fontFamily: "Ic",
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 22)),
                                TextSpan(
                                    text: quote.isNotEmpty ? '”' : "",
                                    style: TextStyle(
                                        fontFamily: "Ic",
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green,
                                        fontSize: 30))
                              ]),
                        ),
                        Text(owner.isEmpty ? "" : "\n" + owner,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: "Ic",
                                color: Colors.white,
                                fontSize: 18)),
                      ])),
              AppBar(
                title: Text(
                  "Motivational Quote",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
            ]),
      ),
      floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            InkWell(
              onTap: !working ? getQuote : null,
              child: Icon(Icons.refresh, size: 35, color: Colors.white),
            ),
            InkWell(
              onTap: quote.isNotEmpty ? copyQuote : null,
              child: Icon(Icons.content_copy, size: 30, color: Colors.white),
            ),
            InkWell(
              onTap: quote.isNotEmpty ? shareQuote : null,
              child: Icon(Icons.share, size: 30, color: Colors.white),
            )
          ]),
    );
  }
}
