import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual goal policy must pass. Check returns its problems, or none.
    protocol ManualGoalPolicyRule {
        func check(_ item: ManualGoalPolicy) -> [String]
    }

    final class ManualGoalPolicyWeightRangeRule: ManualGoalPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualGoalPolicy) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualGoalPolicyRequiredTitleRule: ManualGoalPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualGoalPolicy) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualGoalPolicyCeilingRangeRule: ManualGoalPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualGoalPolicy) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualGoalPolicyRequiredPhoneRule: ManualGoalPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualGoalPolicy) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual goal policy.
    final class ManualGoalPolicyValidator {
        var rules: [any ManualGoalPolicyRule]

        init(rules: [any ManualGoalPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualGoalPolicy) -> [String] {
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

        func requireValid(_ item: ManualGoalPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualGoalPolicy]) -> [String: [String]] {
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

    static func defaultManualGoalPolicyValidator() -> ManualGoalPolicyValidator {
        return ManualGoalPolicyValidator(
            rules: [
                ManualGoalPolicyWeightRangeRule(min: 8.3, max: 1372.3),
                ManualGoalPolicyRequiredTitleRule(message: "manual goal policy needs an entry"),
                ManualGoalPolicyCeilingRangeRule(min: 1.5, max: 4561.3),
                ManualGoalPolicyRequiredPhoneRule(message: "manual goal policy needs this field"),
            ]
        )
    }
}
