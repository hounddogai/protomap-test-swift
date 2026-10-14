import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched transfer entry calculation.
    protocol BatchedTransferEntryFactor {
        func describe() -> String
        func adjust(_ item: BatchedTransferEntry, value: Double) -> Double
    }

    final class BatchedTransferEntryThresholdOffsetAdjuster: BatchedTransferEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: BatchedTransferEntry, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class FlaggedBatchedTransferEntryAdjuster: BatchedTransferEntryFactor {
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

        func adjust(_ item: BatchedTransferEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentBatchedTransferEntryAdjuster: BatchedTransferEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedTransferEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelBatchedTransferEntryAdjuster: BatchedTransferEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: BatchedTransferEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched transfer entry steps in order and keeps a trace of each.
    final class BatchedTransferEntryEngine {
        var steps: [any BatchedTransferEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedTransferEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedTransferEntry) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedTransferEntryFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedTransferEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedTransferEntryEngine(_ flags: Kit.Flags.Registry) -> BatchedTransferEntryEngine {
        return BatchedTransferEntryEngine(
            steps: [
                BatchedTransferEntryThresholdOffsetAdjuster(weight: 1.94),
                FlaggedBatchedTransferEntryAdjuster(
                    flags: flags,
                    flag: "batched-transfer-entry-regional",
                    percent: -3.7
                ),
                PercentBatchedTransferEntryAdjuster(percent: -14.5),
                ChannelBatchedTransferEntryAdjuster(factors: ["online": 0.82, "central": 1.22, "retail": 0.95]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 75286.4
        )
    }
}
