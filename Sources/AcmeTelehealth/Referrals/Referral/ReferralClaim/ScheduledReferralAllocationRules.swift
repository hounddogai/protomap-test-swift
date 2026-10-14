import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled referral allocation must pass. Check returns its problems, or none.
    protocol ScheduledReferralAllocationRule {
        func check(_ item: ScheduledReferralAllocation) -> [String]
    }

    final class ScheduledReferralAllocationAllowedCodeRule: ScheduledReferralAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledReferralAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class ScheduledReferralAllocationRequiredPhoneRule: ScheduledReferralAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReferralAllocation) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledReferralAllocationDurationMinutesRangeRule: ScheduledReferralAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledReferralAllocation) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledReferralAllocationCodeLengthRule: ScheduledReferralAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledReferralAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledReferralAllocationCapacityRangeRule: ScheduledReferralAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledReferralAllocation) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledReferralAllocationCodePrefixRule: ScheduledReferralAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledReferralAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled referral allocation.
    final class ScheduledReferralAllocationValidator {
        var rules: [any ScheduledReferralAllocationRule]

        init(rules: [any ScheduledReferralAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledReferralAllocation) -> [String] {
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

        func requireValid(_ item: ScheduledReferralAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledReferralAllocation]) -> [String: [String]] {
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

    static func defaultScheduledReferralAllocationValidator() -> ScheduledReferralAllocationValidator {
        return ScheduledReferralAllocationValidator(
            rules: [
                ScheduledReferralAllocationAllowedCodeRule(allowed: ["capped"]),
                ScheduledReferralAllocationRequiredPhoneRule(message: "scheduled referral allocation needs a value"),
                ScheduledReferralAllocationDurationMinutesRangeRule(min: 120, max: 120),
                ScheduledReferralAllocationCodeLengthRule(maxLength: 80),
                ScheduledReferralAllocationCapacityRangeRule(min: 120, max: 255),
                ScheduledReferralAllocationCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
