import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study digest must pass. Check returns its problems, or none.
    protocol StudyDigestRule {
        func check(_ item: StudyDigest) -> [String]
    }

    final class StudyDigestAllowedCodeRule: StudyDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class StudyDigestMinimumRangeRule: StudyDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyDigest) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudyDigestRequiredTitleRule: StudyDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a study digest.
    final class StudyDigestValidator {
        var rules: [any StudyDigestRule]

        init(rules: [any StudyDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: StudyDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyDigest]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultStudyDigestValidator() -> StudyDigestValidator {
        return StudyDigestValidator(
            rules: [
                StudyDigestAllowedCodeRule(allowed: ["global", "strict"]),
                StudyDigestMinimumRangeRule(min: 5.4, max: 1336.1),
                StudyDigestRequiredTitleRule(message: "study digest needs an entry"),
            ]
        )
    }
}
