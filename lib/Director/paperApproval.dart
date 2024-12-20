import 'dart:convert';

import 'package:biit_directors_dashbooard/API/api.dart';
import 'package:biit_directors_dashbooard/Director/ApprovedPapersList.dart';
import 'package:biit_directors_dashbooard/Director/UploadedPapersList.dart';
import 'package:biit_directors_dashbooard/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaperApproval extends StatefulWidget {
  final int cid;
  final String coursename;
  final String ccode;
  final String? status;
  final int pid;
    
   const PaperApproval({
    Key? key,
    required this.cid,
    required this.ccode,
    required this.coursename,
    required this.pid,

    this.status,
  }) : super(key: key);

  @override
  State<PaperApproval> createState() => _PaperApprovalState();
}

class _PaperApprovalState extends State<PaperApproval> {
  List<dynamic> plist = [];
  List<dynamic> aplist = [];
  List<dynamic> qlist = [];
      List<dynamic> list=[];
  String? rejected;
  dynamic paperId;
  String? duration;
  String? degree;
  int tMarks = 0;
  String? session;
   int? noOfQuestions;
  String? term;
  int? year;
  DateTime? date;
int questionCountAcceptedOrRejected=0;
  List<dynamic> teachers = [];
  dynamic sid;
  bool isChecked = false;
  bool acceptAllChecked = false; // State variable for "Accept All" checkbox
  Map<int, List<dynamic>> cloMap = {};
  Map<int, TextEditingController> commentControllers =
      {}; // Map for controllers
  Map<int, String> statusMap = {};
  int acceptCount = 0;
  int rejectCount = 0;
  Map<int, List<dynamic>> cloListsForQuestions = {};
   Map<int, List<dynamic>> rejectedQuestionFeedback = {};
  dynamic qNoCounter;
  List<dynamic> listOfClos = [];
  List<int> missingcloss = [];
  List<dynamic> paperGridWeightageOfTerm = [];
  List<int> cloIdsShouldbeAddedList = [];
  List<int> cloWeightageCheck = [];
  Map<int, bool> editingModeMap =
      {}; // Map to track editing mode for each question
  Map<int, TextEditingController> textEditingControllers =
      {}; // Controllers for each TextFormField
  Map<int, List<dynamic>> subQuestions = {};
  List<dynamic> subqlist = [];
  List<dynamic> topicsInPaperList = [];
  List<dynamic> difficultyList=[];
  int easyCount=0;
    int mediumCount=0;
      int hardCount=0;
      int easySelected=0;
      int mediumSelected=0;
      int hardSelected=0;
      int totalQuestion=0;
      int? fid;

     TextEditingController commentController=TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeData();
    loadQuestionsWithUploadedAndApprovedStatus(widget.pid);
    
    
  }

  Future<void> initializeData() async {
    await loadSession();
    if(mounted){
 setState(() {});
    }
    loadTeachers();

    if (sid != null) {
      loadPaperHeaderData(widget.cid, sid!);
    }
   
        
    
    await loadQuestionsWithUploadedAndApprovedStatus(widget.pid);
    if (qlist.isNotEmpty) {
      for (var question in qlist) {
        if (question['q_status'] == 'approved') {
          int qMarks = question['q_marks'];
          if (mounted) {
            setState(() {
              tMarks += qMarks;
              if (qNoCounter != null) {
                qNoCounter--;
              }
              if(question['q_status']=='approved'&&question['q_difficulty']=='Easy'){
      easySelected++;
              }
         if(question['q_status']=='approved'&&question['q_difficulty']=='Medium'){
      mediumSelected++;
              }
              if(question['q_status']=='approved'&&question['q_difficulty']=='Hard'){
      hardSelected++;
              }
            });
          }
          questionCountAcceptedOrRejected++;
        }
      }
      loadCloListsForQuestions();
      checksFunction();
    }
  }

    Future<void> loadDifficulty(int noOfQuest) async {
    try {
      difficultyList = await APIHandler().loadDifficulty(noOfQuest);
      setState(() {
        if (difficultyList.isNotEmpty) {
          easyCount = difficultyList[0]['Easy'];
          mediumCount = difficultyList[0]['Medium'];
          hardCount = difficultyList[0]['Hard'];
        }
      });
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> checksFunction() async {
    // Collect all CLOs for selected questions
    List<List<String>> allCloLists = [];
    for (var question in qlist) {
      int qid = question['q_id'];
      List<String> cloListForQuestion = await loadClosofSpecificQuestion(qid);
      allCloLists.add(cloListForQuestion);
    }

    // Deduct marks for questions already marked as uploaded

    cloIdsShouldbeAddedList.clear();
    for (var item in paperGridWeightageOfTerm) {
      try {
        cloIdsShouldbeAddedList.add(int.parse(item['clonumber']));
      } catch (e) {
        print('Error parsing clonumber: ${item['clonumber']}');
      }
    }
    print(' CLOs should be added: $cloIdsShouldbeAddedList');

    List<int> selectedQuestionIds = qlist
        .where((question) => question['q_status'] == 'approved')
        .map<int>((question) => question['q_id'] as int)
        .toList();
    missingcloss =
        await findMissingCLOs(selectedQuestionIds, cloIdsShouldbeAddedList);

    print('Missing CLOs: $missingcloss');
  }



  Future<List<int>> findMissingCLOs(
      List<int> selectedQuestionIds, List<int> cloIdsShouldbeAddedList) async {
    Set<int> actualCLOs = {};

    for (int questionId in selectedQuestionIds) {
      List<String> cloStrings = await loadClosofSpecificQuestion(questionId);
      actualCLOs.addAll(cloStrings.map((clo) => int.parse(clo)));
    }
    Set<int> notInCloGridSpecificTerm =
        actualCLOs.difference(cloIdsShouldbeAddedList.toSet());
    cloWeightageCheck = notInCloGridSpecificTerm.toList();
    print('Dont have weightage in this term $notInCloGridSpecificTerm');
    print('Actual $actualCLOs');
    List<int> missingcloss =
        cloIdsShouldbeAddedList.toSet().difference(actualCLOs).toList();
    return missingcloss;
  }

  // Future<bool?> customConfirmationDialog(BuildContext context,
  //     {required String title, required String content}) {
  //   return showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(title),
  //         content: Text(content),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(false);
  //             },
  //             child: const Text('No'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(true);
  //             },
  //             child: const Text('Yes'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

bool? isPressed;
  Future<bool?> customConfirmationDialog(BuildContext context,
      {required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
             TextFormField(
            controller: commentController,
            decoration: const InputDecoration(
              hintText: 'Enter Comment...',
            ),
          ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Continue'),
            ),
            TextButton(
              onPressed: () {
               // Navigator.of(context).pop(true);
          isPressed==true;
if(mounted){
  setState(() {
      Navigator.of(context).pop(true);
  });
}
              },
              child: const Text('Send Immediate Feedback'),
            ),
          ],
        );
      },
    );
  }

  

  Future<void> loadClosWeightageofSpecificCourseAndHeaderName(
      int cid, String term) async {
    try {
      List<dynamic> list = await APIHandler()
          .loadClosWeightageofSpecificCourseAndHeaderName(cid, term);
      if (list.isNotEmpty) {
        paperGridWeightageOfTerm = list;
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

  Future<List<String>> loadClosofSpecificQuestion(int qid) async {
    try {
      Uri uri = Uri.parse(
          '${APIHandler().apiUrl}QuestionTopic/getClosOfSpecificQuesestion/$qid');
      var response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> cloData = jsonDecode(response.body);
        List<String> cloNumbers =
            cloData.map((data) => data['clo_number'].toString()).toList();
        return cloNumbers;
      } else {
        throw Exception('Error fetching CLOs for question');
      }
    } catch (e) {
      throw Exception('Failed to load CLOs mapped with question');
    }
  }

  Future<void> loadCloListsForQuestions() async {
    for (var question in qlist) {
      int qid = question['q_id'];
      List<dynamic> cloListForQuestion =
          await APIHandler().loadClosofSpecificQuestion(qid);
      cloListsForQuestions[qid] = cloListForQuestion;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadPaperHeaderData(int cid, int sid) async {
    try {
      plist = await APIHandler().loadPaperHeaderIfTermMidAndApproved(cid, sid);
      setState(() {
        if (plist.isNotEmpty) {
          paperId = plist[0]['p_id'];
          duration = plist[0]['duration'];
          degree = plist[0]['degree'];
          //  tMarks = plist[0]['t_marks'].toString();
          session = plist[0]['session'];
          term = plist[0]['term'];
          noOfQuestions = plist[0]['NoOfQuestions'];
        qNoCounter = noOfQuestions;
             totalQuestion = noOfQuestions!;
          year = plist[0]['year'];
          date = DateTime.parse(plist[0]['exam_date']);
        }
      });

       await loadDifficulty(noOfQuestions!);
      await loadClosWeightageofSpecificCourseAndHeaderName(widget.cid, term!);
      setState(() {});
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

  Future<void> loadTeachers() async {
    try {
      List<dynamic> teachersList =
          await APIHandler().loadTeachersByCourseId(widget.cid);
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

  Future<void> loadQuestionsWithUploadedAndApprovedStatus(int pid) async {
    try {
      qlist = await APIHandler().loadQuestionsWithUploadedStatus(pid);
      if (qlist.isNotEmpty) {
        await loadCloListsForQuestions();
      }
      List<dynamic> allCloLists = []; // List to store CLOs of all questions
      for (var question in qlist) {
        int qid = question['q_id'];
        await loadSubQuestionData(question['q_id']);
        List<dynamic> cloListForQuestion = await APIHandler()
            .loadClosofSpecificQuestion(qid); // Load CLOs for each question
        allCloLists.add(cloListForQuestion); // Add CLOs to the list

        if (!commentControllers.containsKey(qid)) {
          // Add a TextEditingController to the commentControllers map if it doesn't exist
          commentControllers[qid] = TextEditingController();
        }
        // Set the initial status of each question in the statusMap
        statusMap[qid] = question['q_status'];
      }
      setState(() {
        listOfClos = allCloLists; // Assign the list of CLOs to listOfClos
      });
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

  Future<void> loadSubQuestionData(int qid) async {
    try {
      subqlist = await APIHandler().loadSubQuestionOfSpecificQid(qid);
      setState(() {
        subQuestions[qid] = subqlist;
      });
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> updateQuestionStatus(int qid, String newStatus) async {
    try {
      dynamic code = await APIHandler()
          .updateQuestionStatusToApprovedOrRejected(qid, newStatus);
      if (mounted) {
        if (code == 200) {
          setState(() {
            statusMap[qid] = newStatus;
            loadQuestionsWithUploadedAndApprovedStatus(paperId);
          });
        } else {
          throw Exception('Non-200 response code code=$code');
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error changing status of question'),
              content: Text(e.toString()), // Optionally show the error message
            );
          },
        );
      }
    }
  }

  Future<void> updatePaperStatusToApprovedd(int pid) async {
    try {
      dynamic code = await APIHandler().updatePaperStatusToApproved(pid);

      if (mounted) {
        if (code == 200) {
          setState(() {
            showSuccesDialog(context, 'Paper Approved');
          });
        } else {
          throw Exception('Non-200 response code code=$code');
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error changing status of paper'),
              content: Text(e.toString()), // Optionally show the error message
            );
          },
        );
      }
    }
  }

  Future<void> addFeedbackData(
      String feedbackText, int pid, int? qid, int? fid) async {
    try {
      dynamic code =
          await APIHandler().addFeedback(feedbackText, pid, qid, fid);
      setState(() {});
      if (code == 200) {
        if (mounted) {
          showSuccesDialog(context, 'Comment Posted....');
          commentControllers[qid]?.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Error posting Comment');
      }
    }
  }

  Future<void> loadApprovedPapersData() async {
    try {
      aplist = await APIHandler().loadApprovedPapers();
      setState(() {});
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error loading approved papers'),
              content: Text(e.toString()),
            );
          },
        );
      }
    }
  }

  // Future<void> updateAllStatuses(String newStatus) async {
  //   try {
  //     qNoCounter = noOfQuestions;
  //     tMarks = 0;
  //     for (var question in qlist) {
  //       int qid = question['q_id'];
  //       int qmarks = question['q_marks'];

  //       tMarks += qmarks;
  //       qNoCounter--;
  //       await updateQuestionStatus(qid, newStatus);
  //     }
  //     setState(() {
  //       for (var question in qlist) {
  //         int qid = question['q_id'];
  //         statusMap[qid] = newStatus;
  //       }
  //       print('hehe all accept $qNoCounter');
  //     });
  //   } catch (e) {
  //     if (mounted) {
  //       showDialog(
  //         context: context,
  //         builder: (context) {
  //           return AlertDialog(
  //             title: const Text('Error changing statuses of all questions'),
  //             content: Text(e.toString()), // Optionally show the error message
  //           );
  //         },
  //       );
  //     }
  //   }
  // }

  // Future<void> revertAllStatuses() async {
  //   try {
  //     qNoCounter = 0;
  //     for (var question in qlist) {
  //       int qid = question['q_id'];

  //       int qmarks = question['q_marks'];
  //       tMarks -= qmarks;
  //       qNoCounter++;
  //       await updateQuestionStatus(qid, 'uploaded');
  //     }
  //     setState(() {
  //       for (var question in qlist) {
  //         int qid = question['q_id'];
  //         statusMap[qid] = 'uploaded';
  //       }
  //       print('hehe all reject $qNoCounter');
  //     });
  //   } catch (e) {
  //     if (mounted) {
  //       showDialog(
  //         context: context,
  //         builder: (context) {
  //           return AlertDialog(
  //             title: const Text('Error reverting statuses of all questions'),
  //             content: Text(e.toString()), // Optionally show the error message
  //           );
  //         },
  //       );
  //     }
  //   }
  // }

  @override
  void dispose() {
    // Dispose of each TextEditingController to free resources
    textEditingControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: customAppBar(context: context, title: 'Paper Approval'),
      body: Stack(children: [
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
        Column(children: [
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
                  'Barani Institute of Information Technology\n       PMAS Arid Agriculture University,\n                 Rawalpindi,Pakistan\n      ${session ?? 'Session'} ${year ?? 'Loading...'} : ${term ?? ''} Term Examination',
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
                            '${date?.day ?? ''}/${date?.month ?? ''}/${date?.year ?? 'Loading...'}',
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
                          duration ?? 'Loading...',
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
                            child: Text(degree ?? 'Loading...',
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
          // if (qNoCounter == 0)
          //   Row(
          //     children: [
          //       const SizedBox(
          //         width: 280,
          //       ),
          //       const Text('Accept All'),
          //       Checkbox(
          //         value: acceptAllChecked,
          //         onChanged: (value) {
          //           setState(() {
          //             acceptAllChecked = value ?? false;
          //             if (acceptAllChecked) {
          //               updateAllStatuses('approved');
          //             } else {
          //               revertAllStatuses(); // Reset or handle as needed
          //             }
          //           });
          //         },
          //       ),
          //     ],
          //   ),
            Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Row(
                children: [
                  // const SizedBox(
                  //   width: 10,
                  // ),
                  Text('Questions:  $questionCountAcceptedOrRejected/$totalQuestion'),
                  const SizedBox(
                    width: 10,
                  ),
                 
                      Text('Easy:  $easySelected/$easyCount'),
                  const SizedBox(
                    width: 10,
                  ),
                      Text('Medium:  $mediumSelected/$mediumCount'),
                  const SizedBox(
                    width: 10,
                  ),
                    Text('Hard:  $hardSelected/$hardCount'),
                  const SizedBox(
                    width: 10,
                  ),
                   
                 
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(onPressed: (){}, icon: const Icon(Icons.comment),),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: qlist.length,
              itemBuilder: (context, index) {
                final question = qlist[index];
                final imageUrl = question['q_image'];
                final qDifficulty = question['q_difficulty'];
                final qid = question['q_id'];
                final fid = question['f_id'];
                
                List<dynamic> cloListForQuestion =
                    cloListsForQuestions[question['q_id']] ?? [];
                List<dynamic> sqlist = subQuestions[question['q_id']] ?? [];

                // Determine if currently in edit mode
                bool isEditing = editingModeMap.containsKey(qid)
                    ? editingModeMap[qid]!
                    : false;
                final TextEditingController controller =
                    textEditingControllers[qid] ??=
                        TextEditingController(text: question['q_text']);
                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  color: Colors.white.withOpacity(0.8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Toggle editing mode
                        editingModeMap[qid] = !isEditing;
                      });
                    },
                    child: SingleChildScrollView(
                      child: ListTile(
                        tileColor: Colors.white,
                        title: Text(
                          'Question # ${index + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display either text or text form field based on editing mode
                            isEditing
                                ? TextFormField(
                                    controller: controller,
                                    onChanged: (newValue) async {
                                      // Update local state with new value
                                      setState(() {
                                        question['q_text'] = newValue;
                                      });

                                      // Handle immediate submission of new value to update database
                                      int statusCode = await APIHandler()
                                          .updateQuestionText(qid, newValue);
                                      if (statusCode != 200) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Failed to update question text')),
                                          );
                                        }
                                      }
                                    },
                                    onFieldSubmitted: (newValue) {
                                      // Exit editing mode when done
                                      setState(() {
                                        editingModeMap[qid] = false;
                                      });
                                    },
                                  )
                                : Text(question['q_text']),
                            if (imageUrl != null)
                              Image.network(
                                imageUrl,
                                height: 150,
                                width: 300,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const CircularProgressIndicator();
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Text('Error loading image: $error');
                                },
                              ),
                            if (sqlist.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...sqlist.asMap().entries.map((entry) {
                                    int idx = entry.key;
                                    var subQuestion = entry.value;
                                    return Column(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                      '   ${String.fromCharCode(97 + idx)}.  ${subQuestion['sq_text']}'),
                                                ),
                                              ],
                                            ),
                                            if (subQuestion['sq_image'] != null)
                                              Image.network(
                                                subQuestion['sq_image'],
                                                height: 150,
                                                width: 300,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return const CircularProgressIndicator();
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Text(
                                                      'Error loading image: $error');
                                                },
                                              ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('${question['q_difficulty']},'),
                                Text('${question['q_marks']},'),
                                Text(
                                    'CLOs: ${cloListForQuestion.isEmpty ? 'Loading...' : cloListForQuestion.map((entry) => entry['clo_number'] as String).join(', ')}'),
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 170,
                                ),
                                const Text('Accept'),
                                Radio(
                                  value: 'approved',
                                  groupValue: statusMap[qid],
                                  onChanged: (value) {
                                    setState(() {
                                      statusMap[qid] = value!;

                                      tMarks += question['q_marks'] as int;
                                      qNoCounter--;
                                      questionCountAcceptedOrRejected++;
                                      if(question['q_difficulty']=='Easy'){
                                        easySelected++;
                                      }else if(question['q_difficulty']=='Medium'){
                                          mediumSelected++;
                                      }
                                      else if(question['q_difficulty']=='Hard'){
                                          hardSelected++;
                                      }
                                      print('After approval $qNoCounter');
                                      checksFunction();
                                    });
                                    updateQuestionStatus(qid, value!);
                                  },
                                ),
                                const Text('Reject'),
                                
                                Radio(
                                  value: 'rejected',
                                  groupValue: statusMap[qid],
                                  onChanged: (value) async {
                                    setState(() {
                                       statusMap[qid] = value!;
                                    });
                                      
                                    bool? confirmation =
                                    //     await customConfirmationDialog(
                                    //   context,
                                    //   title: 'Confirmation',
                                    //   content:
                                    //       'Do you want to replace this question?',
                                    // );
                                    // if (confirmation == true) {
                                    //     List<String> closMappedWitQuestion=await APIHandler().loadClosMappedWithQuestion(qid);
                                    //   await Navigator.push(
                                    //     context,
                                    //     MaterialPageRoute(
                                    //       builder: (context) =>
                                    //           AdditionlQuestions(
                                    //         pid: paperId,
                                    //         ccode: widget.ccode,
                                    //         cid: widget.cid,
                                    //         coursename: widget.coursename,
                                    //         qdifficulty: qDifficulty,
                                    //         qid: qid,
                                    //         list: closMappedWitQuestion,
                                    //       ),
                                    //     ),
                                    //   );
                                    await customConfirmationDialog(
                                      context,
                                      title: 'Confirmation',
                                      content:
                                          'Click 1 button',
                                    );
                                    if (confirmation == true) {
                                           String comment=commentController.text.toString();
                                          await addFeedbackData('$comment Please Remake the question with CLOS: ${question['mapped_clos']}',
                                              widget.pid, qid, fid);
                                             checksFunction();
                                               await APIHandler().updatePaperStatusToPending(widget.pid);
                                            List<dynamic> ulist=await APIHandler().loadUploadedPapers();
                                await Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                               DRTUploadedPapers(
                                           list: ulist
                                          ),
                                        ),
                                        
                                      );
                                      
                                     
                                    // if (mounted) {
                                    //   setState(() {});
                                    // }
                                    // } else {
                                    //   setState(() {
                                    //     statusMap[qid] = value!;
                                    //     tMarks -= question['q_marks'] as int;
                                    //     qNoCounter++;
                                    //     questionCountAcceptedOrRejected--;
                                    //         if(question['q_difficulty']=='Easy'){
                                    //     easySelected--;
                                        
                                    //   }else if(question['q_difficulty']=='Medium'){
                                    //       mediumSelected--;
                                    //   }
                                    //   else if(question['q_difficulty']=='Hard'){
                                    //       hardSelected--;
                                    //   }
                                    //     print('After rejection$qNoCounter');
                                    //     checksFunction();
                                    //   });
                                    //   setState(() {});
                                    }else{
                                      checksFunction();
                                     if (missingcloss.isNotEmpty) {
                        showErrorDialog(context, 'Missing Clos! $missingcloss');
                      }
                              String comment=commentController.text.toString();
                                    
                                 list.add({"comment":'$comment Please Remake the question with CLOS: ${question['mapped_clos']}',
                                 "pid":widget.pid,
                                 "qid":qid,
                                 "fid":fid
                                 });
                      
                                        // rejectedQuestionFeedback.addEntries(qid,list);
                                    }

                                  },
                                )
                              ],
                            ),
                            // statusMap[qid] == 'rejected'
                            //     ? Row(
                            //         children: <Widget>[
                            //           Container(
                            //             constraints: const BoxConstraints(
                            //               minWidth: 100,
                            //               maxWidth:
                            //                   260, // Maximum width constraint
                            //             ),
                            //             child: TextFormField(
                            //               controller: commentControllers[qid],
                            //               decoration: const InputDecoration(
                            //                 labelText: 'Comment',
                            //                 labelStyle: TextStyle(
                            //                     color: Colors.grey,
                            //                     fontSize: 14),
                            //                 floatingLabelBehavior:
                            //                     FloatingLabelBehavior.never,
                            //                 contentPadding:
                            //                     EdgeInsets.symmetric(
                            //                         vertical: 5, horizontal: 8),
                            //               ),
                            //             ),
                            //           ),
                            //           IconButton(
                            //             onPressed: () async {
                            //               String commentText =
                            //                   commentControllers[qid]?.text ??
                            //                       '';
                            //               if (commentText.isEmpty) {
                            //                 if (mounted) {
                            //                   showErrorDialog(context,
                            //                       'Enter comment first');
                            //                 }
                            //               } else {
                            //                 await addFeedbackData(commentText,
                            //                     widget.pid, qid, fid);
                            //                 await loadQuestionsWithUploadedAndApprovedStatus(
                            //                     widget.pid);
                            //                 checksFunction();
                            //               }
                            //             },
                            //             icon: const Icon(Icons.send),
                            //           ),
                            //           IconButton(
                            //             onPressed: () async {
                            //               List<String> closMappedWitQuestion=await APIHandler().loadClosMappedWithQuestion(qid);
                            //               await Navigator.push(
                            //                 context,
                            //                 MaterialPageRoute(
                            //                   builder: (context) =>
                            //                       AdditionlQuestions(
                            //                     pid: paperId,
                            //                     ccode: widget.ccode,
                            //                     cid: widget.cid,
                            //                     coursename: widget.coursename,
                            //                     qdifficulty: qDifficulty,
                            //                     qid: qid,
                            //                     list: closMappedWitQuestion,
                            //                   ),
                            //                 ),
                            //               );
                            //               setState(() {
                            //                 loadQuestionsWithUploadedAndApprovedStatus(
                            //                     widget.pid);
                            //               });
                            //             },
                            //             icon: const Icon(
                            //                 Icons.find_replace_sharp),
                            //           ),
                            //         ],
                            //       )
                            //     : const SizedBox(),
                              
                                      // IconButton(
                                      //   onPressed: () async {
                                          // String commentText =
                                          //     commentControllers[qid]?.text ??
                                          //         '';
                                          // if (commentText.isEmpty) {
                                          //   if (mounted) {
                                          //     showErrorDialog(context,
                                          //         'Enter comment first');
                                          //   }
                                          // } else {
                                          //   await addFeedbackData(commentText,
                                          //       widget.pid, qid, fid);
                                          //   await loadQuestionsWithUploadedAndApprovedStatus(
                                          //       widget.pid);
                                          //   checksFunction();
                                          // }
                                      //   },
                                      //   icon: const Icon(Icons.send),
                                      // ),
                                      // IconButton(
                                      //   onPressed: () async {
                                      //     List<String> closMappedWitQuestion=await APIHandler().loadClosMappedWithQuestion(qid);
                                      //     await Navigator.push(
                                      //       context,
                                      //       MaterialPageRoute(
                                      //         builder: (context) =>
                                      //             AdditionlQuestions(
                                      //           pid: paperId,
                                      //           ccode: widget.ccode,
                                      //           cid: widget.cid,
                                      //           coursename: widget.coursename,
                                      //           qdifficulty: qDifficulty,
                                      //           qid: qid,
                                      //           list: closMappedWitQuestion,
                                      //         ),
                                      //       ),
                                      //     );
                                      //     setState(() {
                                      //       loadQuestionsWithUploadedAndApprovedStatus(
                                      //           widget.pid);
                                      //     });
                                      //   },
                                      //   icon: const Icon(
                                      //       Icons.find_replace_sharp),
                                      // ),
                                  //  ],
                                 // )
                               // : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Row(
            children: [
              const SizedBox(
                width: 20,
              ),
              customElevatedButton(
                  onPressed: () async {
                    topicsInPaperList =
                        await APIHandler().loadTopicsOfSpecificPaper(paperId);
                    List<dynamic> topicsNotIncluded =
                        await APIHandler().loadTopicsNotIncludedInSpecificPaper(paperId);
                    if (mounted) {
                   showDialog(
  context: context,
  builder: (BuildContext context) {
    // Create a new list that excludes topics present in topicsInPaperList
    List filteredTopicsNotIncludedInPaperList = topicsNotIncluded
        .where((topic) => !topicsInPaperList.contains(topic))
        .toList();

    return AlertDialog(
      title: const Text(
        'Topics Information',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            const Text('Topics Included', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ...topicsInPaperList.map((topic) => Text(topic)).toList(),
            const SizedBox(height: 20),
            const Text('Topics Not Included', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ...filteredTopicsNotIncludedInPaperList.map((topic) => Text(topic)).toList(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
);
                    }
                  },
                  buttonText: 'Topics'),
              const SizedBox(
                width: 170,
              ),
              if(paperId!=null)
            if(questionCountAcceptedOrRejected==noOfQuestions!)
                customElevatedButton(
                    onPressed: () async {
                      if (missingcloss.isNotEmpty) {
                        showErrorDialog(context, 'Missing Clos! $missingcloss');
                      } else if (cloWeightageCheck.isNotEmpty) {
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Clo Weightage Error'),
                                content: Text(
                                    'CLO-$cloWeightageCheck has no weightage in $term'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      } else {
                        checksFunction();
                        
                        

                        updatePaperStatusToApprovedd(widget.pid);
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const DRTApprovedPapers()));
                        setState(() {
                          loadApprovedPapersData();
                        });
                      }
                    }
                    ,
                    buttonText: 'Approve'),
//                     if(paperId!=null)
         
//                 customElevatedButton(
//                     onPressed: () async {
// for(int i=0;i<list.length;i++){
//   await addFeedbackData(list[i]['comment'], list[i]['pid'], list[i]['qid'], list[i]['fid']);
// }


//  //await addFeedbackData('Paper Rejected', widget.pid,0,0);
//      await APIHandler().updatePaperStatusToForwardrdBack(widget.pid);
//     List<dynamic> ulist=await APIHandler().loadUploadedPapers();
//                                 await Navigator.pushReplacement(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                                DRTUploadedPapers(
//                                            list: ulist
//                                           ),
//                                         ),
                                        
//                                       );
                                      
//                       // if (missingcloss.isNotEmpty) {
//                       //   showErrorDialog(context, 'Missing Clos! $missingcloss');
//                       // } else if (cloWeightageCheck.isNotEmpty) {
//                       //   if (mounted) {
//                       //     showDialog(
//                       //       context: context,
//                       //       builder: (context) {
//                       //         return AlertDialog(
//                       //           title: const Text('Clo Weightage Error'),
//                       //           content: Text(
//                       //               'CLO-$cloWeightageCheck has no weightage in $term'),
//                       //           actions: [
//                       //             TextButton(
//                       //               onPressed: () {
//                       //                 Navigator.pop(context);
//                       //               },
//                       //               child: const Text('OK'),
//                       //             ),
//                       //           ],
//                       //         );
//                       //       },
//                       //     );
//                       //   }
//                       // } else {
//                       //   updatePaperStatusToApprovedd(widget.pid);
//                       //   Navigator.pushReplacement(
//                       //       context,
//                       //       MaterialPageRoute(
//                       //           builder: (context) =>
//                       //               const DRTApprovedPapers()));
//                       //   setState(() {
//                       //     loadApprovedPapersData();
//                       //   });
//                       // }
//                     }
//                     ,
//                     buttonText: 'Return '),
            ],
          )
          // : const SizedBox(),
        ]),
      ]),
    );
  }
}
