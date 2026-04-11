import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final String email;

  @HiveField(1)
  String? name;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  String? password; // hashed or plain? for simplicity, plain, but in real app hash

  @HiveField(4)
  bool isAdmin;

  User(this.email, {this.name, this.phone, this.password, this.isAdmin = false});
}
