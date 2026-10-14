import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral baseline must pass. Check returns its problems, or none.
    protocol ReferralBaselineRule {
        func check(_ item: ReferralBaseline) -> [String]
    }

    final class ReferralBaselineRateRangeRule: ReferralBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralBaseline) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralBaselineCodeLengthRule: ReferralBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralBaselinePinnedGuardRule: ReferralBaselineRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ReferralBaseline) -> [String] {
            if item.pinned && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class ReferralBaselineRequiredContactEmailRule: ReferralBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralBaseline) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a referral baseline.
    final class ReferralBaselineValidator {
        var rules: [any ReferralBaselineRule]

        init(rules: [any ReferralBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralBaseline]) -> [String: [String]] {
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

    static func defaultReferralBaselineValidator() -> ReferralBaselineValidator {
        return ReferralBaselineValidator(
            rules: [
                ReferralBaselineRateRangeRule(min: 5.2, max: 3015.3),
                ReferralBaselineCodeLengthRule(maxLength: 3600),
                ReferralBaselinePinnedGuardRule(limit: 255),
                ReferralBaselineRequiredContactEmailRule(message: "referral baseline needs an entry"),
            ]
        )
    }
}
