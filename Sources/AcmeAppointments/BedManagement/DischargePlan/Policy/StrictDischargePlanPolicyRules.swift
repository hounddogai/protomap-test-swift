import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict discharge plan policy must pass. Check returns its problems, or none.
    protocol StrictDischargePlanPolicyRule {
        func check(_ item: StrictDischargePlanPolicy) -> [String]
    }

    final class StrictDischargePlanPolicyMarginRangeRule: StrictDischargePlanPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictDischargePlanPolicy) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictDischargePlanPolicySequenceRangeRule: StrictDischargePlanPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictDischargePlanPolicy) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictDischargePlanPolicyCodeLengthRule: StrictDischargePlanPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDischargePlanPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictDischargePlanPolicyMinimumRangeRule: StrictDischargePlanPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictDischargePlanPolicy) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictDischargePlanPolicyAllowedAllergyRule: StrictDischargePlanPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictDischargePlanPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is expired"]
            }
            return []
        }
    }

    final class StrictDischargePlanPolicyAllergyLengthRule: StrictDischargePlanPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDischargePlanPolicy) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict discharge plan policy.
    final class StrictDischargePlanPolicyValidator {
        var rules: [any StrictDischargePlanPolicyRule]

        init(rules: [any StrictDischargePlanPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictDischargePlanPolicy) -> [String] {
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

        func requireValid(_ item: StrictDischargePlanPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictDischargePlanPolicy]) -> [String: [String]] {
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

    static func defaultStrictDischargePlanPolicyValidator() -> StrictDischargePlanPolicyValidator {
        return StrictDischargePlanPolicyValidator(
            rules: [
                StrictDischargePlanPolicyMarginRangeRule(min: 1.2, max: 868.5),
                StrictDischargePlanPolicySequenceRangeRule(min: 80, max: 3600),
                StrictDischargePlanPolicyCodeLengthRule(maxLength: 3600),
                StrictDischargePlanPolicyMinimumRangeRule(min: 2.7, max: 97.0),
                StrictDischargePlanPolicyAllowedAllergyRule(allowed: ["capped", "seasonal"]),
                StrictDischargePlanPolicyAllergyLengthRule(maxLength: 64),
            ]
        )
    }
}
