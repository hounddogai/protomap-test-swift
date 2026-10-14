import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched remittance target calculation.
    protocol BatchedRemittanceTargetFactor {
        func describe() -> String
        func adjust(_ item: BatchedRemittanceTarget, value: Double) -> Double
    }

    final class CapBatchedRemittanceTargetAdjuster: BatchedRemittanceTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedRemittanceTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentBatchedRemittanceTargetAdjuster: BatchedRemittanceTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedRemittanceTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredBatchedRemittanceTargetAdjuster: BatchedRemittanceTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedRemittanceTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedBatchedRemittanceTargetAdjuster: BatchedRemittanceTargetFactor {
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

        func adjust(_ item: BatchedRemittanceTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched remittance target steps in order and keeps a trace of each.
    final class BatchedRemittanceTargetEngine {
        var steps: [any BatchedRemittanceTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRemittanceTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedRemittanceTarget) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedRemittanceTargetFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedRemittanceTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedRemittanceTargetEngine(_ flags: Kit.Flags.Registry) -> BatchedRemittanceTargetEngine {
        return BatchedRemittanceTargetEngine(
            steps: [
                CapBatchedRemittanceTargetAdjuster(cap: 1289.0),
                PercentBatchedRemittanceTargetAdjuster(percent: 24.5),
                TieredBatchedRemittanceTargetAdjuster(bounds: [2249.0, 3291.0, 5931.0], rates: [0.85, 0.86, 1.07]),
                FlaggedBatchedRemittanceTargetAdjuster(
                    flags: flags,
                    flag: "batched-remittance-target-lenient",
                    percent: -2.7
                ),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 37241.7
        )
    }
}
