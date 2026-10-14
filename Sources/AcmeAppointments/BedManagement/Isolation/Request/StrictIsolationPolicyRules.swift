import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict isolation policy must pass. Check returns its problems, or none.
    protocol StrictIsolationPolicyRule {
        func check(_ item: StrictIsolationPolicy) -> [String]
    }

    final class StrictIsolationPolicyRequiredLabelRule: StrictIsolationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictIsolationPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictIsolationPolicyBudgetRangeRule: StrictIsolationPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictIsolationPolicy) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictIsolationPolicyCodeLengthRule: StrictIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictIsolationPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictIsolationPolicyRequiredCodeRule: StrictIsolationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictIsolationPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictIsolationPolicyReviewerLengthRule: StrictIsolationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictIsolationPolicy) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict isolation policy.
    final class StrictIsolationPolicyValidator {
        var rules: [any StrictIsolationPolicyRule]

        init(rules: [any StrictIsolationPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictIsolationPolicy) -> [String] {
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

        func requireValid(_ item: StrictIsolationPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictIsolationPolicy]) -> [String: [String]] {
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

    static func defaultStrictIsolationPolicyValidator() -> StrictIsolationPolicyValidator {
        return StrictIsolationPolicyValidator(
            rules: [
                StrictIsolationPolicyRequiredLabelRule(message: "strict isolation policy needs this field"),
                StrictIsolationPolicyBudgetRangeRule(min: 2.6, max: 2514.4),
                StrictIsolationPolicyCodeLengthRule(maxLength: 64),
                StrictIsolationPolicyRequiredCodeRule(message: "strict isolation policy needs a value"),
                StrictIsolationPolicyReviewerLengthRule(maxLength: 80),
            ]
        )
    }
}
