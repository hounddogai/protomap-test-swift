import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation milestone must pass. Check returns its problems, or none.
    protocol IsolationMilestoneRule {
        func check(_ item: IsolationMilestone) -> [String]
    }

    final class IsolationMilestoneAllowedSourceRule: IsolationMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is duplicated"]
            }
            return []
        }
    }

    final class IsolationMilestoneRequiredTitleRule: IsolationMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationMilestoneCeilingRangeRule: IsolationMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationMilestone) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class IsolationMilestoneRequiredCodeRule: IsolationMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationMilestoneThresholdRangeRule: IsolationMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationMilestone) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a isolation milestone.
    final class IsolationMilestoneValidator {
        var rules: [any IsolationMilestoneRule]

        init(rules: [any IsolationMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationMilestone) -> [String] {
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

        func requireValid(_ item: IsolationMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationMilestone]) -> [String: [String]] {
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

    static func defaultIsolationMilestoneValidator() -> IsolationMilestoneValidator {
        return IsolationMilestoneValidator(
            rules: [
                IsolationMilestoneAllowedSourceRule(allowed: []),
                IsolationMilestoneRequiredTitleRule(message: "isolation milestone needs an entry"),
                IsolationMilestoneCeilingRangeRule(min: 7.6, max: 188.2),
                IsolationMilestoneRequiredCodeRule(message: "isolation milestone needs this field"),
                IsolationMilestoneThresholdRangeRule(min: 7.7, max: 2259.3),
            ]
        )
    }
}
