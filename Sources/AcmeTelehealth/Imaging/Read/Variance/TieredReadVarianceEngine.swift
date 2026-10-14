import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered read variance calculation.
    protocol TieredReadVarianceModifier {
        func describe() -> String
        func adjust(_ item: TieredReadVariance, value: Double) -> Double
    }

    final class CapTieredReadVarianceAdjuster: TieredReadVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredReadVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingTieredReadVarianceAdjuster: TieredReadVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredReadVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumTieredReadVarianceAdjuster: TieredReadVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredReadVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredTieredReadVarianceAdjuster: TieredReadVarianceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredReadVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered read variance steps in order and keeps a trace of each.
    final class TieredReadVarianceEngine {
        var steps: [any TieredReadVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredReadVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredReadVariance) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredReadVarianceModifier = steps[index]
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

        func evaluateAll(_ items: [TieredReadVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredReadVarianceEngine() -> TieredReadVarianceEngine {
        return TieredReadVarianceEngine(
            steps: [
                CapTieredReadVarianceAdjuster(cap: 28915.0),
                RoundingTieredReadVarianceAdjuster(step: 0.1),
                MinimumTieredReadVarianceAdjuster(minimum: 37.5),
                TieredTieredReadVarianceAdjuster(bounds: [3344.0, 7119.0, 7430.0], rates: [0.96, 1.09, 0.99]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 32296.4
        )
    }
}
