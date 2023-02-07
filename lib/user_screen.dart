import 'dart:convert';
import 'dart:io';

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

  Future<String?> getAccessToken() async {
    final LoginResult loginResult = await FacebookAuth.instance
        .login(permissions: ['email', 'public_profile'], loginBehavior: LoginBehavior.dialogOnly);

    if (loginResult.status == LoginStatus.success) {
      _accessToken = loginResult.accessToken!.token.toString();
      final userInfo = await FacebookAuth.instance.getUserData();
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Login succes"),
        ));
        _userData = userInfo;
      });
    } else {}
  }

  getGroups() async {
    if (list_group.length != 0) return;
    final accessToken = _accessToken;
    final response = await http.get(
      Uri.parse('https://graph.facebook.com/me/groups?access_token=$accessToken'),
    );
    print("response.statusCode ${response.statusCode}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'] as List;
      final nextt = json.decode(response.body)['paging']['next'];
      list_group = data.map((group) => Group.fromJson(group)).toList();
      print("Size ==== ${list_group.length}");
      if (nextt != null) {
        add_next_group(nextt);
      } else {
        setState(() {
          list_group = list_group;
        });
      }
    } else {
      print("response.statusCode ${response.body}");
    }
  }

  add_next_group(String urlll) async {
    final accessToken = _accessToken;

    final response = await http.get(
      Uri.parse(urlll),
    );
    print("response.statusCode ${response.statusCode}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'] as List;
      final nextt = json.decode(response.body)['paging']['next'];
      List<Group> list_group_temp = data.map((group) => Group.fromJson(group)).toList();
      list_group.addAll(list_group_temp);
      print("Size ==== ${list_group.length}");
      if (nextt != null) {
        add_next_group(nextt);
      } else {
        setState(() {
          list_group = list_group;
        });
      }
    } else {
      print("response.statusCode ${response.body}");
    }
  }

  _ifUserIsLoggedIn() async {
    try {
      if (_checking == false) return;
      String? accessToken = await getAccessToken();

      setState(() {
        _checking = false;
      });

      if (accessToken != null) {
        final userData = await FacebookAuth.instance.getUserData();
        _accessToken = accessToken;

        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Login succes"),
          ));
          _userData = userData;
        });
      } else {
        _login();
      }
    } catch (e) {
      setState(() {
        _checking = false;
      });
    }
  }

  _postToGroup(String id_group, String messages_post) async {
    print(_accessToken);
    final graphResponse = await http.post(
      Uri.parse('https://graph.facebook.com/$id_group/feed'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: JSON.jsonEncode({'message': messages_post}),
    );
    print(graphResponse.body);
  }

  Future<void> _postToFacebook(String _imagePath, String group_id, String _message) async {
    final image = await http.MultipartFile.fromPath(
      'source',
      _imagePath,
      contentType: MediaType.parse('image/jpeg'),
    );
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://graph.facebook.com/$group_id/photos'),
    );
    request.fields['message'] = _message;
    request.files.add(image);
    request.headers.addAll({'Authorization': 'Bearer $_accessToken'});

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final result = jsonDecode(responseData);
      print(result);
      // Post was successful
    } else {
      print(responseData);
      // Post was unsuccessful
    }
  }

  _login() async {
    try {
      if (_checking == false) return;
      final LoginResult loginResult = await FacebookAuth.instance
          .login(permissions: ['email', 'public_profile'], loginBehavior: LoginBehavior.dialogOnly);
      setState(() {
        _checking = false;
      });

      if (loginResult.status == LoginStatus.success) {
        _accessToken = loginResult.accessToken!.token;
        final userInfo = await FacebookAuth.instance.getUserData();

        setState(() {
          _noteController = TextEditingController.fromValue(
            TextEditingValue(
              text: _accessToken!,
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Login succes"),
          ));
          _userData = userInfo;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loginResult.message.toString()),
        ));
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  _logOut() async {
    await FacebookAuth.instance.logOut();
    _accessToken = null;
    _userData = null;
    setState(() {
      _checking = true;
    });
  }

  _checktrail() async {}

  @override
  void initState() {
    super.initState();
    str_process = '';
    list_group.clear();
    _noteController = TextEditingController.fromValue(
      const TextEditingValue(
        text: "",
      ),
    );
    _ifUserIsLoggedIn();
  }

  Future<void> updateUser() async {
    final userData = await FacebookAuth.instance.getUserData();
    setState(() {
      _userData = userData;
      _checking = false;
    });
  }

  Future<void> todosomething() async {
    _accessToken = await getAccessToken();
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
                const Text("List group"),
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
                    _postToFacebook(image!.path.toString(), zz.id, _noteController.text);
                  } else {
                    _postToGroup(zz.id, _noteController.text);
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
      child: FutureBuilder(
          future: getGroups(),
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (list_group.length == 0) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return ListView.builder(
                itemCount: list_group.length,
                itemBuilder: (context, index) {
                  return ItemListView(list_group[index], index);
                },
              );
            }
          }),
    );
  }

  Widget ItemListView(Group ll, int position) {
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
          future: getGroups(),
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
              _logOut();
              Navigator.pop(context);
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

List<String> lls = [
  "Group AGroup AGroup AGroup AGroup A",
  "Group B",
  "Group C",
  "Group D",
  "Group E",
  "Group F",
  "Group G",
  "Group H",
  "Group I",
];
List<String> ll = [];

getListGroup() async {
  if (ll.isNotEmpty) return ll;
  for (var zz in lls) {
    Future.delayed(const Duration(milliseconds: 200), () {
      ll.add(zz);
    });
  }
  return ll;
}
