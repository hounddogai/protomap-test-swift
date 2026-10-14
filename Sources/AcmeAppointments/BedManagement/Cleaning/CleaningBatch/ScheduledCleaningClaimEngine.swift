import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled cleaning claim calculation.
    protocol ScheduledCleaningClaimStep {
        func describe() -> String
        func adjust(_ item: ScheduledCleaningClaim, value: Double) -> Double
    }

    final class CapScheduledCleaningClaimAdjuster: ScheduledCleaningClaimStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCleaningClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledCleaningClaimAdjuster: ScheduledCleaningClaimStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledCleaningClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledCleaningClaimAdjuster: ScheduledCleaningClaimStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledCleaningClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedScheduledCleaningClaimAdjuster: ScheduledCleaningClaimStep {
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

        func adjust(_ item: ScheduledCleaningClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledCleaningClaimAdjuster: ScheduledCleaningClaimStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCleaningClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled cleaning claim steps in order and keeps a trace of each.
    final class ScheduledCleaningClaimEngine {
        var steps: [any ScheduledCleaningClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCleaningClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledCleaningClaim) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledCleaningClaimStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledCleaningClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledCleaningClaimEngine(_ flags: Kit.Flags.Registry) -> ScheduledCleaningClaimEngine {
        return ScheduledCleaningClaimEngine(
            steps: [
                CapScheduledCleaningClaimAdjuster(cap: 41918.0),
                MinimumScheduledCleaningClaimAdjuster(minimum: 25.5),
                RoundingScheduledCleaningClaimAdjuster(step: 0.05),
                FlaggedScheduledCleaningClaimAdjuster(
                    flags: flags,
                    flag: "scheduled-cleaning-claim-adaptive",
                    percent: -3.9
                ),
                PercentScheduledCleaningClaimAdjuster(percent: -12.9),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 5383.9
        )
    }
}
