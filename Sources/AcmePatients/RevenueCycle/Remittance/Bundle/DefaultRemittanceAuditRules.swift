import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default remittance audit must pass. Check returns its problems, or none.
    protocol DefaultRemittanceAuditRule {
        func check(_ item: DefaultRemittanceAudit) -> [String]
    }

    final class DefaultRemittanceAuditCodeLengthRule: DefaultRemittanceAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRemittanceAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRemittanceAuditRequiredCodeRule: DefaultRemittanceAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRemittanceAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRemittanceAuditVisitMinutesRangeRule: DefaultRemittanceAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRemittanceAudit) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default remittance audit.
    final class DefaultRemittanceAuditValidator {
        var rules: [any DefaultRemittanceAuditRule]

        init(rules: [any DefaultRemittanceAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRemittanceAudit) -> [String] {
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

        func requireValid(_ item: DefaultRemittanceAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRemittanceAudit]) -> [String: [String]] {
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

    static func defaultDefaultRemittanceAuditValidator() -> DefaultRemittanceAuditValidator {
        return DefaultRemittanceAuditValidator(
            rules: [
                DefaultRemittanceAuditCodeLengthRule(maxLength: 255),
                DefaultRemittanceAuditRequiredCodeRule(message: "default remittance audit needs an entry"),
                DefaultRemittanceAuditVisitMinutesRangeRule(min: 86400, max: 86400),
            ]
        )
    }
}
