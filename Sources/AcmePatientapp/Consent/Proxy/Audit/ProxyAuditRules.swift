import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy audit must pass. Check returns its problems, or none.
    protocol ProxyAuditRule {
        func check(_ item: ProxyAudit) -> [String]
    }

    final class ProxyAuditCostRangeRule: ProxyAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyAudit) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyAuditDiscountRangeRule: ProxyAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyAudit) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyAuditRequiredProcedureCodeRule: ProxyAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyAudit) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyAuditTitleLengthRule: ProxyAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyAuditRequiredTitleRule: ProxyAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyAuditProcedureCodeLengthRule: ProxyAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyAudit) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy audit.
    final class ProxyAuditValidator {
        var rules: [any ProxyAuditRule]

        init(rules: [any ProxyAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyAudit) -> [String] {
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

        func requireValid(_ item: ProxyAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyAudit]) -> [String: [String]] {
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

    static func defaultProxyAuditValidator() -> ProxyAuditValidator {
        return ProxyAuditValidator(
            rules: [
                ProxyAuditCostRangeRule(min: 2.1, max: 2838.5),
                ProxyAuditDiscountRangeRule(min: 5.6, max: 3554.4),
                ProxyAuditRequiredProcedureCodeRule(message: "proxy audit needs a value"),
                ProxyAuditTitleLengthRule(maxLength: 3600),
                ProxyAuditRequiredTitleRule(message: "proxy audit needs a value"),
                ProxyAuditProcedureCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
