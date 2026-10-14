import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority milestone must pass. Check returns its problems, or none.
    protocol PriorityMilestoneRule {
        func check(_ item: PriorityMilestone) -> [String]
    }

    final class PriorityMilestoneUpdatedAtRangeRule: PriorityMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityMilestone) -> [String] {
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

    final class PriorityMilestoneStartsAtRangeRule: PriorityMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityMilestone) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PriorityMilestoneRequiredLocaleRule: PriorityMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityMilestone) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityMilestoneRequiredCodeRule: PriorityMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority milestone.
    final class PriorityMilestoneValidator {
        var rules: [any PriorityMilestoneRule]

        init(rules: [any PriorityMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityMilestone) -> [String] {
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

        func requireValid(_ item: PriorityMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityMilestone]) -> [String: [String]] {
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

    static func defaultPriorityMilestoneValidator() -> PriorityMilestoneValidator {
        return PriorityMilestoneValidator(
            rules: [
                PriorityMilestoneUpdatedAtRangeRule(min: 32, max: 80),
                PriorityMilestoneStartsAtRangeRule(min: 80, max: 3600),
                PriorityMilestoneRequiredLocaleRule(message: "priority milestone needs this field"),
                PriorityMilestoneRequiredCodeRule(message: "priority milestone needs an entry"),
            ]
        )
    }
}
