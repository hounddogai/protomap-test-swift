import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled priority allocation calculation.
    protocol ScheduledPriorityAllocationFactor {
        func describe() -> String
        func adjust(_ item: ScheduledPriorityAllocation, value: Double) -> Double
    }

    final class FlaggedScheduledPriorityAllocationAdjuster: ScheduledPriorityAllocationFactor {
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

        func adjust(_ item: ScheduledPriorityAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledPriorityAllocationAdjuster: ScheduledPriorityAllocationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledPriorityAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentScheduledPriorityAllocationAdjuster: ScheduledPriorityAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledPriorityAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled priority allocation steps in order and keeps a trace of each.
    final class ScheduledPriorityAllocationEngine {
        var steps: [any ScheduledPriorityAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledPriorityAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledPriorityAllocation) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledPriorityAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledPriorityAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledPriorityAllocationEngine(_ flags: Kit.Flags.Registry) -> ScheduledPriorityAllocationEngine {
        return ScheduledPriorityAllocationEngine(
            steps: [
                FlaggedScheduledPriorityAllocationAdjuster(
                    flags: flags,
                    flag: "scheduled-priority-allocation-manual",
                    percent: -5.5
                ),
                CapScheduledPriorityAllocationAdjuster(cap: 25989.0),
                PercentScheduledPriorityAllocationAdjuster(percent: 12.6),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 58627.9
        )
    }
}
