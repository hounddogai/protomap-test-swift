import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a scheduled formulary milestone must pass. Check returns its problems, or none.
    protocol ScheduledFormularyMilestoneRule {
        func check(_ item: ScheduledFormularyMilestone) -> [String]
    }

    final class ScheduledFormularyMilestoneRequiredProcedureCodeRule: ScheduledFormularyMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFormularyMilestone) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFormularyMilestoneRequiredTitleRule: ScheduledFormularyMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFormularyMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFormularyMilestoneRatioRangeRule: ScheduledFormularyMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFormularyMilestone) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled formulary milestone.
    final class ScheduledFormularyMilestoneValidator {
        var rules: [any ScheduledFormularyMilestoneRule]

        init(rules: [any ScheduledFormularyMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFormularyMilestone) -> [String] {
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

        func requireValid(_ item: ScheduledFormularyMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFormularyMilestone]) -> [String: [String]] {
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

    static func defaultScheduledFormularyMilestoneValidator() -> ScheduledFormularyMilestoneValidator {
        return ScheduledFormularyMilestoneValidator(
            rules: [
                ScheduledFormularyMilestoneRequiredProcedureCodeRule(
                    message: "scheduled formulary milestone needs this field"
                ),
                ScheduledFormularyMilestoneRequiredTitleRule(
                    message: "scheduled formulary milestone needs this field"
                ),
                ScheduledFormularyMilestoneRatioRangeRule(min: 0.6, max: 2682.9),
            ]
        )
    }
}
