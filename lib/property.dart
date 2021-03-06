import 'package:flutter/material.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tags/selectable_tags.dart';
import 'drawer.dart';
import 'Profile-Other.dart';
import 'mapProp.dart';

class PropertyPage extends StatefulWidget {
  PropertyPage(this._key, this._col, this.user);
  final FirebaseUser user;
  String _key ;
	String _col;

  @override
  _PropertyPageState createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
	String _name ;
	var _address;
	String _description ;
	var _tags = [] ;
	String _price ;
  String userID ;
  DocumentReference _user;
  bool finsihing = false;

  var imageUrls = <dynamic> [];

  List<NetworkImage> _buildNetworkImages(){
    List<NetworkImage> lst = new List<NetworkImage>();
    for (var i = 0; i < imageUrls.length; i++) {
      lst.add(NetworkImage(imageUrls[i]));
    }
    return lst;
  }

	Widget _buildCoverImage(Size screenSize) => new SizedBox(
    height: screenSize.height/3,
    child: imageUrls.length>0? new Carousel(
      boxFit: BoxFit.cover,
      images: _buildNetworkImages(),
      animationCurve: Curves.fastOutSlowIn,
      animationDuration: Duration(seconds: 4),
      borderRadius: true,
      indicatorBgPadding: 0.0)
      : 
      Image.asset("no_img.png", fit: BoxFit.cover, ),
  );

  Widget _buildName() => Text(
      _name,
  );

  Widget _buildDescription() {
    return Text(_description);
  }

  Widget _buildTags() {
    var temp = <Tag> [];
    for (var i = 0; i < _tags.length; i++) {
      temp.add(Tag(title: _tags[i]));
    }

    return SelectableTags(
      tags: temp,
      color: Colors.orangeAccent,
    );
  }

  Widget _buildPrice() {
    return Card(
      child: Text(_price),
      borderOnForeground: true,
    );
  }

  Widget _buildRowHelper(BuildContext context, bool isAdmin, DocumentSnapshot snap){
    if(isAdmin){
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FlatButton.icon(
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => PropertyMap(_address, _name)),
              );

            },
            icon: Icon(Icons.map),
            label: Text('Map'),
            color: Colors.orangeAccent,
          ),
          FlatButton.icon(
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => Profile(_user.documentID, widget.user)),
              );
            },
            icon: Icon(Icons.person),
            label: Text('Profile'),
            color: Colors.orangeAccent,
          ),
          FlatButton.icon(
            onPressed: (){
              showDialog(
                context: context,
                builder: (_) =>  new AlertDialog(
                  title: new Text('Delete Property Ad?'),
                  content: new Text('The ad will be permanently deleted throught this action.'),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () async {
                        await Firestore.instance.runTransaction((Transaction myTransaction) async {
                          await myTransaction.delete(snap.reference);
                        });                      
                        Navigator.of(context).popUntil(ModalRoute.withName('listings'));  
                      },
                      child: new Text('Delete'),
                    ),
                    FlatButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                      },
                      child: new Text('Cancel'),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.delete),
            label: Text('Delete Ad'),
            color: Colors.orangeAccent,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FlatButton.icon(
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => PropertyMap(_address, _name)),
              );

            },
            icon: Icon(Icons.map),
            label: Text('View in Map'),
            color: Colors.orangeAccent,
          ),
          FlatButton.icon(
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => Profile(_user.documentID, widget.user)),
              );
            },
            icon: Icon(Icons.person),
            label: Text('View User'),
            color: Colors.orangeAccent,
          ),
        ],
      );
    }
  }

  Widget _buildRow(BuildContext context, DocumentSnapshot snap){
    if(widget.user == null){
      return _buildRowHelper(context, false, snap);
    } else{
      return Container(
        child: StreamBuilder(
          stream: Firestore.instance.collection('users').where('user', isEqualTo: widget.user.uid).snapshots(),
          builder: (context, snapshot){
            return _buildRowHelper(context, (snapshot.data.documents[0]['isAdmin'] || widget.user.uid==userID), snap);
          },
        ),
      );
    }
    
  }

  void getData(DocumentSnapshot snapshot){
    _name = snapshot['name'];
    _tags = snapshot['tags'];
    _description = snapshot['description'];
    imageUrls = snapshot['photo'];
    _address = snapshot['location'];
    _price = snapshot['price'].toString();
    _user = snapshot['user'];
  }

	@override
	Widget build (BuildContext context) {
		Size screenSize = MediaQuery.of(context).size;

    if(finsihing){
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  
  	return new Scaffold(
			drawer: new DrawerOnly(widget.user),
			appBar: new AppBar(
				title: new Text('Property Details'),
			),
      body: StreamBuilder(
        stream: Firestore.instance.collection(widget._col).document(widget._key).snapshots(),
        builder: (context, snapshot){
          if(!snapshot.hasData) return new Center(
            child: new CircularProgressIndicator(),
          );
          getData(snapshot.data);
          // String docId = snapshot.data.DocumentReference.
          return new Container(
            child: new SingleChildScrollView(
              child: new ConstrainedBox(
                constraints: new BoxConstraints(
                  minHeight: screenSize.height/1.2
                ),
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    _buildCoverImage(screenSize),
                    Divider(),
                    _buildName(),
                    Divider(),
                    _buildDescription(),
                    Divider(),
                    _buildTags(),
                    Divider(),
                    _buildPrice(),
                    Divider(),
                    _buildRow(context, snapshot.data),
                  ],
                ),
              ),
            ),
          );
        },
      )
		);	
	}
}
