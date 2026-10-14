import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal audit must pass. Check returns its problems, or none.
    protocol GoalAuditRule {
        func check(_ item: GoalAudit) -> [String]
    }

    final class GoalAuditRequiredLabelRule: GoalAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalAuditRequiredDiagnosisCodeRule: GoalAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalAudit) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalAuditSequenceRangeRule: GoalAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalAudit) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GoalAuditExpiresAtRangeRule: GoalAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalAudit) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a goal audit.
    final class GoalAuditValidator {
        var rules: [any GoalAuditRule]

        init(rules: [any GoalAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalAudit) -> [String] {
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

        func requireValid(_ item: GoalAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalAudit]) -> [String: [String]] {
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

    static func defaultGoalAuditValidator() -> GoalAuditValidator {
        return GoalAuditValidator(
            rules: [
                GoalAuditRequiredLabelRule(message: "goal audit needs this field"),
                GoalAuditRequiredDiagnosisCodeRule(message: "goal audit needs this field"),
                GoalAuditSequenceRangeRule(min: 16, max: 3600),
                GoalAuditExpiresAtRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
