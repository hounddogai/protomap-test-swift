import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral summary must pass. Check returns its problems, or none.
    protocol ReferralSummaryRule {
        func check(_ item: ReferralSummary) -> [String]
    }

    final class ReferralSummaryRequiredCodeRule: ReferralSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralSummaryPhoneLengthRule: ReferralSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralSummary) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralSummaryRequiredTitleRule: ReferralSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralSummaryReviewerLengthRule: ReferralSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralSummary) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralSummaryDosageMgRangeRule: ReferralSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralSummary) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a referral summary.
    final class ReferralSummaryValidator {
        var rules: [any ReferralSummaryRule]

        init(rules: [any ReferralSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralSummary]) -> [String: [String]] {
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

    static func defaultReferralSummaryValidator() -> ReferralSummaryValidator {
        return ReferralSummaryValidator(
            rules: [
                ReferralSummaryRequiredCodeRule(message: "referral summary needs an entry"),
                ReferralSummaryPhoneLengthRule(maxLength: 120),
                ReferralSummaryRequiredTitleRule(message: "referral summary needs a value"),
                ReferralSummaryReviewerLengthRule(maxLength: 120),
                ReferralSummaryDosageMgRangeRule(min: 1.5, max: 594.1),
            ]
        )
    }
}
