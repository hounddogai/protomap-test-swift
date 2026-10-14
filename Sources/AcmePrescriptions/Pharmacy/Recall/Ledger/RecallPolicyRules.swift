import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall policy must pass. Check returns its problems, or none.
    protocol RecallPolicyRule {
        func check(_ item: RecallPolicy) -> [String]
    }

    final class RecallPolicyCurrencyLengthRule: RecallPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallPolicy) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallPolicyThresholdRangeRule: RecallPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallPolicy) -> [String] {
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

    final class RecallPolicyCodeLengthRule: RecallPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall policy.
    final class RecallPolicyValidator {
        var rules: [any RecallPolicyRule]

        init(rules: [any RecallPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallPolicy]) -> [String: [String]] {
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

    static func defaultRecallPolicyValidator() -> RecallPolicyValidator {
        return RecallPolicyValidator(
            rules: [
                RecallPolicyCurrencyLengthRule(maxLength: 86400),
                RecallPolicyThresholdRangeRule(min: 6.1, max: 5003.7),
                RecallPolicyCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
