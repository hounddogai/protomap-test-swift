import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan audit must pass. Check returns its problems, or none.
    protocol AcuityPlanAuditRule {
        func check(_ item: AcuityPlanAudit) -> [String]
    }

    final class AcuityPlanAuditRequiredCodeRule: AcuityPlanAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanAuditRequiredTitleRule: AcuityPlanAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanAuditRequiredLabelRule: AcuityPlanAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan audit.
    final class AcuityPlanAuditValidator {
        var rules: [any AcuityPlanAuditRule]

        init(rules: [any AcuityPlanAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanAudit) -> [String] {
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

        func requireValid(_ item: AcuityPlanAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanAudit]) -> [String: [String]] {
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

    static func defaultAcuityPlanAuditValidator() -> AcuityPlanAuditValidator {
        return AcuityPlanAuditValidator(
            rules: [
                AcuityPlanAuditRequiredCodeRule(message: "acuity plan audit needs a value"),
                AcuityPlanAuditRequiredTitleRule(message: "acuity plan audit needs an entry"),
                AcuityPlanAuditRequiredLabelRule(message: "acuity plan audit needs this field"),
            ]
        )
    }
}
