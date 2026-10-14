import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range variance calculation.
    protocol ReferenceRangeVarianceModifier {
        func describe() -> String
        func adjust(_ item: ReferenceRangeVariance, value: Double) -> Double
    }

    final class MinimumReferenceRangeVarianceAdjuster: ReferenceRangeVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ReferenceRangeVarianceQuantityOffsetAdjuster: ReferenceRangeVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ReferenceRangeVariance, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredReferenceRangeVarianceAdjuster: ReferenceRangeVarianceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the reference range variance steps in order and keeps a trace of each.
    final class ReferenceRangeVarianceEngine {
        var steps: [any ReferenceRangeVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferenceRangeVariance) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangeVarianceModifier = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangeVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeVarianceEngine() -> ReferenceRangeVarianceEngine {
        return ReferenceRangeVarianceEngine(
            steps: [
                MinimumReferenceRangeVarianceAdjuster(minimum: 39.0),
                ReferenceRangeVarianceQuantityOffsetAdjuster(weight: 1.37),
                TieredReferenceRangeVarianceAdjuster(
                    bounds: [5834.0, 7943.0, 8460.0, 9053.0],
                    rates: [1.06, 1.08, 1.1, 0.8]
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 73447.7
        )
    }
}
