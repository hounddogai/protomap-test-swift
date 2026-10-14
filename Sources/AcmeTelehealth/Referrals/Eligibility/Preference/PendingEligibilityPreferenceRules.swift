import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending eligibility preference must pass. Check returns its problems, or none.
    protocol PendingEligibilityPreferenceRule {
        func check(_ item: PendingEligibilityPreference) -> [String]
    }

    final class PendingEligibilityPreferenceRequiredCodeRule: PendingEligibilityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingEligibilityPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingEligibilityPreferenceTitleLengthRule: PendingEligibilityPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingEligibilityPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingEligibilityPreferenceRequiredTitleRule: PendingEligibilityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingEligibilityPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingEligibilityPreferenceRequiredPhoneRule: PendingEligibilityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingEligibilityPreference) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending eligibility preference.
    final class PendingEligibilityPreferenceValidator {
        var rules: [any PendingEligibilityPreferenceRule]

        init(rules: [any PendingEligibilityPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingEligibilityPreference) -> [String] {
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

        func requireValid(_ item: PendingEligibilityPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingEligibilityPreference]) -> [String: [String]] {
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

    static func defaultPendingEligibilityPreferenceValidator() -> PendingEligibilityPreferenceValidator {
        return PendingEligibilityPreferenceValidator(
            rules: [
                PendingEligibilityPreferenceRequiredCodeRule(
                    message: "pending eligibility preference needs this field"
                ),
                PendingEligibilityPreferenceTitleLengthRule(maxLength: 32),
                PendingEligibilityPreferenceRequiredTitleRule(message: "pending eligibility preference needs a value"),
                PendingEligibilityPreferenceRequiredPhoneRule(message: "pending eligibility preference needs a value"),
            ]
        )
    }
}
