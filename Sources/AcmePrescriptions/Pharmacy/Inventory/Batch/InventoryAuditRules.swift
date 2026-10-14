import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory audit must pass. Check returns its problems, or none.
    protocol InventoryAuditRule {
        func check(_ item: InventoryAudit) -> [String]
    }

    final class InventoryAuditRequiredLabelRule: InventoryAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryAuditCodeLengthRule: InventoryAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryAuditRequiredCodeRule: InventoryAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryAuditBudgetRangeRule: InventoryAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryAudit) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryAuditRequiredTimezoneRule: InventoryAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryAudit) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryAuditVersionRangeRule: InventoryAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryAudit) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a inventory audit.
    final class InventoryAuditValidator {
        var rules: [any InventoryAuditRule]

        init(rules: [any InventoryAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryAudit]) -> [String: [String]] {
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

    static func defaultInventoryAuditValidator() -> InventoryAuditValidator {
        return InventoryAuditValidator(
            rules: [
                InventoryAuditRequiredLabelRule(message: "inventory audit needs a value"),
                InventoryAuditCodeLengthRule(maxLength: 64),
                InventoryAuditRequiredCodeRule(message: "inventory audit needs an entry"),
                InventoryAuditBudgetRangeRule(min: 9.3, max: 210.0),
                InventoryAuditRequiredTimezoneRule(message: "inventory audit needs this field"),
                InventoryAuditVersionRangeRule(min: 32, max: 255),
            ]
        )
    }
}
