import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback goal group must pass. Check returns its problems, or none.
    protocol FallbackGoalGroupRule {
        func check(_ item: FallbackGoalGroup) -> [String]
    }

    final class FallbackGoalGroupRequiredReviewerRule: FallbackGoalGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackGoalGroup) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackGoalGroupMinimumRangeRule: FallbackGoalGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackGoalGroup) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackGoalGroupRequiredCodeRule: FallbackGoalGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackGoalGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackGoalGroupCodePrefixRule: FallbackGoalGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackGoalGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackGoalGroupCodeLengthRule: FallbackGoalGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackGoalGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackGoalGroupThresholdRangeRule: FallbackGoalGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackGoalGroup) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback goal group.
    final class FallbackGoalGroupValidator {
        var rules: [any FallbackGoalGroupRule]

        init(rules: [any FallbackGoalGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackGoalGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackGoalGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackGoalGroup]) -> [String: [String]] {
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

    static func defaultFallbackGoalGroupValidator() -> FallbackGoalGroupValidator {
        return FallbackGoalGroupValidator(
            rules: [
                FallbackGoalGroupRequiredReviewerRule(message: "fallback goal group needs this field"),
                FallbackGoalGroupMinimumRangeRule(min: 8.3, max: 3106.4),
                FallbackGoalGroupRequiredCodeRule(message: "fallback goal group needs a value"),
                FallbackGoalGroupCodePrefixRule(prefix: "Q"),
                FallbackGoalGroupCodeLengthRule(maxLength: 64),
                FallbackGoalGroupThresholdRangeRule(min: 2.0, max: 3023.5),
            ]
        )
    }
}
