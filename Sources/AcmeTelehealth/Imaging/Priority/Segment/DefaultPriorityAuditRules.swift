import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default priority audit must pass. Check returns its problems, or none.
    protocol DefaultPriorityAuditRule {
        func check(_ item: DefaultPriorityAudit) -> [String]
    }

    final class DefaultPriorityAuditNameLengthRule: DefaultPriorityAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultPriorityAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultPriorityAuditRequiredCodeRule: DefaultPriorityAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultPriorityAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultPriorityAuditLocaleLengthRule: DefaultPriorityAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultPriorityAudit) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default priority audit.
    final class DefaultPriorityAuditValidator {
        var rules: [any DefaultPriorityAuditRule]

        init(rules: [any DefaultPriorityAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultPriorityAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultPriorityAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultPriorityAudit]) -> [String: [String]] {
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

    static func defaultDefaultPriorityAuditValidator() -> DefaultPriorityAuditValidator {
        return DefaultPriorityAuditValidator(
            rules: [
                DefaultPriorityAuditNameLengthRule(maxLength: 32),
                DefaultPriorityAuditRequiredCodeRule(message: "default priority audit needs an entry"),
                DefaultPriorityAuditLocaleLengthRule(maxLength: 32),
            ]
        )
    }
}
