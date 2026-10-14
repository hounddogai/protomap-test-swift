import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled follow up request calculation.
    protocol ScheduledFollowUpRequestStep {
        func describe() -> String
        func adjust(_ item: ScheduledFollowUpRequest, value: Double) -> Double
    }

    final class RoundingScheduledFollowUpRequestAdjuster: ScheduledFollowUpRequestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledFollowUpRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelScheduledFollowUpRequestAdjuster: ScheduledFollowUpRequestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ScheduledFollowUpRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedScheduledFollowUpRequestAdjuster: ScheduledFollowUpRequestStep {
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

        func adjust(_ item: ScheduledFollowUpRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledFollowUpRequestAdjuster: ScheduledFollowUpRequestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledFollowUpRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ScheduledFollowUpRequestAmountOffsetAdjuster: ScheduledFollowUpRequestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ScheduledFollowUpRequest, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the scheduled follow up request steps in order and keeps a trace of each.
    final class ScheduledFollowUpRequestEngine {
        var steps: [any ScheduledFollowUpRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledFollowUpRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledFollowUpRequest) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledFollowUpRequestStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledFollowUpRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledFollowUpRequestEngine(_ flags: Kit.Flags.Registry) -> ScheduledFollowUpRequestEngine {
        return ScheduledFollowUpRequestEngine(
            steps: [
                RoundingScheduledFollowUpRequestAdjuster(step: 0.05),
                LabelScheduledFollowUpRequestAdjuster(factors: ["online": 1.33, "east": 0.77]),
                FlaggedScheduledFollowUpRequestAdjuster(
                    flags: flags,
                    flag: "scheduled-follow-up-request-legacy",
                    percent: 0.7
                ),
                PercentScheduledFollowUpRequestAdjuster(percent: -19.0),
                ScheduledFollowUpRequestAmountOffsetAdjuster(weight: 0.89),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 82679.7
        )
    }
}
