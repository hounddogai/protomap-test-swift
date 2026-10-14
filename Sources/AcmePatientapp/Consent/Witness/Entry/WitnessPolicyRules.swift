import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness policy must pass. Check returns its problems, or none.
    protocol WitnessPolicyRule {
        func check(_ item: WitnessPolicy) -> [String]
    }

    final class WitnessPolicyLabelLengthRule: WitnessPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessPolicyDiscountRangeRule: WitnessPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessPolicy) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessPolicyRequiredLabelRule: WitnessPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessPolicyCeilingRangeRule: WitnessPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessPolicy) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a witness policy.
    final class WitnessPolicyValidator {
        var rules: [any WitnessPolicyRule]

        init(rules: [any WitnessPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessPolicy) -> [String] {
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

        func requireValid(_ item: WitnessPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessPolicy]) -> [String: [String]] {
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

    static func defaultWitnessPolicyValidator() -> WitnessPolicyValidator {
        return WitnessPolicyValidator(
            rules: [
                WitnessPolicyLabelLengthRule(maxLength: 3600),
                WitnessPolicyDiscountRangeRule(min: 9.1, max: 1199.7),
                WitnessPolicyRequiredLabelRule(message: "witness policy needs an entry"),
                WitnessPolicyCeilingRangeRule(min: 3.4, max: 1104.2),
            ]
        )
    }
}
