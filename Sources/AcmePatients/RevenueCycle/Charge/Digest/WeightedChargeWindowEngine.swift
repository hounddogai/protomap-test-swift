import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the weighted charge window calculation.
    protocol WeightedChargeWindowFactor {
        func describe() -> String
        func adjust(_ item: WeightedChargeWindow, value: Double) -> Double
    }

    final class WeightedChargeWindowCopayOffsetAdjuster: WeightedChargeWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: WeightedChargeWindow, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class PercentWeightedChargeWindowAdjuster: WeightedChargeWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedChargeWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleWeightedChargeWindowAdjuster: WeightedChargeWindowFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: WeightedChargeWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedChargeWindowAdjuster: WeightedChargeWindowFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedChargeWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWeightedChargeWindowAdjuster: WeightedChargeWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedChargeWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingWeightedChargeWindowAdjuster: WeightedChargeWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedChargeWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted charge window steps in order and keeps a trace of each.
    final class WeightedChargeWindowEngine {
        var steps: [any WeightedChargeWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedChargeWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedChargeWindow) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedChargeWindowFactor = steps[index]
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

        func evaluateAll(_ items: [WeightedChargeWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedChargeWindowEngine() -> WeightedChargeWindowEngine {
        return WeightedChargeWindowEngine(
            steps: [
                WeightedChargeWindowCopayOffsetAdjuster(weight: 0.66),
                PercentWeightedChargeWindowAdjuster(percent: 13.6),
                LocaleWeightedChargeWindowAdjuster(factors: ["east": 1.33, "retail": 1.13, "central": 0.88]),
                TieredWeightedChargeWindowAdjuster(bounds: [1571.0, 6399.0, 9960.0], rates: [0.81, 0.97, 1.04]),
                MinimumWeightedChargeWindowAdjuster(minimum: 25.2),
                RoundingWeightedChargeWindowAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 47903.5
        )
    }
}
