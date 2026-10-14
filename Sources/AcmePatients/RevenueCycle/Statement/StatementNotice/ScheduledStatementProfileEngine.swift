import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the scheduled statement profile calculation.
    protocol ScheduledStatementProfileAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledStatementProfile, value: Double) -> Double
    }

    final class ScheduledStatementProfileRateOffsetAdjuster: ScheduledStatementProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ScheduledStatementProfile, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class FlaggedScheduledStatementProfileAdjuster: ScheduledStatementProfileAdjuster {
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

        func adjust(_ item: ScheduledStatementProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledStatementProfileAdjuster: ScheduledStatementProfileAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledStatementProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled statement profile steps in order and keeps a trace of each.
    final class ScheduledStatementProfileEngine {
        var steps: [any ScheduledStatementProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledStatementProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledStatementProfile) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledStatementProfileAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledStatementProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledStatementProfileEngine(_ flags: Kit.Flags.Registry) -> ScheduledStatementProfileEngine {
        return ScheduledStatementProfileEngine(
            steps: [
                ScheduledStatementProfileRateOffsetAdjuster(weight: 1.19),
                FlaggedScheduledStatementProfileAdjuster(
                    flags: flags,
                    flag: "scheduled-statement-profile-rolling",
                    percent: -3.0
                ),
                RoundingScheduledStatementProfileAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 90039.7
        )
    }
}
