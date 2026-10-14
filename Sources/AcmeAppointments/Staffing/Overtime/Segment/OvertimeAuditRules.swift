import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime audit must pass. Check returns its problems, or none.
    protocol OvertimeAuditRule {
        func check(_ item: OvertimeAudit) -> [String]
    }

    final class OvertimeAuditCodeLengthRule: OvertimeAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeAuditTitleLengthRule: OvertimeAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeAuditAllowedFacilityRule: OvertimeAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime audit.
    final class OvertimeAuditValidator {
        var rules: [any OvertimeAuditRule]

        init(rules: [any OvertimeAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeAudit]) -> [String: [String]] {
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

    static func defaultOvertimeAuditValidator() -> OvertimeAuditValidator {
        return OvertimeAuditValidator(
            rules: [
                OvertimeAuditCodeLengthRule(maxLength: 3600),
                OvertimeAuditTitleLengthRule(maxLength: 16),
                OvertimeAuditAllowedFacilityRule(allowed: ["capped", "legacy"]),
            ]
        )
    }
}
