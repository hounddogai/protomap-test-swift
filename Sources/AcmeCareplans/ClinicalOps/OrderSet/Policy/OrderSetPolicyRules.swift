import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set policy must pass. Check returns its problems, or none.
    protocol OrderSetPolicyRule {
        func check(_ item: OrderSetPolicy) -> [String]
    }

    final class OrderSetPolicyAmountRangeRule: OrderSetPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetPolicy) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetPolicyArchivedGuardRule: OrderSetPolicyRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: OrderSetPolicy) -> [String] {
            if item.archived && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class OrderSetPolicyRequiredCodeRule: OrderSetPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetPolicyRequiredLabelRule: OrderSetPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set policy.
    final class OrderSetPolicyValidator {
        var rules: [any OrderSetPolicyRule]

        init(rules: [any OrderSetPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetPolicy]) -> [String: [String]] {
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

    static func defaultOrderSetPolicyValidator() -> OrderSetPolicyValidator {
        return OrderSetPolicyValidator(
            rules: [
                OrderSetPolicyAmountRangeRule(min: 7.4, max: 4347.6),
                OrderSetPolicyArchivedGuardRule(limit: 7.8),
                OrderSetPolicyRequiredCodeRule(message: "order set policy needs a value"),
                OrderSetPolicyRequiredLabelRule(message: "order set policy needs a value"),
            ]
        )
    }
}
