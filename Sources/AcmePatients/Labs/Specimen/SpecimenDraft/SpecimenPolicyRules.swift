import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen policy must pass. Check returns its problems, or none.
    protocol SpecimenPolicyRule {
        func check(_ item: SpecimenPolicy) -> [String]
    }

    final class SpecimenPolicyRequiredDescriptionRule: SpecimenPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenPolicy) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenPolicyAllowedPayerRule: SpecimenPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is stale"]
            }
            return []
        }
    }

    final class SpecimenPolicyPayerLengthRule: SpecimenPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenPolicy) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenPolicyRequiredPayerRule: SpecimenPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenPolicy) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenPolicyRateRangeRule: SpecimenPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenPolicy) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a specimen policy.
    final class SpecimenPolicyValidator {
        var rules: [any SpecimenPolicyRule]

        init(rules: [any SpecimenPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenPolicy) -> [String] {
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

        func requireValid(_ item: SpecimenPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenPolicy]) -> [String: [String]] {
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

    static func defaultSpecimenPolicyValidator() -> SpecimenPolicyValidator {
        return SpecimenPolicyValidator(
            rules: [
                SpecimenPolicyRequiredDescriptionRule(message: "specimen policy needs a value"),
                SpecimenPolicyAllowedPayerRule(allowed: ["seasonal", "rolling"]),
                SpecimenPolicyPayerLengthRule(maxLength: 32),
                SpecimenPolicyRequiredPayerRule(message: "specimen policy needs this field"),
                SpecimenPolicyRateRangeRule(min: 1.4, max: 4963.7),
            ]
        )
    }
}
