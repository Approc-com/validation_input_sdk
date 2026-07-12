class Semver {
  static bool isValid(String v) => RegExp(r'^\d+\.\d+\.\d+$').hasMatch(v);

  static int compare(String a, String b) {
    final ap = a.split('.').map(int.parse).toList();
    final bp = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      if (ap[i] > bp[i]) return 1;
      if (ap[i] < bp[i]) return -1;
    }
    return 0;
  }

  static bool isGreater(String a, String b) => compare(a, b) > 0;
  static bool isLess(String a, String b) => compare(a, b) < 0;
}
