import 'package:flutter/foundation.dart';

class PasswordEntry {
  String id;
  String name;
  String path;
  String type;
  String meta;

  PasswordEntry({
    this.id,
    @required this.name,
    this.path,
    this.type,
    this.meta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type,
      'meta': meta,
    };
  }
}

class SnapshotEntry {
  String name;
  String path;
  String content;

  SnapshotEntry({
    @required this.name,
    @required  this.path,
    @required  this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'content': content,
    };
  }
}
