import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:test_venom/constants.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _status = 'Waiting for permission';
  List<File> allFiles = [];
  int count = 0;
  int filterCount = 0;
  List<File> filteredFiles = [];

  @override
  void initState() {
    super.initState();
    allFiles = [];
    filteredFiles = [];
    count = 0;
    filterCount = 0;
  }

  Future<void> _checkPermission() async {
    if (await Permission.storage.isGranted) {
      setState(() {
        _status = 'Permission already granted';
        allFiles = [];
        fetchFiles();
      });
    } else {
      // Request permission via popup
      final status = await Permission.storage.request();
      if (status.isGranted) {
        setState(() {
          _status = 'Permission granted';
          allFiles = [];
          fetchFiles();
        });
      } else if (status.isDenied) {
        setState(() {
          _status = 'Permission denied';
        });
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _status =
              'Permission permanently denied. Please enable it from settings.';
        });
        // Open app settings if permission is permanently denied
        openAppSettings();
      }
    }
  }

  Future<void> fetchFiles() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Fetching")),
    );
    Directory dir = Directory('/storage/emulated/0/');
    setState(() {
      allFiles = [];
      filterCount = 0;
      count = 0;
      filteredFiles = [];
    });
    getAllDir(dir);
    sortTheList();
  }

  void getAllDir(Directory dir) {
    List<FileSystemEntity> entities = [];
    try {
      entities = dir.listSync();
    } catch (e) {
      // If access to the directory is denied, log the error and skip it.
      return;
    }

    for (var entity in entities) {
      if (entity is Directory) {
        getAllDir(entity); // Recursively process subdirectories.
      } else if (entity is File) {
        setState(() {
          count++;
          allFiles.add(entity); // Add file path to the list.
          if (entity.lengthSync() < 200000) {
            filteredFiles.add(entity);
            filterCount++;
          }
        });
      }
    }
  }

  void sortTheList() {
    setState(() {
      allFiles.sort((a, b) {
        // Get file sizes
        int sizeA = a.lengthSync();
        int sizeB = b.lengthSync();

        // Compare file sizes
        return sizeA.compareTo(sizeB);
      });
    });
  }

  void _reset() {
    setState(() {
      allFiles = [];
      filteredFiles = [];
      count = 0;
      filterCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppSizes().initSizes(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Venom"),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: AppSizes().getScreenWidth(),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200], // Light background color for contrast
                borderRadius: BorderRadius.circular(10), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5), // Subtle shadow
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // Shadow position
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkPermission,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      backgroundColor: Colors.blue, // Button background color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(5), // Rounded button
                      ),
                    ),
                    child: const Text("Start"),
                  ),
                  TextButton(
                    onPressed: _reset,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      backgroundColor: Colors.red, // Button background color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(5), // Rounded button
                      ),
                    ),
                    child: const Text("Clear"),
                  ),
                  Column(
                    children: [
                      Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green, // Differentiate count visually
                        ),
                      ),
                      const SizedBox(height: 5), // Add spacing between counts
                      Text(
                        filterCount.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .orange, // Differentiate filter count visually
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(
                child: ListView(
              children: allFiles.map((e) {
                return Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    e.absolute.path,
                    style: TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
            ))
          ],
        ),
      ),
    );
  }
}
