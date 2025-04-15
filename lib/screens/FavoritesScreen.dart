import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/FavoritesProvider.dart';
import '../widgets/NewsCard.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite News'),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          final favorites = favoritesProvider.favorites;
          
          if (favorites.isEmpty) {
            return const Center(
              child: Text('No favorite news yet'),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return NewsCard(
                news: favorites[index],
                showRemoveButton: true,
              );
            },
          );
        },
      ),
    );
  }
}