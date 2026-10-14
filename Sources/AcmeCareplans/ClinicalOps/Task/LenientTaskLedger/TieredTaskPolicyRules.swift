import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered task policy must pass. Check returns its problems, or none.
    protocol TieredTaskPolicyRule {
        func check(_ item: TieredTaskPolicy) -> [String]
    }

    final class TieredTaskPolicyAllowedCodeRule: TieredTaskPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredTaskPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class TieredTaskPolicyRequiredCodeRule: TieredTaskPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredTaskPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredTaskPolicyRequiredExternalRefRule: TieredTaskPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredTaskPolicy) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredTaskPolicyCodeLengthRule: TieredTaskPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredTaskPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredTaskPolicyCostRangeRule: TieredTaskPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredTaskPolicy) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered task policy.
    final class TieredTaskPolicyValidator {
        var rules: [any TieredTaskPolicyRule]

        init(rules: [any TieredTaskPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredTaskPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredTaskPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredTaskPolicy]) -> [String: [String]] {
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

    static func defaultTieredTaskPolicyValidator() -> TieredTaskPolicyValidator {
        return TieredTaskPolicyValidator(
            rules: [
                TieredTaskPolicyAllowedCodeRule(allowed: ["legacy", "default", "rolling"]),
                TieredTaskPolicyRequiredCodeRule(message: "tiered task policy needs this field"),
                TieredTaskPolicyRequiredExternalRefRule(message: "tiered task policy needs an entry"),
                TieredTaskPolicyCodeLengthRule(maxLength: 16),
                TieredTaskPolicyCostRangeRule(min: 5.1, max: 4781.0),
            ]
        )
    }
}
