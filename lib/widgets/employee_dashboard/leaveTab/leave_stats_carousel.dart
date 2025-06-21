import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaveStatsCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> leaveStats;
  final Size size;

  const LeaveStatsCarousel({super.key, required this.leaveStats, required this.size});

  @override
  Widget build(BuildContext context) {
    final cardHeight = size.height * 0.20;
    
    if (leaveStats.isEmpty) {
      return Container(
        height: cardHeight,
        child: Center(
          child: Text(
            'No leave statistics available',
            style: GoogleFonts.inter(fontSize: 16, color: Color(0xFF4A5568)),
          ),
        ),
      );
    }
    
    return CarouselSlider.builder(
      itemCount: leaveStats.length,
      itemBuilder: (context, index, realIndex) {
        final stat = leaveStats[index];
        return _LeaveStatCard(
          title: stat['title'],
          value: stat['value'],
          color: stat['color'],
          icon: stat['icon'],
          gradient: stat['gradient'],
          width: size.width,
        );
      },
      options: CarouselOptions(
        height: cardHeight + 20,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 3),
        viewportFraction: 0.85,
        enableInfiniteScroll: leaveStats.length > 1,
      ),
    );
  }
}

class _LeaveStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final List<Color> gradient;
  final double width;

  const _LeaveStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.gradient,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                gradient.first.withOpacity(0.1),
                gradient.last.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A5568),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}