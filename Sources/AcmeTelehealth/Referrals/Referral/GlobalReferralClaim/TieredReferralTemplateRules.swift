import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered referral template must pass. Check returns its problems, or none.
    protocol TieredReferralTemplateRule {
        func check(_ item: TieredReferralTemplate) -> [String]
    }

    final class TieredReferralTemplateRequiredPayerRule: TieredReferralTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferralTemplate) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferralTemplateReviewerLengthRule: TieredReferralTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferralTemplate) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferralTemplateCodeLengthRule: TieredReferralTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferralTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferralTemplateAllowedReviewerRule: TieredReferralTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredReferralTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is out of range"]
            }
            return []
        }
    }

    final class TieredReferralTemplateDiscountRangeRule: TieredReferralTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReferralTemplate) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered referral template.
    final class TieredReferralTemplateValidator {
        var rules: [any TieredReferralTemplateRule]

        init(rules: [any TieredReferralTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReferralTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredReferralTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReferralTemplate]) -> [String: [String]] {
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

    static func defaultTieredReferralTemplateValidator() -> TieredReferralTemplateValidator {
        return TieredReferralTemplateValidator(
            rules: [
                TieredReferralTemplateRequiredPayerRule(message: "tiered referral template needs this field"),
                TieredReferralTemplateReviewerLengthRule(maxLength: 86400),
                TieredReferralTemplateCodeLengthRule(maxLength: 1000),
                TieredReferralTemplateAllowedReviewerRule(allowed: []),
                TieredReferralTemplateDiscountRangeRule(min: 1.7, max: 3346.7),
            ]
        )
    }
}
