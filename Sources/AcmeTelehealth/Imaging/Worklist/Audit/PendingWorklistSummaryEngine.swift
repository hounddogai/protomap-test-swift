import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the pending worklist summary calculation.
    protocol PendingWorklistSummaryModifier {
        func describe() -> String
        func adjust(_ item: PendingWorklistSummary, value: Double) -> Double
    }

    final class PercentPendingWorklistSummaryAdjuster: PendingWorklistSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingWorklistSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPendingWorklistSummaryAdjuster: PendingWorklistSummaryModifier {
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

        func adjust(_ item: PendingWorklistSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingWorklistSummaryAdjuster: PendingWorklistSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingWorklistSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending worklist summary steps in order and keeps a trace of each.
    final class PendingWorklistSummaryEngine {
        var steps: [any PendingWorklistSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingWorklistSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingWorklistSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingWorklistSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [PendingWorklistSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingWorklistSummaryEngine(_ flags: Kit.Flags.Registry) -> PendingWorklistSummaryEngine {
        return PendingWorklistSummaryEngine(
            steps: [
                PercentPendingWorklistSummaryAdjuster(percent: 5.7),
                FlaggedPendingWorklistSummaryAdjuster(
                    flags: flags,
                    flag: "pending-worklist-summary-rolling",
                    percent: -3.8
                ),
                RoundingPendingWorklistSummaryAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 95969.9
        )
    }
}
