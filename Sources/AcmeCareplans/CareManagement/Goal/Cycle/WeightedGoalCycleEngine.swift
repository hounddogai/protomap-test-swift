import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted goal cycle calculation.
    protocol WeightedGoalCycleFactor {
        func describe() -> String
        func adjust(_ item: WeightedGoalCycle, value: Double) -> Double
    }

    final class PercentWeightedGoalCycleAdjuster: WeightedGoalCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedGoalCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWeightedGoalCycleAdjuster: WeightedGoalCycleFactor {
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

        func adjust(_ item: WeightedGoalCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedGoalCycleAdjuster: WeightedGoalCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedGoalCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingWeightedGoalCycleAdjuster: WeightedGoalCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedGoalCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredWeightedGoalCycleAdjuster: WeightedGoalCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedGoalCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted goal cycle steps in order and keeps a trace of each.
    final class WeightedGoalCycleEngine {
        var steps: [any WeightedGoalCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedGoalCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedGoalCycle) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedGoalCycleFactor = steps[index]
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

        func evaluateAll(_ items: [WeightedGoalCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedGoalCycleEngine(_ flags: Kit.Flags.Registry) -> WeightedGoalCycleEngine {
        return WeightedGoalCycleEngine(
            steps: [
                PercentWeightedGoalCycleAdjuster(percent: 10.3),
                FlaggedWeightedGoalCycleAdjuster(flags: flags, flag: "weighted-goal-cycle-fallback", percent: -7.1),
                MinimumWeightedGoalCycleAdjuster(minimum: 0.1),
                RoundingWeightedGoalCycleAdjuster(step: 0.05),
                TieredWeightedGoalCycleAdjuster(bounds: [8002.0, 8173.0], rates: [0.86, 0.87]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 73268.8
        )
    }
}
