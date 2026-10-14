import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study variance must pass. Check returns its problems, or none.
    protocol StudyVarianceRule {
        func check(_ item: StudyVariance) -> [String]
    }

    final class StudyVarianceTitleLengthRule: StudyVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyVarianceAllowedCodeRule: StudyVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class StudyVarianceRequiredTitleRule: StudyVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyVarianceAttemptsRangeRule: StudyVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyVariance) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StudyVarianceCodePrefixRule: StudyVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StudyVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a study variance.
    final class StudyVarianceValidator {
        var rules: [any StudyVarianceRule]

        init(rules: [any StudyVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyVariance) -> [String] {
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

        func requireValid(_ item: StudyVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyVariance]) -> [String: [String]] {
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

    static func defaultStudyVarianceValidator() -> StudyVarianceValidator {
        return StudyVarianceValidator(
            rules: [
                StudyVarianceTitleLengthRule(maxLength: 1000),
                StudyVarianceAllowedCodeRule(allowed: ["strict"]),
                StudyVarianceRequiredTitleRule(message: "study variance needs a value"),
                StudyVarianceAttemptsRangeRule(min: 16, max: 3600),
                StudyVarianceCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
