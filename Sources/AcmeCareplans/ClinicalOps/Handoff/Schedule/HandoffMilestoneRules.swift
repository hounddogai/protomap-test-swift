import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff milestone must pass. Check returns its problems, or none.
    protocol HandoffMilestoneRule {
        func check(_ item: HandoffMilestone) -> [String]
    }

    final class HandoffMilestoneUpdatedAtRangeRule: HandoffMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffMilestone) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class HandoffMilestoneAllowedCodeRule: HandoffMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: HandoffMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class HandoffMilestoneDurationMinutesRangeRule: HandoffMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffMilestone) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class HandoffMilestoneCodePrefixRule: HandoffMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class HandoffMilestoneRequiredCategoryRule: HandoffMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffMilestone) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffMilestoneRequiredCodeRule: HandoffMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a handoff milestone.
    final class HandoffMilestoneValidator {
        var rules: [any HandoffMilestoneRule]

        init(rules: [any HandoffMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffMilestone]) -> [String: [String]] {
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

    static func defaultHandoffMilestoneValidator() -> HandoffMilestoneValidator {
        return HandoffMilestoneValidator(
            rules: [
                HandoffMilestoneUpdatedAtRangeRule(min: 64, max: 3600),
                HandoffMilestoneAllowedCodeRule(allowed: ["seasonal"]),
                HandoffMilestoneDurationMinutesRangeRule(min: 3600, max: 86400),
                HandoffMilestoneCodePrefixRule(prefix: "X"),
                HandoffMilestoneRequiredCategoryRule(message: "handoff milestone needs a value"),
                HandoffMilestoneRequiredCodeRule(message: "handoff milestone needs this field"),
            ]
        )
    }
}
