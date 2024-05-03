import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:strasi/db/database_bloc.dart';
import 'package:strasi/notifiers/tracking_state_notifier.dart';
import 'package:strasi/pages/live_view.dart';
import 'package:strasi/util/theme.dart';
import 'package:strasi/pages/recording_manager.dart';
import 'package:strasi/pages/vehicle_selection.dart';
import 'package:strasi/util/app_version.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseBloc = DatabaseBloc();

  runApp(MyApp(databaseBloc: databaseBloc));
}

class MyApp extends StatelessWidget {
  final DatabaseBloc databaseBloc;
  const MyApp({Key? key, required this.databaseBloc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strasi',
      theme: appTheme,
      home: Builder(
        builder: (context) {
          return BoardingPage(databaseBloc: databaseBloc);
        },
      ),
    );
  }
}

class BoardingPage extends StatefulWidget {
  const BoardingPage({super.key, required this.databaseBloc});

  final DatabaseBloc databaseBloc;

  @override
  State<StatefulWidget> createState() => _BoardingPageState();

}

class _BoardingPageState extends State<BoardingPage> {

  Future<bool> _shouldShowIntroduction() async {
    const hasShownIntroduction = "has_shown_introduction";

    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(hasShownIntroduction) && prefs.getBool(hasShownIntroduction)!) {
      return false;
    }

    await prefs.setBool(hasShownIntroduction, true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _shouldShowIntroduction(),
      builder: (context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error!;
        } else if (!snapshot.hasData) {
          return const Offstage();
        }

        final shouldShowIntroduction = snapshot.data!;

        if (shouldShowIntroduction) {
          return IntroductionScreen(
            pages: [
              PageViewModel(
                title: "Data Protection",
                body: 'By using this app you agree to:\nDatenschutzerklärung\n\nPersonenbezogene Daten (nachfolgend zumeist nur „Daten" genannt) werden von uns nur im Rahmen der Erforderlichkeit sowie zum Zwecke der Bereitstellung eines funktionsfähigen und nutzerfreundlichen Internetauftritts, inklusive seiner Inhalte und der dort angebotenen Leistungen, verarbeitet.\n\nGemäß Art. 4 Ziffer 1. der Verordnung (EU) 2016/679, also der Datenschutz-Grundverordnung (nachfolgend nur „DSGVO" genannt), gilt als „Verarbeitung" jeder mit oder ohne Hilfe automatisierter Verfahren ausgeführter Vorgang oder jede solche Vorgangsreihe im Zusammenhang mit personenbezogenen Daten, wie das Erheben, das Erfassen, die Organisation, das Ordnen, die Speicherung, die Anpassung oder Veränderung, das Auslesen, das Abfragen, die Verwendung, die Offenlegung durch Übermittlung, Verbreitung oder eine andere Form der Bereitstellung, den Abgleich oder die Verknüpfung, die Einschränkung, das Löschen oder die Vernichtung.\n\nMit der nachfolgenden Datenschutzerklärung informieren wir Sie insbesondere über Art, Umfang, Zweck, Dauer und Rechtsgrundlage der Verarbeitung personenbezogener Daten, soweit wir entweder allein oder gemeinsam mit anderen über die Zwecke und Mittel der Verarbeitung entscheiden. Zudem informieren wir Sie nachfolgend über die von uns zu Optimierungszwecken sowie zur Steigerung der Nutzungsqualität eingesetzten Fremdkomponenten, soweit hierdurch Dritte Daten in wiederum eigener Verantwortung verarbeiten.\n\nUnsere Datenschutzerklärung ist wie folgt gegliedert:\n\nI. Informationen über uns als Verantwortliche\nII. Rechte der Nutzer und Betroffenen\nIII. Informationen zur Datenverarbeitung\nI. Informationen über uns als Verantwortliche\n\nVerantwortlicher Anbieter dieses Internetauftritts im datenschutzrechtlichen Sinne ist:\nhello.tlm.solutions\n\nII. Rechte der Nutzer und Betroffenen\n\nMit Blick auf die nachfolgend noch näher beschriebene Datenverarbeitung haben die Nutzer und Betroffenen das Recht\n\n    auf Bestätigung, ob sie betreffende Daten verarbeitet werden, auf Auskunft über die verarbeiteten Daten, auf weitere Informationen über die Datenverarbeitung sowie auf Kopien der Daten (vgl. auch Art. 15 DSGVO);\n    auf Berichtigung oder Vervollständigung unrichtiger bzw. unvollständiger Daten (vgl. auch Art. 16 DSGVO);\n    auf unverzügliche Löschung der sie betreffenden Daten (vgl. auch Art. 17 DSGVO), oder, alternativ, soweit eine weitere Verarbeitung gemäß Art. 17 Abs. 3 DSGVO erforderlich ist, auf Einschränkung der Verarbeitung nach Maßgabe von Art. 18 DSGVO;\n    auf Erhalt der sie betreffenden und von ihnen bereitgestellten Daten und auf Übermittlung dieser Daten an andere Anbieter/Verantwortliche (vgl. auch Art. 20 DSGVO);\n    auf Beschwerde gegenüber der Aufsichtsbehörde, sofern sie der Ansicht sind, dass die sie betreffenden Daten durch den Anbieter unter Verstoß gegen datenschutzrechtliche Bestimmungen verarbeitet werden (vgl. auch Art. 77 DSGVO).\n\nDarüber hinaus ist der Anbieter dazu verpflichtet, alle Empfänger, denen gegenüber Daten durch den Anbieter offengelegt worden sind, über jedwede Berichtigung oder Löschung von Daten oder die Einschränkung der Verarbeitung, die aufgrund der Artikel 16, 17 Abs. 1, 18 DSGVO erfolgt, zu unterrichten. Diese Verpflichtung besteht jedoch nicht, soweit diese Mitteilung unmöglich oder mit einem unverhältnismäßigen Aufwand verbunden ist. Unbeschadet dessen hat der Nutzer ein Recht auf Auskunft über diese Empfänger.\n\nEbenfalls haben die Nutzer und Betroffenen nach Art. 21 DSGVO das Recht auf Widerspruch gegen die künftige Verarbeitung der sie betreffenden Daten, sofern die Daten durch den Anbieter nach Maßgabe von Art. 6 Abs. 1 lit. f) DSGVO verarbeitet werden. Insbesondere ist ein Widerspruch gegen die Datenverarbeitung zum Zwecke der Direktwerbung statthaft.\nIII. Informationen zur Datenverarbeitung\n\nIhre bei Nutzung unseres Internetauftritts verarbeiteten Daten werden gelöscht oder gesperrt, sobald der Zweck der Speicherung entfällt, der Löschung der Daten keine gesetzlichen Aufbewahrungspflichten entgegenstehen und nachfolgend keine anderslautenden Angaben zu einzelnen Verarbeitungsverfahren gemacht werden.\nServerdaten\n\nAus technischen Gründen, insbesondere zur Gewährleistung eines sicheren und stabilen Internetauftritts, werden Daten durch Ihren Internet-Browser an uns bzw. an unseren Webspace-Provider übermittelt. Mit diesen sog. Server-Logfiles werden u.a. Typ und Version Ihres Internetbrowsers, das Betriebssystem, die Website, von der aus Sie auf unseren Internetauftritt gewechselt haben (Referrer URL), die Website(s) unseres Internetauftritts, die Sie besuchen, Datum und Uhrzeit des jeweiligen Zugriffs sowie die IP-Adresse des Internetanschlusses, von dem aus die Nutzung unseres Internetauftritts erfolgt, erhoben.\n\nDiese so erhobenen Daten werden vorrübergehend gespeichert, dies jedoch nicht gemeinsam mit anderen Daten von Ihnen.\n\nDiese Speicherung erfolgt auf der Rechtsgrundlage von Art. 6 Abs. 1 lit. f) DSGVO. Unser berechtigtes Interesse liegt in der Verbesserung, Stabilität, Funktionalität und Sicherheit unseres Internetauftritts.\n\nDie Daten werden spätestens nach sieben Tage wieder gelöscht, soweit keine weitere Aufbewahrung zu Beweiszwecken erforderlich ist. Andernfalls sind die Daten bis zur endgültigen Klärung eines Vorfalls ganz oder teilweise von der Löschung ausgenommen.\nOpenStreetMap\n\nFür Anfahrtsbeschreibungen setzen wir OpenStreetMap, einen Dienst der OpenStreetMap Foundation, St John’s Innovation Centre, Cowley Road, Cambridge, CB 4 0 WS, United Kingdom, nachfolgend nur „OpenStreetMap" genannt, ein.\n\nBei Aufruf einer unserer Internetseiten, in die der Dienst OpenStreetMap eingebunden ist, wird durch OpenStreetMap ein Cookie über Ihren Internet-Browser auf Ihrem Endgerät gespeichert. Hierdurch werden Ihre Nutzereinstellungen und Nutzerdaten zum Zwecke der Anzeige der Seite bzw. zur Gewährleistung der Funktionalität des Dienstes OpenStreetMap verarbeitet. Durch diese Verarbeitung kann OpenStreetMap erkennen, von welcher Internetseite Ihre Anfrage gesendet worden ist und an welche IP- Adresse die Darstellung der Anfahrt übermittelt werden soll.\n\nIm Falle einer von Ihnen erteilten Einwilligung für diese Verarbeitung ist Rechtsgrundlage Art. 6 Abs. 1 lit. a DSGVO. Rechtsgrundlage kann auch Art. 6 Abs. 1 lit. f DSGVO sein. Unser berechtigtes Interesse liegt in der Optimierung und dem wirtschaftlichen Betrieb unseres Internetauftritts.\n\nSofern Sie mit dieser Verarbeitung nicht einverstanden sind, haben Sie die Möglichkeit, die Installation der Cookies durch die entsprechenden Einstellungen in Ihrem Internet-Browser zu verhindern. Einzelheiten hierzu finden Sie vorstehend unter dem Punkt „Cookies".\n\nOpenStreetMap bietet unter\n\nhttps://wiki.osmfoundation.org/wiki/Privacy_Policy\n\nweitere Informationen zur Erhebung und Nutzung der Daten sowie zu Ihren Rechten und Möglichkeiten zum Schutz Ihrer Privatsphäre an.\n\nMuster-Datenschutzerklärung der Anwaltskanzlei Weiß & Partner',
              ),
              PageViewModel(
                title: "Welcome 🤗",
                body: "Hello Tram Enthusiast,\n\nYou are here to track some trams. Here is how it works in 5 easy steps.\n\nBy burts - photo taken by burts, CC BY-SA 3.0, https://commons.wikimedia.org/w/index.php?curid=723883",
                image: const Image(image: AssetImage("assets/tram_front.png")),
                decoration: const PageDecoration(
                    imagePadding: EdgeInsets.only(top: 25.0),
                ),
              ),
              PageViewModel(
                title: "Select a region",
                body: "Use the selector 😉.",
              ),
              PageViewModel(
                title: "Press the enter button",
                body: "This will start the recording.\nEnter the line and the run number.\nYou can find them by looking over the shoulder of the tram/bus driver.",
                image: const Image(image: AssetImage("assets/interface_bus.png")),
                decoration: const PageDecoration(
                    imagePadding: EdgeInsets.only(top: 25.0),
                ),
              ),
              PageViewModel(
                title: "Edit and Submit",
                body: "Edit the recording to perfectly fit the actual run and press the little upload symbol.",
              ),
              PageViewModel(
                title: "And now you're golden",
                body: "That's all folks. Happy tracking.",
              ),
            ],
            onDone: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => MyHomePage(title: 'Strasi', databaseBloc: widget.databaseBloc)),
                    (Route <dynamic> route) => false,
              );
            },
            done: const Text("Done"),
            next: const Text("Next"),
          );
        }

        return MyHomePage(title: 'Strasi', databaseBloc: widget.databaseBloc);
      }
    );


  }

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.databaseBloc}) : super(key: key);

  final String title;
  final DatabaseBloc databaseBloc;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ChangeNotifierProvider(
        create: (context) => TrackingStateNotifier(),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            VehicleSelection(databaseBloc: widget.databaseBloc),
            RecordingManager(databaseBloc: widget.databaseBloc),
            const LiveView(),
            FutureBuilder(
              future: _getLicensePageData(),
              builder: (context, AsyncSnapshot<_LicensePageData> snapshot) {
                if (snapshot.hasError) {
                  throw snapshot.error!;
                } else if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final data = snapshot.data!;

                final commitId = data.commitId.trim().substring(0, 8);
                var userId = "";
                if (data.userId != null) {
                  userId = " [user id: ${data.userId}]";
                }

                return LicensePage(
                  applicationName: "Strasi ($commitId)$userId",
                  applicationLegalese: """Copyright 2023 TLM Solutions

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.""",
                );
              },
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.ease,
            );
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.tram),
            label: "Track",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Runs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv),
            label: "Live View",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: "Legal",
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _LicensePageData {
  final String commitId;
  final String? userId;

  const _LicensePageData({
    required this.commitId,
    required this.userId,
  });
}

Future<_LicensePageData> _getLicensePageData() async {
  final commitId = await AppVersion.getCommitId();
  final userId = (await SharedPreferences.getInstance()).getString("user_id");

  return _LicensePageData(commitId: commitId, userId: userId);
}

