import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled follow up group calculation.
    protocol ScheduledFollowUpGroupModifier {
        func describe() -> String
        func adjust(_ item: ScheduledFollowUpGroup, value: Double) -> Double
    }

    final class RoundingScheduledFollowUpGroupAdjuster: ScheduledFollowUpGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledFollowUpGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumScheduledFollowUpGroupAdjuster: ScheduledFollowUpGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledFollowUpGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredScheduledFollowUpGroupAdjuster: ScheduledFollowUpGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledFollowUpGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedScheduledFollowUpGroupAdjuster: ScheduledFollowUpGroupModifier {
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

        func adjust(_ item: ScheduledFollowUpGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ScheduledFollowUpGroupDiscountOffsetAdjuster: ScheduledFollowUpGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: ScheduledFollowUpGroup, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the scheduled follow up group steps in order and keeps a trace of each.
    final class ScheduledFollowUpGroupEngine {
        var steps: [any ScheduledFollowUpGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledFollowUpGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledFollowUpGroup) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledFollowUpGroupModifier = steps[index]
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

        func evaluateAll(_ items: [ScheduledFollowUpGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledFollowUpGroupEngine(_ flags: Kit.Flags.Registry) -> ScheduledFollowUpGroupEngine {
        return ScheduledFollowUpGroupEngine(
            steps: [
                RoundingScheduledFollowUpGroupAdjuster(step: 1.0),
                MinimumScheduledFollowUpGroupAdjuster(minimum: 10.7),
                TieredScheduledFollowUpGroupAdjuster(
                    bounds: [2048.0, 5177.0, 6593.0, 8143.0],
                    rates: [1.17, 0.99, 0.93, 0.9]
                ),
                FlaggedScheduledFollowUpGroupAdjuster(
                    flags: flags,
                    flag: "scheduled-follow-up-group-default",
                    percent: -5.2
                ),
                ScheduledFollowUpGroupDiscountOffsetAdjuster(weight: 1.06),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 23896.0
        )
    }
}
