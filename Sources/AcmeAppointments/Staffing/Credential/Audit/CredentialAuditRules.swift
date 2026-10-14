import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential audit must pass. Check returns its problems, or none.
    protocol CredentialAuditRule {
        func check(_ item: CredentialAudit) -> [String]
    }

    final class CredentialAuditPatientRefLengthRule: CredentialAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialAudit) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialAuditQuantityRangeRule: CredentialAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialAudit) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialAuditCodePrefixRule: CredentialAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialAuditRequiredTitleRule: CredentialAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialAuditVisibleGuardRule: CredentialAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CredentialAudit) -> [String] {
            if item.visible && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class CredentialAuditRequiredPatientRefRule: CredentialAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialAudit) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential audit.
    final class CredentialAuditValidator {
        var rules: [any CredentialAuditRule]

        init(rules: [any CredentialAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialAudit]) -> [String: [String]] {
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

    static func defaultCredentialAuditValidator() -> CredentialAuditValidator {
        return CredentialAuditValidator(
            rules: [
                CredentialAuditPatientRefLengthRule(maxLength: 16),
                CredentialAuditQuantityRangeRule(min: 16, max: 120),
                CredentialAuditCodePrefixRule(prefix: "Q"),
                CredentialAuditRequiredTitleRule(message: "credential audit needs an entry"),
                CredentialAuditVisibleGuardRule(limit: 16),
                CredentialAuditRequiredPatientRefRule(message: "credential audit needs this field"),
            ]
        )
    }
}
