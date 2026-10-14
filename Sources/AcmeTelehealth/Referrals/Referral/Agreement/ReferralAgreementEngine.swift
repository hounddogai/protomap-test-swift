import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral agreement calculation.
    protocol ReferralAgreementStep {
        func describe() -> String
        func adjust(_ item: ReferralAgreement, value: Double) -> Double
    }

    final class RoundingReferralAgreementAdjuster: ReferralAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ReferralAgreementThresholdOffsetAdjuster: ReferralAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ReferralAgreement, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class CountryReferralAgreementAdjuster: ReferralAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ReferralAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentReferralAgreementAdjuster: ReferralAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the referral agreement steps in order and keeps a trace of each.
    final class ReferralAgreementEngine {
        var steps: [any ReferralAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferralAgreement) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralAgreementStep = steps[index]
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

        func evaluateAll(_ items: [ReferralAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferralAgreementEngine() -> ReferralAgreementEngine {
        return ReferralAgreementEngine(
            steps: [
                RoundingReferralAgreementAdjuster(step: 0.25),
                ReferralAgreementThresholdOffsetAdjuster(weight: 1.07),
                CountryReferralAgreementAdjuster(factors: ["north": 1.33, "retail": 0.86, "online": 1.28]),
                PercentReferralAgreementAdjuster(percent: 14.1),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 69377.0
        )
    }
}
