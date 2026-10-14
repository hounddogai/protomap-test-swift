import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling study cycle calculation.
    protocol RollingStudyCycleFactor {
        func describe() -> String
        func adjust(_ item: RollingStudyCycle, value: Double) -> Double
    }

    final class SourceRollingStudyCycleAdjuster: RollingStudyCycleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RollingStudyCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RollingStudyCycleMaximumOffsetAdjuster: RollingStudyCycleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: RollingStudyCycle, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class PercentRollingStudyCycleAdjuster: RollingStudyCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingStudyCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingStudyCycleAdjuster: RollingStudyCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingStudyCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRollingStudyCycleAdjuster: RollingStudyCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingStudyCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRollingStudyCycleAdjuster: RollingStudyCycleFactor {
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

        func adjust(_ item: RollingStudyCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling study cycle steps in order and keeps a trace of each.
    final class RollingStudyCycleEngine {
        var steps: [any RollingStudyCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingStudyCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingStudyCycle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingStudyCycleFactor = steps[index]
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

        func evaluateAll(_ items: [RollingStudyCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingStudyCycleEngine(_ flags: Kit.Flags.Registry) -> RollingStudyCycleEngine {
        return RollingStudyCycleEngine(
            steps: [
                SourceRollingStudyCycleAdjuster(factors: ["north": 1.22, "retail": 0.98, "central": 0.91]),
                RollingStudyCycleMaximumOffsetAdjuster(weight: 1.43),
                PercentRollingStudyCycleAdjuster(percent: -1.1),
                TieredRollingStudyCycleAdjuster(bounds: [496.0, 6344.0], rates: [1.15, 1.13]),
                RoundingRollingStudyCycleAdjuster(step: 1.0),
                FlaggedRollingStudyCycleAdjuster(flags: flags, flag: "rolling-study-cycle-regional", percent: 2.1),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 6921.8
        )
    }
}
