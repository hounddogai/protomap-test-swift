import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling referral allocation must pass. Check returns its problems, or none.
    protocol RollingReferralAllocationRule {
        func check(_ item: RollingReferralAllocation) -> [String]
    }

    final class RollingReferralAllocationCountryLengthRule: RollingReferralAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingReferralAllocation) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingReferralAllocationRequiredCountryRule: RollingReferralAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReferralAllocation) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingReferralAllocationCodePrefixRule: RollingReferralAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingReferralAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingReferralAllocationRequiredCodeRule: RollingReferralAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReferralAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingReferralAllocationStartsAtRangeRule: RollingReferralAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingReferralAllocation) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingReferralAllocationRatioRangeRule: RollingReferralAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingReferralAllocation) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling referral allocation.
    final class RollingReferralAllocationValidator {
        var rules: [any RollingReferralAllocationRule]

        init(rules: [any RollingReferralAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingReferralAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: RollingReferralAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingReferralAllocation]) -> [String: [String]] {
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

    static func defaultRollingReferralAllocationValidator() -> RollingReferralAllocationValidator {
        return RollingReferralAllocationValidator(
            rules: [
                RollingReferralAllocationCountryLengthRule(maxLength: 1000),
                RollingReferralAllocationRequiredCountryRule(message: "rolling referral allocation needs an entry"),
                RollingReferralAllocationCodePrefixRule(prefix: "OPS"),
                RollingReferralAllocationRequiredCodeRule(message: "rolling referral allocation needs this field"),
                RollingReferralAllocationStartsAtRangeRule(min: 64, max: 64),
                RollingReferralAllocationRatioRangeRule(min: 7.6, max: 2639.1),
            ]
        )
    }
}
