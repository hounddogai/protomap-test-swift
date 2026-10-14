import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral metric calculation.
    protocol ReferralMetricAdjuster {
        func describe() -> String
        func adjust(_ item: ReferralMetric, value: Double) -> Double
    }

    final class TieredReferralMetricAdjuster: ReferralMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ReferralMetricStartsAtOffsetAdjuster: ReferralMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: ReferralMetric, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class FlaggedReferralMetricAdjuster: ReferralMetricAdjuster {
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

        func adjust(_ item: ReferralMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the referral metric steps in order and keeps a trace of each.
    final class ReferralMetricEngine {
        var steps: [any ReferralMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferralMetric) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralMetricAdjuster = steps[index]
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

        func evaluateAll(_ items: [ReferralMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferralMetricEngine(_ flags: Kit.Flags.Registry) -> ReferralMetricEngine {
        return ReferralMetricEngine(
            steps: [
                TieredReferralMetricAdjuster(bounds: [3818.0, 3854.0, 7905.0], rates: [1.13, 0.84, 0.91]),
                ReferralMetricStartsAtOffsetAdjuster(weight: 0.52),
                FlaggedReferralMetricAdjuster(flags: flags, flag: "referral-metric-weighted", percent: -1.1),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 76395.0
        )
    }
}
