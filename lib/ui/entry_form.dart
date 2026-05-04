import 'package:flutter/material.dart';
import '../models/contact.dart';

class EntryForm extends StatefulWidget {
  final Contact contact;

  const EntryForm(this.contact, {super.key});

  @override
  _EntryFormState createState() => _EntryFormState(contact);
}

class _EntryFormState extends State<EntryForm> {
  Contact contact;

  _EntryFormState(this.contact);

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = contact.name;
    phoneController.text = contact.phone;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Form Contact')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                if (contact.id == null) {
                  contact = Contact(
                    nameController.text,
                    phoneController.text,
                  );
                } else {
                  contact.name = nameController.text;
                  contact.phone = phoneController.text;
                }

                Navigator.pop(context, contact);
              },
            ),
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
    );
  }
}