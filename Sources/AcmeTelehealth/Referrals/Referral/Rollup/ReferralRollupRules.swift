import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral rollup must pass. Check returns its problems, or none.
    protocol ReferralRollupRule {
        func check(_ item: ReferralRollup) -> [String]
    }

    final class ReferralRollupLocaleLengthRule: ReferralRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralRollup) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralRollupAllowedLocaleRule: ReferralRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is expired"]
            }
            return []
        }
    }

    final class ReferralRollupUpdatedAtRangeRule: ReferralRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralRollup) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferralRollupCopayRangeRule: ReferralRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralRollup) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferralRollupRequiredLabelRule: ReferralRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a referral rollup.
    final class ReferralRollupValidator {
        var rules: [any ReferralRollupRule]

        init(rules: [any ReferralRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralRollup]) -> [String: [String]] {
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

    static func defaultReferralRollupValidator() -> ReferralRollupValidator {
        return ReferralRollupValidator(
            rules: [
                ReferralRollupLocaleLengthRule(maxLength: 64),
                ReferralRollupAllowedLocaleRule(allowed: ["global", "regional", "scheduled"]),
                ReferralRollupUpdatedAtRangeRule(min: 16, max: 86400),
                ReferralRollupCopayRangeRule(min: 2.6, max: 4664.1),
                ReferralRollupRequiredLabelRule(message: "referral rollup needs a value"),
            ]
        )
    }
}
