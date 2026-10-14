import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral cycle must pass. Check returns its problems, or none.
    protocol ReferralCycleRule {
        func check(_ item: ReferralCycle) -> [String]
    }

    final class ReferralCycleAllowedReviewerRule: ReferralCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is duplicated"]
            }
            return []
        }
    }

    final class ReferralCycleCapacityRangeRule: ReferralCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralCycle) -> [String] {
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

    final class ReferralCycleRequiredReviewerRule: ReferralCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralCycle) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralCycleCreatedAtRangeRule: ReferralCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralCycle) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferralCycleCodeLengthRule: ReferralCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralCycleRequiredLabelRule: ReferralCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a referral cycle.
    final class ReferralCycleValidator {
        var rules: [any ReferralCycleRule]

        init(rules: [any ReferralCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralCycle) -> [String] {
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

        func requireValid(_ item: ReferralCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralCycle]) -> [String: [String]] {
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

    static func defaultReferralCycleValidator() -> ReferralCycleValidator {
        return ReferralCycleValidator(
            rules: [
                ReferralCycleAllowedReviewerRule(allowed: ["regional"]),
                ReferralCycleCapacityRangeRule(min: 80, max: 80),
                ReferralCycleRequiredReviewerRule(message: "referral cycle needs this field"),
                ReferralCycleCreatedAtRangeRule(min: 16, max: 64),
                ReferralCycleCodeLengthRule(maxLength: 3600),
                ReferralCycleRequiredLabelRule(message: "referral cycle needs an entry"),
            ]
        )
    }
}
