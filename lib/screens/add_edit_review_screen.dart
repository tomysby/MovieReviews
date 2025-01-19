import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:image_picker/image_picker.dart';

class AddEditReviewScreen extends StatefulWidget {
  final String username;
  final Map<dynamic, dynamic>? review;

  const AddEditReviewScreen({Key? key, required this.username, this.review}) : super(key: key);

  @override
  _AddEditReviewScreenState createState() => _AddEditReviewScreenState();
}

class _AddEditReviewScreenState extends State<AddEditReviewScreen> {
  final _titleController = TextEditingController();
  final _ratingController = TextEditingController();
  final _commentController = TextEditingController();

  Uint8List? _selectedImage;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.review != null) {
      // Jika dalam mode edit, isi controller dengan data review
      _titleController.text = widget.review!['title'] ?? '';
      _ratingController.text = widget.review!['rating'].toString();
      _commentController.text = widget.review!['comment'] ?? '';

      if (widget.review!['imageBase64'] != null) {
        _selectedImage = base64Decode(widget.review!['imageBase64']);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = imageBytes;
      });
    }
  }

  String encodeToBase64(Uint8List data) {
    return base64Encode(data);
  }

  void _saveReview() async {
    final title = _titleController.text.trim();
    final rating = int.tryParse(_ratingController.text) ?? 0;
    final comment = _commentController.text.trim();
    final isLiked = widget.review?['isLiked'] ?? false; // Default isLiked = false untuk review baru

    // Validasi input
    if (title.isEmpty || rating < 1 || rating > 10 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul, komentar, dan rating (1-10) harus diisi.')),
      );
      return;
    }

    // Konversi gambar ke Base64 jika tersedia
    String? base64Image = _selectedImage != null ? encodeToBase64(_selectedImage!) : null;

    bool success;
    if (widget.review == null) {
      // Tambah review baru
      success = await _apiService.addReview(
        widget.username, title, rating, comment, base64Image,
      );
    } else {
      // Edit review
      success = await _apiService.updateReview(
        widget.review!['_id'], widget.username, title, rating, comment, base64Image, isLiked
      );
    }

    if (success) {
      Navigator.pop(context, true); // Berhasil, kembali ke layar sebelumnya
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.review != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Review' : 'Tambah Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul Film'),
              readOnly: isEditMode, // Nonaktifkan input judul jika dalam mode edit
            ),
            TextField(
              controller: _ratingController,
              decoration: const InputDecoration(labelText: 'Rating (1-10)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Komentar'),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _selectedImage != null
                    ? Image.memory(
                        _selectedImage!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image, size: 100),
                TextButton(
                  onPressed: _pickImage,
                  child: const Text('Pilih Gambar'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveReview,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
