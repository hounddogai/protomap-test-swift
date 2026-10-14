import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled reference range baseline calculation.
    protocol ScheduledReferenceRangeBaselineFactor {
        func describe() -> String
        func adjust(_ item: ScheduledReferenceRangeBaseline, value: Double) -> Double
    }

    final class CapScheduledReferenceRangeBaselineAdjuster: ScheduledReferenceRangeBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledReferenceRangeBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledReferenceRangeBaselineAdjuster: ScheduledReferenceRangeBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledReferenceRangeBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedScheduledReferenceRangeBaselineAdjuster: ScheduledReferenceRangeBaselineFactor {
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

        func adjust(_ item: ScheduledReferenceRangeBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled reference range baseline steps in order and keeps a trace of each.
    final class ScheduledReferenceRangeBaselineEngine {
        var steps: [any ScheduledReferenceRangeBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledReferenceRangeBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledReferenceRangeBaseline) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledReferenceRangeBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledReferenceRangeBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledReferenceRangeBaselineEngine(_ flags: Kit.Flags.Registry) -> ScheduledReferenceRangeBaselineEngine {
        return ScheduledReferenceRangeBaselineEngine(
            steps: [
                CapScheduledReferenceRangeBaselineAdjuster(cap: 4994.0),
                MinimumScheduledReferenceRangeBaselineAdjuster(minimum: 0.9),
                FlaggedScheduledReferenceRangeBaselineAdjuster(
                    flags: flags,
                    flag: "scheduled-reference-range-baseline-manual",
                    percent: -7.9
                ),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 83296.0
        )
    }
}
