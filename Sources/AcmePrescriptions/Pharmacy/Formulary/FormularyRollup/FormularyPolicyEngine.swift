import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary policy calculation.
    protocol FormularyPolicyModifier {
        func describe() -> String
        func adjust(_ item: FormularyPolicy, value: Double) -> Double
    }

    final class LabelFormularyPolicyAdjuster: FormularyPolicyModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FormularyPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FormularyPolicyBudgetOffsetAdjuster: FormularyPolicyModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: FormularyPolicy, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CapFormularyPolicyAdjuster: FormularyPolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFormularyPolicyAdjuster: FormularyPolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the formulary policy steps in order and keeps a trace of each.
    final class FormularyPolicyEngine {
        var steps: [any FormularyPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FormularyPolicy) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyPolicyModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [FormularyPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFormularyPolicyEngine() -> FormularyPolicyEngine {
        return FormularyPolicyEngine(
            steps: [
                LabelFormularyPolicyAdjuster(factors: ["east": 1.23]),
                FormularyPolicyBudgetOffsetAdjuster(weight: 0.57),
                CapFormularyPolicyAdjuster(cap: 34407.0),
                PercentFormularyPolicyAdjuster(percent: 18.3),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 62485.5
        )
    }
}
