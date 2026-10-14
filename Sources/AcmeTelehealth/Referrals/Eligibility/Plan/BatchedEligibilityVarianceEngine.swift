import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched eligibility variance calculation.
    protocol BatchedEligibilityVarianceModifier {
        func describe() -> String
        func adjust(_ item: BatchedEligibilityVariance, value: Double) -> Double
    }

    final class FlaggedBatchedEligibilityVarianceAdjuster: BatchedEligibilityVarianceModifier {
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

        func adjust(_ item: BatchedEligibilityVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedEligibilityVarianceAdjuster: BatchedEligibilityVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedEligibilityVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingBatchedEligibilityVarianceAdjuster: BatchedEligibilityVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedEligibilityVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredBatchedEligibilityVarianceAdjuster: BatchedEligibilityVarianceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedEligibilityVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched eligibility variance steps in order and keeps a trace of each.
    final class BatchedEligibilityVarianceEngine {
        var steps: [any BatchedEligibilityVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedEligibilityVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedEligibilityVariance) -> Double {
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

        func evaluateAll(_ items: [BatchedEligibilityVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedEligibilityVarianceEngine(_ flags: Kit.Flags.Registry) -> BatchedEligibilityVarianceEngine {
        return BatchedEligibilityVarianceEngine(
            steps: [
                FlaggedBatchedEligibilityVarianceAdjuster(
                    flags: flags,
                    flag: "batched-eligibility-variance-weighted",
                    percent: 4.9
                ),
                CapBatchedEligibilityVarianceAdjuster(cap: 15123.0),
                RoundingBatchedEligibilityVarianceAdjuster(step: 0.25),
                TieredBatchedEligibilityVarianceAdjuster(bounds: [5265.0, 7017.0], rates: [1.0, 0.8]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 53783.2
        )
    }
}
