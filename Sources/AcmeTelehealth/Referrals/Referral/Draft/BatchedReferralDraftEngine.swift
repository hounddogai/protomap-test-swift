import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched referral draft calculation.
    protocol BatchedReferralDraftStep {
        func describe() -> String
        func adjust(_ item: BatchedReferralDraft, value: Double) -> Double
    }

    final class BatchedReferralDraftSequenceOffsetAdjuster: BatchedReferralDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: BatchedReferralDraft, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class TieredBatchedReferralDraftAdjuster: BatchedReferralDraftStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedReferralDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBatchedReferralDraftAdjuster: BatchedReferralDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedReferralDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentBatchedReferralDraftAdjuster: BatchedReferralDraftStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedReferralDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedReferralDraftAdjuster: BatchedReferralDraftStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedReferralDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the batched referral draft steps in order and keeps a trace of each.
    final class BatchedReferralDraftEngine {
        var steps: [any BatchedReferralDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedReferralDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedReferralDraft) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [BatchedReferralDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedReferralDraftEngine() -> BatchedReferralDraftEngine {
        return BatchedReferralDraftEngine(
            steps: [
                BatchedReferralDraftSequenceOffsetAdjuster(weight: 1.31),
                TieredBatchedReferralDraftAdjuster(bounds: [3292.0, 7480.0, 8534.0], rates: [0.82, 0.89, 0.84]),
                RoundingBatchedReferralDraftAdjuster(step: 0.25),
                PercentBatchedReferralDraftAdjuster(percent: 6.1),
                CapBatchedReferralDraftAdjuster(cap: 26764.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 19699.2
        )
    }
}
