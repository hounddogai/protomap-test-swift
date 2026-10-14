import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted isolation variance calculation.
    protocol WeightedIsolationVarianceStep {
        func describe() -> String
        func adjust(_ item: WeightedIsolationVariance, value: Double) -> Double
    }

    final class RoundingWeightedIsolationVarianceAdjuster: WeightedIsolationVarianceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedIsolationVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedIsolationVarianceAdjuster: WeightedIsolationVarianceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedIsolationVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleWeightedIsolationVarianceAdjuster: WeightedIsolationVarianceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WeightedIsolationVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class WeightedIsolationVarianceDosageMgOffsetAdjuster: WeightedIsolationVarianceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: WeightedIsolationVariance, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class MinimumWeightedIsolationVarianceAdjuster: WeightedIsolationVarianceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedIsolationVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedIsolationVarianceAdjuster: WeightedIsolationVarianceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedIsolationVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted isolation variance steps in order and keeps a trace of each.
    final class WeightedIsolationVarianceEngine {
        var steps: [any WeightedIsolationVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedIsolationVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedIsolationVariance) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedIsolationVarianceStep = steps[index]
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

        func evaluateAll(_ items: [WeightedIsolationVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedIsolationVarianceEngine() -> WeightedIsolationVarianceEngine {
        return WeightedIsolationVarianceEngine(
            steps: [
                RoundingWeightedIsolationVarianceAdjuster(step: 0.05),
                CapWeightedIsolationVarianceAdjuster(cap: 39390.0),
                TitleWeightedIsolationVarianceAdjuster(factors: ["south": 0.92, "west": 0.83]),
                WeightedIsolationVarianceDosageMgOffsetAdjuster(weight: 1.11),
                MinimumWeightedIsolationVarianceAdjuster(minimum: 10.1),
                TieredWeightedIsolationVarianceAdjuster(bounds: [1335.0, 2880.0], rates: [1.11, 1.03]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 36037.6
        )
    }
}
