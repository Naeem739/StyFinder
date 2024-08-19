import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import package for date formatting

class ManageDatabasePage extends StatefulWidget {
  final String title;
  final String collection;
  final List<String> fields;
  final Map<String, dynamic>? defaultValues; // New variable for default values

  ManageDatabasePage({
    required this.title,
    required this.collection,
    required this.fields,
    this.defaultValues,
  });

  @override
  _ManageDatabasePageState createState() => _ManageDatabasePageState();
}

class _ManageDatabasePageState extends State<ManageDatabasePage> {
  final Map<String, TextEditingController> controllers = {};
  final List<TextEditingController> imageControllers = [
    TextEditingController()
  ]; // Initialize with one controller
  bool status = false; // New variable to hold status field value

  @override
  void initState() {
    super.initState();
    for (String field in widget.fields) {
      controllers[field] = TextEditingController();
      if (field == 'status' &&
          widget.defaultValues != null &&
          widget.defaultValues!.containsKey('status')) {
        status = widget.defaultValues!['status'];
        controllers[field]!.text = status.toString();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    for (var controller in imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateRoomStatus(String roomId, bool newStatus) {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .update({'status': newStatus}).then((_) {
      print('Room status updated successfully!');
    }).catchError((error) {
      print('Failed to update room status: $error');
    });
  }

  void _showDialog({DocumentSnapshot? doc, required bool isEditing}) {
    if (isEditing && doc != null) {
      for (String field in widget.fields) {
        if (field == 'status') {
          status = doc['status'];
          controllers[field]!.text = status.toString();
        } else if (field == 'images') {
          imageControllers.clear();
          List<String> images = List<String>.from(doc['images'] ?? []);
          for (var url in images) {
            imageControllers.add(TextEditingController(text: url));
          }
        } else {
          controllers[field]!.text = doc[field].toString();
        }
      }
    } else {
      controllers.forEach((key, controller) {
        if (key == 'status') {
          status = false; // Default to false if adding new entry
          controller.text = status.toString();
        } else {
          controller.clear();
        }
      });
      imageControllers.clear();
      imageControllers.add(
          TextEditingController()); // Ensure one image URL field is always present
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${isEditing ? 'Edit' : 'Add'} ${widget.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...widget.fields.map((field) {
                      if (field == 'images') {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Images'),
                            ...imageControllers.map((controller) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                          labelText: 'Image URL'),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        imageControllers.remove(controller);
                                      });
                                    },
                                  ),
                                ],
                              );
                            }).toList(),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  imageControllers.add(TextEditingController());
                                });
                              },
                            ),
                          ],
                        );
                      } else {
                        return TextFormField(
                          controller: controllers[field],
                          decoration:
                              InputDecoration(labelText: field.capitalize()),
                          keyboardType: field == 'price' || field == 'phone'
                              ? TextInputType.number
                              : TextInputType.text,
                        );
                      }
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Map<String, dynamic> data = {};
                    widget.fields.forEach((field) {
                      if (field == 'price' || field == 'phone') {
                        data[field] =
                            int.tryParse(controllers[field]!.text) ?? 0;
                      } else if (field == 'status') {
                        data[field] = controllers[field]!.text ==
                            'true'; // Convert string to bool
                      } else if (field == 'images') {
                        data[field] = imageControllers
                            .map((controller) => controller.text)
                            .toList();
                      } else {
                        data[field] = controllers[field]!.text;
                      }
                    });

                    if (isEditing && doc != null) {
                      FirebaseFirestore.instance
                          .collection(widget.collection)
                          .doc(doc.id)
                          .update(data)
                          .then((_) {
                        Navigator.pop(context);
                      });
                    } else {
                      FirebaseFirestore.instance
                          .collection(widget.collection)
                          .add(data)
                          .then((docRef) {
                        // Update the document with the room_id
                        FirebaseFirestore.instance
                            .collection(widget.collection)
                            .doc(docRef.id)
                            .update({'room_id': docRef.id}).then((_) {
                          Navigator.pop(context);
                        });
                      });
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DataSearchDelegate(
                  widget.collection,
                  widget.fields,
                  showDialogFunction: _showDialog, // Pass _showDialog function
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(widget.collection)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var documents = snapshot.data!.docs;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('ID')),
                        ...widget.fields.map((field) =>
                            DataColumn(label: Text(field.capitalize()))),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: documents.map((doc) {
                        return DataRow(cells: [
                          DataCell(Text(doc.id)),
                          ...widget.fields.map((field) {
                            if (field == 'start_date' || field == 'end_date') {
                              // Format dates
                              DateTime? date = doc[field]?.toDate();
                              String formattedDate =
                                  DateFormat('dd/MM/yyyy').format(date!);
                              return DataCell(Text(formattedDate));
                            } else if (field == 'status') {
                              return DataCell(
                                  Text(doc[field] ? 'true' : 'false'));
                            } else if (field == 'images') {
                              return DataCell(SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(
                                    (doc[field] as List).length,
                                    (index) => Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Text(doc[field][index] ?? ''),
                                    ),
                                  ),
                                ),
                              ));
                            } else {
                              return DataCell(
                                  Text(doc[field]?.toString() ?? ''));
                            }
                          }).toList(),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _showDialog(doc: doc, isEditing: true);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection(widget.collection)
                                      .doc(doc.id)
                                      .delete();
                                },
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showDialog(isEditing: false);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class DataSearchDelegate extends SearchDelegate<String> {
  final String collectionName;
  final List<String> fields;
  final Function({DocumentSnapshot? doc, required bool isEditing})
      showDialogFunction;

  DataSearchDelegate(this.collectionName, this.fields,
      {required this.showDialogFunction});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          // Perform a case-insensitive search across all fields
          return fields.any((field) {
            var fieldValue = doc[field]?.toString().toLowerCase() ?? '';
            return fieldValue.contains(query.toLowerCase());
          });
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('ID')),
              ...fields
                  .map((field) => DataColumn(label: Text(field.capitalize()))),
              DataColumn(label: Text('Actions')),
            ],
            rows: filteredDocs.map((doc) {
              return DataRow(cells: [
                DataCell(Text(doc.id)),
                ...fields.map((field) {
                  if (field == 'start_date' || field == 'end_date') {
                    // Format dates
                    DateTime? date = doc[field]?.toDate();
                    String formattedDate =
                        DateFormat('dd/MM/yyyy').format(date!);
                    return DataCell(Text(formattedDate));
                  } else if (field == 'status') {
                    return DataCell(Text(doc[field] ? 'true' : 'false'));
                  } else if (field == 'images') {
                    return DataCell(SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          (doc[field] as List).length,
                          (index) => Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Text(doc[field][index] ?? ''),
                          ),
                        ),
                      ),
                    ));
                  } else {
                    return DataCell(Text(doc[field]?.toString() ?? ''));
                  }
                }).toList(),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        // Implement editing functionality
                        showDialogFunction(doc: doc, isEditing: true);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        // Implement deletion functionality
                        FirebaseFirestore.instance
                            .collection(collectionName)
                            .doc(doc.id)
                            .delete();
                      },
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
