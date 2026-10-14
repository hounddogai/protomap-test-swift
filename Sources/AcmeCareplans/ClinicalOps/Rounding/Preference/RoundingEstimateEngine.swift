import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding estimate calculation.
    protocol RoundingEstimateStep {
        func describe() -> String
        func adjust(_ item: RoundingEstimate, value: Double) -> Double
    }

    final class NameRoundingEstimateAdjuster: RoundingEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RoundingEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRoundingEstimateAdjuster: RoundingEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRoundingEstimateAdjuster: RoundingEstimateStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: RoundingEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRoundingEstimateAdjuster: RoundingEstimateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRoundingEstimateAdjuster: RoundingEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRoundingEstimateAdjuster: RoundingEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rounding estimate steps in order and keeps a trace of each.
    final class RoundingEstimateEngine {
        var steps: [any RoundingEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RoundingEstimate) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingEstimateStep = steps[index]
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

        func evaluateAll(_ items: [RoundingEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRoundingEstimateEngine(_ flags: Kit.Flags.Registry) -> RoundingEstimateEngine {
        return RoundingEstimateEngine(
            steps: [
                NameRoundingEstimateAdjuster(factors: ["retail": 0.7, "online": 0.75]),
                TieredRoundingEstimateAdjuster(bounds: [3594.0, 4535.0, 8840.0], rates: [1.12, 0.91, 0.93]),
                FlaggedRoundingEstimateAdjuster(flags: flags, flag: "rounding-estimate-strict", percent: 8.2),
                RoundingRoundingEstimateAdjuster(step: 5.0),
                CapRoundingEstimateAdjuster(cap: 39252.0),
                MinimumRoundingEstimateAdjuster(minimum: 17.8),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 93722.8
        )
    }
}
