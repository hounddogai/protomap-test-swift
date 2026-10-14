import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary allocation calculation.
    protocol FormularyAllocationStep {
        func describe() -> String
        func adjust(_ item: FormularyAllocation, value: Double) -> Double
    }

    final class TieredFormularyAllocationAdjuster: FormularyAllocationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFormularyAllocationAdjuster: FormularyAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularyAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FormularyAllocationExpiresAtOffsetAdjuster: FormularyAllocationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: FormularyAllocation, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class CapFormularyAllocationAdjuster: FormularyAllocationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFormularyAllocationAdjuster: FormularyAllocationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FormularyAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the formulary allocation steps in order and keeps a trace of each.
    final class FormularyAllocationEngine {
        var steps: [any FormularyAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyAllocation) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyAllocationStep = steps[index]
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

        func evaluateAll(_ items: [FormularyAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyAllocationEngine() -> FormularyAllocationEngine {
        return FormularyAllocationEngine(
            steps: [
                TieredFormularyAllocationAdjuster(
                    bounds: [3089.0, 5811.0, 7092.0, 8599.0],
                    rates: [1.04, 1.18, 1.04, 1.1]
                ),
                MinimumFormularyAllocationAdjuster(minimum: 46.6),
                FormularyAllocationExpiresAtOffsetAdjuster(weight: 0.33),
                CapFormularyAllocationAdjuster(cap: 16053.0),
                RoundingFormularyAllocationAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 22180.9
        )
    }
}
