import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up plan calculation.
    protocol FollowUpPlanAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpPlan, value: Double) -> Double
    }

    final class FollowUpPlanAmountOffsetAdjuster: FollowUpPlanAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: FollowUpPlan, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class RoundingFollowUpPlanAdjuster: FollowUpPlanAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFollowUpPlanAdjuster: FollowUpPlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFollowUpPlanAdjuster: FollowUpPlanAdjuster {
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

        func adjust(_ item: FollowUpPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the follow up plan steps in order and keeps a trace of each.
    final class FollowUpPlanEngine {
        var steps: [any FollowUpPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FollowUpPlan) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [FollowUpPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFollowUpPlanEngine(_ flags: Kit.Flags.Registry) -> FollowUpPlanEngine {
        return FollowUpPlanEngine(
            steps: [
                FollowUpPlanAmountOffsetAdjuster(weight: 0.29),
                RoundingFollowUpPlanAdjuster(step: 1.0),
                MinimumFollowUpPlanAdjuster(minimum: 23.0),
                FlaggedFollowUpPlanAdjuster(flags: flags, flag: "follow-up-plan-lenient", percent: -2.1),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 92462.6
        )
    }
}
