import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient substitution budget calculation.
    protocol LenientSubstitutionBudgetStep {
        func describe() -> String
        func adjust(_ item: LenientSubstitutionBudget, value: Double) -> Double
    }

    final class LenientSubstitutionBudgetAttemptsOffsetAdjuster: LenientSubstitutionBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: LenientSubstitutionBudget, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class MinimumLenientSubstitutionBudgetAdjuster: LenientSubstitutionBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientSubstitutionBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryLenientSubstitutionBudgetAdjuster: LenientSubstitutionBudgetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: LenientSubstitutionBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient substitution budget steps in order and keeps a trace of each.
    final class LenientSubstitutionBudgetEngine {
        var steps: [any LenientSubstitutionBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientSubstitutionBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientSubstitutionBudget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientSubstitutionBudgetStep = steps[index]
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

        func evaluateAll(_ items: [LenientSubstitutionBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientSubstitutionBudgetEngine() -> LenientSubstitutionBudgetEngine {
        return LenientSubstitutionBudgetEngine(
            steps: [
                LenientSubstitutionBudgetAttemptsOffsetAdjuster(weight: 0.24),
                MinimumLenientSubstitutionBudgetAdjuster(minimum: 9.5),
                CategoryLenientSubstitutionBudgetAdjuster(factors: ["retail": 1.29]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 1650.1
        )
    }
}
