import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling proxy audit must pass. Check returns its problems, or none.
    protocol RollingProxyAuditRule {
        func check(_ item: RollingProxyAudit) -> [String]
    }

    final class RollingProxyAuditSpecialtyLengthRule: RollingProxyAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProxyAudit) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingProxyAuditRequiredContactEmailRule: RollingProxyAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingProxyAudit) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingProxyAuditNameLengthRule: RollingProxyAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProxyAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling proxy audit.
    final class RollingProxyAuditValidator {
        var rules: [any RollingProxyAuditRule]

        init(rules: [any RollingProxyAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingProxyAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingProxyAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingProxyAudit]) -> [String: [String]] {
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

    static func defaultRollingProxyAuditValidator() -> RollingProxyAuditValidator {
        return RollingProxyAuditValidator(
            rules: [
                RollingProxyAuditSpecialtyLengthRule(maxLength: 86400),
                RollingProxyAuditRequiredContactEmailRule(message: "rolling proxy audit needs this field"),
                RollingProxyAuditNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
