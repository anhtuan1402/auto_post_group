import 'dart:convert';

import 'package:auto_post_group/Model/Group.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as JSON;

var userData = null;
String _accessToken = '';
List<Group> list_group = [];
getAccessToken() async {
  final LoginResult loginResult = await FacebookAuth.instance
      .login(permissions: ['email', 'public_profile', 'pages_show_list'], loginBehavior: LoginBehavior.webOnly);

  if (loginResult.status == LoginStatus.success) {
    _accessToken = loginResult.accessToken!.token.toString();
    print("_accessToken $_accessToken");
    if (_accessToken != '') {
      try {
        userData = await FacebookAuth.instance.getUserData();
      } catch (e) {}
    }
  }

  return userData;
}

ifUserIsLoggedIn() async {
  if (_accessToken != '') {
    userData = await FacebookAuth.instance.getUserData();
    return userData;
  } else {
    return getAccessToken();
  }
}

getGroups() async {
  final response = await http.get(
    Uri.parse('https://graph.facebook.com/me/groups?access_token=$_accessToken'),
  );
  print("response.statusCode ${response.statusCode}");
  if (response.statusCode == 200) {
    final data = json.decode(response.body)['data'] as List;
    final nextt = json.decode(response.body)['paging']['next'];
    list_group = data.map((group) => Group.fromJson(group)).toList();
    print("Size ==== ${list_group.length}");
    if (nextt != null) {
      add_next_group(nextt);
    }
  } else {
    print("response.statusCode ${response.body}");
  }
  print("Size ==== ${list_group.length}");
  return list_group;
}

add_next_group(String urlll) async {
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
    }
  }
}

postToGroup(String id_group, String messages_post) async {
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

postImageToGroup(String imagePath, String group_id, String _accessToken) async {
  var graphResponse = await http.post(Uri.parse('https://graph.facebook.com/$group_id/photos'), headers: {
    "Content-Type": "multipart/form-data",
    "Authorization": "Bearer $_accessToken"
  }, body: {
    "url": imagePath,
    "published": "false",
  });
  print("graphResponse.statusCode ${graphResponse.statusCode}");
  if (graphResponse.statusCode != 200) {
    throw Exception('Failed to upload image');
  }

  var postResponse = await http.post(Uri.parse('https://graph.facebook.com/$group_id/photos'), headers: {
    "Content-Type": "application/x-www-form-urlencoded",
    "Authorization": "Bearer $_accessToken"
  }, body: {
    "url": imagePath,
    "published": "true",
  });
  print("postResponse.statusCode ${postResponse.statusCode}");

  if (postResponse.statusCode != 200) {
    throw Exception('Failed to post to group');
  }
}

logOut() async {
  await FacebookAuth.instance.logOut();
}
