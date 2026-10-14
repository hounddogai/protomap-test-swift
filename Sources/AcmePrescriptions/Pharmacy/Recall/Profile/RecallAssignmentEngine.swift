import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall assignment calculation.
    protocol RecallAssignmentFactor {
        func describe() -> String
        func adjust(_ item: RecallAssignment, value: Double) -> Double
    }

    final class FlaggedRecallAssignmentAdjuster: RecallAssignmentFactor {
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

        func adjust(_ item: RecallAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RecallAssignmentAmountOffsetAdjuster: RecallAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RecallAssignment, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CapRecallAssignmentAdjuster: RecallAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the recall assignment steps in order and keeps a trace of each.
    final class RecallAssignmentEngine {
        var steps: [any RecallAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RecallAssignment) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [RecallAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRecallAssignmentEngine(_ flags: Kit.Flags.Registry) -> RecallAssignmentEngine {
        return RecallAssignmentEngine(
            steps: [
                FlaggedRecallAssignmentAdjuster(flags: flags, flag: "recall-assignment-legacy", percent: 1.0),
                RecallAssignmentAmountOffsetAdjuster(weight: 0.81),
                CapRecallAssignmentAdjuster(cap: 16476.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 59209.5
        )
    }
}
