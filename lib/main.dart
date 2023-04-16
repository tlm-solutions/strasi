import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stasi/db/database_bloc.dart';
import 'package:stasi/notifiers/running_recording.dart';
import 'package:stasi/util/theme.dart';
import 'package:stasi/pages/recording_manager.dart';
import 'package:stasi/pages/vehicle_selection.dart';


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
      title: 'Stasi',
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
                MaterialPageRoute(builder: (_) => MyHomePage(title: 'Stasi', databaseBloc: widget.databaseBloc)),
                    (Route <dynamic> route) => false,
              );
            },
            done: const Text("Done"),
            next: const Text("Next"),
          );
        }

        return MyHomePage(title: 'Stasi', databaseBloc: widget.databaseBloc);
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
  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ChangeNotifierProvider(
        create: (context) => RunningRecording(),
        child: PageView(
          controller: controller,
          children: [
            VehicleSelection(databaseBloc: widget.databaseBloc),
            RecordingManager(databaseBloc: widget.databaseBloc),
            const LicensePage(
              applicationName: "Stasi",
              applicationLegalese: """
                © TKFRvision All Rights Reserved
                Can we decide on FOSS-License already? For fuck's sake!
              """,
            ),
          ],
        ),
      ),
    );
  }
}
