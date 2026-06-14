import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final AppController controller;
  const OnboardingScreen({super.key, required this.controller});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Sudarshan Study',
      description: 'Pratyek vishay mein maharat hasil karein Spaced Repetition (SM-2) ki shakti se.',
      image: Icons.auto_stories,
      color: const Color(0xFFFFF9C4), // Soft Yellow
    ),
    OnboardingData(
      title: 'Active Recall',
      description: 'Sirf padhein nahi, yaad karein. Quiz aur Flashcards ke saath apni memory test karein.',
      image: Icons.psychology,
      color: const Color(0xFFE3F2FD), // Soft Blue
    ),
    OnboardingData(
      title: 'Social Leaderboard',
      description: 'Doston ko invite karein, unke saath custom leaderboard banayein aur milkar grow karein.',
      image: Icons.groups,
      color: const Color(0xFFE8F5E9), // Soft Green
    ),
    OnboardingData(
      title: 'Track Your Growth',
      description: 'Apna Level badhayein, Achievements unlock karein aur Sudarshan Immortal banein.',
      image: Icons.workspace_premium,
      color: const Color(0xFFF3E5F5), // Soft Purple
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: _pages[index].color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_pages[index].image, size: 100, color: AppColors.text),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _pages[index].title,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _pages[index].description,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.accent : AppColors.line,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        widget.controller.completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData image;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
