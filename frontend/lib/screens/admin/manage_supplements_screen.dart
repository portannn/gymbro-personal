import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supplement_provider.dart';
import '../../models/product_model.dart';

class ManageSupplementsScreen extends StatefulWidget {
  const ManageSupplementsScreen({super.key});

  @override
  State<ManageSupplementsScreen> createState() => _ManageSupplementsScreenState();
}

class _ManageSupplementsScreenState extends State<ManageSupplementsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SupplementProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SupplementProvider>(context);
    final filteredProducts = provider.products.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) || (p.category?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Inventaris Suplemen', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF292929),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari suplemen atau kategori...',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFCCFF00)),
                filled: true,
                fillColor: const Color(0xFF292929),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Product List
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.fetchProducts,
              color: const Color(0xFFCCFF00),
              child: provider.isLoading && provider.products.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)))
                  : _buildProductList(filteredProducts, provider),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFCCFF00),
        onPressed: () => _showProductDialog(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildProductList(List<Product> products, SupplementProvider provider) {
    if (products.isEmpty) {
      return const Center(child: Text('Tidak ada suplemen ditemukan', style: TextStyle(color: Color(0xFF9E9E9E))));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF292929),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(product.imageUrl!, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                  : _buildPlaceholder(),
            ),
            title: Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.category ?? 'Tanpa Kategori', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rp ${product.price.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFCCFF00), fontWeight: FontWeight.bold)),
                    Text('Stok: ${product.stock}', style: TextStyle(color: product.stock < 5 ? Colors.red : Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductDialog(context, product: product)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, product)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[800],
      child: const Icon(Icons.shopping_bag, color: Colors.white24),
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    final bool isEdit = product != null;
    final TextEditingController nameCtrl = TextEditingController(text: product?.name);
    final TextEditingController descCtrl = TextEditingController(text: product?.description);
    final TextEditingController priceCtrl = TextEditingController(text: product?.price.toString());
    final TextEditingController stockCtrl = TextEditingController(text: product?.stock.toString());
    final TextEditingController catCtrl = TextEditingController(text: product?.category);
    final TextEditingController imgCtrl = TextEditingController(text: product?.imageUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(isEdit ? 'Edit Suplemen' : 'Tambah Suplemen', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField('Nama', nameCtrl),
              _buildDialogField('Kategori', catCtrl),
              _buildDialogField('Harga', priceCtrl, keyboardType: TextInputType.number),
              _buildDialogField('Stok', stockCtrl, keyboardType: TextInputType.number),
              _buildDialogField('URL Gambar (Opsional)', imgCtrl),
              _buildDialogField('Deskripsi Nutrisi', descCtrl, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Color(0xFF9E9E9E)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCCFF00), foregroundColor: Colors.black),
            onPressed: () async {
              final data = {
                'name': nameCtrl.text,
                'description': descCtrl.text,
                'price': double.tryParse(priceCtrl.text) ?? 0,
                'stock': int.tryParse(stockCtrl.text) ?? 0,
                'category': catCtrl.text,
                'image_url': imgCtrl.text,
              };

              final provider = Provider.of<SupplementProvider>(context, listen: false);
              bool success;
              if (isEdit) {
                success = await provider.updateProduct(product.id, data);
              } else {
                success = await provider.addProduct(data);
              }

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Berhasil diperbarui' : 'Berhasil ditambah'), backgroundColor: Colors.green));
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Gagal menyimpan'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF292929))),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCFF00))),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Konfirmasi Hapus', style: TextStyle(color: Colors.white)),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?', style: const TextStyle(color: Color(0xFF9E9E9E))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Color(0xFF9E9E9E)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await Provider.of<SupplementProvider>(context, listen: false).deleteProduct(product.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil dihapus'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
