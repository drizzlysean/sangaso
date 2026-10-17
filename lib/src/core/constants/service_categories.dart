const List<String> kSearchCategories = [
  'All',
  'Cleaning',
  'Plumbing',
  'Electrical',
  'Carpentry',
  'Painting',
  'Gardening',
  'Moving',
  'Tutoring',
  'Beauty & Wellness',
  'IT & Tech Support',
  'Event Planning',
  'Other',
];

String validateSearchCategory(String? candidate) {
  if (candidate == null || candidate.trim().isEmpty) return 'All';
  final trimmed = candidate.trim();
  if (!kSearchCategories.contains(trimmed)) return 'All';
  return trimmed;
}
