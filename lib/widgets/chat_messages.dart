import 'package:chat_app/widgets/message_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages found.'),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong.'),
          );
        }

        final loadedMessages = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 40, right: 12, left: 12),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            final chatMessage = loadedMessages[index].data();
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data()
                : null;

            final currentMessageUserId = chatMessage['user_id'];
            final nextMessageUserId =
                nextChatMessage != null ? nextChatMessage['user_id'] : null;
            final isNextMessageSameUser =
                currentMessageUserId == nextMessageUserId;

            if (isNextMessageSameUser) {
              return MessageBubble.next(
                message: chatMessage['text'],
                isMe: currentMessageUserId == currentUser.uid,
              );
            } else {
              return MessageBubble.first(
                userImage: chatMessage['user_image'],
                username: chatMessage['username'],
                message: chatMessage['text'],
                isMe: currentMessageUserId == currentUser.uid,
              );
            }
          },
        );
      },
    );
  }
}
