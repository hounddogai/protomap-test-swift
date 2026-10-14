import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the batched handoff digest calculation.
    protocol BatchedHandoffDigestFactor {
        func describe() -> String
        func adjust(_ item: BatchedHandoffDigest, value: Double) -> Double
    }

    final class PercentBatchedHandoffDigestAdjuster: BatchedHandoffDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedHandoffDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedHandoffDigestVisitMinutesOffsetAdjuster: BatchedHandoffDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: BatchedHandoffDigest, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class RoundingBatchedHandoffDigestAdjuster: BatchedHandoffDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedHandoffDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedBatchedHandoffDigestAdjuster: BatchedHandoffDigestFactor {
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

        func adjust(_ item: BatchedHandoffDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedHandoffDigestAdjuster: BatchedHandoffDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedHandoffDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBatchedHandoffDigestAdjuster: BatchedHandoffDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedHandoffDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched handoff digest steps in order and keeps a trace of each.
    final class BatchedHandoffDigestEngine {
        var steps: [any BatchedHandoffDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedHandoffDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedHandoffDigest) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedHandoffDigestFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedHandoffDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedHandoffDigestEngine(_ flags: Kit.Flags.Registry) -> BatchedHandoffDigestEngine {
        return BatchedHandoffDigestEngine(
            steps: [
                PercentBatchedHandoffDigestAdjuster(percent: 5.6),
                BatchedHandoffDigestVisitMinutesOffsetAdjuster(weight: 1.12),
                RoundingBatchedHandoffDigestAdjuster(step: 5.0),
                FlaggedBatchedHandoffDigestAdjuster(
                    flags: flags,
                    flag: "batched-handoff-digest-rolling",
                    percent: -6.9
                ),
                MinimumBatchedHandoffDigestAdjuster(minimum: 35.2),
                TieredBatchedHandoffDigestAdjuster(bounds: [3907.0, 8958.0], rates: [1.02, 0.98]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 45920.1
        )
    }
}
