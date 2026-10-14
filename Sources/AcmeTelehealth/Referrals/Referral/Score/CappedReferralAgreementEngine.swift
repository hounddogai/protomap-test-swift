import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped referral agreement calculation.
    protocol CappedReferralAgreementFactor {
        func describe() -> String
        func adjust(_ item: CappedReferralAgreement, value: Double) -> Double
    }

    final class CappedReferralAgreementVisitMinutesOffsetAdjuster: CappedReferralAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: CappedReferralAgreement, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class RoundingCappedReferralAgreementAdjuster: CappedReferralAgreementFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedReferralAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCappedReferralAgreementAdjuster: CappedReferralAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedReferralAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped referral agreement steps in order and keeps a trace of each.
    final class CappedReferralAgreementEngine {
        var steps: [any CappedReferralAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedReferralAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedReferralAgreement) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedReferralAgreementFactor = steps[index]
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

        func evaluateAll(_ items: [CappedReferralAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedReferralAgreementEngine() -> CappedReferralAgreementEngine {
        return CappedReferralAgreementEngine(
            steps: [
                CappedReferralAgreementVisitMinutesOffsetAdjuster(weight: 0.84),
                RoundingCappedReferralAgreementAdjuster(step: 5.0),
                TieredCappedReferralAgreementAdjuster(bounds: [283.0, 2592.0, 8370.0], rates: [1.16, 0.98, 0.81]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 3461.8
        )
    }
}
