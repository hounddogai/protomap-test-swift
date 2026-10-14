import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial budget calculation.
    protocol DenialBudgetStep {
        func describe() -> String
        func adjust(_ item: DenialBudget, value: Double) -> Double
    }

    final class TieredDenialBudgetAdjuster: DenialBudgetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDenialBudgetAdjuster: DenialBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDenialBudgetAdjuster: DenialBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDenialBudgetAdjuster: DenialBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the denial budget steps in order and keeps a trace of each.
    final class DenialBudgetEngine {
        var steps: [any DenialBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DenialBudget) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialBudgetStep = steps[index]
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

        func evaluateAll(_ items: [DenialBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDenialBudgetEngine() -> DenialBudgetEngine {
        return DenialBudgetEngine(
            steps: [
                TieredDenialBudgetAdjuster(bounds: [6931.0, 8738.0], rates: [0.8, 1.11]),
                RoundingDenialBudgetAdjuster(step: 0.1),
                CapDenialBudgetAdjuster(cap: 16973.0),
                MinimumDenialBudgetAdjuster(minimum: 11.5),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 36092.0
        )
    }
}
