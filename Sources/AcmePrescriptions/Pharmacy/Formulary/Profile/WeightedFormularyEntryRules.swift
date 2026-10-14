import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted formulary entry must pass. Check returns its problems, or none.
    protocol WeightedFormularyEntryRule {
        func check(_ item: WeightedFormularyEntry) -> [String]
    }

    final class WeightedFormularyEntrySequenceRangeRule: WeightedFormularyEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedFormularyEntry) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedFormularyEntryAllowedCodeRule: WeightedFormularyEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedFormularyEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class WeightedFormularyEntryAmountRangeRule: WeightedFormularyEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedFormularyEntry) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted formulary entry.
    final class WeightedFormularyEntryValidator {
        var rules: [any WeightedFormularyEntryRule]

        init(rules: [any WeightedFormularyEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFormularyEntry) -> [String] {
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

        func requireValid(_ item: WeightedFormularyEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFormularyEntry]) -> [String: [String]] {
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

    static func defaultWeightedFormularyEntryValidator() -> WeightedFormularyEntryValidator {
        return WeightedFormularyEntryValidator(
            rules: [
                WeightedFormularyEntrySequenceRangeRule(min: 80, max: 120),
                WeightedFormularyEntryAllowedCodeRule(allowed: ["strict"]),
                WeightedFormularyEntryAmountRangeRule(min: 8.8, max: 1677.2),
            ]
        )
    }
}
