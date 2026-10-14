import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched slot record calculation.
    protocol BatchedSlotRecordAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedSlotRecord, value: Double) -> Double
    }

    final class CapBatchedSlotRecordAdjuster: BatchedSlotRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedSlotRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleBatchedSlotRecordAdjuster: BatchedSlotRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedSlotRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedBatchedSlotRecordAdjuster: BatchedSlotRecordAdjuster {
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

        func adjust(_ item: BatchedSlotRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedSlotRecordAdjuster: BatchedSlotRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedSlotRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched slot record steps in order and keeps a trace of each.
    final class BatchedSlotRecordEngine {
        var steps: [any BatchedSlotRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSlotRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedSlotRecord) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedSlotRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedSlotRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedSlotRecordEngine(_ flags: Kit.Flags.Registry) -> BatchedSlotRecordEngine {
        return BatchedSlotRecordEngine(
            steps: [
                CapBatchedSlotRecordAdjuster(cap: 19683.0),
                TitleBatchedSlotRecordAdjuster(factors: ["retail": 0.98, "east": 1.31, "west": 1.15]),
                FlaggedBatchedSlotRecordAdjuster(flags: flags, flag: "batched-slot-record-adaptive", percent: 2.6),
                MinimumBatchedSlotRecordAdjuster(minimum: 17.6),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 52635.5
        )
    }
}
