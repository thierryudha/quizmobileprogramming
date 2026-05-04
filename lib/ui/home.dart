import 'package:flutter/material.dart';
import '../helpers/firebase_helper.dart';
import '../models/contact.dart';
import 'entry_form.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseHelper firebaseHelper = FirebaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contacts')),
      body: StreamBuilder<List<Contact>>(
        stream: firebaseHelper.getContacts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final contactList = snapshot.data!;

          return ListView.builder(
            itemCount: contactList.length,
            itemBuilder: (context, index) {
              final c = contactList[index];

              return Card(
                child: ListTile(
                  title: Text(c.name),
                  subtitle: Text(c.phone),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      if (c.id != null) {
                        firebaseHelper.delete(c.id!);
                      }
                    },
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EntryForm(c),
                      ),
                    );

                    if (result != null && c.id != null) {
                      firebaseHelper.update(c.id!, result);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EntryForm(Contact('', '')),
            ),
          );

          if (result != null) {
            firebaseHelper.insert(result);
          }
        },
      ),
    );
  }
}