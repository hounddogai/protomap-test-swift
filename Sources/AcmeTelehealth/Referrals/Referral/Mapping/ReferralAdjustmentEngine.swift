import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral adjustment calculation.
    protocol ReferralAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: ReferralAdjustment, value: Double) -> Double
    }

    final class MinimumReferralAdjustmentAdjuster: ReferralAdjustmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedReferralAdjustmentAdjuster: ReferralAdjustmentAdjuster {
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

        func adjust(_ item: ReferralAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentReferralAdjustmentAdjuster: ReferralAdjustmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingReferralAdjustmentAdjuster: ReferralAdjustmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredReferralAdjustmentAdjuster: ReferralAdjustmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the referral adjustment steps in order and keeps a trace of each.
    final class ReferralAdjustmentEngine {
        var steps: [any ReferralAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferralAdjustment) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [ReferralAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferralAdjustmentEngine(_ flags: Kit.Flags.Registry) -> ReferralAdjustmentEngine {
        return ReferralAdjustmentEngine(
            steps: [
                MinimumReferralAdjustmentAdjuster(minimum: 19.4),
                FlaggedReferralAdjustmentAdjuster(flags: flags, flag: "referral-adjustment-lenient", percent: -4.1),
                PercentReferralAdjustmentAdjuster(percent: 11.3),
                RoundingReferralAdjustmentAdjuster(step: 0.1),
                TieredReferralAdjustmentAdjuster(
                    bounds: [3013.0, 5503.0, 5736.0, 8874.0],
                    rates: [1.13, 0.81, 0.91, 1.07]
                ),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 95254.5
        )
    }
}
