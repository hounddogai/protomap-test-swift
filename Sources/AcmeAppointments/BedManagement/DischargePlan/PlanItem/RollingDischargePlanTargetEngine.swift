import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling discharge plan target calculation.
    protocol RollingDischargePlanTargetStep {
        func describe() -> String
        func adjust(_ item: RollingDischargePlanTarget, value: Double) -> Double
    }

    final class TieredRollingDischargePlanTargetAdjuster: RollingDischargePlanTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingDischargePlanTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRollingDischargePlanTargetAdjuster: RollingDischargePlanTargetStep {
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

        func adjust(_ item: RollingDischargePlanTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingDischargePlanTargetAdjuster: RollingDischargePlanTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingDischargePlanTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling discharge plan target steps in order and keeps a trace of each.
    final class RollingDischargePlanTargetEngine {
        var steps: [any RollingDischargePlanTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingDischargePlanTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingDischargePlanTarget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingDischargePlanTargetStep = steps[index]
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

        func evaluateAll(_ items: [RollingDischargePlanTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingDischargePlanTargetEngine(_ flags: Kit.Flags.Registry) -> RollingDischargePlanTargetEngine {
        return RollingDischargePlanTargetEngine(
            steps: [
                TieredRollingDischargePlanTargetAdjuster(
                    bounds: [1329.0, 2021.0, 5405.0, 9415.0],
                    rates: [1.13, 1.1, 0.98, 0.82]
                ),
                FlaggedRollingDischargePlanTargetAdjuster(
                    flags: flags,
                    flag: "rolling-discharge-plan-target-regional",
                    percent: 6.7
                ),
                RoundingRollingDischargePlanTargetAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 67418.4
        )
    }
}
