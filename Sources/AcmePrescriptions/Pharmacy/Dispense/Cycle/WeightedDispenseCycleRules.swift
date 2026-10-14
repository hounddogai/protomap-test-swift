import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted dispense cycle must pass. Check returns its problems, or none.
    protocol WeightedDispenseCycleRule {
        func check(_ item: WeightedDispenseCycle) -> [String]
    }

    final class WeightedDispenseCycleRateRangeRule: WeightedDispenseCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedDispenseCycle) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedDispenseCycleCodePrefixRule: WeightedDispenseCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedDispenseCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedDispenseCycleRequiredCodeRule: WeightedDispenseCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedDispenseCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted dispense cycle.
    final class WeightedDispenseCycleValidator {
        var rules: [any WeightedDispenseCycleRule]

        init(rules: [any WeightedDispenseCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedDispenseCycle) -> [String] {
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

        func requireValid(_ item: WeightedDispenseCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedDispenseCycle]) -> [String: [String]] {
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

    static func defaultWeightedDispenseCycleValidator() -> WeightedDispenseCycleValidator {
        return WeightedDispenseCycleValidator(
            rules: [
                WeightedDispenseCycleRateRangeRule(min: 9.4, max: 3333.8),
                WeightedDispenseCycleCodePrefixRule(prefix: "OPS"),
                WeightedDispenseCycleRequiredCodeRule(message: "weighted dispense cycle needs a value"),
            ]
        )
    }
}
