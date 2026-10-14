import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling goal policy must pass. Check returns its problems, or none.
    protocol RollingGoalPolicyRule {
        func check(_ item: RollingGoalPolicy) -> [String]
    }

    final class RollingGoalPolicyCodePrefixRule: RollingGoalPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingGoalPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingGoalPolicyDurationMinutesRangeRule: RollingGoalPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingGoalPolicy) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingGoalPolicyCodeLengthRule: RollingGoalPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingGoalPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling goal policy.
    final class RollingGoalPolicyValidator {
        var rules: [any RollingGoalPolicyRule]

        init(rules: [any RollingGoalPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingGoalPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingGoalPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingGoalPolicy]) -> [String: [String]] {
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

    static func defaultRollingGoalPolicyValidator() -> RollingGoalPolicyValidator {
        return RollingGoalPolicyValidator(
            rules: [
                RollingGoalPolicyCodePrefixRule(prefix: "Q"),
                RollingGoalPolicyDurationMinutesRangeRule(min: 1000, max: 1000),
                RollingGoalPolicyCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
