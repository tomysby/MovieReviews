import 'package:flutter/material.dart';
import '../api_service.dart';
import 'add_edit_review_screen.dart';

class MovieReviewsScreen extends StatefulWidget {
  final String username;

  const MovieReviewsScreen({Key? key, required this.username}) : super(key: key);

  @override
  _MovieReviewsScreenState createState() => _MovieReviewsScreenState();
}

class _MovieReviewsScreenState extends State<MovieReviewsScreen> {
  final _apiService = ApiService();
  List<dynamic> _reviews = [];
  bool _isLoading = false; // Tambahkan indikator loading

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

  Future<void> _toggleLike(String id, bool isCurrentlyLiked, String title, int rating, String comment, String imageUrl) async {
    try {
      final success = await _apiService.updateReview(id, widget.username, title, rating, comment, imageUrl, !isCurrentlyLiked);
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
          SnackBar(content: Text('Gagal menghapus review')),
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
        title: Text('Review Film Saya'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
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
          ? Center(child: CircularProgressIndicator()) // Indikator loading
          : _reviews.isEmpty
              ? Center(child: Text('Belum ada review. Tambahkan sekarang!'))
              : ListView.builder(
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: ListTile(
                        leading: review['imageUrl'] != null && review['imageUrl'].isNotEmpty
                            ? Image.network(
                                review['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                              )
                            : CircleAvatar(
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
                                review['imageUrl'] ?? '',
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit),
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
                              icon: Icon(Icons.delete),
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