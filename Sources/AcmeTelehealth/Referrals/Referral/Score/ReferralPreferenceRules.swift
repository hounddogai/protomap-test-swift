import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral preference must pass. Check returns its problems, or none.
    protocol ReferralPreferenceRule {
        func check(_ item: ReferralPreference) -> [String]
    }

    final class ReferralPreferenceCodeLengthRule: ReferralPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralPreferenceRequiredFacilityRule: ReferralPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralPreference) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralPreferenceRequiredOwnerIDRule: ReferralPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralPreference) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a referral preference.
    final class ReferralPreferenceValidator {
        var rules: [any ReferralPreferenceRule]

        init(rules: [any ReferralPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralPreference]) -> [String: [String]] {
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

    static func defaultReferralPreferenceValidator() -> ReferralPreferenceValidator {
        return ReferralPreferenceValidator(
            rules: [
                ReferralPreferenceCodeLengthRule(maxLength: 3600),
                ReferralPreferenceRequiredFacilityRule(message: "referral preference needs a value"),
                ReferralPreferenceRequiredOwnerIDRule(message: "referral preference needs this field"),
            ]
        )
    }
}
