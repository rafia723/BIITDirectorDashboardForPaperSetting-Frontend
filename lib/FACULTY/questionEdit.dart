import 'dart:typed_data';

import 'package:biit_directors_dashbooard/API/api.dart';
import 'package:biit_directors_dashbooard/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class QuestionEdit extends StatefulWidget {
  final int? cid;
  final String coursename;
  final String ccode;
  final int fid;
  final int qid;

  const QuestionEdit({
    super.key,
    required this.cid,
    required this.ccode,
    required this.coursename,
    required this.fid,
    required this.qid,
  });

  @override
  State<QuestionEdit> createState() => _QuestionEditState();
}

class _QuestionEditState extends State<QuestionEdit> {
  TextEditingController questionController = TextEditingController();
  TextEditingController marksController = TextEditingController();
  String dropdownValue = 'Easy';
  dynamic paperId;
  dynamic sid;
  DateTime? date;
  String? duration;
  String? degree;
  int tMarks = 0;
  Map<int, String> facultyNames = {};
  dynamic fname;
  String? session;
  String? term;
  int? questions;
  int? year;
  List<dynamic> list = [];
  List<dynamic> teachers = [];
  List<dynamic> qlist = [];
  //////////Question
  String? qtext;
  int? qmarks;
  String? qdifficulty;
  String? qstatus;
  int? tid;
  int? pid;
  dynamic facultyId;
  Uint8List? selectedImage;
  List<dynamic> topicList = [];
  List<bool> isCheckedList = [];
  int? selectedTopicId;
  
  List<int> selectedTopicIds = [];
  List<dynamic> cloList=[];


  @override
  void initState() {
    super.initState();
    loadTeachers();
    initializeData();
   loadTopics();
  }

  Future<void> initializeData() async {
    await loadSession();
    if (sid != null) {
      await loadPaperHeader(widget.cid!, sid);
      if (mounted) {
        setState(() {});
      }
    }
    if (paperId != null) {
      await loadQuestion(paperId);
      for (var marks in qlist) {
        tMarks += (marks['q_marks'] as int);
      }
      if (mounted) {
        setState(() {});
      }
    }
  
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please make sure to add at least one question of each difficulty level (Easy, Medium, Hard) for each topic.',
          ),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              // Add any action here if needed
            },
          ),
        ),
      );
    }

  }

  Future<void> loadFacultyName(int facultyid) async {
    try {
      fname = await APIHandler().loadFacultyName(facultyid);
      setState(() {
        facultyNames[facultyid] = fname;
      });
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

 

  

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      setState(() {
        selectedImage = bytes;
      });
    }
  }

  Future<void> loadPaperHeader(int cid, int sid) async {
    try {
      list = await APIHandler().loadPaperHeaderIfTermMidAndApproved(cid, sid);
      setState(() {});
      if (list.isNotEmpty) {
        paperId = list[0]['p_id'];
        duration = list[0]['duration'];
        degree = list[0]['degree'];
        // tMarks = list[0]['t_marks'].toString();
        session = list[0]['session'];
        term = list[0]['term'];
        questions = list[0]['NoOfQuestions'];
        year = list[0]['year'];
        date = DateTime.parse(list[0]['exam_date']);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error..'),
              content: Text(e.toString()),
            );
          },
        );
      }
    }
  }

 

  Future<void> loadQuestion(int pid) async {
  try {
    qlist = await APIHandler().loadQuestion(pid);
    List<dynamic> allCloLists = []; // List to store CLOs of all questions
    for (var question in qlist) {
      facultyId = question['f_id'];
      int qid = question['q_id'];
      List<dynamic> cloListForQuestion = await APIHandler().loadClosofSpecificQuestion(qid); // Load CLOs for each question
      allCloLists.add(cloListForQuestion); // Add CLOs to the list
      if (facultyId != null) {
        await loadFacultyName(facultyId!);
      }
    }
    setState(() {
      cloList = allCloLists; // Assign the list of CLOs to cloList
    });
  } catch (e) {
    if (mounted) {
      showErrorDialog(context, e.toString());
    }
  }
}
  Future<void> loadTopics() async {
    try {
      topicList = await APIHandler().loadTopics(widget.cid!);
      setState(() {
        if(topicList.isNotEmpty){
 isCheckedList = List<bool>.filled(topicList.length, false);
        }
      
      });
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }
  Future<void> loadTeachers() async {
    try {
      List<dynamic> teachersList =
          await APIHandler().loadTeachersByCourseId(widget.cid!);
      setState(() {
        teachers = teachersList;
      });
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error..'),
              content: Text(e.toString()),
            );
          },
        );
      }
    }
  }

  Future<void> loadSession() async {
    try {
      sid = await APIHandler().loadFirstSessionId();
      setState(() {});
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
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
      resizeToAvoidBottomInset: false,
      appBar: customAppBar(context: context, title: 'Paper Setting'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 70, // Adjust the width of the circular logo
                      height: 70, // Adjust the height of the circular logo
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white, // Adjust the border color
                          width: 1.0, // Adjust the border width
                        ),
                        image: const DecorationImage(
                          image: AssetImage(
                              'assets/images/biit.png'), // Replace with the path to your logo image
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    Text(
                      'Barani Institute of Information Technology\n       PMAS Arid Agriculture University,\n                 Rawalpindi,Pakistan\n      ${session ?? 'Session'} ${year ?? 0} : ${term ?? ''} Term Examination',
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      width: 70, // Adjust the width of the circular logo
                      height: 70, // Adjust the height of the circular logo
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white, // Adjust the border color
                          width: 1.0, // Adjust the border width
                        ),
                        image: const DecorationImage(
                          image: AssetImage(
                              'assets/images/biit.png'), // Replace with the path to your logo image
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(width: 1.0, color: Colors.black)),
                  child: GestureDetector(
                    onTap: () => {
                      Navigator.pop(context),
                    },
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Course Title: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Expanded(
                                child: Text(
                              widget.coursename,
                              //  overflow: TextOverflow.ellipsis, // Optionally, set overflow behavior
                              //      maxLines: 5,
                              style: const TextStyle(fontSize: 12),
                            )),
                            const Text(
                              'Course Code: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Expanded(
                                child: Text(
                              widget.ccode,
                              style: const TextStyle(fontSize: 12),
                            )),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Date of Exam: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Expanded(
                              child: Text(
                                '${date?.day ?? ''}/${date?.month ?? ''}/${date?.year ?? ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const Text(
                              'Duration: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Expanded(
                                child: Text(
                              duration ?? '',
                              style: const TextStyle(fontSize: 12),
                            )),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Degree Program: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Expanded(
                                child: Text(degree ?? '',
                                    style: const TextStyle(fontSize: 12))),
                            const Text(
                              'Total Marks: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Expanded(
                                child: Text(
                              '$tMarks',
                              style: const TextStyle(fontSize: 12),
                            )),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Teachers Name: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Expanded(
                              child: Text(
                                teachers.isEmpty
                                    ? 'Loading...' // Display loading text
                                    : teachers
                                        .map<String>((teacher) =>
                                            teacher['f_name'] as String)
                                        .join(', '),
                                // overflow: TextOverflow.ellipsis,
                                // maxLines: 1,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ////////////////////////////////////// Add Questions Section////////////////////////////////////////
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: questionController,
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 12.0),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(16.0)))),
                      ),
                    ),
                    IconButton(
                    onPressed: () async {
  try {
    // Validate the necessary fields
    if (questionController.text.isEmpty || marksController.text.isEmpty) {
      showErrorDialog(context, 'Please provide all necessary information');
      return; // Exit if validation fails
    }

    int? marks;
    try {
      marks = int.parse(marksController.text);
    } catch (e) {
      showErrorDialog(context, 'Invalid marks. Please enter a valid number.');
      return; // Exit if marks parsing fails
    }

    Map<String, dynamic> headerData = {
      "q_text": questionController.text,
      if (selectedImage != null) "q_image": selectedImage,
      "q_marks": marks,
      "q_difficulty": dropdownValue,
      "q_status": 'uploaded',
      if (selectedTopicId != null) "t_id": selectedTopicId,
      "p_id": paperId,
      "f_id": widget.fid,
    };

    int response = await APIHandler().updateQuestionOfSpecificQid(
      widget.qid, // Replace this with the actual question ID
      headerData,
    );

    if (response == 200) {
      if (selectedTopicIds.isNotEmpty) {
        await APIHandler().updateTopicQuestionMapping(widget.qid, selectedTopicIds);
      }
      tMarks += marks;

      questionController.clear();
      marksController.clear();
      selectedImage = null;
      selectedTopicId = null;
      setState(() {
        dropdownValue = 'Easy';
        isCheckedList = List<bool>.filled(topicList.length, false);
        selectedTopicIds.clear();
        loadQuestion(paperId!);
      });
    } else {
      if (mounted) {
        showErrorDialog(context, 'Error');
      }
    }
  } catch (e) {
    showErrorDialog(context, 'An unexpected error occurred: $e');
  }
},
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const SizedBox(height: 10),
                  if (selectedImage != null)
                    Stack(
                      children: [
                        Image.memory(
                          selectedImage!,
                          width: 200,
                          height: 200,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedImage =
                                    null; // Remove the selected image
                              });
                            },
                            child: Container(
                              color: Colors.red,
                              padding: const EdgeInsets.all(5),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Row(
                children: [
                  const Text('    Difficulty:  '),
                  DropdownButton<String>(
                    value: dropdownValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                      });
                    },
                    items: <String>['Easy', 'Medium', 'Hard']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(
                    width: 50,
                  ),
                  const Text('Topic:  '),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            //to update the status within alertbox
                            builder:
                                (BuildContext context, StateSetter setState) {
                              return AlertDialog(
                                title: const Text('Topics'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  height: 300,
                                  child: ListView.builder(
                                    itemCount: topicList.length,
                                    itemBuilder: (context, index) {
                                      final topic = topicList[index];

                                      return CheckboxListTile(
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${index + 1}. ${topic['t_name']}'),
                                          ],
                                        ),
                                        value: isCheckedList[
                                            index], // Set the initial value of checkbox

                                        onChanged: (bool? value) {
                                          setState(() {
                                            isCheckedList[index] = value!;

                                            selectedTopicId = topic['t_id'];
                                            if (value == true) {
                                              selectedTopicIds
                                                  .add(topic['t_id']);
                                            } else {
                                              selectedTopicIds
                                                  .remove(topic['t_id']);
                                              print(selectedTopicId);
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                                actions: [
                                  Center(
                                      child: customElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);

                                            print(selectedTopicIds);
                                          },
                                          buttonText: 'Save'))
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Select',
                      style: TextStyle(color: Colors.black),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Marks:  '),
                  SizedBox(
                    width: 50,
                    height: 35, // Set the width as needed
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      maxLines: 1,
                      controller: marksController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ///////////////////////////////////////////////////Questions Display///////////////////////////////////////////////////////////////
             Expanded(
  child: ListView.builder(
    itemCount: qlist.length,
    itemBuilder: (context, index) {
      final question = qlist[index];
      final imageUrl = question['q_image'];
      facultyId = question['f_id'];
      final facultyName = facultyNames[facultyId] ?? 'Loading...';

      // Load cloList for each question
      Future<List<dynamic>> loadCloList() async {
        int qid = question['q_id'];
        return await APIHandler().loadClosofSpecificQuestion(qid);
      }

      return FutureBuilder(
        future: loadCloList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('');
          } else if (snapshot.hasError) {
            return Text('Error loading CLOs: ${snapshot.error}');
          } else {
            List<dynamic> cloListForQuestion = snapshot.data ?? [];
            return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              color: Colors.white.withOpacity(0.8),
              child: ListTile(
                tileColor: Colors.white,
                title: Text(
                  'Question # ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question['q_text']),
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        height: 150,
                        width: 300,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const CircularProgressIndicator();
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Text('Error loading image: $error');
                        },
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${question['q_difficulty']},'),
                        Text('${question['q_marks']},'),
                        Text('$facultyName,'),
                        Text(
                          'CLOs: ${cloListForQuestion.map((entry) => entry['clo_number'] as String).join(', ')}'
                        )
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        },
      );
    },
  ),
),
// customElevatedButton(onPressed: (){
//   Navigator.pop(context);
// }, buttonText: 'Save')
            ],
          )
        ],
      ),
    );
  }
}
