import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility profile must pass. Check returns its problems, or none.
    protocol EligibilityProfileRule {
        func check(_ item: EligibilityProfile) -> [String]
    }

    final class EligibilityProfileRequiredCountryRule: EligibilityProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityProfile) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityProfileAllowedPatientRefRule: EligibilityProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is expired"]
            }
            return []
        }
    }

    final class EligibilityProfileEndsAtRangeRule: EligibilityProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityProfile) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilityProfileAmountRangeRule: EligibilityProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityProfile) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a eligibility profile.
    final class EligibilityProfileValidator {
        var rules: [any EligibilityProfileRule]

        init(rules: [any EligibilityProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityProfile) -> [String] {
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

        func requireValid(_ item: EligibilityProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityProfile]) -> [String: [String]] {
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

    static func defaultEligibilityProfileValidator() -> EligibilityProfileValidator {
        return EligibilityProfileValidator(
            rules: [
                EligibilityProfileRequiredCountryRule(message: "eligibility profile needs an entry"),
                EligibilityProfileAllowedPatientRefRule(allowed: ["fallback", "lenient"]),
                EligibilityProfileEndsAtRangeRule(min: 64, max: 64),
                EligibilityProfileAmountRangeRule(min: 1.4, max: 300.3),
            ]
        )
    }
}
