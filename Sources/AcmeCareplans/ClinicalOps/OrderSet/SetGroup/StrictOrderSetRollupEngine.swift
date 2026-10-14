import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict order set rollup calculation.
    protocol StrictOrderSetRollupStep {
        func describe() -> String
        func adjust(_ item: StrictOrderSetRollup, value: Double) -> Double
    }

    final class TieredStrictOrderSetRollupAdjuster: StrictOrderSetRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictOrderSetRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocaleStrictOrderSetRollupAdjuster: StrictOrderSetRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: StrictOrderSetRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentStrictOrderSetRollupAdjuster: StrictOrderSetRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictOrderSetRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StrictOrderSetRollupEndsAtOffsetAdjuster: StrictOrderSetRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: StrictOrderSetRollup, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class RoundingStrictOrderSetRollupAdjuster: StrictOrderSetRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictOrderSetRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapStrictOrderSetRollupAdjuster: StrictOrderSetRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictOrderSetRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict order set rollup steps in order and keeps a trace of each.
    final class StrictOrderSetRollupEngine {
        var steps: [any StrictOrderSetRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictOrderSetRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictOrderSetRollup) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictOrderSetRollupStep = steps[index]
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

        func evaluateAll(_ items: [StrictOrderSetRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictOrderSetRollupEngine() -> StrictOrderSetRollupEngine {
        return StrictOrderSetRollupEngine(
            steps: [
                TieredStrictOrderSetRollupAdjuster(
                    bounds: [3818.0, 6230.0, 7373.0, 9494.0],
                    rates: [1.13, 0.89, 0.81, 1.03]
                ),
                LocaleStrictOrderSetRollupAdjuster(factors: ["north": 1.3, "online": 1.26]),
                PercentStrictOrderSetRollupAdjuster(percent: -18.7),
                StrictOrderSetRollupEndsAtOffsetAdjuster(weight: 1.62),
                RoundingStrictOrderSetRollupAdjuster(step: 0.1),
                CapStrictOrderSetRollupAdjuster(cap: 22941.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 7774.4
        )
    }
}
