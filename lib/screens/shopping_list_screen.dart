import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_item.dart'; // Import model dari folder models

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingItem> _allItems = [];
  List<ShoppingItem> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();
  
  // Filter: 0 = Semua, 1 = Belum, 2 = Selesai
  int _filterIndex = 0; 
  final List<String> _categories = ['Makanan', 'Minuman', 'Elektronik', 'Pakaian', 'Rumah', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIKA DATABASE LOKAL ---
  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString('shop_master_db_v2');
    if (itemsJson != null) {
      final List<dynamic> decodedList = jsonDecode(itemsJson);
      setState(() {
        _allItems = decodedList.map((item) => ShoppingItem.fromJson(item)).toList();
        _applyFilters();
      });
    }
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(_allItems.map((item) => item.toJson()).toList());
    await prefs.setString('shop_master_db_v2', encodedList);
  }

  // --- LOGIKA FILTER & PENCARIAN ---
  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        // 1. Filter Status (Tab)
        bool statusMatch = true;
        if (_filterIndex == 1) statusMatch = !item.isBought; // Belum
        if (_filterIndex == 2) statusMatch = item.isBought;  // Selesai

        // 2. Filter Pencarian
        bool searchMatch = true;
        if (_searchController.text.isNotEmpty) {
          searchMatch = item.name.toLowerCase().contains(_searchController.text.toLowerCase());
        }

        return statusMatch && searchMatch;
      }).toList();

      // Sort: Yang belum dibeli selalu di atas
      _filteredItems.sort((a, b) {
        if (a.isBought == b.isBought) return 0;
        return a.isBought ? 1 : -1;
      });
    });
  }

  // --- CRUD OPERATIONS ---
  void _addItem(String name, String qty, String category) {
    final newItem = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: qty,
      category: category,
    );
    
    setState(() {
      _allItems.insert(0, newItem);
      _applyFilters();
    });
    _saveItems();
  }

  void _deleteItem(String id) {
    final index = _allItems.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final deletedItem = _allItems[index];
    
    setState(() {
      _allItems.removeAt(index);
      _applyFilters();
    });
    _saveItems();

    // Fitur Undo
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedItem.name} dihapus'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'BATALKAN',
          onPressed: () {
            setState(() {
              _allItems.insert(index, deletedItem);
              _applyFilters();
            });
            _saveItems();
          },
        ),
      ),
    );
  }

  void _toggleStatus(String id) {
    final index = _allItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      setState(() {
        _allItems[index].isBought = !_allItems[index].isBought;
        _applyFilters();
      });
      _saveItems();
    }
  }

  // --- UI HELPER ---
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makanan': return Icons.lunch_dining;
      case 'Minuman': return Icons.local_bar;
      case 'Elektronik': return Icons.devices;
      case 'Pakaian': return Icons.checkroom;
      case 'Rumah': return Icons.house;
      default: return Icons.category;
    }
  }

  // --- MODAL INPUT ---
  void _showAddSheet() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    String selectedCategory = _categories[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.fromLTRB(20, 25, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tambah Belanjaan", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Nama Barang',
                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: InputDecoration(
                          labelText: 'Jumlah',
                          hintText: '1 Pcs',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 6,
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setModalState(() => selectedCategory = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                        _addItem(nameCtrl.text, qtyCtrl.text, selectedCategory);
                        Navigator.pop(ctx);
                        _searchController.clear(); // Reset search saat tambah baru
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("SIMPAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(), // Tutup keyboard saat tap background
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            // --- HEADER PROFESSIONAL ---
            Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF818CF8)], // Indigo Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ShopMaster", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text("Manage your daily needs", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cari barang...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ],
              ),
            ),

            // --- FILTER TABS ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: Row(
                children: [
                  _buildFilterTab("Semua", 0),
                  const SizedBox(width: 10),
                  _buildFilterTab("Belum", 1),
                  const SizedBox(width: 10),
                  _buildFilterTab("Selesai", 2),
                ],
              ),
            ),

            // --- LIST ITEMS ---
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                            child: Icon(Icons.playlist_add_check, size: 60, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _searchController.text.isNotEmpty ? "Tidak ditemukan" : "Daftar Kosong",
                            style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteItem(item.id),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: item.isBought ? Colors.grey[100] : const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getCategoryIcon(item.category),
                                  color: item.isBought ? Colors.grey : const Color(0xFF4F46E5),
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: item.isBought ? Colors.grey : const Color(0xFF1F2937),
                                  decoration: item.isBought ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Text(
                                "${item.quantity} • ${item.category}",
                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                              ),
                              trailing: Transform.scale(
                                scale: 1.1,
                                child: Checkbox(
                                  value: item.isBought,
                                  activeColor: const Color(0xFF10B981), // Green Success
                                  shape: const CircleBorder(),
                                  onChanged: (_) => _toggleStatus(item.id),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddSheet,
          backgroundColor: const Color(0xFF4F46E5),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Barang Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, int index) {
    bool isActive = _filterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterIndex = index;
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}