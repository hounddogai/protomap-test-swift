import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral summary calculation.
    protocol ReferralSummaryFactor {
        func describe() -> String
        func adjust(_ item: ReferralSummary, value: Double) -> Double
    }

    final class TieredReferralSummaryAdjuster: ReferralSummaryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryReferralSummaryAdjuster: ReferralSummaryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ReferralSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentReferralSummaryAdjuster: ReferralSummaryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingReferralSummaryAdjuster: ReferralSummaryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the referral summary steps in order and keeps a trace of each.
    final class ReferralSummaryEngine {
        var steps: [any ReferralSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferralSummary) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ReferralSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferralSummaryEngine() -> ReferralSummaryEngine {
        return ReferralSummaryEngine(
            steps: [
                TieredReferralSummaryAdjuster(bounds: [6146.0, 6681.0, 7242.0], rates: [1.09, 0.89, 1.07]),
                CountryReferralSummaryAdjuster(factors: ["west": 1.17, "central": 1.04]),
                PercentReferralSummaryAdjuster(percent: 9.8),
                RoundingReferralSummaryAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 59579.8
        )
    }
}
