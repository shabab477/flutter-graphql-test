import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: graphQlObject.client,
      child: CacheProvider(
        child: MaterialApp(
          title: 'Graphql Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: MyHomePage(title: 'Graphql Demo Home Page'),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _offset = 0;

  ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_scrollListener);
  }

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      setState(() {
        _offset += 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Query(
          options: QueryOptions(document: QueryService.fetchQuery(_offset)),
          
          builder: (result, {VoidCallback refetch}) {
            if (result.loading) {
              return Center(child: CircularProgressIndicator());
            } else if (result.hasErrors) {
              return Text(result.errors.toString());
            }

            return ListView.builder(
              controller: _controller,
              itemBuilder: (context, index) {
                if (index == result.data['recentNotes'].length) {
                  return Container(
                    height: 20.0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(),
                    )
                  );
                }

                return SimpleCardItem(result.data['recentNotes'][index]);
              },
              itemCount: result.data["recentNotes"].length + 1,
            );
          }
      )
    );
  }
}

class GraphQlObject {
  static HttpLink httpLink = HttpLink(
    uri: 'http://10.0.3.2:8080/graphql',
  );
  static AuthLink authLink = AuthLink();
  static Link link = httpLink;

  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      cache: InMemoryCache(),
      link: link,
    ),
  );
}

GraphQlObject graphQlObject = new GraphQlObject();


class QueryService {

  static String fetchQuery(int offset) {
    return """
      {
        recentNotes(count: ${(offset + 1) * 8}, offset: 0) {
          id
          description
          totalTask
        } 
      }
    """;
  }

  static String fetchQueryWithTasks(int offset) {
    return """
      {
        recentNotes(count: ${(offset + 1) * 15}, offset: 0) {
          id
          minifiedDescription
          totalTask
          tasks {
            id
            description
          }
        } 
      }
    """;
  }
}


class SimpleCardItem extends StatelessWidget {

  final dynamic response;

  SimpleCardItem(this.response);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(response['id']),
      child: Column(
        children: <Widget>[
          ListTile(
            title: Text("Description: ${response['description']}"),
          ),
          ListTile(
            title: Text('Tasks: ${response['totalTask']}'),
          )
        ],
      ),
    );
  }
}

class ExpandableCardItem extends SimpleCardItem {

  ExpandableCardItem(response) : super(response);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text("Description: ${response['minifiedDescription']}"),
      leading: CircleAvatar(
        child: Text("${response['totalTask']}"),
      ),
      children: <Widget>[
        for (int c = 0; c < response["tasks"].length; c++)
          ListTile(
            title: Text(response["tasks"][c]["description"]),
          )
      ],
    );
  }
}

