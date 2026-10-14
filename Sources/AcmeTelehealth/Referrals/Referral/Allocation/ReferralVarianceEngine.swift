import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral variance calculation.
    protocol ReferralVarianceStep {
        func describe() -> String
        func adjust(_ item: ReferralVariance, value: Double) -> Double
    }

    final class ChannelReferralVarianceAdjuster: ReferralVarianceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ReferralVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ReferralVarianceRatioOffsetAdjuster: ReferralVarianceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ReferralVariance, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class FlaggedReferralVarianceAdjuster: ReferralVarianceStep {
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

        func adjust(_ item: ReferralVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredReferralVarianceAdjuster: ReferralVarianceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the referral variance steps in order and keeps a trace of each.
    final class ReferralVarianceEngine {
        var steps: [any ReferralVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferralVariance) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralVarianceStep = steps[index]
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

        func evaluateAll(_ items: [ReferralVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferralVarianceEngine(_ flags: Kit.Flags.Registry) -> ReferralVarianceEngine {
        return ReferralVarianceEngine(
            steps: [
                ChannelReferralVarianceAdjuster(factors: ["east": 1.2]),
                ReferralVarianceRatioOffsetAdjuster(weight: 1.28),
                FlaggedReferralVarianceAdjuster(flags: flags, flag: "referral-variance-fallback", percent: 3.5),
                TieredReferralVarianceAdjuster(bounds: [8495.0, 8586.0, 8592.0], rates: [0.94, 0.81, 0.83]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 10358.6
        )
    }
}
