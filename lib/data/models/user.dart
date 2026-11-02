import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(checked: true, explicitToJson: true)
class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.website,
    this.address,
    this.company,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? website;

  /// Вложенные модели (необязательные).
  final Address? address;
  final Company? company;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable(checked: true, explicitToJson: true)
class Address {
  const Address({this.street, this.suite, this.city, this.zipcode, this.geo});

  final String? street;
  final String? suite;
  final String? city;
  final String? zipcode;
  final Geo? geo;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

@JsonSerializable(checked: true)
class Geo {
  const Geo({this.lat, this.lng});

  final String? lat;
  final String? lng;

  factory Geo.fromJson(Map<String, dynamic> json) => _$GeoFromJson(json);
  Map<String, dynamic> toJson() => _$GeoToJson(this);
}

@JsonSerializable(checked: true)
class Company {
  const Company({this.name, this.catchPhrase, this.bs});

  final String? name;
  final String? catchPhrase;
  final String? bs;

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);
  Map<String, dynamic> toJson() => _$CompanyToJson(this);
}
