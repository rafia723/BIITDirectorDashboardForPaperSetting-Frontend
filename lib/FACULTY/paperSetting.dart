import 'dart:typed_data';
import 'package:biit_directors_dashbooard/API/api.dart';
import 'package:biit_directors_dashbooard/FACULTY/questionEdit.dart';
import 'package:biit_directors_dashbooard/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PaperSetting extends StatefulWidget {
  final int? cid;
  final String coursename;
  final String ccode;
  final int fid;

  const PaperSetting({
    super.key,
    required this.cid,
    required this.ccode,
    required this.coursename,
    required this.fid,
  });

  @override
  State<PaperSetting> createState() => _PaperSettingState();
}

class _PaperSettingState extends State<PaperSetting> {
  TextEditingController questionController = TextEditingController();
  TextEditingController subquestionController = TextEditingController();
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
  List<dynamic> commonTopicList = [];
  List<bool> isCheckedList = [];
  int? selectedTopicId;
  Map<int, List<dynamic>> cloListsForQuestions = {};
  List<int> selectedTopicIds = [];
  List<dynamic> subqlist = [];
  List<dynamic> cloList = [];
  Map<int, bool> dialogVisibility = {};
  Map<int, List<dynamic>> subQuestions = {};
  Map<int, bool> dialogSubQuestionVisibility = {};
  List<Uint8List> selectedImages = [];
  List<Map<String, dynamic>> qilist=[];

  dynamic fetchedSQText;
  dynamic fetchedSQImgUrl;

  @override
  void initState() {
    super.initState();
    loadTeachers();
    initializeData();
    loadCommonTopics();
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
      if (qlist.isNotEmpty) {
        for (var marks in qlist) {
          int qid = marks['q_id'];
          tMarks += (marks['q_marks'] as int);
          loadCloListsForQuestions(qid);
        }
      }
  
/////////////for multiple 
    //  await loadQuestionWithMultipleImages(paperId);
    //   if (qilist.isNotEmpty) {
    //     for (var marks in qilist) {
    //       int qid = marks['q_id'];
    //       tMarks += (marks['q_marks'] as int);
    //       loadCloListsForQuestions(qid);
    //     }
    //   }
      }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please make sure to add at least one question of each difficulty level (Easy, Medium, Hard) for each topic.',
          ),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> checksFunction() async {
    if (paperId != null) {
      await loadQuestion(paperId);
     // await loadQuestionWithMultipleImages(paperId);
    }
  }

  // Custom dialog widget
  Widget _buildCustomDialog(int qId, int qNo) {
    return AlertDialog(
      title: Text(
        'Add Parts of Question # $qNo',
        style: const TextStyle(fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            controller: subquestionController,
            decoration: const InputDecoration(
              hintText: 'Enter Question...',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                onPressed: () {
                  _selectImage();
                },
                icon: const Icon(Icons.photo_library),
              ),
              IconButton(
                onPressed: () async {
                  if (subquestionController.text.isEmpty) {
                    showErrorDialog(
                        context, 'Please Enter required information');
                  } else {
                    dynamic response = await APIHandler().addSubQuestion(
                        subquestionController.text,
                        selectedImage,
                        qId,
                        widget.cid!);

                    if (response != null && response['status'] == 200) {
                      setState(() {
                        showSuccesDialog(context, 'Inserted');
                        subquestionController.clear();
                        checksFunction();
                      });
                    } else if (response['status'] == 409) {
                      if (mounted) {
                        showErrorDialog(
                            context, 'Similar question already exists');
                      }
                    } else {
                      if (mounted) {
                        showErrorDialog(context, 'Error');
                      }
                    }
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
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
                            selectedImage = null; // Remove the selected image
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
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            setState(() {
              dialogVisibility[qId] = false;
              subquestionController.clear();
            });
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Future<Uint8List?> _selectImage2() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return await image.readAsBytes();
    }
    return null;
  }


  Future<void> pickImages() async {
  final ImagePicker pickerr = ImagePicker();
  final List<XFile> images = await pickerr.pickMultiImage();

  for (var image in images) {
    Uint8List imageData = await image.readAsBytes();
    selectedImages.add(imageData);
  }
}

Widget _buildCustomUpdateDialog(int sqId) {
  return AlertDialog(
    title: const Text(
      'Update Question',
      style: TextStyle(fontSize: 20),
    ),
    content: StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            controller: subquestionController,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                onPressed: () async {
                  final selectedImage = await _selectImage2();
                  setState(() {
                    this.selectedImage = selectedImage;
                    fetchedSQImgUrl = null;
                  });
                },
                icon: const Icon(Icons.photo_library),
              ),
              IconButton(
                onPressed: () async {
                  try {
                    // Validate necessary fields
                    if (subquestionController.text.isEmpty) {
                      showErrorDialog(
                        context,
                        'Please provide necessary information',
                      );
                      return;
                    }
                    
                    // Handle image retrieval
                    Uint8List? sqimage;
                    if (fetchedSQImgUrl != null) {
                      var response = await http.get(Uri.parse(fetchedSQImgUrl!));
                      if (response.statusCode == 200) {
                        sqimage = Uint8List.fromList(response.bodyBytes);
                      } else {
                        if (mounted) {
                          showErrorDialog(context, 'Error downloading image');
                        }
                      }
                    }

                    // Perform update operation
                    int response = await APIHandler().updateSubQuestionOfSpecificSQid(
                      sqId,
                      subquestionController.text,
                      selectedImage ?? sqimage,
                      widget.cid!,
                    );

                    // Handle response
                    if (response == 200) {
                      showSuccesDialog(context, 'Updated');
                      setState(() {
                        subquestionController.clear();
                        selectedImage = null;
                        fetchedSQImgUrl = null;
                        checksFunction();
                      });
                    } else if (response == 409) {
                      showErrorDialog(context, 'Similar Question already exists, try changing the question');
                    } else {
                      showErrorDialog(context, 'Error');
                    }
                  } catch (e) {
                    showErrorDialog(context, 'An unexpected error occurred: $e');
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (fetchedSQImgUrl != null || selectedImage != null)
            Stack(
              key: UniqueKey(), // Key added for forced rebuild
              children: [
                fetchedSQImgUrl != null
                    ? Image.network(
                        fetchedSQImgUrl!,
                        width: 200,
                        height: 200,
                      )
                    : Image.memory(
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
                        fetchedSQImgUrl = null;
                        selectedImage = null;
                      });
                    },
                    child: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.all(5),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        child: const Text('Close'),
        onPressed: () {
          setState(() {
            dialogSubQuestionVisibility[sqId] = false;
               subquestionController.clear();
          });
          Navigator.of(context).pop(true);
        },
      ),
    ],
  );
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

  Future<void> loadCloListsForQuestions(int qid) async {
    List<dynamic> cloListForQuestion =
        await APIHandler().loadClosofSpecificQuestion(qid);
    cloListsForQuestions[qid] = cloListForQuestion;
    if (mounted) {
      setState(() {});
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

  Future<void> loadCommonTopics() async {
    try {
      commonTopicList = await APIHandler().loadCommonTopics(widget.cid!);
      setState(() {
        if (commonTopicList.isNotEmpty) {
          isCheckedList = List<bool>.filled(commonTopicList.length, false);
        }
      });
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> loadQuestion(int pid) async {
    try {
      qlist = await APIHandler().loadQuestion(pid);
      List<dynamic> allCloLists = []; // List to store CLOs of all questions
      //  List<dynamic> allTopicLists = []; // List to store topic of all questions
      for (var question in qlist) {
        int fId = question['f_id'];
        int qid = question['q_id'];

        await loadSubQuestionData(question['q_id']);
        List<dynamic> cloListForQuestion = await APIHandler()
            .loadClosofSpecificQuestion(qid); // Load CLOs for each question
        allCloLists.add(cloListForQuestion); // Add CLOs to the list
        loadCloListsForQuestions(qid);
        await loadFacultyName(fId);
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

   Future<void> loadQuestionWithMultipleImages(int pid) async {
  try {
     qilist = await APIHandler().loadQuestionWithMultipleImages(pid);
    List<List<dynamic>> allCloLists = [];

    for (var question in qilist) {
      int fId = question['f_id'];
      int qid = question['q_id'];

      await loadSubQuestionData(qid); // Assuming qid is used to load subquestions
      List<dynamic> cloListForQuestion = await APIHandler().loadClosofSpecificQuestion(qid);
      allCloLists.add(cloListForQuestion);
      loadCloListsForQuestions(qid); // Assuming this function updates some local state
      await loadFacultyName(fId);
    }

    setState(() {
      cloList = allCloLists;
    });
  } catch (e) {
    if (mounted) {
      showErrorDialog(context, 'Failed to load question data with images: $e');
    }
  }
}

  Future<void> loadSubQuestionData(int qid) async {
    try {
      subqlist = await APIHandler().loadSubQuestionOfSpecificQid(qid);
      for (var subquestion in subqlist) {
        fetchedSQText = subquestion['sq_text'];
        fetchedSQImgUrl = subquestion['sq_image'];
        print('fetchedurl $fetchedSQImgUrl');
      }
      setState(() {
        subQuestions[qid] = subqlist;
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
                              child: tMarks == 0
                                  ? const Text('0')
                                  : Text(
                                      '$tMarks',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                            ),
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
                        onPressed: () {
                          _selectImage();
                       //  pickImages();
                        },
                        icon: const Icon(Icons.photo_library)),
                    IconButton(
                      onPressed: () async {
                        if (selectedTopicIds.isEmpty ||
                            dropdownValue.isEmpty ||
                            marksController.text.isEmpty) {
                          showErrorDialog(context,
                              'Please select required information Topic,Difficulty and marks');
                        } else {
                          dynamic response = await APIHandler().addQuestion(
                            questionController.text,
                            selectedImage,
                            int.parse(marksController.text),
                            dropdownValue,
                            'pending',
                            paperId,
                            widget.fid,
                            widget.cid!,
                          );

                          if (response != null && response['status'] == 200) {
                            int qId = response['q_id'];
                            await APIHandler()
                                .addTopicOfQuestion(qId, selectedTopicIds);
                            tMarks += int.parse(marksController.text);
                            questionController.clear();
                            marksController.clear();
                            selectedImage = null;
                            //  selectedTopicId = null;
                            setState(() {
                              dropdownValue = 'Easy';
                              isCheckedList = List<bool>.filled(
                                  commonTopicList.length, false);
                              selectedTopicIds.clear();
                              loadQuestion(paperId);
                            });
                          } else if (response['status'] == 409) {
                            if (mounted) {
                              showErrorDialog(
                                  context, 'Similar question already exists');
                            }
                          } else {
                            if (mounted) {
                              showErrorDialog(context, 'Error');
                            }
                          }
                        }
                        checksFunction();
                      },
                      icon: const Icon(Icons.add),
                    ),


                    ///////multiple images
//                     IconButton(
//   onPressed: () async {
//     checksFunction();

//     if (selectedTopicIds.isEmpty ||
//         dropdownValue.isEmpty ||
//         marksController.text.isEmpty) {
//       showErrorDialog(context,
//           'Please select required information: Topic, Difficulty, and Marks');
//     } else {
//       dynamic response = await APIHandler().addQuestionWithMultipleImages(
//         questionController.text,
//         selectedImages, // Pass the list of selected images
//         int.parse(marksController.text),
//         dropdownValue,
//         'pending',
//         paperId,
//         widget.fid,
//         widget.cid!,
//       );

//       if (response != null && response['status'] == 200) {
//         int qId = response['q_id'];
        
//         await APIHandler().addTopicOfQuestion(qId, selectedTopicIds);
//         tMarks += int.parse(marksController.text);
//         questionController.clear();
//         marksController.clear();
//         selectedImages = [];

//         setState(() {
//           dropdownValue = 'Easy';
//           isCheckedList = List<bool>.filled(commonTopicList.length, false);
//           selectedTopicIds.clear();
//          // loadQuestion(paperId);
//          loadQuestionWithMultipleImages(paperId);
//         });
//       } else if (response['status'] == 409) {
//         if (mounted) {
//           showErrorDialog(context, 'Similar question already exists');
//         }
//       } else {
//         if (mounted) {
//           showErrorDialog(context, 'Error');
//         }
//       }
//     }
//   },
//   icon: const Icon(Icons.add),
// )

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
                                    itemCount: commonTopicList.length,
                                    itemBuilder: (context, index) {
                                      final topic = commonTopicList[index];

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

                                            //   selectedTopicId = topic['t_id'];
                                            if (value == true) {
                                              selectedTopicIds
                                                  .add(topic['t_id']);
                                            } else {
                                              selectedTopicIds
                                                  .remove(topic['t_id']);
                                              //  print(selectedTopicId);
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
                    List<dynamic> cloListForQuestion =
                        cloListsForQuestions[question['q_id']] ?? [];
                    List<dynamic> sqlist = subQuestions[question['q_id']] ?? [];
                    print(
                        'CLOs for Question #${index + 1}: $cloListForQuestion');
                    int qno = index + 1;

                    return Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      color: Colors.white.withOpacity(0.8),
                      child: ListTile(
                        tileColor: Colors.white,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Question # ${index + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${question['q_text']}',
                                    maxLines: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (facultyId == widget.fid)
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuestionEdit(
                                        fromPaperSettingScreen: true,
                                        fid: widget.fid,
                                        cid: widget.cid,
                                        ccode: widget.ccode,
                                        coursename: widget.coursename,
                                        qid: question['q_id'],
                                        fromCommentScreen: false,
                                        
                                      ),
                                    ),
                                  ).then((_) {
                                    // This block will be executed when the QuestionEdit screen is popped
                                    setState(() {
                                      loadQuestion(paperId);
                                    // loadQuestionWithMultipleImages(paperId);
                                    });
                                  });
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  size: 22,
                                ),
                              ),
                            // if (facultyId == widget.fid)
                            //   IconButton(
                            //     onPressed: () {
                            //       dialogVisibility[question['q_id']] = true;
                            //       showDialog(
                            //         context: context,
                            //         builder: (BuildContext context) {
                            //           return _buildCustomDialog(
                            //               question['q_id'], qno);
                            //         },
                            //       );
                            //     },
                            //     icon: const Icon(
                            //       Icons.add,
                            //       size: 22,
                            //     ),
                            //   ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                                if (facultyId == widget.fid)
                                                  IconButton(
                                                    onPressed: () async {
                                                      await loadSubQuestionData(
                                                          question['q_id']);
                                                   subquestionController.text=fetchedSQText;
                                                      dialogSubQuestionVisibility[
                                                          subQuestion[
                                                              'sq_id']] = true;
                                                      if (mounted) {
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return _buildCustomUpdateDialog(
                                                                subQuestion[
                                                                    'sq_id']);
                                                          },
                                                        );
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size: 18,
                                                    ),
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
                                Text('$facultyName,'),
                                Text(
                                    'CLOs: ${cloListForQuestion.isEmpty ? 'Loading...' : cloListForQuestion.map((entry) => entry['clo_number'] as String).join(', ')}')
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
///////////////////For multiple images
// Expanded(
//   child: ListView.builder(
//     itemCount: qilist.length,
//     itemBuilder: (context, index) {
//       final Map<String, dynamic> question = qilist[index];
      
//       // Ensure q_images is properly initialized or set to an empty list if null
//       final List<dynamic> images = question['q_images'] ?? [];

//       // Other variables from question map
//       int facultyId = question['f_id'];
//       final facultyName = facultyNames[facultyId] ?? 'Loading...';
//       List<dynamic> cloListForQuestion = cloListsForQuestions[question['q_id']] ?? [];
//       List<dynamic> sqlist = subQuestions[question['q_id']] ?? [];

//       return Card(
//         elevation: 5,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(15.0),
//         ),
//         color: Colors.white.withOpacity(0.8),
//         child: ListTile(
//           tileColor: Colors.white,
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Question # ${index + 1}',
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       '${question['q_text']}',
//                       maxLines: 10,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//               // Edit button for faculty
//               if (facultyId == widget.fid)
//                 IconButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => QuestionEdit(
//                           fid: widget.fid,
//                           cid: widget.cid,
//                           ccode: widget.ccode,
//                           coursename: widget.coursename,
//                           qid: question['q_id'],
//                         ),
//                       ),
//                     ).then((_) {
//                       setState(() {
//                         loadQuestionWithMultipleImages(paperId);
//                       });
//                     });
//                   },
//                   icon: const Icon(
//                     Icons.edit,
//                     size: 22,
//                   ),
//                 ),
//               // Add subquestion button for faculty
//               if (facultyId == widget.fid)
//                 IconButton(
//                   onPressed: () {
//                     dialogVisibility[question['q_id']] = true;
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return _buildCustomDialog(question['q_id'], index + 1);
//                       },
//                     );
//                   },
//                   icon: const Icon(
//                     Icons.add,
//                     size: 22,
//                   ),
//                 ),
//             ],
//           ),
//           subtitle: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Display images if present
//               if (images.isNotEmpty)
//                 Column(
//                   children: images.map((image) {
//                     return Image.network(
//                       image, // Use image directly as a string
//                       height: 150,
//                       width: 300,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return const CircularProgressIndicator();
//                       },
//                       errorBuilder: (context, error, stackTrace) {
//                         return Text('Error loading image: $error');
//                       },
//                     );
//                   }).toList(),
//                 ),
//               // Display subquestions if present
//               if (sqlist.isNotEmpty)
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: sqlist.asMap().entries.map((entry) {
//                     int idx = entry.key;
//                     var subQuestion = entry.value;
//                     return Column(
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 '   ${String.fromCharCode(97 + idx)}.  ${subQuestion['sq_text']}',
//                               ),
//                             ),
//                             // Edit subquestion button for faculty
//                             if (facultyId == widget.fid)
//                               IconButton(
//                                 onPressed: () async {
//                                   await loadSubQuestionData(question['q_id']);
//                                   subquestionController.text = fetchedSQText;
//                                   dialogSubQuestionVisibility[subQuestion['sq_id']] = true;
//                                   if (mounted) {
//                                     showDialog(
//                                       context: context,
//                                       builder: (BuildContext context) {
//                                         return _buildCustomUpdateDialog(subQuestion['sq_id']);
//                                       },
//                                     );
//                                   }
//                                 },
//                                 icon: const Icon(
//                                   Icons.edit,
//                                   size: 18,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         // Display subquestion image if present
//                         if (subQuestion['sq_image'] != null)
//                           Image.network(
//                             subQuestion['sq_image'],
//                             height: 150,
//                             width: 300,
//                             loadingBuilder: (context, child, loadingProgress) {
//                               if (loadingProgress == null) {
//                                 return child;
//                               }
//                               return const CircularProgressIndicator();
//                             },
//                             errorBuilder: (context, error, stackTrace) {
//                               return Text('Error loading image: $error');
//                             },
//                           ),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               // Display metadata (difficulty, marks, etc.)
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Text('${question['q_difficulty']},'),
//                   Text('${question['q_marks']},'),
//                   Text('$facultyName,'),
//                   Text(
//                     'CLOs: ${cloListForQuestion.isEmpty ? 'Loading...' : cloListForQuestion.map((entry) => entry['clo_number'] as String).join(', ')}',
//                   )
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   ),
// ),

            ],
          )
        ],
      ),
    );
  }
}
