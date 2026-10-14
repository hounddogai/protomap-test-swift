import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory baseline must pass. Check returns its problems, or none.
    protocol InventoryBaselineRule {
        func check(_ item: InventoryBaseline) -> [String]
    }

    final class InventoryBaselineCodeLengthRule: InventoryBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryBaselineWeightRangeRule: InventoryBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryBaseline) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryBaselineRequiredLabelRule: InventoryBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory baseline.
    final class InventoryBaselineValidator {
        var rules: [any InventoryBaselineRule]

        init(rules: [any InventoryBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryBaseline]) -> [String: [String]] {
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

    static func defaultInventoryBaselineValidator() -> InventoryBaselineValidator {
        return InventoryBaselineValidator(
            rules: [
                InventoryBaselineCodeLengthRule(maxLength: 120),
                InventoryBaselineWeightRangeRule(min: 7.0, max: 4659.6),
                InventoryBaselineRequiredLabelRule(message: "inventory baseline needs this field"),
            ]
        )
    }
}
