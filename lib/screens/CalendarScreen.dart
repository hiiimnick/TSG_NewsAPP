import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/NewsProvider.dart';
import '../classes/NewsModel.dart';
import '../widgets/NewsCard.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<NewsModel> _selectedDayNews = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _isLoading = true;
              });
              
              Provider.of<NewsProvider>(context, listen: false)
                  .getNewsByDate(selectedDay)
                  .then((newsList) {
                setState(() {
                  _selectedDayNews = newsList;
                  _isLoading = false;
                });
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading news: $error')),
                );
                setState(() {
                  _isLoading = false;
                });
              });
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedDay == null
                    ? const Center(child: Text('Select a day to see news'))
                    : _selectedDayNews.isEmpty
                        ? const Center(child: Text('No news found for this day'))
                        : ListView.builder(
                            itemCount: _selectedDayNews.length,
                            itemBuilder: (context, index) {
                              return NewsCard(news: _selectedDayNews[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}