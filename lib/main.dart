import 'package:flutter/material.dart';
import 'db/database_helper.dart';
import 'models/post.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OfflinePostsManagerApp());
}

class OfflinePostsManagerApp extends StatelessWidget {
  const OfflinePostsManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Posts Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PostsListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PostsListPage extends StatefulWidget {
  const PostsListPage({super.key});

  @override
  State<PostsListPage> createState() => _PostsListPageState();
}

class _PostsListPageState extends State<PostsListPage> {
  final db = DatabaseHelper.instance;
  List<Post> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final posts = await db.getAllPosts();
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _addOrEditPost([Post? existing]) async {
    final result = await Navigator.push<Post?>(
      context,
      MaterialPageRoute(builder: (_) => PostEditPage(post: existing)),
    );

    if (result != null) {
      try {
        if (existing == null) {
          await db.insertPost(result);
        } else {
          await db.updatePost(result);
        }
        await _loadPosts();
      } catch (e) {
        _showSnack('Save failed: $e');
      }
    }
  }

  Future<void> _deletePost(Post post) async {
    try {
      await db.deletePost(post.id!);
      _showSnack('Deleted "${post.title}"');
      await _loadPosts();
    } catch (e) {
      _showSnack('Delete failed: $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Posts Manager')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _posts.isEmpty
          ? const Center(child: Text('No posts yet. Tap + to add one.'))
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return Dismissible(
                    key: ValueKey(post.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _deletePost(post),
                    child: ListTile(
                      title: Text(post.title),
                      subtitle: Text(
                        post.content.length > 70
                            ? '${post.content.substring(0, 70)}...'
                            : post.content,
                      ),
                      trailing: Text(
                        '${post.createdAt.toLocal()}'.split('.')[0],
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailPage(post: post),
                          ),
                        );
                        await _loadPosts();
                      },
                      onLongPress: () => _addOrEditPost(post),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditPost(),
        tooltip: 'Add Post',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PostDetailPage extends StatelessWidget {
  final Post post;
  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${post.createdAt.toLocal()}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(post.content, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () async {
                    final updated = await Navigator.push<Post?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostEditPage(post: post),
                      ),
                    );
                    if (updated != null && context.mounted) {
                      try {
                        await DatabaseHelper.instance.updatePost(updated);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post updated.')),
                          );
                          Navigator.pop(context); // Go back to list
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Update failed: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  onPressed: () async {
                    try {
                      await DatabaseHelper.instance.deletePost(post.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post deleted.')),
                        );
                        Navigator.pop(context); // leave details view
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Delete failed: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PostEditPage extends StatefulWidget {
  final Post? post;
  const PostEditPage({super.key, this.post});

  @override
  State<PostEditPage> createState() => _PostEditPageState();
}

class _PostEditPageState extends State<PostEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post?.title ?? '');
    _contentController = TextEditingController(
      text: widget.post?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final post = Post(
      id: widget.post?.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: widget.post?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, post);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.post != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Post' : 'Add Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Content is required'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
