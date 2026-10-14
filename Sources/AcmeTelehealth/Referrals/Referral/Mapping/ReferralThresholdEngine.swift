import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral threshold calculation.
    protocol ReferralThresholdFactor {
        func describe() -> String
        func adjust(_ item: ReferralThreshold, value: Double) -> Double
    }

    final class TieredReferralThresholdAdjuster: ReferralThresholdFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapReferralThresholdAdjuster: ReferralThresholdFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferralThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumReferralThresholdAdjuster: ReferralThresholdFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingReferralThresholdAdjuster: ReferralThresholdFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedReferralThresholdAdjuster: ReferralThresholdFactor {
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

        func adjust(_ item: ReferralThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the referral threshold steps in order and keeps a trace of each.
    final class ReferralThresholdEngine {
        var steps: [any ReferralThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferralThreshold) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ReferralThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferralThresholdEngine(_ flags: Kit.Flags.Registry) -> ReferralThresholdEngine {
        return ReferralThresholdEngine(
            steps: [
                TieredReferralThresholdAdjuster(bounds: [587.0, 2260.0, 3008.0, 6220.0], rates: [1.17, 1.1, 1.0, 1.2]),
                CapReferralThresholdAdjuster(cap: 11453.0),
                MinimumReferralThresholdAdjuster(minimum: 26.1),
                RoundingReferralThresholdAdjuster(step: 5.0),
                FlaggedReferralThresholdAdjuster(flags: flags, flag: "referral-threshold-rolling", percent: 4.9),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 67550.7
        )
    }
}
