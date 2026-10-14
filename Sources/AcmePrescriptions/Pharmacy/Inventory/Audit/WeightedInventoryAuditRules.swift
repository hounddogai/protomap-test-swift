import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted inventory audit must pass. Check returns its problems, or none.
    protocol WeightedInventoryAuditRule {
        func check(_ item: WeightedInventoryAudit) -> [String]
    }

    final class WeightedInventoryAuditQuantityRangeRule: WeightedInventoryAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedInventoryAudit) -> [String] {
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

    final class WeightedInventoryAuditLabelLengthRule: WeightedInventoryAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedInventoryAudit) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedInventoryAuditNameLengthRule: WeightedInventoryAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedInventoryAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedInventoryAuditRequiredSpecialtyRule: WeightedInventoryAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInventoryAudit) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedInventoryAuditSpecialtyLengthRule: WeightedInventoryAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedInventoryAudit) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted inventory audit.
    final class WeightedInventoryAuditValidator {
        var rules: [any WeightedInventoryAuditRule]

        init(rules: [any WeightedInventoryAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedInventoryAudit) -> [String] {
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

        func requireValid(_ item: WeightedInventoryAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedInventoryAudit]) -> [String: [String]] {
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

    static func defaultWeightedInventoryAuditValidator() -> WeightedInventoryAuditValidator {
        return WeightedInventoryAuditValidator(
            rules: [
                WeightedInventoryAuditQuantityRangeRule(min: 16, max: 86400),
                WeightedInventoryAuditLabelLengthRule(maxLength: 1000),
                WeightedInventoryAuditNameLengthRule(maxLength: 16),
                WeightedInventoryAuditRequiredSpecialtyRule(message: "weighted inventory audit needs this field"),
                WeightedInventoryAuditSpecialtyLengthRule(maxLength: 86400),
            ]
        )
    }
}
