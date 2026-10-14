import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy referral target must pass. Check returns its problems, or none.
    protocol LegacyReferralTargetRule {
        func check(_ item: LegacyReferralTarget) -> [String]
    }

    final class LegacyReferralTargetAllowedCodeRule: LegacyReferralTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyReferralTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class LegacyReferralTargetTitleLengthRule: LegacyReferralTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyReferralTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyReferralTargetRequiredNameRule: LegacyReferralTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferralTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyReferralTargetEndsAtRangeRule: LegacyReferralTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyReferralTarget) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyReferralTargetEncounterIDLengthRule: LegacyReferralTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyReferralTarget) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy referral target.
    final class LegacyReferralTargetValidator {
        var rules: [any LegacyReferralTargetRule]

        init(rules: [any LegacyReferralTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyReferralTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyReferralTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyReferralTarget]) -> [String: [String]] {
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

    static func defaultLegacyReferralTargetValidator() -> LegacyReferralTargetValidator {
        return LegacyReferralTargetValidator(
            rules: [
                LegacyReferralTargetAllowedCodeRule(allowed: []),
                LegacyReferralTargetTitleLengthRule(maxLength: 16),
                LegacyReferralTargetRequiredNameRule(message: "legacy referral target needs a value"),
                LegacyReferralTargetEndsAtRangeRule(min: 80, max: 120),
                LegacyReferralTargetEncounterIDLengthRule(maxLength: 64),
            ]
        )
    }
}
