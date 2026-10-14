import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal eligibility quota must pass. Check returns its problems, or none.
    protocol SeasonalEligibilityQuotaRule {
        func check(_ item: SeasonalEligibilityQuota) -> [String]
    }

    final class SeasonalEligibilityQuotaScoreRangeRule: SeasonalEligibilityQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalEligibilityQuota) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalEligibilityQuotaRequiredAllergyRule: SeasonalEligibilityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalEligibilityQuota) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalEligibilityQuotaPhoneLengthRule: SeasonalEligibilityQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalEligibilityQuota) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal eligibility quota.
    final class SeasonalEligibilityQuotaValidator {
        var rules: [any SeasonalEligibilityQuotaRule]

        init(rules: [any SeasonalEligibilityQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalEligibilityQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalEligibilityQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalEligibilityQuota]) -> [String: [String]] {
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

    static func defaultSeasonalEligibilityQuotaValidator() -> SeasonalEligibilityQuotaValidator {
        return SeasonalEligibilityQuotaValidator(
            rules: [
                SeasonalEligibilityQuotaScoreRangeRule(min: 1.2, max: 4044.9),
                SeasonalEligibilityQuotaRequiredAllergyRule(message: "seasonal eligibility quota needs a value"),
                SeasonalEligibilityQuotaPhoneLengthRule(maxLength: 80),
            ]
        )
    }
}
