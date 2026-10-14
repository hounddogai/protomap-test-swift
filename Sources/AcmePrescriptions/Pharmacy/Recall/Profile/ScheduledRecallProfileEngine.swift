import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the scheduled recall profile calculation.
    protocol ScheduledRecallProfileModifier {
        func describe() -> String
        func adjust(_ item: ScheduledRecallProfile, value: Double) -> Double
    }

    final class MinimumScheduledRecallProfileAdjuster: ScheduledRecallProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledRecallProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledRecallProfileAdjuster: ScheduledRecallProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledRecallProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedScheduledRecallProfileAdjuster: ScheduledRecallProfileModifier {
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

        func adjust(_ item: ScheduledRecallProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledRecallProfileAdjuster: ScheduledRecallProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledRecallProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled recall profile steps in order and keeps a trace of each.
    final class ScheduledRecallProfileEngine {
        var steps: [any ScheduledRecallProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledRecallProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledRecallProfile) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledRecallProfileModifier = steps[index]
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

        func evaluateAll(_ items: [ScheduledRecallProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledRecallProfileEngine(_ flags: Kit.Flags.Registry) -> ScheduledRecallProfileEngine {
        return ScheduledRecallProfileEngine(
            steps: [
                MinimumScheduledRecallProfileAdjuster(minimum: 44.7),
                CapScheduledRecallProfileAdjuster(cap: 42690.0),
                FlaggedScheduledRecallProfileAdjuster(
                    flags: flags,
                    flag: "scheduled-recall-profile-rolling",
                    percent: -6.1
                ),
                PercentScheduledRecallProfileAdjuster(percent: 20.6),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 87172.9
        )
    }
}
