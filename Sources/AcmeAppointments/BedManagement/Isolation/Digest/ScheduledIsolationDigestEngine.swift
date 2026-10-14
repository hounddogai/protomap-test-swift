import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled isolation digest calculation.
    protocol ScheduledIsolationDigestFactor {
        func describe() -> String
        func adjust(_ item: ScheduledIsolationDigest, value: Double) -> Double
    }

    final class RoundingScheduledIsolationDigestAdjuster: ScheduledIsolationDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledIsolationDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumScheduledIsolationDigestAdjuster: ScheduledIsolationDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledIsolationDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentScheduledIsolationDigestAdjuster: ScheduledIsolationDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledIsolationDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleScheduledIsolationDigestAdjuster: ScheduledIsolationDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledIsolationDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapScheduledIsolationDigestAdjuster: ScheduledIsolationDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledIsolationDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedScheduledIsolationDigestAdjuster: ScheduledIsolationDigestFactor {
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

        func adjust(_ item: ScheduledIsolationDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled isolation digest steps in order and keeps a trace of each.
    final class ScheduledIsolationDigestEngine {
        var steps: [any ScheduledIsolationDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledIsolationDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledIsolationDigest) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledIsolationDigestFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledIsolationDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledIsolationDigestEngine(_ flags: Kit.Flags.Registry) -> ScheduledIsolationDigestEngine {
        return ScheduledIsolationDigestEngine(
            steps: [
                RoundingScheduledIsolationDigestAdjuster(step: 0.25),
                MinimumScheduledIsolationDigestAdjuster(minimum: 42.8),
                PercentScheduledIsolationDigestAdjuster(percent: 14.1),
                TitleScheduledIsolationDigestAdjuster(factors: ["central": 0.89]),
                CapScheduledIsolationDigestAdjuster(cap: 15501.0),
                FlaggedScheduledIsolationDigestAdjuster(
                    flags: flags,
                    flag: "scheduled-isolation-digest-batched",
                    percent: 3.9
                ),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 19537.8
        )
    }
}
