import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict referral preference must pass. Check returns its problems, or none.
    protocol StrictReferralPreferenceRule {
        func check(_ item: StrictReferralPreference) -> [String]
    }

    final class StrictReferralPreferenceTitleLengthRule: StrictReferralPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReferralPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReferralPreferenceSequenceRangeRule: StrictReferralPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictReferralPreference) -> [String] {
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

    final class StrictReferralPreferenceRequiredSpecialtyRule: StrictReferralPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReferralPreference) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict referral preference.
    final class StrictReferralPreferenceValidator {
        var rules: [any StrictReferralPreferenceRule]

        init(rules: [any StrictReferralPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictReferralPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictReferralPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictReferralPreference]) -> [String: [String]] {
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

    static func defaultStrictReferralPreferenceValidator() -> StrictReferralPreferenceValidator {
        return StrictReferralPreferenceValidator(
            rules: [
                StrictReferralPreferenceTitleLengthRule(maxLength: 86400),
                StrictReferralPreferenceSequenceRangeRule(min: 32, max: 80),
                StrictReferralPreferenceRequiredSpecialtyRule(message: "strict referral preference needs this field"),
            ]
        )
    }
}
