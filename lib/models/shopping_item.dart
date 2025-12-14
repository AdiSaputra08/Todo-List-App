class ShoppingItem {
  String id;
  String name;
  String quantity;
  String category;
  bool isBought;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    this.isBought = false,
  });

  // Konversi JSON agar bisa disimpan di memori HP
  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'],
        name: json['name'],
        quantity: json['quantity'],
        category: json['category'],
        isBought: json['isBought'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'category': category,
        'isBought': isBought,
      };
}