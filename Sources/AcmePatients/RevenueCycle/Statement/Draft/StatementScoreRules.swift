import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement score must pass. Check returns its problems, or none.
    protocol StatementScoreRule {
        func check(_ item: StatementScore) -> [String]
    }

    final class StatementScoreLabelLengthRule: StatementScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementScoreRequiredLabelRule: StatementScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementScoreRequiredEncounterIDRule: StatementScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementScore) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementScoreMarginRangeRule: StatementScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementScore) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementScoreCodePrefixRule: StatementScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementScoreEncounterIDLengthRule: StatementScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementScore) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement score.
    final class StatementScoreValidator {
        var rules: [any StatementScoreRule]

        init(rules: [any StatementScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementScore) -> [String] {
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

        func requireValid(_ item: StatementScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementScore]) -> [String: [String]] {
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

    static func defaultStatementScoreValidator() -> StatementScoreValidator {
        return StatementScoreValidator(
            rules: [
                StatementScoreLabelLengthRule(maxLength: 64),
                StatementScoreRequiredLabelRule(message: "statement score needs an entry"),
                StatementScoreRequiredEncounterIDRule(message: "statement score needs an entry"),
                StatementScoreMarginRangeRule(min: 5.1, max: 2925.5),
                StatementScoreCodePrefixRule(prefix: "ACM"),
                StatementScoreEncounterIDLengthRule(maxLength: 16),
            ]
        )
    }
}
