import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'image_preview_screen.dart';
import 'export_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Filtreleme için tarih değişkenleri
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  // Türk para formatı için yardımcı fonksiyon
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    return '₺${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YZ Muhasebe Sistemi'),
        actions: [
          // Veri Aktarımı butonu
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExportScreen()),
              );
            },
            tooltip: 'Veri Aktarımı',
          ),
          // Çıkış Yap butonu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Column(
        children: [
          // İstatistikler Bölümü
          _buildStatisticsSection(),

          // Filtreleme ve Arama Bölümü
          _buildFilterSection(),

          // Fatura Listesi
          Expanded(
            child: _buildInvoiceList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _captureInvoice,
        label: const Text('Yeni Fatura'),
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }

  // İstatistikler Widget'ı
  Widget _buildStatisticsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('invoices')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final invoices = snapshot.data!.docs;
        final totalCount = invoices.length;
        double totalAmount = 0;

        for (var doc in invoices) {
          final data = doc.data() as Map<String, dynamic>;
          totalAmount += (data['toplamTutar'] as num?)?.toDouble() ?? 0;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.receipt_long,
                title: 'Toplam Fatura',
                value: totalCount.toString(),
                color: Colors.white,
              ),
              _buildStatCard(
                icon: Icons.currency_lira,
                title: 'Toplam Tutar',
                value: _formatCurrency(totalAmount),
                color: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }

  // İstatistik Kartı Widget'ı
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(color: color, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Filtreleme Bölümü Widget'ı
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Arama Çubuğu
          TextField(
            decoration: InputDecoration(
              hintText: 'Satıcı adı ile ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),

          // Tarih Filtreleme
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: _startDate == null
                      ? 'Başlangıç'
                      : DateFormat('dd/MM/yyyy').format(_startDate!),
                  onPressed: () => _selectDate(context, isStartDate: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  label: _endDate == null
                      ? 'Bitiş'
                      : DateFormat('dd/MM/yyyy').format(_endDate!),
                  onPressed: () => _selectDate(context, isStartDate: false),
                ),
              ),
              if (_startDate != null || _endDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  tooltip: 'Filtreyi Temizle',
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Tarih Seçim Butonu
  Widget _buildDateButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  // Tarih Seçici
  Future<void> _selectDate(BuildContext context,
      {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Fatura Listesi Widget'ı
  Widget _buildInvoiceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('invoices')
          .orderBy('kayitTarihi', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Henüz fatura eklenmemiş',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yeni fatura eklemek için butona tıklayın',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // Filtreleme işlemi
        var filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final saticiAdi = (data['saticiAdi'] as String?)?.toLowerCase() ?? '';
          final faturaTarihi = data['faturaTarihi'] as String?;

          // Arama filtresi
          if (_searchQuery.isNotEmpty && !saticiAdi.contains(_searchQuery)) {
            return false;
          }

          // Tarih filtresi
          if (faturaTarihi != null &&
              (_startDate != null || _endDate != null)) {
            try {
              final parts = faturaTarihi.split('-');
              if (parts.length == 3) {
                final invoiceDate = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );

                if (_startDate != null && invoiceDate.isBefore(_startDate!)) {
                  return false;
                }
                if (_endDate != null && invoiceDate.isAfter(_endDate!)) {
                  return false;
                }
              }
            } catch (e) {
              // Tarih parse hatası
            }
          }

          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Text('Filtreye uygun fatura bulunamadı'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildInvoiceCard(
              saticiAdi: data['saticiAdi'] as String? ?? 'Bilinmiyor',
              faturaTarihi: data['faturaTarihi'] as String? ?? 'Tarih Yok',
              toplamTutar: (data['toplamTutar'] as num?)?.toDouble() ?? 0.0,
              docId: doc.id,
            );
          },
        );
      },
    );
  }

  // Fatura Kartı Widget'ı
  Widget _buildInvoiceCard({
    required String saticiAdi,
    required String faturaTarihi,
    required double toplamTutar,
    required String docId,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.receipt, color: Colors.blue.shade700),
        ),
        title: Text(
          saticiAdi,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(faturaTarihi),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(toplamTutar),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: Colors.grey.shade400),
          ],
        ),
        onTap: () =>
            _showInvoiceDetails(docId, saticiAdi, faturaTarihi, toplamTutar),
        onLongPress: () => _showDeleteDialog(docId, saticiAdi),
      ),
    );
  }

  // Fatura Detay Dialog'u
  void _showInvoiceDetails(
      String docId, String saticiAdi, String faturaTarihi, double toplamTutar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fatura Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Satıcı Adı:', saticiAdi),
            const SizedBox(height: 8),
            _buildDetailRow('Fatura Tarihi:', faturaTarihi),
            const SizedBox(height: 8),
            _buildDetailRow('Toplam Tutar:', _formatCurrency(toplamTutar)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Detay dialogunu kapat
                  _showEditDialog(docId, saticiAdi, faturaTarihi,
                      toplamTutar); // Düzenleme dialogu aç
                },
                icon: const Icon(Icons.edit),
                label: const Text('Faturayı Düzenle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Detay dialogunu kapat
                  _showDeleteDialog(docId, saticiAdi); // Silme onayı göster
                },
                icon: const Icon(Icons.delete),
                label: const Text('Faturayı Sil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  // Fatura Düzenleme Dialog'u
  void _showEditDialog(
      String docId, String saticiAdi, String faturaTarihi, double toplamTutar) {
    final TextEditingController saticiController =
        TextEditingController(text: saticiAdi);
    final TextEditingController tarihController =
        TextEditingController(text: faturaTarihi);
    final TextEditingController tutarController =
        TextEditingController(text: toplamTutar.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faturayı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: saticiController,
                decoration: const InputDecoration(
                  labelText: 'Satıcı Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tarihController,
                decoration: const InputDecoration(
                  labelText: 'Fatura Tarihi (GG-AA-YYYY)',
                  border: OutlineInputBorder(),
                  hintText: '01-12-2025',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tutarController,
                decoration: const InputDecoration(
                  labelText: 'Toplam Tutar',
                  border: OutlineInputBorder(),
                  prefixText: '₺',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newSatici = saticiController.text;
              final newTarih = tarihController.text;
              final newTutar = double.tryParse(tutarController.text);

              if (newSatici.isEmpty || newTarih.isEmpty || newTutar == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Lütfen tüm alanları doğru doldurun')),
                );
                return;
              }

              _updateInvoice(docId, newSatici, newTarih, newTutar);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Fatura Güncelleme İşlemi
  Future<void> _updateInvoice(String docId, String saticiAdi,
      String faturaTarihi, double toplamTutar) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('invoices')
          .doc(docId)
          .update({
        'saticiAdi': saticiAdi,
        'faturaTarihi': faturaTarihi,
        'toplamTutar': toplamTutar,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fatura güncellendi ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme hatası: $e')),
        );
      }
    }
  }

  // Fatura Silme Dialog'u
  void _showDeleteDialog(String docId, String saticiAdi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faturayı Sil'),
        content:
            Text('$saticiAdi faturasını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              _deleteInvoice(docId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // Fatura Silme İşlemi
  Future<void> _deleteInvoice(String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('invoices')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fatura silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  // Oturum Kapatma
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılamadı: $e')),
        );
      }
    }
  }

  // Kamera ile Fatura Çekme
  Future<void> _captureInvoice() async {
    PermissionStatus status = await Permission.camera.status;

    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      try {
        final XFile? photo =
            await _picker.pickImage(source: ImageSource.camera);

        if (photo != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreviewScreen(imagePath: photo.path),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kamera hatası: $e')),
          );
        }
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kamera İzni Gerekli'),
            content: const Text(
              'Fatura taraması için kamera iznine ihtiyacımız var. Lütfen ayarlardan kamera iznini açın.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Ayarları Aç'),
              ),
            ],
          ),
        );
      }
    }
  }
}
