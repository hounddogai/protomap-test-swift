import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory adjustment must pass. Check returns its problems, or none.
    protocol InventoryAdjustmentRule {
        func check(_ item: InventoryAdjustment) -> [String]
    }

    final class InventoryAdjustmentCodeLengthRule: InventoryAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryAdjustmentCodePrefixRule: InventoryAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InventoryAdjustmentCurrencyLengthRule: InventoryAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryAdjustment) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryAdjustmentMaximumRangeRule: InventoryAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryAdjustment) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventoryAdjustmentRequiredCurrencyRule: InventoryAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryAdjustment) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryAdjustmentRequiredLabelRule: InventoryAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryAdjustment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory adjustment.
    final class InventoryAdjustmentValidator {
        var rules: [any InventoryAdjustmentRule]

        init(rules: [any InventoryAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryAdjustment) -> [String] {
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

        func requireValid(_ item: InventoryAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryAdjustment]) -> [String: [String]] {
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

    static func defaultInventoryAdjustmentValidator() -> InventoryAdjustmentValidator {
        return InventoryAdjustmentValidator(
            rules: [
                InventoryAdjustmentCodeLengthRule(maxLength: 1000),
                InventoryAdjustmentCodePrefixRule(prefix: "REF"),
                InventoryAdjustmentCurrencyLengthRule(maxLength: 3600),
                InventoryAdjustmentMaximumRangeRule(min: 1.3, max: 3037.1),
                InventoryAdjustmentRequiredCurrencyRule(message: "inventory adjustment needs this field"),
                InventoryAdjustmentRequiredLabelRule(message: "inventory adjustment needs a value"),
            ]
        )
    }
}
