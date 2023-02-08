import 'dart:convert';
import 'dart:io';

import 'package:auto_post_group/Data/account_data.dart';
import 'package:auto_post_group/Model/Group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as JSON;
import 'package:http_parser/http_parser.dart';

import 'package:image_picker/image_picker.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String str_process = '';
  Map<String, dynamic>? _userData;
  String? _accessToken;
  bool? _checking = true;
  bool? is_tick = true;
  Set<Group> list_tick = Set<Group>();
  List<Group> list_group = [];
  late TextEditingController _noteController;
  TextEditingController delayController = TextEditingController();
  ImagePicker picker = ImagePicker();
  XFile? image;

  @override
  void initState() {
    super.initState();
    str_process = '';
    updateUser();
    list_group.clear();
    //list_group.add(Group(id: '', name: ''));
    _noteController = TextEditingController.fromValue(
      const TextEditingValue(
        text: "",
      ),
    );
  }

  // getListGroup() async {
  //   getGroups(list_group);
  //   _checking = false;
  //   setState(() {});
  // }

  updateUser() async {
    _userData = await ifUserIsLoggedIn();
    list_group = await getGroups();
    setState(() {
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: _checking!
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DisplayInfor(context),
                      const SizedBox(
                        height: 50,
                      ),
                      ElevatedButton(
                          onPressed: () async {
                            //getListGroup();
                            setState(() {});
                          },
                          child: Text("Get All List Group")),
                      ListViewGroup(),
                      const SizedBox(
                        height: 50,
                      ),
                      Row(
                        children: [
                          Container(
                              height: 250,
                              width: MediaQuery.of(context).size.width / 2,
                              child: Column(
                                children: [
                                  const Text("Message"),
                                  inputText(),
                                ],
                              )),
                          Container(
                            height: 250,
                            width: 170,
                            child: Column(
                              children: [
                                Text("Process"),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(str_process)
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ButtonPost(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              onPressed: () async {
                                image = await picker.pickImage(source: ImageSource.gallery);
                                setState(() {});
                              },
                              child: Text("Pick Image")),
                          ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  image = null;
                                });
                              },
                              child: Text("Clear image")),
                        ],
                      ),
                      image != null
                          ? Container(
                              height: MediaQuery.of(context).size.height / 2,
                              width: MediaQuery.of(context).size.width / 2,
                              child: Image.file(File(image!.path)))
                          : Text('')
                    ],
                  ),
                )),
    );
  }

  Widget ButtonPost() {
    return Row(
      children: [
        Row(
          children: [
            const Text('Delay (milisecon) :'),
            Container(
              width: 80,
              height: 30,
              child: const TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(
          width: 40,
        ),
        ElevatedButton(
            onPressed: () {
              int dem = 1;
              for (var zz in list_tick) {
                Future.delayed(const Duration(milliseconds: 1000), () {
                  setState(() {
                    str_process = '$dem / ${list_tick.length}';
                  });
                  if (image != null) {
                    postImageToGroup(image!.path.toString(), zz.id, _noteController.text);
                  } else {
                    postToGroup(zz.id, _noteController.text);
                  }
                  dem++;
                });
              }
            },
            child: const Text('Get')),
      ],
    );
  }

  Container inputText() {
    return Container(
      margin: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.black)),
      height: 200,
      child: TextField(
          style: const TextStyle(fontSize: 20),
          decoration: const InputDecoration(border: InputBorder.none),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          controller: _noteController),
    );
  }

  Widget ListViewGroup() {
    return Container(
        margin: const EdgeInsets.only(top: 15.0, left: 50.0, right: 50.0),
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.black)),
        height: 200,
        child: ListView.builder(
          itemCount: list_group.length,
          itemBuilder: (context, index) {
            return ItemListView(list_group[index], index);
          },
        ));
  }

  Widget ItemListView(Group ll, int position) {
    if (ll.id == '')
      return Text('Loading........');
    else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 100, child: Text(ll.name)),
          Checkbox(
            value: ll.is_check,
            onChanged: (value) {
              setState(() {
                ll.is_check = !ll.is_check;
                if (ll.is_check == true)
                  list_tick.add(ll);
                else
                  list_tick.remove(ll);
                print(list_tick.length);
              });
            },
          )
        ],
      );
    }
  }

  Widget ItemListView_Process(Group ll) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
            width: 100,
            child: Text(
              ll.name,
              maxLines: 1,
              style: TextStyle(),
            )),
        const Text("Complete"),
      ],
    );
  }

  Widget List_Group_Process(List<String> ll) {
    return Container(
      decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.black)),
      height: 200,
      child: FutureBuilder(
          future: null,
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot == null) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ItemListView_Process(snapshot.data![index]);
                },
              );
            }
          }),
    );
  }

  Padding DisplayInfor(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          _userData != null
              ? Container(
                  child: CircleAvatar(
                    radius: 20.0,
                    backgroundImage: NetworkImage(_userData!['picture']['data']['url']),
                    backgroundColor: Colors.white,
                  ),
                  // child: Image.network(_userData!['picture']['data']['url'], height: 40),
                )
              : Container(),
          const SizedBox(
            width: 20,
          ),
          _userData != null
              ? Text(
                  '${_userData!['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                )
              : Container(),
          const SizedBox(
            width: 20,
          ),
          ElevatedButton(
            onPressed: () {
              logOut();
              Navigator.pop(context);
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
