import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan audit must pass. Check returns its problems, or none.
    protocol DischargePlanAuditRule {
        func check(_ item: DischargePlanAudit) -> [String]
    }

    final class DischargePlanAuditCodeLengthRule: DischargePlanAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanAuditTitleLengthRule: DischargePlanAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanAuditAllowedCodeRule: DischargePlanAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class DischargePlanAuditRequiredCodeRule: DischargePlanAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan audit.
    final class DischargePlanAuditValidator {
        var rules: [any DischargePlanAuditRule]

        init(rules: [any DischargePlanAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanAudit) -> [String] {
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

        func requireValid(_ item: DischargePlanAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanAudit]) -> [String: [String]] {
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

    static func defaultDischargePlanAuditValidator() -> DischargePlanAuditValidator {
        return DischargePlanAuditValidator(
            rules: [
                DischargePlanAuditCodeLengthRule(maxLength: 86400),
                DischargePlanAuditTitleLengthRule(maxLength: 64),
                DischargePlanAuditAllowedCodeRule(allowed: ["regional"]),
                DischargePlanAuditRequiredCodeRule(message: "discharge plan audit needs an entry"),
            ]
        )
    }
}
