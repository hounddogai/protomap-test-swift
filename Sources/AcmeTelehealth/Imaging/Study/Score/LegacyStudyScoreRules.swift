import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy study score must pass. Check returns its problems, or none.
    protocol LegacyStudyScoreRule {
        func check(_ item: LegacyStudyScore) -> [String]
    }

    final class LegacyStudyScoreCodePrefixRule: LegacyStudyScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyStudyScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyStudyScoreBudgetRangeRule: LegacyStudyScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyStudyScore) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyStudyScoreRequiredDescriptionRule: LegacyStudyScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStudyScore) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyStudyScoreLabelLengthRule: LegacyStudyScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStudyScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy study score.
    final class LegacyStudyScoreValidator {
        var rules: [any LegacyStudyScoreRule]

        init(rules: [any LegacyStudyScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyStudyScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyStudyScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyStudyScore]) -> [String: [String]] {
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

    static func defaultLegacyStudyScoreValidator() -> LegacyStudyScoreValidator {
        return LegacyStudyScoreValidator(
            rules: [
                LegacyStudyScoreCodePrefixRule(prefix: "ACM"),
                LegacyStudyScoreBudgetRangeRule(min: 8.6, max: 1444.3),
                LegacyStudyScoreRequiredDescriptionRule(message: "legacy study score needs a value"),
                LegacyStudyScoreLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
