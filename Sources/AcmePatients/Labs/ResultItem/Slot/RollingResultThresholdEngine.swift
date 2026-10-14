import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling result threshold calculation.
    protocol RollingResultThresholdFactor {
        func describe() -> String
        func adjust(_ item: RollingResultThreshold, value: Double) -> Double
    }

    final class NameRollingResultThresholdAdjuster: RollingResultThresholdFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingResultThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingResultThresholdAdjuster: RollingResultThresholdFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingResultThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRollingResultThresholdAdjuster: RollingResultThresholdFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingResultThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRollingResultThresholdAdjuster: RollingResultThresholdFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingResultThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingResultThresholdAdjuster: RollingResultThresholdFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingResultThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRollingResultThresholdAdjuster: RollingResultThresholdFactor {
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

        func adjust(_ item: RollingResultThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling result threshold steps in order and keeps a trace of each.
    final class RollingResultThresholdEngine {
        var steps: [any RollingResultThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingResultThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingResultThreshold) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingResultThresholdFactor = steps[index]
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

        func evaluateAll(_ items: [RollingResultThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingResultThresholdEngine(_ flags: Kit.Flags.Registry) -> RollingResultThresholdEngine {
        return RollingResultThresholdEngine(
            steps: [
                NameRollingResultThresholdAdjuster(factors: ["north": 1.27]),
                TieredRollingResultThresholdAdjuster(bounds: [4839.0, 8164.0], rates: [1.04, 0.82]),
                MinimumRollingResultThresholdAdjuster(minimum: 25.4),
                PercentRollingResultThresholdAdjuster(percent: -4.8),
                CapRollingResultThresholdAdjuster(cap: 5590.0),
                FlaggedRollingResultThresholdAdjuster(
                    flags: flags,
                    flag: "rolling-result-threshold-strict",
                    percent: 10.0
                ),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 16852.7
        )
    }
}
