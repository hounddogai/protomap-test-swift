import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled study policy calculation.
    protocol ScheduledStudyPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledStudyPolicy, value: Double) -> Double
    }

    final class FlaggedScheduledStudyPolicyAdjuster: ScheduledStudyPolicyAdjuster {
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

        func adjust(_ item: ScheduledStudyPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledStudyPolicyAdjuster: ScheduledStudyPolicyAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledStudyPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentScheduledStudyPolicyAdjuster: ScheduledStudyPolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledStudyPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled study policy steps in order and keeps a trace of each.
    final class ScheduledStudyPolicyEngine {
        var steps: [any ScheduledStudyPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledStudyPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledStudyPolicy) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledStudyPolicyAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledStudyPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledStudyPolicyEngine(_ flags: Kit.Flags.Registry) -> ScheduledStudyPolicyEngine {
        return ScheduledStudyPolicyEngine(
            steps: [
                FlaggedScheduledStudyPolicyAdjuster(
                    flags: flags,
                    flag: "scheduled-study-policy-default",
                    percent: 5.1
                ),
                CapScheduledStudyPolicyAdjuster(cap: 19642.0),
                PercentScheduledStudyPolicyAdjuster(percent: 2.1),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 5969.7
        )
    }
}
