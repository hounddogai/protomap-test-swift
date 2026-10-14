import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff audit must pass. Check returns its problems, or none.
    protocol HandoffAuditRule {
        func check(_ item: HandoffAudit) -> [String]
    }

    final class HandoffAuditRequiredLabelRule: HandoffAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffAuditApprovedGuardRule: HandoffAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: HandoffAudit) -> [String] {
            if item.approved && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class HandoffAuditCeilingRangeRule: HandoffAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffAudit) -> [String] {
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

    /// Runs every rule of a handoff audit.
    final class HandoffAuditValidator {
        var rules: [any HandoffAuditRule]

        init(rules: [any HandoffAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffAudit]) -> [String: [String]] {
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

    static func defaultHandoffAuditValidator() -> HandoffAuditValidator {
        return HandoffAuditValidator(
            rules: [
                HandoffAuditRequiredLabelRule(message: "handoff audit needs this field"),
                HandoffAuditApprovedGuardRule(limit: 3600),
                HandoffAuditCeilingRangeRule(min: 1.6, max: 4526.2),
            ]
        )
    }
}
