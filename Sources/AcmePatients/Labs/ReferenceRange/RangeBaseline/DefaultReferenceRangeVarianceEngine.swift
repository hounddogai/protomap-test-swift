import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default reference range variance calculation.
    protocol DefaultReferenceRangeVarianceFactor {
        func describe() -> String
        func adjust(_ item: DefaultReferenceRangeVariance, value: Double) -> Double
    }

    final class DefaultReferenceRangeVarianceDosageMgOffsetAdjuster: DefaultReferenceRangeVarianceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: DefaultReferenceRangeVariance, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class TieredDefaultReferenceRangeVarianceAdjuster: DefaultReferenceRangeVarianceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultReferenceRangeVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDefaultReferenceRangeVarianceAdjuster: DefaultReferenceRangeVarianceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultReferenceRangeVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default reference range variance steps in order and keeps a trace of each.
    final class DefaultReferenceRangeVarianceEngine {
        var steps: [any DefaultReferenceRangeVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultReferenceRangeVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultReferenceRangeVariance) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultReferenceRangeVarianceFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultReferenceRangeVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultReferenceRangeVarianceEngine() -> DefaultReferenceRangeVarianceEngine {
        return DefaultReferenceRangeVarianceEngine(
            steps: [
                DefaultReferenceRangeVarianceDosageMgOffsetAdjuster(weight: 1.02),
                TieredDefaultReferenceRangeVarianceAdjuster(
                    bounds: [897.0, 1023.0, 7738.0],
                    rates: [0.99, 0.91, 0.85]
                ),
                RoundingDefaultReferenceRangeVarianceAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 32770.4
        )
    }
}
