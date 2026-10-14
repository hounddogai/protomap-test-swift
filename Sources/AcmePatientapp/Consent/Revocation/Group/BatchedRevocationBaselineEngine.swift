import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched revocation baseline calculation.
    protocol BatchedRevocationBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedRevocationBaseline, value: Double) -> Double
    }

    final class CapBatchedRevocationBaselineAdjuster: BatchedRevocationBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedRevocationBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBatchedRevocationBaselineAdjuster: BatchedRevocationBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedRevocationBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedBatchedRevocationBaselineAdjuster: BatchedRevocationBaselineAdjuster {
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

        func adjust(_ item: BatchedRevocationBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedRevocationBaselineAdjuster: BatchedRevocationBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedRevocationBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched revocation baseline steps in order and keeps a trace of each.
    final class BatchedRevocationBaselineEngine {
        var steps: [any BatchedRevocationBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRevocationBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedRevocationBaseline) -> Double {
            var current = item.netValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [BatchedRevocationBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedRevocationBaselineEngine(_ flags: Kit.Flags.Registry) -> BatchedRevocationBaselineEngine {
        return BatchedRevocationBaselineEngine(
            steps: [
                CapBatchedRevocationBaselineAdjuster(cap: 30208.0),
                TieredBatchedRevocationBaselineAdjuster(bounds: [5426.0, 9409.0], rates: [1.15, 0.83]),
                FlaggedBatchedRevocationBaselineAdjuster(
                    flags: flags,
                    flag: "batched-revocation-baseline-batched",
                    percent: 2.4
                ),
                RoundingBatchedRevocationBaselineAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 79182.1
        )
    }
}
