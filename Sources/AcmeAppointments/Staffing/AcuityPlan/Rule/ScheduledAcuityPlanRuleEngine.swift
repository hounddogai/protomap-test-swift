import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the scheduled acuity plan rule calculation.
    protocol ScheduledAcuityPlanRuleStep {
        func describe() -> String
        func adjust(_ item: ScheduledAcuityPlanRule, value: Double) -> Double
    }

    final class MinimumScheduledAcuityPlanRuleAdjuster: ScheduledAcuityPlanRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledAcuityPlanRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ScheduledAcuityPlanRuleCostOffsetAdjuster: ScheduledAcuityPlanRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ScheduledAcuityPlanRule, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class RoundingScheduledAcuityPlanRuleAdjuster: ScheduledAcuityPlanRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledAcuityPlanRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedScheduledAcuityPlanRuleAdjuster: ScheduledAcuityPlanRuleStep {
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

        func adjust(_ item: ScheduledAcuityPlanRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled acuity plan rule steps in order and keeps a trace of each.
    final class ScheduledAcuityPlanRuleEngine {
        var steps: [any ScheduledAcuityPlanRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAcuityPlanRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledAcuityPlanRule) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledAcuityPlanRuleStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledAcuityPlanRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledAcuityPlanRuleEngine(_ flags: Kit.Flags.Registry) -> ScheduledAcuityPlanRuleEngine {
        return ScheduledAcuityPlanRuleEngine(
            steps: [
                MinimumScheduledAcuityPlanRuleAdjuster(minimum: 2.3),
                ScheduledAcuityPlanRuleCostOffsetAdjuster(weight: 0.15),
                RoundingScheduledAcuityPlanRuleAdjuster(step: 5.0),
                FlaggedScheduledAcuityPlanRuleAdjuster(
                    flags: flags,
                    flag: "scheduled-acuity-plan-rule-pending",
                    percent: 4.0
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 40009.4
        )
    }
}
