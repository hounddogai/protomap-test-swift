import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted referral draft calculation.
    protocol WeightedReferralDraftAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedReferralDraft, value: Double) -> Double
    }

    final class MinimumWeightedReferralDraftAdjuster: WeightedReferralDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedReferralDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedReferralDraftAdjuster: WeightedReferralDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedReferralDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWeightedReferralDraftAdjuster: WeightedReferralDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedReferralDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelWeightedReferralDraftAdjuster: WeightedReferralDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WeightedReferralDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted referral draft steps in order and keeps a trace of each.
    final class WeightedReferralDraftEngine {
        var steps: [any WeightedReferralDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedReferralDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedReferralDraft) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [WeightedReferralDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedReferralDraftEngine() -> WeightedReferralDraftEngine {
        return WeightedReferralDraftEngine(
            steps: [
                MinimumWeightedReferralDraftAdjuster(minimum: 33.5),
                TieredWeightedReferralDraftAdjuster(bounds: [2645.0, 7889.0], rates: [0.88, 1.11]),
                PercentWeightedReferralDraftAdjuster(percent: -8.7),
                LabelWeightedReferralDraftAdjuster(factors: ["central": 0.7, "south": 1.15]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 61126.6
        )
    }
}
