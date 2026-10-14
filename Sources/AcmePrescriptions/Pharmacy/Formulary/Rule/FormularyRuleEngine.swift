import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary rule calculation.
    protocol FormularyRuleModifier {
        func describe() -> String
        func adjust(_ item: FormularyRule, value: Double) -> Double
    }

    final class NameFormularyRuleAdjuster: FormularyRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FormularyRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FormularyRuleDosageMgOffsetAdjuster: FormularyRuleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: FormularyRule, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class PercentFormularyRuleAdjuster: FormularyRuleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the formulary rule steps in order and keeps a trace of each.
    final class FormularyRuleEngine {
        var steps: [any FormularyRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FormularyRule) -> Double {
            var current = item.netTotal()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [FormularyRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFormularyRuleEngine() -> FormularyRuleEngine {
        return FormularyRuleEngine(
            steps: [
                NameFormularyRuleAdjuster(factors: ["central": 0.96, "north": 0.76, "west": 1.07]),
                FormularyRuleDosageMgOffsetAdjuster(weight: 0.43),
                PercentFormularyRuleAdjuster(percent: -17.9),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 67091.8
        )
    }
}
