import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool budget must pass. Check returns its problems, or none.
    protocol FloatPoolBudgetRule {
        func check(_ item: FloatPoolBudget) -> [String]
    }

    final class FloatPoolBudgetRequiredSourceRule: FloatPoolBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolBudget) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolBudgetSegmentLengthRule: FloatPoolBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolBudget) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolBudgetCostRangeRule: FloatPoolBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolBudget) -> [String] {
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

    final class FloatPoolBudgetCodePrefixRule: FloatPoolBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FloatPoolBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool budget.
    final class FloatPoolBudgetValidator {
        var rules: [any FloatPoolBudgetRule]

        init(rules: [any FloatPoolBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolBudget) -> [String] {
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

        func requireValid(_ item: FloatPoolBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolBudget]) -> [String: [String]] {
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

    static func defaultFloatPoolBudgetValidator() -> FloatPoolBudgetValidator {
        return FloatPoolBudgetValidator(
            rules: [
                FloatPoolBudgetRequiredSourceRule(message: "float pool budget needs a value"),
                FloatPoolBudgetSegmentLengthRule(maxLength: 255),
                FloatPoolBudgetCostRangeRule(min: 8.1, max: 3971.0),
                FloatPoolBudgetCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
