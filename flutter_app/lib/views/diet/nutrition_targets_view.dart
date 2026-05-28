// DASH Nutrition Targets – reference panel for clinical nutrient goals.
// Displays the 8 primary DASH targets with progress-style visualisation
// and South Indian dietary adaptations section.

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

class NutritionTargetsView extends StatelessWidget {
  const NutritionTargetsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          const AppHeader(
            title: 'DASH Targets',
            subtitle: 'Clinical nutrition guidelines',
            showBack: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                _SectionLabel(text: 'Daily Nutrient Targets'),
                SizedBox(height: 12),
                _TargetCard(
                  icon: Icons.water_drop_outlined,
                  color: Color(0xFF2563EB),
                  label: 'Sodium',
                  target: '≤ 1,500 mg',
                  rationale:
                      'Strict DASH cap. Reduces systolic BP by 5–6 mmHg. '
                      'Indian foods often exceed this; limit pickles, papads, and processed snacks.',
                  fraction: 0.0, // no daily data here; illustrative only
                  showBar: false,
                ),
                _TargetCard(
                  icon: Icons.bolt_outlined,
                  color: Color(0xFF16A34A),
                  label: 'Potassium',
                  target: '4,700 mg',
                  rationale:
                      'Counteracts sodium; lowers BP by 3–4 mmHg. '
                      'Abundant in drumstick leaves, banana, sweet potato, coconut water.',
                  fraction: 0.0,
                  showBar: false,
                ),
                _TargetCard(
                  icon: Icons.opacity_outlined,
                  color: Color(0xFF0891B2),
                  label: 'Calcium',
                  target: '1,250 mg',
                  rationale:
                      'Key for vascular tone. Sources: ragi (finger millet), '
                      'low-fat curd, sesame seeds (til), curry leaves.',
                  fraction: 0.0,
                  showBar: false,
                ),
                _TargetCard(
                  icon: Icons.auto_awesome_outlined,
                  color: Color(0xFF7C3AED),
                  label: 'Magnesium',
                  target: '500 mg',
                  rationale:
                      'Vasodilatory; reduces arterial stiffness. '
                      'Found in ragi, green leafy vegetables, nuts, seeds.',
                  fraction: 0.0,
                  showBar: false,
                ),
                _TargetCard(
                  icon: Icons.eco_outlined,
                  color: Color(0xFF059669),
                  label: 'Dietary Fiber',
                  target: '30 g',
                  rationale:
                      'Soluble fiber reduces LDL and systolic BP. '
                      'Oats, ragi, whole pulses, vegetables provide bulk.',
                  fraction: 0.0,
                  showBar: false,
                ),
                _TargetCard(
                  icon: Icons.fitness_center_outlined,
                  color: Color(0xFFD97706),
                  label: 'Protein',
                  target: '75–100 g',
                  rationale:
                      'Plant proteins preferred (dals, legumes, paneer). '
                      'DASH allows lean fish/egg for non-vegetarians.',
                  fraction: 0.0,
                  showBar: false,
                ),
                _TargetCard(
                  icon: Icons.local_fire_department_outlined,
                  color: Color(0xFFEA580C),
                  label: 'Energy (Calories)',
                  target: '~2,000 kcal',
                  rationale:
                      'Adjusted per BMI and activity level. '
                      'Weight reduction of 1 kg lowers BP by ~1 mmHg.',
                  fraction: 0.0,
                  showBar: false,
                ),
                _TargetCard(
                  icon: Icons.favorite_border_outlined,
                  color: Color(0xFFDC2626),
                  label: 'Saturated Fat',
                  target: '≤ 7% of kcal (≈ 15 g)',
                  rationale:
                      'Reduce coconut oil, ghee, full-fat dairy. '
                      'Replace with cold-pressed sesame/sunflower oil.',
                  fraction: 0.0,
                  showBar: false,
                ),
                SizedBox(height: 24),
                _SectionLabel(text: 'South Indian Adaptations'),
                SizedBox(height: 12),
                _AdaptationCard(
                  title: 'Ragi (Finger Millet)',
                  body:
                      'Highest calcium grain (344mg/100g). Swap white rice with ragi mudde '
                      'or ragi dosa for breakfast/dinner. Also high in fiber and Mg.',
                  emoji: '🌾',
                ),
                _AdaptationCard(
                  title: 'Reduce Coconut & Ghee',
                  body:
                      'Limit coconut chutney to 2 tbsp/serving. Use thin coconut milk '
                      'instead of thick. Replace ghee tadka with a light mustard-seed tempering '
                      'in sesame oil.',
                  emoji: '🥥',
                ),
                _AdaptationCard(
                  title: 'Limit Pickle & Papad',
                  body:
                      'A single mango pickle = 400–600 mg sodium. One papad = 150–250 mg. '
                      'Switch to fresh coriander/mint chutney and home-made low-salt varieties.',
                  emoji: '🥒',
                ),
                _AdaptationCard(
                  title: 'Drumstick (Moringa)',
                  body:
                      'Drumstick leaves contain 440mg K⁺ and 440mg Ca per 100g — '
                      'among the highest of any vegetable. Add to sambar, kootu, and dal daily.',
                  emoji: '🥬',
                ),
                _AdaptationCard(
                  title: 'Fermented Foods & Probiotics',
                  body:
                      'Idli, dosa, kanji, and curd are naturally fermented. '
                      'Gut microbiome diversity correlates with lower BP; include these daily.',
                  emoji: '🫙',
                ),
                _AdaptationCard(
                  title: 'Coconut Water',
                  body:
                      'Natural electrolyte: ~600mg K⁺ per cup, very low sodium (~250mg). '
                      'Ideal DASH-compliant hydration between meals.',
                  emoji: '🥤',
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.darkSlate,
        ),
      );
}

class _TargetCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String target;
  final String rationale;
  final double fraction;
  final bool showBar;

  const _TargetCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.target,
    required this.rationale,
    required this.fraction,
    required this.showBar,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkSlate)),
                      Text(target,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(rationale,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.midSlate,
                    height: 1.5)),
          ],
        ),
      );
}

class _AdaptationCard extends StatelessWidget {
  final String title;
  final String body;
  final String emoji;

  const _AdaptationCard({
    required this.title,
    required this.body,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkSlate)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.midSlate,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
}
