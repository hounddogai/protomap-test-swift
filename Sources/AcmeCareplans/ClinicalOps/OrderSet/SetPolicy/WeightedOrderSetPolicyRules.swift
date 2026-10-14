import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted order set policy must pass. Check returns its problems, or none.
    protocol WeightedOrderSetPolicyRule {
        func check(_ item: WeightedOrderSetPolicy) -> [String]
    }

    final class WeightedOrderSetPolicyCodeLengthRule: WeightedOrderSetPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOrderSetPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedOrderSetPolicyAllowedPayerRule: WeightedOrderSetPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedOrderSetPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is not allowed"]
            }
            return []
        }
    }

    final class WeightedOrderSetPolicyRequiredProcedureCodeRule: WeightedOrderSetPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedOrderSetPolicy) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedOrderSetPolicyPayerLengthRule: WeightedOrderSetPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOrderSetPolicy) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted order set policy.
    final class WeightedOrderSetPolicyValidator {
        var rules: [any WeightedOrderSetPolicyRule]

        init(rules: [any WeightedOrderSetPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedOrderSetPolicy) -> [String] {
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

        func requireValid(_ item: WeightedOrderSetPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedOrderSetPolicy]) -> [String: [String]] {
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

    static func defaultWeightedOrderSetPolicyValidator() -> WeightedOrderSetPolicyValidator {
        return WeightedOrderSetPolicyValidator(
            rules: [
                WeightedOrderSetPolicyCodeLengthRule(maxLength: 64),
                WeightedOrderSetPolicyAllowedPayerRule(allowed: ["global", "seasonal"]),
                WeightedOrderSetPolicyRequiredProcedureCodeRule(message: "weighted order set policy needs an entry"),
                WeightedOrderSetPolicyPayerLengthRule(maxLength: 255),
            ]
        )
    }
}
