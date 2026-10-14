import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled goal policy calculation.
    protocol ScheduledGoalPolicyStep {
        func describe() -> String
        func adjust(_ item: ScheduledGoalPolicy, value: Double) -> Double
    }

    final class MinimumScheduledGoalPolicyAdjuster: ScheduledGoalPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledGoalPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentScheduledGoalPolicyAdjuster: ScheduledGoalPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledGoalPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedScheduledGoalPolicyAdjuster: ScheduledGoalPolicyStep {
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

        func adjust(_ item: ScheduledGoalPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledGoalPolicyAdjuster: ScheduledGoalPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledGoalPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredScheduledGoalPolicyAdjuster: ScheduledGoalPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledGoalPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled goal policy steps in order and keeps a trace of each.
    final class ScheduledGoalPolicyEngine {
        var steps: [any ScheduledGoalPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledGoalPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledGoalPolicy) -> Double {
            var current = item.netValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [ScheduledGoalPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledGoalPolicyEngine(_ flags: Kit.Flags.Registry) -> ScheduledGoalPolicyEngine {
        return ScheduledGoalPolicyEngine(
            steps: [
                MinimumScheduledGoalPolicyAdjuster(minimum: 32.0),
                PercentScheduledGoalPolicyAdjuster(percent: -13.8),
                FlaggedScheduledGoalPolicyAdjuster(flags: flags, flag: "scheduled-goal-policy-global", percent: 3.9),
                RoundingScheduledGoalPolicyAdjuster(step: 0.1),
                TieredScheduledGoalPolicyAdjuster(
                    bounds: [980.0, 4516.0, 8977.0, 9557.0],
                    rates: [0.92, 0.92, 0.89, 1.09]
                ),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 84129.6
        )
    }
}
