import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral allocation must pass. Check returns its problems, or none.
    protocol ReferralAllocationRule {
        func check(_ item: ReferralAllocation) -> [String]
    }

    final class ReferralAllocationSourceLengthRule: ReferralAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralAllocation) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralAllocationTitleLengthRule: ReferralAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralAllocationRequiredSourceRule: ReferralAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralAllocation) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralAllocationRatioRangeRule: ReferralAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralAllocation) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral allocation.
    final class ReferralAllocationValidator {
        var rules: [any ReferralAllocationRule]

        init(rules: [any ReferralAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralAllocation]) -> [String: [String]] {
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

    static func defaultReferralAllocationValidator() -> ReferralAllocationValidator {
        return ReferralAllocationValidator(
            rules: [
                ReferralAllocationSourceLengthRule(maxLength: 16),
                ReferralAllocationTitleLengthRule(maxLength: 16),
                ReferralAllocationRequiredSourceRule(message: "referral allocation needs this field"),
                ReferralAllocationRatioRangeRule(min: 1.2, max: 2392.2),
            ]
        )
    }
}
