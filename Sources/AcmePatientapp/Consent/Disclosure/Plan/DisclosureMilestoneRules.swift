import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure milestone must pass. Check returns its problems, or none.
    protocol DisclosureMilestoneRule {
        func check(_ item: DisclosureMilestone) -> [String]
    }

    final class DisclosureMilestoneVisitMinutesRangeRule: DisclosureMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureMilestone) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DisclosureMilestoneAllowedLocaleRule: DisclosureMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is blocked"]
            }
            return []
        }
    }

    final class DisclosureMilestoneLabelLengthRule: DisclosureMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureMilestone) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureMilestoneRequiredLocaleRule: DisclosureMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureMilestone) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure milestone.
    final class DisclosureMilestoneValidator {
        var rules: [any DisclosureMilestoneRule]

        init(rules: [any DisclosureMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureMilestone) -> [String] {
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

        func requireValid(_ item: DisclosureMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureMilestone]) -> [String: [String]] {
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

    static func defaultDisclosureMilestoneValidator() -> DisclosureMilestoneValidator {
        return DisclosureMilestoneValidator(
            rules: [
                DisclosureMilestoneVisitMinutesRangeRule(min: 80, max: 1000),
                DisclosureMilestoneAllowedLocaleRule(allowed: ["manual", "pending", "capped"]),
                DisclosureMilestoneLabelLengthRule(maxLength: 86400),
                DisclosureMilestoneRequiredLocaleRule(message: "disclosure milestone needs this field"),
            ]
        )
    }
}
