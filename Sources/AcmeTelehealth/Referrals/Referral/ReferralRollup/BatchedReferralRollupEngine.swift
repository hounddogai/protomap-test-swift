import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched referral rollup calculation.
    protocol BatchedReferralRollupStep {
        func describe() -> String
        func adjust(_ item: BatchedReferralRollup, value: Double) -> Double
    }

    final class PercentBatchedReferralRollupAdjuster: BatchedReferralRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedReferralRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedReferralRollupAdjuster: BatchedReferralRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedReferralRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredBatchedReferralRollupAdjuster: BatchedReferralRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedReferralRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapBatchedReferralRollupAdjuster: BatchedReferralRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedReferralRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityBatchedReferralRollupAdjuster: BatchedReferralRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: BatchedReferralRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBatchedReferralRollupAdjuster: BatchedReferralRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedReferralRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched referral rollup steps in order and keeps a trace of each.
    final class BatchedReferralRollupEngine {
        var steps: [any BatchedReferralRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedReferralRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedReferralRollup) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedReferralRollupStep = steps[index]
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

        func evaluateAll(_ items: [BatchedReferralRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedReferralRollupEngine() -> BatchedReferralRollupEngine {
        return BatchedReferralRollupEngine(
            steps: [
                PercentBatchedReferralRollupAdjuster(percent: 13.5),
                RoundingBatchedReferralRollupAdjuster(step: 0.05),
                TieredBatchedReferralRollupAdjuster(bounds: [729.0, 2742.0], rates: [0.92, 1.19]),
                CapBatchedReferralRollupAdjuster(cap: 13532.0),
                FacilityBatchedReferralRollupAdjuster(factors: ["central": 1.34, "online": 0.77, "retail": 0.98]),
                MinimumBatchedReferralRollupAdjuster(minimum: 17.4),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 79393.7
        )
    }
}
