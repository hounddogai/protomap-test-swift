import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy acuity plan milestone must pass. Check returns its problems, or none.
    protocol LegacyAcuityPlanMilestoneRule {
        func check(_ item: LegacyAcuityPlanMilestone) -> [String]
    }

    final class LegacyAcuityPlanMilestoneWardLengthRule: LegacyAcuityPlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAcuityPlanMilestone) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAcuityPlanMilestonePriorityRangeRule: LegacyAcuityPlanMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAcuityPlanMilestone) -> [String] {
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

    final class LegacyAcuityPlanMilestoneAllowedWardRule: LegacyAcuityPlanMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyAcuityPlanMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy acuity plan milestone.
    final class LegacyAcuityPlanMilestoneValidator {
        var rules: [any LegacyAcuityPlanMilestoneRule]

        init(rules: [any LegacyAcuityPlanMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAcuityPlanMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyAcuityPlanMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAcuityPlanMilestone]) -> [String: [String]] {
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

    static func defaultLegacyAcuityPlanMilestoneValidator() -> LegacyAcuityPlanMilestoneValidator {
        return LegacyAcuityPlanMilestoneValidator(
            rules: [
                LegacyAcuityPlanMilestoneWardLengthRule(maxLength: 120),
                LegacyAcuityPlanMilestonePriorityRangeRule(min: 16, max: 120),
                LegacyAcuityPlanMilestoneAllowedWardRule(allowed: ["primary", "capped", "seasonal"]),
            ]
        )
    }
}
