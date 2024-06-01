import 'package:biit_directors_dashbooard/API/api.dart';
import 'package:biit_directors_dashbooard/customWidgets.dart';
import 'package:flutter/material.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final TextEditingController sessionNameController = TextEditingController();
  final TextEditingController sessionYearController = TextEditingController();
  List<dynamic> list = [];
  bool isPressed = false;
  dynamic sid;

  String activeSession = '';

  Future<void> loadSession() async {
    try {
      list = await APIHandler().loadSession();
      for (var session in list) {
        if (session['flag'] == 'active') {
          activeSession = "${session['s_name']}-${session['year']}";
          break;
        }
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  Future<void> setActiveSession(String sessionId) async {
    try {
      int code = await APIHandler().updateSessionStatus(int.parse(sessionId));
      if (code == 200) {
       
        setState(() {
          
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: customAppBar(context: context, title: 'Manage Session'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Session Name',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    focusColor: Colors.black,
                    fillColor: Colors.white70,
                    filled: true,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  controller: sessionNameController,
                  maxLines: 1,
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Session Year',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    focusColor: Colors.black,
                    fillColor: Colors.white70,
                    filled: true,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  controller: sessionYearController,
                  maxLines: 1,
                ),
                customElevatedButton(
                  onPressed: () async {
                    if (!isPressed) {
                      int code = await APIHandler().addSession(sessionNameController.text, int.parse(sessionYearController.text), 'inactive');
                      if (code == 200) {
                        if (mounted) {
                          showSuccesDialog(context, 'Session Added');
                        }
                        setState(() {
                          loadSession();
                          isPressed = false;
                          sessionNameController.clear();
                          sessionYearController.clear();
                        });
                      }
                    } else {
                      int code = await APIHandler().updateSession(sid, sessionNameController.text, int.parse(sessionYearController.text));
                      if (code == 200) {
                        if (mounted) {
                          showSuccesDialog(context, 'Updated');
                          setState(() {
                            loadSession();
                            isPressed = false;
                            sessionNameController.clear();
                            sessionYearController.clear();
                          });
                        }
                      }
                    }
                  },
                  buttonText: isPressed == false ? 'Add' : 'Update',
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      String session = "${list[index]['s_name']}-${list[index]['year']}";
                      bool isActive = session == activeSession;
                      return ListTile(
                        title: Text(
                          session,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Wrap(
                          spacing: 12, // space between two icons
                          children: <Widget>[
                            SizedBox(
                              width: 117,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await setActiveSession(list[index]['s_id'].toString());
                                  setState(() {
                                    activeSession = "${list[index]['s_name']}-${list[index]['year']}";
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isActive ? const Color.fromARGB(255, 113, 212, 116) : const Color.fromARGB(255, 231, 81, 70),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(isActive ? 'Active' : 'Set Active'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                isPressed = true;
                                sessionNameController.text = list[index]['s_name'];
                                sessionYearController.text = list[index]['year'].toString();
                                sid = list[index]['s_id'];
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}