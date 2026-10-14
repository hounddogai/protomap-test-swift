import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory exception must pass. Check returns its problems, or none.
    protocol InventoryExceptionRule {
        func check(_ item: InventoryException) -> [String]
    }

    final class InventoryExceptionCodeLengthRule: InventoryExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryExceptionPriorityRangeRule: InventoryExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryException) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryExceptionRequiredLabelRule: InventoryExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryException) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryExceptionAttemptsRangeRule: InventoryExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryException) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventoryExceptionCodePrefixRule: InventoryExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InventoryExceptionUnitLengthRule: InventoryExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryException) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory exception.
    final class InventoryExceptionValidator {
        var rules: [any InventoryExceptionRule]

        init(rules: [any InventoryExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryException) -> [String] {
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

        func requireValid(_ item: InventoryException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryException]) -> [String: [String]] {
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

    static func defaultInventoryExceptionValidator() -> InventoryExceptionValidator {
        return InventoryExceptionValidator(
            rules: [
                InventoryExceptionCodeLengthRule(maxLength: 1000),
                InventoryExceptionPriorityRangeRule(min: 120, max: 255),
                InventoryExceptionRequiredLabelRule(message: "inventory exception needs a value"),
                InventoryExceptionAttemptsRangeRule(min: 255, max: 86400),
                InventoryExceptionCodePrefixRule(prefix: "REF"),
                InventoryExceptionUnitLengthRule(maxLength: 64),
            ]
        )
    }
}
