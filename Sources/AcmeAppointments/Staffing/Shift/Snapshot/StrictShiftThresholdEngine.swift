import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict shift threshold calculation.
    protocol StrictShiftThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: StrictShiftThreshold, value: Double) -> Double
    }

    final class CapStrictShiftThresholdAdjuster: StrictShiftThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictShiftThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StrictShiftThresholdCostOffsetAdjuster: StrictShiftThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: StrictShiftThreshold, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class WardStrictShiftThresholdAdjuster: StrictShiftThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: StrictShiftThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStrictShiftThresholdAdjuster: StrictShiftThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictShiftThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStrictShiftThresholdAdjuster: StrictShiftThresholdAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictShiftThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingStrictShiftThresholdAdjuster: StrictShiftThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictShiftThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict shift threshold steps in order and keeps a trace of each.
    final class StrictShiftThresholdEngine {
        var steps: [any StrictShiftThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictShiftThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictShiftThreshold) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictShiftThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [StrictShiftThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictShiftThresholdEngine() -> StrictShiftThresholdEngine {
        return StrictShiftThresholdEngine(
            steps: [
                CapStrictShiftThresholdAdjuster(cap: 49798.0),
                StrictShiftThresholdCostOffsetAdjuster(weight: 1.24),
                WardStrictShiftThresholdAdjuster(factors: ["east": 0.84]),
                TieredStrictShiftThresholdAdjuster(bounds: [2639.0, 2736.0, 3393.0], rates: [0.87, 1.06, 0.86]),
                MinimumStrictShiftThresholdAdjuster(minimum: 28.0),
                RoundingStrictShiftThresholdAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 34997.5
        )
    }
}
