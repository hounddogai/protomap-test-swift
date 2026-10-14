import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched revocation target calculation.
    protocol BatchedRevocationTargetFactor {
        func describe() -> String
        func adjust(_ item: BatchedRevocationTarget, value: Double) -> Double
    }

    final class TieredBatchedRevocationTargetAdjuster: BatchedRevocationTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedRevocationTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BatchedRevocationTargetDiscountOffsetAdjuster: BatchedRevocationTargetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: BatchedRevocationTarget, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class CategoryBatchedRevocationTargetAdjuster: BatchedRevocationTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: BatchedRevocationTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedBatchedRevocationTargetAdjuster: BatchedRevocationTargetFactor {
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

        func adjust(_ item: BatchedRevocationTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched revocation target steps in order and keeps a trace of each.
    final class BatchedRevocationTargetEngine {
        var steps: [any BatchedRevocationTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRevocationTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedRevocationTarget) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedRevocationTargetFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedRevocationTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedRevocationTargetEngine(_ flags: Kit.Flags.Registry) -> BatchedRevocationTargetEngine {
        return BatchedRevocationTargetEngine(
            steps: [
                TieredBatchedRevocationTargetAdjuster(bounds: [2918.0, 2972.0, 8131.0], rates: [1.16, 0.88, 1.19]),
                BatchedRevocationTargetDiscountOffsetAdjuster(weight: 0.61),
                CategoryBatchedRevocationTargetAdjuster(factors: ["south": 1.19]),
                FlaggedBatchedRevocationTargetAdjuster(
                    flags: flags,
                    flag: "batched-revocation-target-scheduled",
                    percent: -0.4
                ),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 25126.8
        )
    }
}
