import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'add_edit_review_screen.dart';

class MovieReviewsScreen extends StatefulWidget {
  final String username;

  const MovieReviewsScreen({super.key, required this.username});

  @override
  _MovieReviewsScreenState createState() => _MovieReviewsScreenState();
}

class _MovieReviewsScreenState extends State<MovieReviewsScreen> {
  final _apiService = ApiService();
  List<dynamic> _reviews = [];
  bool _isLoading = false; // Indikator loading

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true; // Tampilkan indikator loading
    });

    try {
      final reviews = await _apiService.getReviews(widget.username);
      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat review: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Sembunyikan indikator loading
      });
    }
  }

  Future<void> _toggleLike(String id, bool isCurrentlyLiked, String title, int rating, String comment, String? imageBase64) async {
    try {
      final success = await _apiService.updateReview(
        id,
        widget.username,
        title,
        rating,
        comment,
        imageBase64,
        !isCurrentlyLiked,
      );
      if (success) {
        setState(() {
          _reviews = _reviews.map((review) {
            if (review['_id'] == id) {
              return {
                ...review,
                'isLiked': !isCurrentlyLiked,
              };
            }
            return review;
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status like: $e')),
      );
    }
  }

  void _deleteReview(String id) async {
    try {
      final success = await _apiService.deleteReview(id);
      if (success) {
        _loadReviews();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus review')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Film Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditReviewScreen(username: widget.username),
                ),
              );
              if (result == true) _loadReviews();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Indikator loading
          : _reviews.isEmpty
              ? const Center(child: Text('Belum ada review. Tambahkan sekarang!'))
              : ListView.builder(
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    Uint8List? imageBytes;

                    // Decode Base64 jika ada gambar
                    if (review['imageBase64'] != null) {
                      try {
                        imageBytes = base64Decode(review['imageBase64']);
                      } catch (e) {
                        imageBytes = null;
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: ListTile(
                        leading: imageBytes != null
                            ? Image.memory(
                                imageBytes,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.movie),
                              ),
                        title: Text(review['title'] ?? 'Judul tidak tersedia'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${review['rating'] ?? 0} / 10'),
                            Text(review['comment'] ?? 'Komentar tidak tersedia'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                review['isLiked'] == true ? Icons.thumb_up : Icons.thumb_up_outlined,
                                color: review['isLiked'] == true ? Colors.blue : Colors.grey,
                              ),
                              onPressed: () => _toggleLike(
                                review['_id'],
                                review['isLiked'] ?? false,
                                review['title'] ?? '',
                                review['rating'] ?? 0,
                                review['comment'] ?? '',
                                review['imageBase64'],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditReviewScreen(
                                      username: widget.username,
                                      review: review,
                                    ),
                                  ),
                                );
                                if (result == true) _loadReviews();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteReview(review['_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}