import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shop.g.dart';

@HiveType(typeId: 1)
@JsonSerializable(explicitToJson: true)
class ShopModel extends HiveObject {
  @HiveField(0)
  @JsonKey(name: '_id')
  late String id;

  @HiveField(1)
  @JsonKey(name: 'shopName')
  late String shopName;

  @HiveField(2)
  @JsonKey(name: 'shopRegisterNumber')
  String? shopRegisterNumber;

  ShopModel({
    required this.id,
    required this.shopName,
    this.shopRegisterNumber,
  });

  // From JSON
  factory ShopModel.fromJson(Map<String, dynamic> json) =>
      _$ShopModelFromJson(json);

  // To JSON
  Map<String, dynamic> toJson() => _$ShopModelToJson(this);
}
