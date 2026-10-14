import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient referral target must pass. Check returns its problems, or none.
    protocol LenientReferralTargetRule {
        func check(_ item: LenientReferralTarget) -> [String]
    }

    final class LenientReferralTargetLabelLengthRule: LenientReferralTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReferralTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientReferralTargetRequiredLabelRule: LenientReferralTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferralTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReferralTargetQuantityRangeRule: LenientReferralTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReferralTarget) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientReferralTargetDescriptionLengthRule: LenientReferralTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReferralTarget) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient referral target.
    final class LenientReferralTargetValidator {
        var rules: [any LenientReferralTargetRule]

        init(rules: [any LenientReferralTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReferralTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientReferralTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReferralTarget]) -> [String: [String]] {
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

    static func defaultLenientReferralTargetValidator() -> LenientReferralTargetValidator {
        return LenientReferralTargetValidator(
            rules: [
                LenientReferralTargetLabelLengthRule(maxLength: 32),
                LenientReferralTargetRequiredLabelRule(message: "lenient referral target needs this field"),
                LenientReferralTargetQuantityRangeRule(min: 120, max: 120),
                LenientReferralTargetDescriptionLengthRule(maxLength: 16),
            ]
        )
    }
}
