import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling care gap milestone must pass. Check returns its problems, or none.
    protocol RollingCareGapMilestoneRule {
        func check(_ item: RollingCareGapMilestone) -> [String]
    }

    final class RollingCareGapMilestoneRequiredWardRule: RollingCareGapMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareGapMilestone) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCareGapMilestoneWeightRangeRule: RollingCareGapMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareGapMilestone) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCareGapMilestonePriorityRangeRule: RollingCareGapMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareGapMilestone) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCareGapMilestoneRequiredCodeRule: RollingCareGapMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareGapMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCareGapMilestoneAllowedTitleRule: RollingCareGapMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingCareGapMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling care gap milestone.
    final class RollingCareGapMilestoneValidator {
        var rules: [any RollingCareGapMilestoneRule]

        init(rules: [any RollingCareGapMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareGapMilestone) -> [String] {
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

        func requireValid(_ item: RollingCareGapMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareGapMilestone]) -> [String: [String]] {
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

    static func defaultRollingCareGapMilestoneValidator() -> RollingCareGapMilestoneValidator {
        return RollingCareGapMilestoneValidator(
            rules: [
                RollingCareGapMilestoneRequiredWardRule(message: "rolling care gap milestone needs this field"),
                RollingCareGapMilestoneWeightRangeRule(min: 3.4, max: 300.2),
                RollingCareGapMilestonePriorityRangeRule(min: 32, max: 86400),
                RollingCareGapMilestoneRequiredCodeRule(message: "rolling care gap milestone needs this field"),
                RollingCareGapMilestoneAllowedTitleRule(allowed: ["tiered"]),
            ]
        )
    }
}
