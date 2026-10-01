import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/invoice_model.dart';
import '../models/vendor_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> deactivateUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': false,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<String> createVendor(Vendor vendor) async {
    final docRef = await _firestore
        .collection('users')
        .doc(vendor.userId)
        .collection('vendors')
        .add(vendor.toFirestore());
    return docRef.id;
  }

  Future<Vendor?> getVendor(String userId, String vendorId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('vendors')
        .doc(vendorId)
        .get();

    if (doc.exists) {
      return Vendor.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<Vendor>> getVendors(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('vendors')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Vendor.fromFirestore(doc)).toList());
  }

  Future<void> updateVendor(
      String userId, String vendorId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('vendors')
        .doc(vendorId)
        .update(data);
  }

  Future<List<Vendor>> searchVendors(String userId, String query) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('vendors')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs.map((doc) => Vendor.fromFirestore(doc)).toList();
  }

  Future<Vendor> findOrCreateVendor(String userId, String vendorName) async {
    final searchResults = await searchVendors(userId, vendorName);

    if (searchResults.isNotEmpty) {
      return searchResults.first;
    }

    final newVendor = Vendor.simple(userId: userId, name: vendorName);
    final vendorId = await createVendor(newVendor);

    return newVendor.copyWith(id: vendorId);
  }

  Future<void> deactivateVendor(String userId, String vendorId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('vendors')
        .doc(vendorId)
        .update({
      'isActive': false,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<String> createInvoice(Invoice invoice) async {
    final docRef = await _firestore
        .collection('users')
        .doc(invoice.userId)
        .collection('invoices')
        .add(invoice.toFirestore());

    await _updateVendorStats(invoice.userId, invoice.vendorId);

    return docRef.id;
  }

  Future<Invoice?> getInvoice(String userId, String invoiceId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(invoiceId)
        .get();

    if (doc.exists) {
      return Invoice.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<Invoice>> getInvoices(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList());
  }

  Future<List<Invoice>> getInvoicesByDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    final startDateStr =
        '${startDate.day.toString().padLeft(2, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.year}';
    final endDateStr =
        '${endDate.day.toString().padLeft(2, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.year}';

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .where('invoiceDate', isGreaterThanOrEqualTo: startDateStr)
        .where('invoiceDate', isLessThanOrEqualTo: endDateStr)
        .orderBy('invoiceDate', descending: false)
        .get();

    return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
  }

  Future<List<Invoice>> getInvoicesByVendor(
      String userId, String vendorId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
  }

  Future<void> updateInvoice(
      String userId, String invoiceId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(invoiceId)
        .update(data);
  }

  Future<void> deleteInvoice(String userId, String invoiceId) async {
    final invoice = await getInvoice(userId, invoiceId);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(invoiceId)
        .delete();

    if (invoice != null) {
      await _updateVendorStats(userId, invoice.vendorId);
    }
  }

  Future<void> _updateVendorStats(String userId, String vendorId) async {
    final invoices = await getInvoicesByVendor(userId, vendorId);

    final invoiceCount = invoices.length;
    final totalAmount = invoices.fold<double>(
      0.0,
      (total, invoice) => total + invoice.totalAmount,
    );

    await updateVendor(userId, vendorId, {
      'invoiceCount': invoiceCount,
      'totalAmount': totalAmount,
    });
  }

  Future<int> getTotalInvoiceCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  Future<double> getTotalInvoiceAmount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .get();

    return snapshot.docs.fold<double>(
      0.0,
      (total, doc) {
        final data = doc.data();
        return total + ((data['totalAmount'] as num?)?.toDouble() ?? 0.0);
      },
    );
  }

  Future<Map<String, dynamic>> getMonthlyStats(
      String userId, int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final invoices = await getInvoicesByDateRange(userId, startDate, endDate);

    return {
      'count': invoices.length,
      'totalAmount': invoices.fold<double>(
        0.0,
        (total, invoice) => total + invoice.totalAmount,
      ),
      'averageAmount': invoices.isEmpty
          ? 0.0
          : invoices.fold<double>(
                0.0,
                (total, invoice) => total + invoice.totalAmount,
              ) /
              invoices.length,
    };
  }
}
