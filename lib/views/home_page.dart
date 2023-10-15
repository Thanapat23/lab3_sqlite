import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lab3_sqlite/database/sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SingingCharacter { food, drink }

class _HomePageState extends State<HomePage> {
  // All journals
  List<Map<String, dynamic>> _journals = [];

  SingingCharacter? _character = SingingCharacter.food;
  bool _isLoading = true;
  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals(); // Loading the diary when the app starts
  }

  final TextEditingController _namefoodController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int? id) async {
    _namefoodController.text = '';
    _priceController.text = '';
    _character = SingingCharacter.food;
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal =
          _journals.firstWhere((element) => element['id'] == id);
      _namefoodController.text = existingJournal['namefood'];
      _priceController.text = existingJournal['price'].toString();
      _character = SingingCharacter.values[int.parse(existingJournal['type'])];
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.only(
                top: 15,
                left: 15,
                right: 15,
                // this will prevent the soft keyboard from covering the text fields
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _namefoodController,
                    decoration: const InputDecoration(
                      hintText: 'Food/Drink',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      hintText: 'Price',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Text(
                          'Type : ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          flex: 2,
                          child: ListTile(
                            title: Row(
                              children: [
                                Radio<SingingCharacter>(
                                    activeColor: Colors.black,
                                    value: SingingCharacter.food,
                                    groupValue: _character,
                                    onChanged: (SingingCharacter? value) {
                                      setState(() {
                                        _character = value;
                                      });
                                    }),
                                const Text(
                                  'Food',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: ListTile(
                            title: Row(
                              children: [
                                Radio<SingingCharacter>(
                                    activeColor: Colors.black,
                                    value: SingingCharacter.drink,
                                    groupValue: _character,
                                    onChanged: (SingingCharacter? value) {
                                      setState(() {
                                        _character = value;
                                      });
                                    }),
                                const Text(
                                  'Drink',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), // <-- Radius
                        ),
                      ),
                      onPressed: () async {
                        // Save new journal
                        if (id == null) {
                          await _addItem();
                        }

                        if (id != null) {
                          await _updateItem(id);
                        }

                        // Clear the text fields
                        _namefoodController.text = '';
                        _priceController.text = '';
                        _character = SingingCharacter.food;
                        // Close the bottom sheet
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        id == null ? 'Create New' : 'Update',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                ],
              ),
            );
          });
        });
  }

// Insert a new journal to the database
  Future<void> _addItem() async {
    inspect(_character!.index.toString());
    // inspect(SingingCharacter.values[_character!.index].name);
    await SQLHelper.createItem(_namefoodController.text,
        int.parse(_priceController.text), _character!.index.toString());
    _refreshJournals();
  }

  // Update an existing journal
  Future<void> _updateItem(int id) async {
    inspect(_character!.index.toString());
    await SQLHelper.updateItem(id, _namefoodController.text,
        int.parse(_priceController.text), _character!.index.toString());
    _refreshJournals();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a journal!'),
    ));
    _refreshJournals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 252, 236),
      appBar: AppBar(
        title: const Text('Manage Restaurant'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 254, 246, 127),
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              padding: const EdgeInsets.all(15),
              child: ListView.builder(
                  itemCount: _journals.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 254, 250, 192),
                          border: Border.all(width: 2, color: Colors.black),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20))),
                      child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _journals[index]['type'] == '0'
                                  ? const Text('Food',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold))
                                  : const Text('Drink',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold))
                            ],
                          ),
                          title: Text(_journals[index]['namefood'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          subtitle: Text('${_journals[index]['price']} B',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          trailing: SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.grey),
                                  onPressed: () =>
                                      _showForm(_journals[index]['id']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _deleteItem(_journals[index]['id']),
                                ),
                              ],
                            ),
                          )),
                    );
                  }),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        backgroundColor: Colors.grey,
        child: const Icon(
          Icons.add,
          color: Colors.black,
          size: 35,
        ),
      ),
    );
  }
}
