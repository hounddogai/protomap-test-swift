import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal referral profile must pass. Check returns its problems, or none.
    protocol SeasonalReferralProfileRule {
        func check(_ item: SeasonalReferralProfile) -> [String]
    }

    final class SeasonalReferralProfileRequiredLabelRule: SeasonalReferralProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReferralProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalReferralProfileCodePrefixRule: SeasonalReferralProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalReferralProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalReferralProfileCeilingRangeRule: SeasonalReferralProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalReferralProfile) -> [String] {
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

    final class SeasonalReferralProfileGraceDaysRangeRule: SeasonalReferralProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalReferralProfile) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalReferralProfileAllergyLengthRule: SeasonalReferralProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalReferralProfile) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal referral profile.
    final class SeasonalReferralProfileValidator {
        var rules: [any SeasonalReferralProfileRule]

        init(rules: [any SeasonalReferralProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalReferralProfile) -> [String] {
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

        func requireValid(_ item: SeasonalReferralProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalReferralProfile]) -> [String: [String]] {
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

    static func defaultSeasonalReferralProfileValidator() -> SeasonalReferralProfileValidator {
        return SeasonalReferralProfileValidator(
            rules: [
                SeasonalReferralProfileRequiredLabelRule(message: "seasonal referral profile needs an entry"),
                SeasonalReferralProfileCodePrefixRule(prefix: "OPS"),
                SeasonalReferralProfileCeilingRangeRule(min: 7.7, max: 4591.9),
                SeasonalReferralProfileGraceDaysRangeRule(min: 80, max: 3600),
                SeasonalReferralProfileAllergyLengthRule(maxLength: 1000),
            ]
        )
    }
}
