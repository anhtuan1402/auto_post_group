import 'dart:convert';

import 'package:auto_post_group/Model/Group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String _message = 'Not logged in yet';
  Map<String, dynamic>? _userData;
  String? _accessToken;
  bool? _checking = true;
  bool? is_tick = true;
  late TextEditingController _noteController;
  TextEditingController delayController = TextEditingController();

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
    final accessToken = _accessToken;
    print("tokennnnnn ne: $accessToken");
    final response = await http.get(
      Uri.parse('https://graph.facebook.com/me/groups?access_token=$accessToken'),
    );
    print("response.statusCode ${response.statusCode}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'] as List;
      final nextt = json.decode(response.body)['paging']['next'];
      print("nextt ne $nextt");

      setState(() {
        _noteController = TextEditingController.fromValue(
          TextEditingValue(
            text: data.toString(),
          ),
        );
      });

      print("aaaaaaaaaaaaaaaaaaaaaaaaa $data");
      return data.map((group) => Group.fromJson(group)).toList();
    } else {
      print("response.statusCode ${response.body}");
      return null;
    }
  }

  _ifUserIsLoggedIn() async {
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
  }

  _login() async {
    final LoginResult loginResult = await FacebookAuth.instance
        .login(permissions: ['email', 'public_profile'], loginBehavior: LoginBehavior.dialogOnly);

    if (loginResult.status == LoginStatus.success) {
      _accessToken = loginResult.accessToken!.token;
      final userInfo = await FacebookAuth.instance.getUserData();

      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Login succes"),
        ));
        _userData = userInfo;
      });
    } else {}
  }

  _logOut() async {
    await FacebookAuth.instance.logOut();
    _accessToken = null;
    _userData = null;
  }

  _checktrail() async {}

  @override
  void initState() {
    super.initState();
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
                      ListViewGroup(ll),
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
                                const Text("Process"),
                                const SizedBox(
                                  height: 10,
                                ),
                                List_Group_Process(ll)
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ButtonPost()
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
              getGroups();
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

  Widget ListViewGroup(List<String> ll) {
    return Container(
      margin: const EdgeInsets.only(top: 15.0, left: 50.0, right: 50.0),
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.black)),
      height: 200,
      child: FutureBuilder(
          future: getListGroup(),
          builder: (context, AsyncSnapshot snapshot) {
            if (ll.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return ListView.builder(
                itemCount: ll.length,
                itemBuilder: (context, index) {
                  return ItemListView(ll, index);
                },
              );
            }
          }),
    );
  }

  Widget ItemListView(List<String> ll, int position) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 100, child: Text(ll[position])),
        Checkbox(
          value: is_tick,
          onChanged: (value) {
            setState(() {
              is_tick = !is_tick!;
            });
          },
        )
      ],
    );
  }

  Widget ItemListView_Process(List<String> ll, int position) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
            width: 100,
            child: Text(
              ll[position],
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
          future: getListGroup(),
          builder: (context, AsyncSnapshot snapshot) {
            if (ll.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return ListView.builder(
                itemCount: ll.length,
                itemBuilder: (context, index) {
                  return ItemListView_Process(ll, index);
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
