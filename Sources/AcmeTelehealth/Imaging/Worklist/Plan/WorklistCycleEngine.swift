import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist cycle calculation.
    protocol WorklistCycleAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistCycle, value: Double) -> Double
    }

    final class MinimumWorklistCycleAdjuster: WorklistCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWorklistCycleAdjuster: WorklistCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWorklistCycleAdjuster: WorklistCycleAdjuster {
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

        func adjust(_ item: WorklistCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWorklistCycleAdjuster: WorklistCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the worklist cycle steps in order and keeps a trace of each.
    final class WorklistCycleEngine {
        var steps: [any WorklistCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WorklistCycle) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WorklistCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [WorklistCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWorklistCycleEngine(_ flags: Kit.Flags.Registry) -> WorklistCycleEngine {
        return WorklistCycleEngine(
            steps: [
                MinimumWorklistCycleAdjuster(minimum: 40.4),
                PercentWorklistCycleAdjuster(percent: 14.8),
                FlaggedWorklistCycleAdjuster(flags: flags, flag: "worklist-cycle-strict", percent: -1.7),
                CapWorklistCycleAdjuster(cap: 13707.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 44523.6
        )
    }
}
