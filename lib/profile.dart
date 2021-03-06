import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hidden_gems/editPost.dart';
import 'navBar.dart';
import 'postView.dart';
import 'auth.dart';
import 'authProvider.dart';
import 'profileEdit.dart';


class Profile extends StatefulWidget {
  const Profile({this.onSignedOut});
  final VoidCallback onSignedOut;

  @override
  State<StatefulWidget> createState() => new _Profile();
}

class _Profile extends State<Profile> {
  String _userId;
  String _email = ' ';
  String _username = ' ';
  String _name = ' ';
  String _bio = ' ';
  String _picture = ' ';
  int _rating = 0;

  int totalPosts = 0;
  int totalRatings = 0;
  int _newRating = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final BaseAuth auth = AuthProvider.of(context).auth;
    //once currentUser() returns a user since it is a Future, then we can do something
    auth.currentUser().then((userId) {
      _userId = userId;
      _getInfo();
    });
  }

  /// Button for user to sign out of their account
  Future<void> _signOut(BuildContext context) async{
    try{
      final BaseAuth auth = AuthProvider.of(context).auth;
      await auth.signOut();
      widget.onSignedOut(); // call voidCallback function
      if(Navigator.canPop(context)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }catch(e){
      print(e);
    }
  }

  Future<void> _getInfo() async {
    Firestore.instance.collection('users').document(_userId).get().then((doc){
      if(doc.exists){
        _email = doc.data['email'];
        _username = doc.data['username'];
        _name = doc.data['name'];
        _bio = doc.data['bio'];
        _picture = doc.data['picture'];
        _rating = doc.data['rating'];
      }
    });
  }

  bool _deleteGem(String docId){
    Firestore.instance.collection('posts').document(docId)
        .delete()
        .catchError((e) {
          print(e);
          return true;
        }
    );
    return false;
  }

  /// determines user rating
  Widget _userRating(){
    if(totalPosts == 0){
      _newRating = 0;
    }else if(totalPosts > 3 && totalRatings > 20){
      _newRating = 5;
    }else if((totalPosts > 3 && totalRatings > 10) || (totalPosts < 3 && totalRatings > 15)){
      _newRating = 4;
    }else if((totalPosts > 3 && totalRatings > 5) || (totalPosts < 3 && totalRatings > 0)){
      _newRating = 3;
    }else if(totalRatings > -5){
      _newRating = 2;
    }else{
      _newRating = 1;
    }
    _updateRating(_newRating);
    return Container(width: 0.0, height: 0.0,);
  }

  /// update database with new rating
  _updateRating(int newRating) {
      var batch = Firestore.instance.batch();
      var currUser = Firestore.instance.collection('users').document(_userId);
      batch.updateData(currUser, {
        'rating': newRating
      });
      batch.commit();
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
          title: Text('Hidden Gems'),
          actions: <Widget>[
            new FlatButton(
              onPressed: () => _signOut(context),
              child: new Text(
                'Logout',
                style: new TextStyle(
                    fontSize: 17.0,
                    color: Colors.white
                ),
              )
            )
          ]
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<void>(
          future: Firestore.instance.collection('users').document(_userId).get().then((doc){
                        if(doc.exists){
                          _email = doc.data['email'];
                          _username = doc.data['username'];
                          _name = doc.data['name'];
                          _bio = doc.data['bio'];
                          _picture = doc.data['picture'];
                          _rating = doc.data['rating'];
                        }}),
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.waiting){
              return new Center(child: new CircularProgressIndicator());
            }else if(snapshot.connectionState == ConnectionState.done){
              if(snapshot.hasError){
                return new Text('${snapshot.error}');
              }else{
                return _buildPage(context);
              }
            }
          }
        )
      ),
      drawer: MyDrawer(value: _username),
    );
  }

  /// Widget that creates the whole page after fetches information
  Widget _buildPage(BuildContext context){
    return Scrollbar( child: Column(
      children: <Widget>[
        // top portion
        _simplePadding(),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _buildProfileImage(),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildName(),
                    _buildUsername(),
                    Padding(
                        padding: EdgeInsets.only(bottom: 10)
                    ),
                    _buildRating(_rating),
                  ],
                ),
              ),
            ],
          ),
        ),
        _simplePadding(),
        _buildBio(context),
        _simplePadding(),
        _divider(),
        /// Displays user Gems
        StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection('posts').where("userid", isEqualTo: _username).snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Center(child: new CircularProgressIndicator());
              default:
                return ListView(
                  shrinkWrap: true,
                  children: ListTile.divideTiles(
                    context: context,
                    tiles: snapshot.data.documents.map((DocumentSnapshot doc){
                    for(int i = 0; i < doc.data['name'].length; i++){
                      totalPosts++;
                      totalRatings += doc.data['rating'];

                      String curr = doc.data['name'];
                      /// details about gems the user has posted
                      return ListTile(
                            leading: getPicture(doc.data['picture']),
                            title: Row(
                                children: <Widget> [
                                  _titleGems(doc),
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    color: Colors.lightBlue,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        new MaterialPageRoute(builder: (context) => new EditPost(id: doc.documentID, username: _username)),
                                      );
                                    },
                                  )
                                ]
                            ),
                            subtitle: _descGems(doc),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              color: Colors.pinkAccent,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    // return object of type Dialog
                                    return AlertDialog(
                                      title: Text("Are you sure you want to delete " + curr + "?"),
                                      content: Text("You can't take back this action"),
                                      actions: <Widget>[
                                        // usually buttons at the bottom of the dialog
                                        new FlatButton(
                                          child: Text("Delete"),
                                          textColor: Colors.pinkAccent,
                                          onPressed: (){
                                            bool err = _deleteGem(doc.documentID);
                                            if(err){
                                              Fluttertoast.showToast(
                                                  msg: "Error deleting post, try again later",
                                                  toastLength: Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.CENTER,
                                                  timeInSecForIos: 2,
                                                  backgroundColor: Colors.black54,
                                                  textColor: Colors.white,
                                                  fontSize: 16.0
                                              );
                                            }else{
                                              Navigator.of(context).pop();
                                            }
                                          },
                                        ),
                                        new FlatButton(
                                          child: Text("Close"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                new MaterialPageRoute(builder: (context) => new PostView(id: doc.documentID, username: _username,)),
                              );
                            },
                      );
                    }
                  }),
                ).toList(),
                );
            }
          },
        ),
        _simplePadding(),
        _editButton(),
        _userRating(),
        Padding(
            padding: EdgeInsets.only(bottom: 25)
        )
      ],
    )
    );
  }

  // ---- Other Widgets ----

  Padding _simplePadding(){
    return Padding(
        padding: EdgeInsets.only(bottom: 15)
    );
  }

  Divider _divider(){
    return Divider(
      height: 2.0,
      color: Colors.grey,
    );
  }

  Widget _editButton(){
    return FloatingActionButton(
        tooltip: 'Edit Profile Page',
        child: new Icon(Icons.edit),
        onPressed: (){
          Navigator.push(
            context,
            new MaterialPageRoute(builder
                : (context) => new ProfileEdit(value:
            User(
                userId: _userId,
                username: _username,
                name: _name,
                email: _email,
                bio:
                _bio,
                imageUrl: _picture
            ))),
          )
          ;
        }
    );
  }

  Widget _buildName() {
    TextStyle _nameTextStyle = TextStyle(
      fontFamily: 'Roboto',
      color: Colors.black,
      fontSize: 28.0,
      fontWeight: FontWeight.w600,
    );
    return Text(
      _name,
      style: _nameTextStyle,
    );
  }

  Widget _buildUsername(){
    TextStyle _userNameTextStyle = TextStyle(
      fontFamily: 'Roboto',
      color: Colors.black38,
      fontSize: 18.0,
      fontWeight: FontWeight.w400,
    );

    return Text(
      _username,
      style: _userNameTextStyle,
    );
  }

  Widget _buildProfileImage() {
    if(_picture.length > 1){
      return Center(
        child: Container(
          width: 140.0,
          height: 140.0,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fitHeight,
              image: NetworkImage(_picture),
            ),
            borderRadius: BorderRadius.circular(80.0),
            border: Border.all(
              color: Colors.white,
              width: 10.0,
            ),
          ),
        ),
      );
    }else{
      // if user doesn't have a profile picture in Database
      return Center(
        child: Container(
          width: 140.0,
          height: 140.0,
          child: Icon(
            Icons.person,
            size: 60.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(80.0),
            border: Border.all(
              color: Colors.white,
              width: 10.0,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBio(BuildContext context) {
    TextStyle bioTextStyle = TextStyle(
      fontFamily: 'Spectral',
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: Color(0xFF799497),
      fontSize: 16.0,
    );

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.all(8.0),
      child: Text(
        _bio,
        textAlign: TextAlign.center,
        style: bioTextStyle,
      ),
    );
  }


  Widget _buildRating(int rating){
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
        );
      }),
    );
  }

  /// getting picture for gems
  Image getPicture(String url){
    if(url == ""){
      return Image.asset(
        //Would become a photo
        'assets/gem.png',
        width: 76.0,
        height: 45,
      );
    }
    return Image.network(
      //Would become a photo
      url,
      width: 76.0,
      height: 45,
    );
  }

  Text _titleGems(DocumentSnapshot doc){
    return Text(
      doc.data['name'],
      style: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Text _descGems(DocumentSnapshot doc){
    return Text(
      doc.data['description'],
      style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
          color: Colors.black38
      ),
    );
  }

}
