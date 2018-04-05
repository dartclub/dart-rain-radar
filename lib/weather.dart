import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/services/asset_bundle.dart';

class RadarAssetBundle extends AssetBundle {
  final Map<String, ByteData> cache = new LinkedHashMap();

  fetchRadarImage(String url) async {
    var httpClient = new HttpClient();
    var radarUri = Uri.parse(url);
    var request = await httpClient.getUrl(radarUri);
    var response = await request.close();
    var responseLists = await response.toList();
    var bytesList = <int>[];
    for (var elements in responseLists) {
      bytesList.addAll(elements);
    }
    return new Uint8List.fromList(bytesList);
  }

  initAssets(List<String> urls, int listenerThreshold, listener()) async {
    var counter = 0;
    for (var url in urls) {
      final urlAndKey = "https://grundid.de/data/weather/" + url;
      final imageBytes =
          await fetchRadarImage(urlAndKey);
      print("$urlAndKey =>  ${imageBytes.length}");
      cache.putIfAbsent(urlAndKey, () => new ByteData.view(imageBytes.buffer));

      if (counter == listenerThreshold) {
        listener();
      }
      counter++;
    }
  }

  @override
  Future<ByteData> load(String key) {
    final containsKey = cache.containsKey(key);
    print("Loading key $key, contains: $containsKey");
    return new Future.sync(() => cache[key]);
  }

  @override
  Future<String> loadString(String key, {bool cache: true}) {
    print("Loading string for  key $key");
  }

  @override
  Future<T> loadStructuredData<T>(
      String key, Future<T> Function(String value) parser) {
    print("loadStructuredData for  key $key");
    if (key == "AssetManifest.json") {
      final Map<String, List<String>> jsonObject = <String, List<String>>{};
      for (var url in cache.keys) {
        final List<String> variants = <String>[];
        variants.add(url);
        jsonObject[url] = variants;
      }
      return parser(json.encode(jsonObject));
    }
  }
}

class RainViewWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new RainState();
  }
}

class RainState extends State<RainViewWidget>
    with SingleTickerProviderStateMixin {
  RadarAssetBundle assetBundle;

  Animation<int> rainRadarIndex;
  AnimationController controller;

  var radarUrls = <String>[];
  var currentRainRadarIndex = 0;
  var lastIndex = -1;

  @override
  void initState() {
    super.initState();

    assetBundle = new RadarAssetBundle();
    getRainUrls().then((rainUrls) {
      radarUrls = rainUrls;
      final duration = 2000 * radarUrls.length;
      controller = new AnimationController(
          duration: new Duration(milliseconds: duration), vsync: this);
      rainRadarIndex =
      new StepTween(begin: 0, end: radarUrls.length - 1).animate(controller)
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


      assetBundle.initAssets(rainUrls, 3, () {
        controller.forward();
      });

    });
  }

  getRainUrls() async {
    var httpClient = new HttpClient();
    var uri = new Uri.https('grundid.de', '/data/weather/files4.json',
        {'time': new DateTime.now().millisecondsSinceEpoch.toString()});
    var request = await httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    List<String> data = json.decode(responseBody);
    return data;
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
      body: rainRadarIndex == null
          ? new Image.asset("images/loading.png")
          : new Image.asset(
              "https://grundid.de/data/weather/"+radarUrls[rainRadarIndex.value],
              bundle: assetBundle,
              gaplessPlayback: true,
            ),
    );
  }
}
