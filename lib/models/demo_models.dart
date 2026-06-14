class DemoQuestion {
  const DemoQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.topic,
    this.explanation = '',
  });

  final String question;
  final List<String> options;
  final int answerIndex;
  final String topic;
  final String explanation;
}

class DemoTest {
  const DemoTest({
    required this.title,
    required this.subject,
    required this.chapter,
    required this.level,
    required this.timeLimitMin,
    required this.questions,
    this.isPublished = false,
    this.isDaily = false,
  });

  final String title;
  final String subject;
  final String chapter;
  final String level;
  final int timeLimitMin;
  final List<DemoQuestion> questions;
  final bool isPublished;
  final bool isDaily;

  int get questionCount => questions.length;
}

class DemoNotebookCard {
  const DemoNotebookCard({
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.question,
    required this.answer,
    required this.scheduleLabel,
  });

  final String subject;
  final String chapter;
  final String topic;
  final String question;
  final String answer;
  final String scheduleLabel;
}

class TrialStatus {
  const TrialStatus({
    required this.daysLeft,
    required this.planName,
  });

  final int daysLeft;
  final String planName;

  bool get isActive => daysLeft > 0;
}

const trialStatus = TrialStatus(
  daysLeft: 7,
  planName: 'Starter Trial',
);

const demoNotebookCards = <DemoNotebookCard>[
  DemoNotebookCard(
    subject: 'Science',
    chapter: 'Chemical Reactions',
    topic: 'Acids and Bases',
    question: 'Blue litmus acid me kis color me badalta hai?',
    answer: 'Red',
    scheduleLabel: 'Due now',
  ),
  DemoNotebookCard(
    subject: 'Math',
    chapter: 'Quadratic Equations',
    topic: 'Factorization',
    question: 'x² + 5x + 6 ko factor form me likho.',
    answer: '(x + 2)(x + 3)',
    scheduleLabel: 'Review in 2h',
  ),
  DemoNotebookCard(
    subject: 'SST',
    chapter: 'Nationalism in India',
    topic: 'Movements',
    question: 'Civil Disobedience Movement kis year me launch hua?',
    answer: '1930',
    scheduleLabel: 'Tomorrow',
  ),
];

const demoTests = <DemoTest>[
  DemoTest(
    title: 'Daily Weak Topic Drill',
    subject: 'Science',
    chapter: 'Chemical Reactions',
    level: 'Level 1',
    timeLimitMin: 12,
    isPublished: true,
    isDaily: true,
    questions: [
      DemoQuestion(
        question:
            'Neutralization reaction me acid aur base milkar kya banate hain?',
        options: ['Salt and water', 'Only oxygen', 'Only gas', 'Only metal'],
        answerIndex: 0,
        topic: 'Acids and Bases',
        explanation:
            'Acid aur base ke reaction se generally salt aur water banta hai.',
      ),
      DemoQuestion(
        question: 'pH value 7 kis solution ko dikhati hai?',
        options: ['Acidic', 'Basic', 'Neutral', 'Salty'],
        answerIndex: 2,
        topic: 'Acids and Bases',
        explanation: 'pH 7 neutral hota hai.',
      ),
      DemoQuestion(
        question: 'Turmeric basic solution me kis color me dikhti hai?',
        options: ['Blue', 'Red-brown', 'Green', 'Black'],
        answerIndex: 1,
        topic: 'Indicators',
        explanation: 'Haldi base me red-brown ho jati hai.',
      ),
    ],
  ),
  DemoTest(
    title: 'Board Sprint Set',
    subject: 'Math',
    chapter: 'Quadratic Equations',
    level: 'Level 2',
    timeLimitMin: 20,
    isPublished: true,
    questions: [
      DemoQuestion(
        question: 'x² - 5x + 6 = 0 ke roots kya hain?',
        options: ['2 and 3', '1 and 6', '-2 and -3', '0 and 6'],
        answerIndex: 0,
        topic: 'Roots',
        explanation: 'Equation ko factor karne par (x-2)(x-3) milta hai.',
      ),
      DemoQuestion(
        question: 'Quadratic equation ka standard form kya hota hai?',
        options: ['ax + b = 0', 'ax² + bx + c = 0', 'ax³ + bx² = 0', 'a/x = 0'],
        answerIndex: 1,
        topic: 'Form',
        explanation: 'Quadratic degree 2 hoti hai, isliye ax² + bx + c = 0.',
      ),
      DemoQuestion(
        question: 'Discriminant ka formula kya hai?',
        options: ['b² - 4ac', 'a² + b²', '2ab', 'b² + 4ac'],
        answerIndex: 0,
        topic: 'Discriminant',
        explanation: 'Quadratic ke liye discriminant D = b² - 4ac hota hai.',
      ),
    ],
  ),
  DemoTest(
    title: 'Subjective Writing Push',
    subject: 'SST',
    chapter: 'Nationalism in India',
    level: 'Level 1',
    timeLimitMin: 18,
    questions: [
      DemoQuestion(
        question: 'Non-Cooperation Movement kisne lead kiya?',
        options: ['Bhagat Singh', 'Mahatma Gandhi', 'Subhas Bose', 'Tilak'],
        answerIndex: 1,
        topic: 'Movements',
        explanation:
            'Non-Cooperation Movement Mahatma Gandhi ne lead kiya tha.',
      ),
      DemoQuestion(
        question: 'Salt March kis year me hua tha?',
        options: ['1920', '1930', '1942', '1919'],
        answerIndex: 1,
        topic: 'Movements',
        explanation: 'Salt March 1930 me hua tha.',
      ),
      DemoQuestion(
        question:
            'Nationalism ko strong karne me print culture ka kya role tha?',
        options: [
          'It reduced awareness',
          'It spread ideas fast',
          'It ended politics',
          'It banned newspapers'
        ],
        answerIndex: 1,
        topic: 'Print Culture',
        explanation: 'Print culture ne nationalist ideas ko fast spread kiya.',
      ),
    ],
  ),
];
