import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the default referral agreement calculation.
    protocol DefaultReferralAgreementModifier {
        func describe() -> String
        func adjust(_ item: DefaultReferralAgreement, value: Double) -> Double
    }

    final class TieredDefaultReferralAgreementAdjuster: DefaultReferralAgreementModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultReferralAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameDefaultReferralAgreementAdjuster: DefaultReferralAgreementModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DefaultReferralAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDefaultReferralAgreementAdjuster: DefaultReferralAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultReferralAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default referral agreement steps in order and keeps a trace of each.
    final class DefaultReferralAgreementEngine {
        var steps: [any DefaultReferralAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultReferralAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultReferralAgreement) -> Double {
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

        func evaluateAll(_ items: [DefaultReferralAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultReferralAgreementEngine() -> DefaultReferralAgreementEngine {
        return DefaultReferralAgreementEngine(
            steps: [
                TieredDefaultReferralAgreementAdjuster(bounds: [942.0, 4246.0, 7075.0], rates: [1.03, 1.15, 1.19]),
                NameDefaultReferralAgreementAdjuster(factors: ["north": 0.92, "central": 0.8]),
                PercentDefaultReferralAgreementAdjuster(percent: 10.8),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 70659.6
        )
    }
}
