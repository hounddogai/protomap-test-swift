import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert audit must pass. Check returns its problems, or none.
    protocol AlertAuditRule {
        func check(_ item: AlertAudit) -> [String]
    }

    final class AlertAuditRequiredTimezoneRule: AlertAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertAudit) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertAuditProcedureCodeLengthRule: AlertAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertAudit) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertAuditRequiredProcedureCodeRule: AlertAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertAudit) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert audit.
    final class AlertAuditValidator {
        var rules: [any AlertAuditRule]

        init(rules: [any AlertAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertAudit]) -> [String: [String]] {
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

    static func defaultAlertAuditValidator() -> AlertAuditValidator {
        return AlertAuditValidator(
            rules: [
                AlertAuditRequiredTimezoneRule(message: "alert audit needs a value"),
                AlertAuditProcedureCodeLengthRule(maxLength: 86400),
                AlertAuditRequiredProcedureCodeRule(message: "alert audit needs an entry"),
            ]
        )
    }
}
