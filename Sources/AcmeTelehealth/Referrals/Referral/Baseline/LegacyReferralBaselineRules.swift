import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy referral baseline must pass. Check returns its problems, or none.
    protocol LegacyReferralBaselineRule {
        func check(_ item: LegacyReferralBaseline) -> [String]
    }

    final class LegacyReferralBaselineRequiredSummaryRule: LegacyReferralBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferralBaseline) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyReferralBaselineCodeLengthRule: LegacyReferralBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyReferralBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyReferralBaselineCodePrefixRule: LegacyReferralBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyReferralBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyReferralBaselineAmountRangeRule: LegacyReferralBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyReferralBaseline) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy referral baseline.
    final class LegacyReferralBaselineValidator {
        var rules: [any LegacyReferralBaselineRule]

        init(rules: [any LegacyReferralBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyReferralBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyReferralBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyReferralBaseline]) -> [String: [String]] {
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

    static func defaultLegacyReferralBaselineValidator() -> LegacyReferralBaselineValidator {
        return LegacyReferralBaselineValidator(
            rules: [
                LegacyReferralBaselineRequiredSummaryRule(message: "legacy referral baseline needs this field"),
                LegacyReferralBaselineCodeLengthRule(maxLength: 64),
                LegacyReferralBaselineCodePrefixRule(prefix: "OPS"),
                LegacyReferralBaselineAmountRangeRule(min: 3.7, max: 2715.5),
            ]
        )
    }
}
