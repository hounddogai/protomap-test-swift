import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted charge policy must pass. Check returns its problems, or none.
    protocol WeightedChargePolicyRule {
        func check(_ item: WeightedChargePolicy) -> [String]
    }

    final class WeightedChargePolicyRequiredContactEmailRule: WeightedChargePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedChargePolicy) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedChargePolicyCodePrefixRule: WeightedChargePolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedChargePolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedChargePolicyAllowedContactEmailRule: WeightedChargePolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedChargePolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is missing"]
            }
            return []
        }
    }

    final class WeightedChargePolicyRequiredLabelRule: WeightedChargePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedChargePolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted charge policy.
    final class WeightedChargePolicyValidator {
        var rules: [any WeightedChargePolicyRule]

        init(rules: [any WeightedChargePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedChargePolicy) -> [String] {
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

        func requireValid(_ item: WeightedChargePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedChargePolicy]) -> [String: [String]] {
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

    static func defaultWeightedChargePolicyValidator() -> WeightedChargePolicyValidator {
        return WeightedChargePolicyValidator(
            rules: [
                WeightedChargePolicyRequiredContactEmailRule(message: "weighted charge policy needs an entry"),
                WeightedChargePolicyCodePrefixRule(prefix: "REF"),
                WeightedChargePolicyAllowedContactEmailRule(allowed: ["weighted", "lenient", "adaptive"]),
                WeightedChargePolicyRequiredLabelRule(message: "weighted charge policy needs this field"),
            ]
        )
    }
}
