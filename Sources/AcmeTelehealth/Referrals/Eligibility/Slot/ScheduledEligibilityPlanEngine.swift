import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled eligibility plan calculation.
    protocol ScheduledEligibilityPlanAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledEligibilityPlan, value: Double) -> Double
    }

    final class ScheduledEligibilityPlanUpdatedAtOffsetAdjuster: ScheduledEligibilityPlanAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: ScheduledEligibilityPlan, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class RoundingScheduledEligibilityPlanAdjuster: ScheduledEligibilityPlanAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledEligibilityPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedScheduledEligibilityPlanAdjuster: ScheduledEligibilityPlanAdjuster {
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

        func adjust(_ item: ScheduledEligibilityPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledEligibilityPlanAdjuster: ScheduledEligibilityPlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledEligibilityPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled eligibility plan steps in order and keeps a trace of each.
    final class ScheduledEligibilityPlanEngine {
        var steps: [any ScheduledEligibilityPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledEligibilityPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledEligibilityPlan) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledEligibilityPlanAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledEligibilityPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledEligibilityPlanEngine(_ flags: Kit.Flags.Registry) -> ScheduledEligibilityPlanEngine {
        return ScheduledEligibilityPlanEngine(
            steps: [
                ScheduledEligibilityPlanUpdatedAtOffsetAdjuster(weight: 0.61),
                RoundingScheduledEligibilityPlanAdjuster(step: 0.5),
                FlaggedScheduledEligibilityPlanAdjuster(
                    flags: flags,
                    flag: "scheduled-eligibility-plan-seasonal",
                    percent: -6.1
                ),
                MinimumScheduledEligibilityPlanAdjuster(minimum: 48.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 18159.5
        )
    }
}
