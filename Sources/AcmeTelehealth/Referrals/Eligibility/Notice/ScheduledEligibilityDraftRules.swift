import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled eligibility draft must pass. Check returns its problems, or none.
    protocol ScheduledEligibilityDraftRule {
        func check(_ item: ScheduledEligibilityDraft) -> [String]
    }

    final class ScheduledEligibilityDraftCostRangeRule: ScheduledEligibilityDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledEligibilityDraft) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledEligibilityDraftQuantityRangeRule: ScheduledEligibilityDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledEligibilityDraft) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledEligibilityDraftWardLengthRule: ScheduledEligibilityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledEligibilityDraft) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledEligibilityDraftAllowedWardRule: ScheduledEligibilityDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledEligibilityDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is expired"]
            }
            return []
        }
    }

    final class ScheduledEligibilityDraftCeilingRangeRule: ScheduledEligibilityDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledEligibilityDraft) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledEligibilityDraftCodePrefixRule: ScheduledEligibilityDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledEligibilityDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled eligibility draft.
    final class ScheduledEligibilityDraftValidator {
        var rules: [any ScheduledEligibilityDraftRule]

        init(rules: [any ScheduledEligibilityDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledEligibilityDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledEligibilityDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledEligibilityDraft]) -> [String: [String]] {
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

    static func defaultScheduledEligibilityDraftValidator() -> ScheduledEligibilityDraftValidator {
        return ScheduledEligibilityDraftValidator(
            rules: [
                ScheduledEligibilityDraftCostRangeRule(min: 0.5, max: 2012.7),
                ScheduledEligibilityDraftQuantityRangeRule(min: 120, max: 1000),
                ScheduledEligibilityDraftWardLengthRule(maxLength: 3600),
                ScheduledEligibilityDraftAllowedWardRule(allowed: ["adaptive", "fallback", "weighted"]),
                ScheduledEligibilityDraftCeilingRangeRule(min: 5.2, max: 3136.4),
                ScheduledEligibilityDraftCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
