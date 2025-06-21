import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaveTabBar extends StatelessWidget {
  final TabController tabController;
  final List<Widget> tabs;

  const LeaveTabBar({super.key, required this.tabController, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TabBar(
            controller: tabController,
            labelColor: const Color(0xFF1976D2),
            unselectedLabelColor: const Color(0xFF718096),
            indicatorColor: const Color(0xFF1976D2),
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.pending),
                text: 'Pending',
              ),
              Tab(
                icon: Icon(Icons.check_circle),
                text: 'Approved',
              ),
              Tab(
                icon: Icon(Icons.cancel),
                text: 'Rejected',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: tabs,
          ),
        ),
      ],
    );
  }
}