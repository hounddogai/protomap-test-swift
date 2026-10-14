import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist override must pass. Check returns its problems, or none.
    protocol WorklistOverrideRule {
        func check(_ item: WorklistOverride) -> [String]
    }

    final class WorklistOverrideRequiredTitleRule: WorklistOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistOverrideCodeLengthRule: WorklistOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistOverrideTitleLengthRule: WorklistOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistOverrideStartsAtRangeRule: WorklistOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistOverride) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistOverrideRequiredLocaleRule: WorklistOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistOverride) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistOverrideAttemptsRangeRule: WorklistOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistOverride) -> [String] {
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

    /// Runs every rule of a worklist override.
    final class WorklistOverrideValidator {
        var rules: [any WorklistOverrideRule]

        init(rules: [any WorklistOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistOverride]) -> [String: [String]] {
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

    static func defaultWorklistOverrideValidator() -> WorklistOverrideValidator {
        return WorklistOverrideValidator(
            rules: [
                WorklistOverrideRequiredTitleRule(message: "worklist override needs an entry"),
                WorklistOverrideCodeLengthRule(maxLength: 3600),
                WorklistOverrideTitleLengthRule(maxLength: 80),
                WorklistOverrideStartsAtRangeRule(min: 32, max: 255),
                WorklistOverrideRequiredLocaleRule(message: "worklist override needs a value"),
                WorklistOverrideAttemptsRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
