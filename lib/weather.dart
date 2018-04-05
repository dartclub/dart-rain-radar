import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class RainViewWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new RainState();
  }
}

class RainState extends State<RainViewWidget> with SingleTickerProviderStateMixin {

  Animation<int> rainRadarIndex;
  AnimationController controller;

  var radarUrls = <String>[];
  var currentRainRadarIndex = 0;
  var lastIndex = -1;

  @override
  void initState() {
    super.initState();
    getRainUrls();
  }

  getRainUrls() async {
    var httpClient = new HttpClient();
    var uri = new Uri.https(
        'grundid.de', '/data/weather/files4.json',
        {'time': new DateTime.now().millisecondsSinceEpoch.toString()});
    var request = await httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    List<String> data = json.decode(responseBody);

    data.forEach((url) {

    });



    radarUrls = data;
    final duration = 2000*radarUrls.length;
    controller = new AnimationController(
        duration: new Duration(milliseconds: duration), vsync: this);
    rainRadarIndex = new StepTween(begin: 0, end: radarUrls.length-1).animate(controller)
      ..addListener(() {
        if (lastIndex != rainRadarIndex.value) {
          print("listener: $rainRadarIndex.value");
          setState(() {});
          lastIndex = rainRadarIndex.value;
        }
      })
    ..addStatusListener((status) {
      print(status);
    });
    controller.forward();
  }

  dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(rainRadarIndex);
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Startup Name Generator'),
      ),
      body: rainRadarIndex == null  ?  new Image.asset("images/loading.png") :
      new Image.network("https://grundid.de/data/weather/"+radarUrls[rainRadarIndex.value], gaplessPlayback: true,) ,
    );
  }

}