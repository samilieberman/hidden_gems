import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'profile.dart';
import 'voteTracker.dart';
import 'mapview.dart';
import 'listView.dart';
import 'newPost.dart';

class MyDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the Drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 75.0,
            child: DrawerHeader(
              child: Text('Menu', style: TextStyle(color: Colors.white)),
              decoration: BoxDecoration(
                  color: Colors.pinkAccent
              ),
            ),
          ),
          ListTile(
            title: Text('List View'),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.push(
                context,
                new MaterialPageRoute(builder: (context) => new listView()),
              );
              //Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Map View'),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.push(
                context,
                new MaterialPageRoute(builder: (context) => new MapsDemo()),
              );
              //Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Profile'),
            onTap: () {
              Navigator.push(
                context,
                // TODO: currently the Profile Page breaks the system
                new MaterialPageRoute(builder: (context) => new Profile()),
              );
              //Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('New Post'),
            onTap: () {
              Navigator.push(
                context,
                new MaterialPageRoute(builder: (context) => new CustomForm()),
              );
              //Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Logout'),
            onTap: () {
              Navigator.push(
                context,
                // TODO: make this actually send to the sign in Page , also need to set global Variable to false after logged out
                new MaterialPageRoute(builder: (context) => new Login()),
              );
              //Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}