import 'package:flutter/material.dart';
import 'package:shopping/data/categories.dart';
import 'package:shopping/models/grocery_list.dart';
import 'package:shopping/screens/new_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroceryCategoriesScreen extends StatefulWidget {
  const GroceryCategoriesScreen({super.key});

  @override
  State<GroceryCategoriesScreen> createState() =>
      _GroceryCategoriesScreenState();
}

class _GroceryCategoriesScreenState extends State<GroceryCategoriesScreen> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('flutter-first-6706c-default-rtdb.firebaseio.com',
        'shopping-list.json');

    try {
      final response = await http.get(url);
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Unable to fetch data. Please try again later';
      });
    }

    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
      
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (var item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.categoryName == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }

    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
      
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again later.';
      });

      
    }

    
  }

  void _navigateNewItemScreen() async {
    final addedGrocery = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (addedGrocery == null) {
      return;
    }
    setState(() {
      _groceryItems.add(addedGrocery);
    });
  }

  void _removeItem(item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('flutter-first-6706c-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);
    if (response.statusCode >=400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
      
    }

  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet...'),
    );
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) => _removeItem(_groceryItems[index]),
          child: ListTile(
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            title: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(_groceryItems[index].name),
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
              onPressed: _navigateNewItemScreen,
              icon: const Icon(Icons.control_point_duplicate_sharp))
        ],
      ),
      body: content,

      // body: Column(
      //   children: [
      //   for (final item in groceryItems)
      //     ListTile(

      //       leading: Container(
      //         width: 20,
      //         height: 20,
      //         color: item.category.color,
      //       ),
      //       title: Padding(
      //         padding: const EdgeInsets.only(left: 10),
      //         child: Text(item.name),
      //       ),
      //       trailing: Text(item.quantity.toString(), style: const TextStyle(fontSize: 12),),
      //     )
      // ]),
    );
  }
}
