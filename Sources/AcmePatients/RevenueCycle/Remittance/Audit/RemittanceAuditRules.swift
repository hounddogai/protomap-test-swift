import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance audit must pass. Check returns its problems, or none.
    protocol RemittanceAuditRule {
        func check(_ item: RemittanceAudit) -> [String]
    }

    final class RemittanceAuditExpiresAtRangeRule: RemittanceAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceAudit) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceAuditRequiredOwnerIDRule: RemittanceAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceAudit) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceAuditCeilingRangeRule: RemittanceAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceAudit) -> [String] {
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

    /// Runs every rule of a remittance audit.
    final class RemittanceAuditValidator {
        var rules: [any RemittanceAuditRule]

        init(rules: [any RemittanceAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceAudit) -> [String] {
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

        func requireValid(_ item: RemittanceAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceAudit]) -> [String: [String]] {
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

    static func defaultRemittanceAuditValidator() -> RemittanceAuditValidator {
        return RemittanceAuditValidator(
            rules: [
                RemittanceAuditExpiresAtRangeRule(min: 16, max: 64),
                RemittanceAuditRequiredOwnerIDRule(message: "remittance audit needs a value"),
                RemittanceAuditCeilingRangeRule(min: 2.7, max: 2823.3),
            ]
        )
    }
}
