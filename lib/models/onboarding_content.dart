class OnboardingContent {
  final String title;
  final String description;
  final String imagePath;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

List<OnboardingContent> onboardingContents = [
  OnboardingContent(
    title: 'Welcome to BSharp Cuts',
    description:
        'Your premium barber appointment booking app. Style your way, anytime.',
    imagePath: 'assets/images/onboarding1.png',
  ),
  OnboardingContent(
    title: 'Easy Booking',
    description:
        'Book your favorite barber with just a few taps. No more waiting in line.',
    imagePath: 'assets/images/onboarding2.png',
  ),
  OnboardingContent(
    title: 'Style Catalog',
    description:
        'Browse through trending hairstyles and find your perfect look.',
    imagePath: 'assets/images/onboarding3.png',
  ),
];
