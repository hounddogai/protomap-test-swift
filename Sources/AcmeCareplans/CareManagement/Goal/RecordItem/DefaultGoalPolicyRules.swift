import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default goal policy must pass. Check returns its problems, or none.
    protocol DefaultGoalPolicyRule {
        func check(_ item: DefaultGoalPolicy) -> [String]
    }

    final class DefaultGoalPolicyRequiredNameRule: DefaultGoalPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultGoalPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultGoalPolicyGraceDaysRangeRule: DefaultGoalPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultGoalPolicy) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultGoalPolicyNameLengthRule: DefaultGoalPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultGoalPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultGoalPolicyRequiredCodeRule: DefaultGoalPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultGoalPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultGoalPolicyActiveGuardRule: DefaultGoalPolicyRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultGoalPolicy) -> [String] {
            if item.active && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class DefaultGoalPolicyWardLengthRule: DefaultGoalPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultGoalPolicy) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default goal policy.
    final class DefaultGoalPolicyValidator {
        var rules: [any DefaultGoalPolicyRule]

        init(rules: [any DefaultGoalPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultGoalPolicy) -> [String] {
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

        func requireValid(_ item: DefaultGoalPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultGoalPolicy]) -> [String: [String]] {
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

    static func defaultDefaultGoalPolicyValidator() -> DefaultGoalPolicyValidator {
        return DefaultGoalPolicyValidator(
            rules: [
                DefaultGoalPolicyRequiredNameRule(message: "default goal policy needs this field"),
                DefaultGoalPolicyGraceDaysRangeRule(min: 16, max: 120),
                DefaultGoalPolicyNameLengthRule(maxLength: 1000),
                DefaultGoalPolicyRequiredCodeRule(message: "default goal policy needs a value"),
                DefaultGoalPolicyActiveGuardRule(limit: 64),
                DefaultGoalPolicyWardLengthRule(maxLength: 86400),
            ]
        )
    }
}
