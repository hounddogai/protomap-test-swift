import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default task record calculation.
    protocol DefaultTaskRecordFactor {
        func describe() -> String
        func adjust(_ item: DefaultTaskRecord, value: Double) -> Double
    }

    final class CapDefaultTaskRecordAdjuster: DefaultTaskRecordFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultTaskRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDefaultTaskRecordAdjuster: DefaultTaskRecordFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultTaskRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDefaultTaskRecordAdjuster: DefaultTaskRecordFactor {
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

        func adjust(_ item: DefaultTaskRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultTaskRecordGraceDaysOffsetAdjuster: DefaultTaskRecordFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: DefaultTaskRecord, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the default task record steps in order and keeps a trace of each.
    final class DefaultTaskRecordEngine {
        var steps: [any DefaultTaskRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultTaskRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultTaskRecord) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultTaskRecordFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultTaskRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultTaskRecordEngine(_ flags: Kit.Flags.Registry) -> DefaultTaskRecordEngine {
        return DefaultTaskRecordEngine(
            steps: [
                CapDefaultTaskRecordAdjuster(cap: 16821.0),
                RoundingDefaultTaskRecordAdjuster(step: 0.05),
                FlaggedDefaultTaskRecordAdjuster(flags: flags, flag: "default-task-record-adaptive", percent: -0.5),
                DefaultTaskRecordGraceDaysOffsetAdjuster(weight: 1.66),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 15128.2
        )
    }
}
