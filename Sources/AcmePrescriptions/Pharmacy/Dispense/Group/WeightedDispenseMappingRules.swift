import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted dispense mapping must pass. Check returns its problems, or none.
    protocol WeightedDispenseMappingRule {
        func check(_ item: WeightedDispenseMapping) -> [String]
    }

    final class WeightedDispenseMappingBudgetRangeRule: WeightedDispenseMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedDispenseMapping) -> [String] {
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

    final class WeightedDispenseMappingCodeLengthRule: WeightedDispenseMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDispenseMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDispenseMappingNameLengthRule: WeightedDispenseMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDispenseMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDispenseMappingRequiredCodeRule: WeightedDispenseMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedDispenseMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted dispense mapping.
    final class WeightedDispenseMappingValidator {
        var rules: [any WeightedDispenseMappingRule]

        init(rules: [any WeightedDispenseMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedDispenseMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedDispenseMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedDispenseMapping]) -> [String: [String]] {
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

    static func defaultWeightedDispenseMappingValidator() -> WeightedDispenseMappingValidator {
        return WeightedDispenseMappingValidator(
            rules: [
                WeightedDispenseMappingBudgetRangeRule(min: 7.9, max: 1911.9),
                WeightedDispenseMappingCodeLengthRule(maxLength: 1000),
                WeightedDispenseMappingNameLengthRule(maxLength: 80),
                WeightedDispenseMappingRequiredCodeRule(message: "weighted dispense mapping needs this field"),
            ]
        )
    }
}
