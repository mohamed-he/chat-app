import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
late User loggedIn;

class ChatScreen extends StatefulWidget {
  static const String id = "chat_screen";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextControler = TextEditingController();
  final _auth = FirebaseAuth.instance;

  late String messageText;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrent();
  }

  void getCurrent() async {
    try {
      final user = await _auth.currentUser;

      if (user != null) {
        loggedIn = user;
        print(loggedIn.email);
      }
    } catch (e) {
      print(e);
    }
  }

  /*void messagesStreams() async {
    await for (var snapshot in _firestore.collection("messages").snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data());
      }
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStreams(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextControler,
                      onChanged: (value) {
                        messageText = value;
                        //Do something with the user input.
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextControler.clear();
                      //Implement send functionality.
                      // messageTest + loggedInUser.email
                      _firestore.collection("messages").add(
                        {
                          "text": messageText,
                          "sender": loggedIn.email,
                          "time": FieldValue.serverTimestamp()
                        },
                      );
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStreams extends StatelessWidget {
  const MessagesStreams({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _firestore.collection("messages").orderBy("time").snapshots(),
      builder: (Context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent),
          );
        }
        final messages = snapshot.data!.docs.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageText = message.get("text");
          final messageSender = message.get("sender");
          final currentUser = loggedIn.email;
          final messageBubble = MessageBubble(
            text: messageText,
            sender: messageSender,
            isMe: currentUser == messageSender,
          );
          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.text, this.sender, this.isMe});
  final String? text;
  final String? sender;
  final bool? isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe! ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender!,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Material(
            borderRadius: isMe!
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0)),
            elevation: 5.0,
            color: isMe! ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                text!,
                style: TextStyle(
                    fontSize: 15.0,
                    color: isMe! ? Colors.white : Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
