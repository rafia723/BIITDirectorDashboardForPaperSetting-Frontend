import 'package:biit_directors_dashbooard/API/api.dart';
import 'package:biit_directors_dashbooard/Director/ApprovedPapersList.dart';
import 'package:biit_directors_dashbooard/Director/UnUploadedPapers.dart';
import 'package:biit_directors_dashbooard/Director/UploadedPapersList.dart';
import 'package:biit_directors_dashbooard/customWidgets.dart';
import 'package:flutter/material.dart';

class Director extends StatefulWidget {
  const Director({super.key});

  @override
  State<Director> createState() => _DirectorState();
}

class _DirectorState extends State<Director> {

   List<dynamic> ulist=[];
  @override
  void initState() {
    super.initState();
    loadUploadedPapersData();
  }
Future<void> loadUploadedPapersData() async {
   try {
       ulist =await APIHandler().loadUploadedPapers();
      setState(() {});
   } catch (e) {
    if(mounted){
     showDialog(
        context: context,
        builder: (context) {
          return  AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
          );
        },
      );
    }
   }
    
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        backgroundColor: customAppBarColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        title: const Text(
          'Director Dashboard',
          style: TextStyle(fontSize: 21.0, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
            child: const Icon(Icons.logout),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        )),
        body: Stack(children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.png', // Replace with the path to your background image
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(height: 10),
                  const Text(
                    'Welcome, Dr. Jameel Sawar!', // Replace with the actual user's name
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 100),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                          ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>  DRTUploadedPapers(
                                  list: ulist,
                                ),

                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: customButtonColor,
                            minimumSize: const Size(160, 80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                          child: const Text('       Uploaded        \n         Papers',
                              style: TextStyle(color: Colors.black)),
                        ),
                          const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DRTApprovedPapers(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: customButtonColor,
                            minimumSize: const Size(160, 80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                          child: const Text('Approved/Printed\n         Papers',
                              style: TextStyle(color: Colors.black)),
                        ),
                        const SizedBox(height: 30),
                      
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UnUploadedPapersScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: customButtonColor,
                            minimumSize: const Size(160, 80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                          child: const Text('    Un-Uploaded     \n         Papers',
                              style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]));
  }
}