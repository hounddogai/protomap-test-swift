import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback order set batch calculation.
    protocol FallbackOrderSetBatchStep {
        func describe() -> String
        func adjust(_ item: FallbackOrderSetBatch, value: Double) -> Double
    }

    final class RoundingFallbackOrderSetBatchAdjuster: FallbackOrderSetBatchStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackOrderSetBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFallbackOrderSetBatchAdjuster: FallbackOrderSetBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackOrderSetBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelFallbackOrderSetBatchAdjuster: FallbackOrderSetBatchStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FallbackOrderSetBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapFallbackOrderSetBatchAdjuster: FallbackOrderSetBatchStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackOrderSetBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackOrderSetBatchAdjuster: FallbackOrderSetBatchStep {
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

        func adjust(_ item: FallbackOrderSetBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback order set batch steps in order and keeps a trace of each.
    final class FallbackOrderSetBatchEngine {
        var steps: [any FallbackOrderSetBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackOrderSetBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackOrderSetBatch) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackOrderSetBatchStep = steps[index]
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

        func evaluateAll(_ items: [FallbackOrderSetBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackOrderSetBatchEngine(_ flags: Kit.Flags.Registry) -> FallbackOrderSetBatchEngine {
        return FallbackOrderSetBatchEngine(
            steps: [
                RoundingFallbackOrderSetBatchAdjuster(step: 5.0),
                PercentFallbackOrderSetBatchAdjuster(percent: 18.6),
                LabelFallbackOrderSetBatchAdjuster(factors: ["north": 1.18]),
                CapFallbackOrderSetBatchAdjuster(cap: 10650.0),
                FlaggedFallbackOrderSetBatchAdjuster(
                    flags: flags,
                    flag: "fallback-order-set-batch-manual",
                    percent: 2.0
                ),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 26008.4
        )
    }
}
