import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched dispense override calculation.
    protocol BatchedDispenseOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedDispenseOverride, value: Double) -> Double
    }

    final class BatchedDispenseOverrideDosageMgOffsetAdjuster: BatchedDispenseOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: BatchedDispenseOverride, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class NameBatchedDispenseOverrideAdjuster: BatchedDispenseOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BatchedDispenseOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapBatchedDispenseOverrideAdjuster: BatchedDispenseOverrideAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedDispenseOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedDispenseOverrideAdjuster: BatchedDispenseOverrideAdjuster {
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

        func adjust(_ item: BatchedDispenseOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched dispense override steps in order and keeps a trace of each.
    final class BatchedDispenseOverrideEngine {
        var steps: [any BatchedDispenseOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDispenseOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedDispenseOverride) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedDispenseOverrideAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedDispenseOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedDispenseOverrideEngine(_ flags: Kit.Flags.Registry) -> BatchedDispenseOverrideEngine {
        return BatchedDispenseOverrideEngine(
            steps: [
                BatchedDispenseOverrideDosageMgOffsetAdjuster(weight: 0.87),
                NameBatchedDispenseOverrideAdjuster(factors: ["east": 1.17]),
                CapBatchedDispenseOverrideAdjuster(cap: 30563.0),
                FlaggedBatchedDispenseOverrideAdjuster(
                    flags: flags,
                    flag: "batched-dispense-override-global",
                    percent: 3.4
                ),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 67102.1
        )
    }
}
