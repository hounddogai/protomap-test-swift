import AcmePlatform
import Foundation

extension Labs {
    /// One step of the batched reference range record calculation.
    protocol BatchedReferenceRangeRecordAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedReferenceRangeRecord, value: Double) -> Double
    }

    final class PercentBatchedReferenceRangeRecordAdjuster: BatchedReferenceRangeRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedReferenceRangeRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedReferenceRangeRecordAdjuster: BatchedReferenceRangeRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedReferenceRangeRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapBatchedReferenceRangeRecordAdjuster: BatchedReferenceRangeRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedReferenceRangeRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedReferenceRangeRecordAdjuster: BatchedReferenceRangeRecordAdjuster {
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

        func adjust(_ item: BatchedReferenceRangeRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched reference range record steps in order and keeps a trace of each.
    final class BatchedReferenceRangeRecordEngine {
        var steps: [any BatchedReferenceRangeRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedReferenceRangeRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedReferenceRangeRecord) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedReferenceRangeRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedReferenceRangeRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedReferenceRangeRecordEngine(_ flags: Kit.Flags.Registry) -> BatchedReferenceRangeRecordEngine {
        return BatchedReferenceRangeRecordEngine(
            steps: [
                PercentBatchedReferenceRangeRecordAdjuster(percent: -17.4),
                RoundingBatchedReferenceRangeRecordAdjuster(step: 0.25),
                CapBatchedReferenceRangeRecordAdjuster(cap: 49520.0),
                FlaggedBatchedReferenceRangeRecordAdjuster(
                    flags: flags,
                    flag: "batched-reference-range-record-batched",
                    percent: 7.3
                ),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 62117.8
        )
    }
}
