import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending acuity plan milestone must pass. Check returns its problems, or none.
    protocol PendingAcuityPlanMilestoneRule {
        func check(_ item: PendingAcuityPlanMilestone) -> [String]
    }

    final class PendingAcuityPlanMilestoneQuantityRangeRule: PendingAcuityPlanMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingAcuityPlanMilestone) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingAcuityPlanMilestoneTitleLengthRule: PendingAcuityPlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAcuityPlanMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAcuityPlanMilestoneRequiredLabelRule: PendingAcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAcuityPlanMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingAcuityPlanMilestoneRequiredCodeRule: PendingAcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAcuityPlanMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending acuity plan milestone.
    final class PendingAcuityPlanMilestoneValidator {
        var rules: [any PendingAcuityPlanMilestoneRule]

        init(rules: [any PendingAcuityPlanMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingAcuityPlanMilestone) -> [String] {
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

        func requireValid(_ item: PendingAcuityPlanMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingAcuityPlanMilestone]) -> [String: [String]] {
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

    static func defaultPendingAcuityPlanMilestoneValidator() -> PendingAcuityPlanMilestoneValidator {
        return PendingAcuityPlanMilestoneValidator(
            rules: [
                PendingAcuityPlanMilestoneQuantityRangeRule(min: 80, max: 86400),
                PendingAcuityPlanMilestoneTitleLengthRule(maxLength: 80),
                PendingAcuityPlanMilestoneRequiredLabelRule(message: "pending acuity plan milestone needs a value"),
                PendingAcuityPlanMilestoneRequiredCodeRule(message: "pending acuity plan milestone needs this field"),
            ]
        )
    }
}
