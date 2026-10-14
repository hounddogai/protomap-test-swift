import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral profile must pass. Check returns its problems, or none.
    protocol ReferralProfileRule {
        func check(_ item: ReferralProfile) -> [String]
    }

    final class ReferralProfileRequiredLabelRule: ReferralProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralProfileLabelLengthRule: ReferralProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralProfileAllowedClinicianIDRule: ReferralProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is duplicated"]
            }
            return []
        }
    }

    final class ReferralProfileTitleLengthRule: ReferralProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralProfileMaximumRangeRule: ReferralProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralProfile) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a referral profile.
    final class ReferralProfileValidator {
        var rules: [any ReferralProfileRule]

        init(rules: [any ReferralProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralProfile]) -> [String: [String]] {
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

    static func defaultReferralProfileValidator() -> ReferralProfileValidator {
        return ReferralProfileValidator(
            rules: [
                ReferralProfileRequiredLabelRule(message: "referral profile needs an entry"),
                ReferralProfileLabelLengthRule(maxLength: 64),
                ReferralProfileAllowedClinicianIDRule(allowed: ["scheduled", "primary", "fallback"]),
                ReferralProfileTitleLengthRule(maxLength: 64),
                ReferralProfileMaximumRangeRule(min: 1.2, max: 2798.4),
            ]
        )
    }
}
