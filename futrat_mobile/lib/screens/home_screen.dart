import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/app_theme.dart';
import '../models/all_models.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedRound = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<DataProvider>(context, listen: false).initData()
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataProvider>(context);
    
    // Фильтрация по туру
    final matchesInRound = data.matches.where((m) => m.round == _selectedRound).toList();

    return Container(
      decoration: AppTheme.mainGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(data.selectedLeague?.name ?? "Матчи"),
          centerTitle: true,
        ),
        drawer: _buildDrawer(context, data),
        
        body: Column(
          children: [
            // ВЫБОР ТУРА (Горизонтальный список)
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: 38, // Максимум туров
                itemBuilder: (context, index) {
                  final round = index + 1;
                  final isSelected = round == _selectedRound;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRound = round),
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.neonPurple : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: Colors.white24),
                      ),
                      child: Text("Тур $round", style: TextStyle(color: isSelected ? Colors.white : Colors.grey)),
                    ),
                  );
                },
              ),
            ),

            // СПИСОК МАТЧЕЙ
            Expanded(
              child: data.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
                : matchesInRound.isEmpty
                    ? const Center(child: Text("Нет матчей в этом туре", style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: matchesInRound.length,
                        itemBuilder: (context, index) {
                          return _buildMatchCard(context, matchesInRound[index], data);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchModel match, DataProvider data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Home
            Expanded(
              child: Column(children: [
                _buildLogo(match.homeTeam.logoUrl),
                const SizedBox(height: 8),
                Text(match.homeTeam.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
            // Score
            Column(
              children: [
                Text(
                  match.status == 'FINISHED' || match.status == 'IN_PLAY'
                   ? "${match.scoreHome} - ${match.scoreAway}"
                   : DateFormat('HH:mm').format(match.dateTime),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(DateFormat('dd.MM').format(match.dateTime), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (match.status == 'IN_PLAY')
                   const Text("LIVE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            ),
            // Away
            Expanded(
              child: Column(children: [
                _buildLogo(match.awayTeam.logoUrl),
                const SizedBox(height: 8),
                Text(match.awayTeam.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // Универсальный виджет логотипа
  Widget _buildLogo(String? url) {
    if (url == null || url.isEmpty) return const Icon(Icons.shield, color: Colors.white24, size: 40);
    // API часто отдает SVG. Flutter Image.network не умеет SVG. 
    // Для простоты, если это SVG - показываем заглушку, либо нужен пакет flutter_svg.
    // Если PNG - показываем.
    if (url.endsWith('.svg')) {
       // В реальном проекте тут нужен SvgPicture.network из flutter_svg
       return const Icon(Icons.shield, color: AppTheme.neonPurple, size: 40); 
    }
    return Image.network(
      url, 
      height: 40, width: 40, 
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, color: Colors.white24, size: 40),
    );
  }

  Drawer _buildDrawer(BuildContext context, DataProvider data) {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Column(
        children: [
           DrawerHeader(
             decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.deepPurple, AppTheme.almostBlack])),
             child: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.sports_soccer, size: 50, color: AppTheme.neonPurple),
                   const SizedBox(height: 10),
                   const Text("Лиги", style: TextStyle(color: Colors.white, fontSize: 20)),
                 ],
               ),
             ),
           ),
           Expanded(
             child: ListView.builder(
               itemCount: data.tournaments.length,
               itemBuilder: (ctx, i) {
                 final t = data.tournaments[i];
                 final isSel = t.id == data.selectedLeague?.id;
                 final isFav = data.isLeagueFavorite(t.id);
                 return ListTile(
                   title: Text(t.name, style: TextStyle(color: isSel ? AppTheme.neonPurple : Colors.white)),
                   trailing: IconButton(
                     icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.grey),
                     onPressed: () => data.toggleTournamentFavorite(t.id),
                   ),
                   onTap: () {
                     data.selectLeague(t);
                     Navigator.pop(context);
                   },
                 );
               },
             ),
           )
        ],
      ),
    );
  }
}