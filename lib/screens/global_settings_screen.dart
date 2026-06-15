import "dart:async";

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../gameState/base_game_state.dart';
import '../gameState/host_game_state.dart';


Future<String?> getUsername() async {
  final prefs = await SharedPreferences.getInstance();
  return Future.value(prefs.getString('username') );
}



Future<void> setUsername(String username) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('username', username);
}

Future<void> updateUsername(String username, BuildContext context) async {
  await setUsername(username);
  Provider.of<HostGameState>(context, listen: false).setNames(username);
}



class GlobalSettingsScreen extends StatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  State<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
    
}

class _GlobalSettingsScreenState extends State<GlobalSettingsScreen>{


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text("Global Settings"),
      ),
      body: Padding( //adding current Username with button change to get textfield, 
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView(
              shrinkWrap: true,
              children: [
                
                ListTile(
                  title:  Text("Username:"),
                  subtitle: FutureBuilder<String?>(
                    future: getUsername(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text("");
                      } else if (snapshot.hasError) {
                        return const Text("Error loading username");
                      } else {
                        final username = snapshot.data ?? '';
                        return Text(username.isNotEmpty ? username : "No username set");
                      }
                    },
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      bool? didChange = await usernameInputDialog(context, false);
                      if(didChange == true){
                        setState(() {
                          // Refresh to show new username
                        });
                      }
                    },
                    child: const Text("Change"),
                  ),
                ),
              ],
            )
            //SizedBox(height: 20, child: Text("Current username: $_username", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
  
}

  final usernameController = TextEditingController();
Future<dynamic> usernameInputDialog(BuildContext context, bool startup) async {
  final localFormKey = GlobalKey<FormState>();
    return showDialog(
      
      context: context,
      barrierDismissible: !startup,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Username'),
          content: Form(
            key: localFormKey,
            child: TextFormField(
              controller: usernameController,
              decoration: InputDecoration(hintText: "Enter new username"),
              maxLength: 15,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username cannot be empty';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            if(startup == false) 
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
             TextButton(
              child: Text('OK'),
              onPressed: () {
                if(localFormKey.currentState!.validate()){
                setUsername(usernameController.text);
                Provider.of<HostGameState>(context, listen:false).setNames(usernameController.text);
                Navigator.pop(context, true);
                }
              },
            ),
          ],
        );
      },
    );
  }


//TODO add more settings like Avatar and/or color preference (host gives them a shade of the color so that everyone has their own)
//TODO add more options like Dark/While mode or custom theme colors, Sound on/off maybe standalone mode toggle to just use a device as server with permanent stats screen and more if time permits