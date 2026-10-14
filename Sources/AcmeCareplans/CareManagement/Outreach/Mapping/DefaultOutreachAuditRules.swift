import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default outreach audit must pass. Check returns its problems, or none.
    protocol DefaultOutreachAuditRule {
        func check(_ item: DefaultOutreachAudit) -> [String]
    }

    final class DefaultOutreachAuditContactEmailLengthRule: DefaultOutreachAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultOutreachAudit) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultOutreachAuditRequiredContactEmailRule: DefaultOutreachAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultOutreachAudit) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultOutreachAuditSequenceRangeRule: DefaultOutreachAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultOutreachAudit) -> [String] {
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

    final class DefaultOutreachAuditCodePrefixRule: DefaultOutreachAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultOutreachAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultOutreachAuditCodeLengthRule: DefaultOutreachAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultOutreachAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default outreach audit.
    final class DefaultOutreachAuditValidator {
        var rules: [any DefaultOutreachAuditRule]

        init(rules: [any DefaultOutreachAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultOutreachAudit) -> [String] {
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

        func requireValid(_ item: DefaultOutreachAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultOutreachAudit]) -> [String: [String]] {
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

    static func defaultDefaultOutreachAuditValidator() -> DefaultOutreachAuditValidator {
        return DefaultOutreachAuditValidator(
            rules: [
                DefaultOutreachAuditContactEmailLengthRule(maxLength: 16),
                DefaultOutreachAuditRequiredContactEmailRule(message: "default outreach audit needs a value"),
                DefaultOutreachAuditSequenceRangeRule(min: 16, max: 86400),
                DefaultOutreachAuditCodePrefixRule(prefix: "Q"),
                DefaultOutreachAuditCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
