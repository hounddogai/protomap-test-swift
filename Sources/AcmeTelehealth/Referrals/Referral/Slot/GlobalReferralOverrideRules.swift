import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global referral override must pass. Check returns its problems, or none.
    protocol GlobalReferralOverrideRule {
        func check(_ item: GlobalReferralOverride) -> [String]
    }

    final class GlobalReferralOverrideWeightRangeRule: GlobalReferralOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReferralOverride) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalReferralOverrideTitleLengthRule: GlobalReferralOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReferralOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalReferralOverrideNotesLengthRule: GlobalReferralOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReferralOverride) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalReferralOverrideCodePrefixRule: GlobalReferralOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalReferralOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a global referral override.
    final class GlobalReferralOverrideValidator {
        var rules: [any GlobalReferralOverrideRule]

        init(rules: [any GlobalReferralOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReferralOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalReferralOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReferralOverride]) -> [String: [String]] {
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

    static func defaultGlobalReferralOverrideValidator() -> GlobalReferralOverrideValidator {
        return GlobalReferralOverrideValidator(
            rules: [
                GlobalReferralOverrideWeightRangeRule(min: 8.1, max: 1832.6),
                GlobalReferralOverrideTitleLengthRule(maxLength: 80),
                GlobalReferralOverrideNotesLengthRule(maxLength: 80),
                GlobalReferralOverrideCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
