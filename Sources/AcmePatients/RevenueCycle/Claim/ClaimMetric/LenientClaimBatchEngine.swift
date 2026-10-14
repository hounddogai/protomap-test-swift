import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient claim batch calculation.
    protocol LenientClaimBatchAdjuster {
        func describe() -> String
        func adjust(_ item: LenientClaimBatch, value: Double) -> Double
    }

    final class TieredLenientClaimBatchAdjuster: LenientClaimBatchAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientClaimBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLenientClaimBatchAdjuster: LenientClaimBatchAdjuster {
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

        func adjust(_ item: LenientClaimBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientClaimBatchAdjuster: LenientClaimBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientClaimBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LenientClaimBatchDiscountOffsetAdjuster: LenientClaimBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: LenientClaimBatch, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class PercentLenientClaimBatchAdjuster: LenientClaimBatchAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientClaimBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient claim batch steps in order and keeps a trace of each.
    final class LenientClaimBatchEngine {
        var steps: [any LenientClaimBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientClaimBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientClaimBatch) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [LenientClaimBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientClaimBatchEngine(_ flags: Kit.Flags.Registry) -> LenientClaimBatchEngine {
        return LenientClaimBatchEngine(
            steps: [
                TieredLenientClaimBatchAdjuster(bounds: [31.0, 909.0], rates: [1.15, 1.09]),
                FlaggedLenientClaimBatchAdjuster(flags: flags, flag: "lenient-claim-batch-scheduled", percent: 2.4),
                MinimumLenientClaimBatchAdjuster(minimum: 26.1),
                LenientClaimBatchDiscountOffsetAdjuster(weight: 1.85),
                PercentLenientClaimBatchAdjuster(percent: 7.9),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 13270.3
        )
    }
}
