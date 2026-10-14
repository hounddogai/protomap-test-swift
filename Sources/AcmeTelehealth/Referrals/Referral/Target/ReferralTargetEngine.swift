import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral target calculation.
    protocol ReferralTargetStep {
        func describe() -> String
        func adjust(_ item: ReferralTarget, value: Double) -> Double
    }

    final class ReferralTargetMaximumOffsetAdjuster: ReferralTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: ReferralTarget, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class NameReferralTargetAdjuster: ReferralTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ReferralTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumReferralTargetAdjuster: ReferralTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedReferralTargetAdjuster: ReferralTargetStep {
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

        func adjust(_ item: ReferralTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredReferralTargetAdjuster: ReferralTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingReferralTargetAdjuster: ReferralTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the referral target steps in order and keeps a trace of each.
    final class ReferralTargetEngine {
        var steps: [any ReferralTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReferralTarget) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [ReferralTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReferralTargetEngine(_ flags: Kit.Flags.Registry) -> ReferralTargetEngine {
        return ReferralTargetEngine(
            steps: [
                ReferralTargetMaximumOffsetAdjuster(weight: 1.99),
                NameReferralTargetAdjuster(factors: ["central": 0.8]),
                MinimumReferralTargetAdjuster(minimum: 4.5),
                FlaggedReferralTargetAdjuster(flags: flags, flag: "referral-target-fallback", percent: -0.7),
                TieredReferralTargetAdjuster(
                    bounds: [3219.0, 6252.0, 6919.0, 7626.0],
                    rates: [1.14, 0.84, 0.88, 1.05]
                ),
                RoundingReferralTargetAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 60034.0
        )
    }
}
