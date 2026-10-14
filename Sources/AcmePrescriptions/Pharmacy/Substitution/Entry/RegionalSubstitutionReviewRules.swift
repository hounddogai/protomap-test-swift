import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional substitution review must pass. Check returns its problems, or none.
    protocol RegionalSubstitutionReviewRule {
        func check(_ item: RegionalSubstitutionReview) -> [String]
    }

    final class RegionalSubstitutionReviewRequiredCountryRule: RegionalSubstitutionReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSubstitutionReview) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSubstitutionReviewRequiredNameRule: RegionalSubstitutionReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSubstitutionReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSubstitutionReviewRateRangeRule: RegionalSubstitutionReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSubstitutionReview) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalSubstitutionReviewNameLengthRule: RegionalSubstitutionReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSubstitutionReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSubstitutionReviewAllowedPayerRule: RegionalSubstitutionReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalSubstitutionReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is stale"]
            }
            return []
        }
    }

    final class RegionalSubstitutionReviewPatientRefLengthRule: RegionalSubstitutionReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSubstitutionReview) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional substitution review.
    final class RegionalSubstitutionReviewValidator {
        var rules: [any RegionalSubstitutionReviewRule]

        init(rules: [any RegionalSubstitutionReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSubstitutionReview) -> [String] {
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

        func requireValid(_ item: RegionalSubstitutionReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSubstitutionReview]) -> [String: [String]] {
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

    static func defaultRegionalSubstitutionReviewValidator() -> RegionalSubstitutionReviewValidator {
        return RegionalSubstitutionReviewValidator(
            rules: [
                RegionalSubstitutionReviewRequiredCountryRule(
                    message: "regional substitution review needs this field"
                ),
                RegionalSubstitutionReviewRequiredNameRule(message: "regional substitution review needs this field"),
                RegionalSubstitutionReviewRateRangeRule(min: 8.6, max: 4075.4),
                RegionalSubstitutionReviewNameLengthRule(maxLength: 255),
                RegionalSubstitutionReviewAllowedPayerRule(allowed: ["seasonal", "tiered", "rolling"]),
                RegionalSubstitutionReviewPatientRefLengthRule(maxLength: 80),
            ]
        )
    }
}
