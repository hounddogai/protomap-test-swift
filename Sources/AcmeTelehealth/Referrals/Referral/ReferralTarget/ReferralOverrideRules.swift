import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral override must pass. Check returns its problems, or none.
    protocol ReferralOverrideRule {
        func check(_ item: ReferralOverride) -> [String]
    }

    final class ReferralOverrideCodePrefixRule: ReferralOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferralOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferralOverrideRequiredTimezoneRule: ReferralOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralOverride) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralOverrideEncounterIDLengthRule: ReferralOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralOverride) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralOverrideWindowDaysRangeRule: ReferralOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralOverride) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralOverrideLabelLengthRule: ReferralOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral override.
    final class ReferralOverrideValidator {
        var rules: [any ReferralOverrideRule]

        init(rules: [any ReferralOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralOverride]) -> [String: [String]] {
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

    static func defaultReferralOverrideValidator() -> ReferralOverrideValidator {
        return ReferralOverrideValidator(
            rules: [
                ReferralOverrideCodePrefixRule(prefix: "Q"),
                ReferralOverrideRequiredTimezoneRule(message: "referral override needs this field"),
                ReferralOverrideEncounterIDLengthRule(maxLength: 64),
                ReferralOverrideWindowDaysRangeRule(min: 120, max: 3600),
                ReferralOverrideLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
