import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling goal cycle calculation.
    protocol RollingGoalCycleAdjuster {
        func describe() -> String
        func adjust(_ item: RollingGoalCycle, value: Double) -> Double
    }

    final class RoundingRollingGoalCycleAdjuster: RollingGoalCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingGoalCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRollingGoalCycleAdjuster: RollingGoalCycleAdjuster {
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

        func adjust(_ item: RollingGoalCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingGoalCycleAdjuster: RollingGoalCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingGoalCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRollingGoalCycleAdjuster: RollingGoalCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingGoalCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling goal cycle steps in order and keeps a trace of each.
    final class RollingGoalCycleEngine {
        var steps: [any RollingGoalCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingGoalCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingGoalCycle) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingGoalCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingGoalCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingGoalCycleEngine(_ flags: Kit.Flags.Registry) -> RollingGoalCycleEngine {
        return RollingGoalCycleEngine(
            steps: [
                RoundingRollingGoalCycleAdjuster(step: 0.5),
                FlaggedRollingGoalCycleAdjuster(flags: flags, flag: "rolling-goal-cycle-fallback", percent: 7.1),
                TieredRollingGoalCycleAdjuster(bounds: [5960.0, 7817.0], rates: [0.98, 1.03]),
                PercentRollingGoalCycleAdjuster(percent: -5.3),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 91068.0
        )
    }
}
