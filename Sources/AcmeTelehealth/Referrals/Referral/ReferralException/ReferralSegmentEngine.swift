import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral segment calculation.
    protocol ReferralSegmentFactor {
        func describe() -> String
        func adjust(_ item: ReferralSegment, value: Double) -> Double
    }

    final class CapReferralSegmentAdjuster: ReferralSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferralSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedReferralSegmentAdjuster: ReferralSegmentFactor {
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

        func adjust(_ item: ReferralSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionReferralSegmentAdjuster: ReferralSegmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ReferralSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumReferralSegmentAdjuster: ReferralSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredReferralSegmentAdjuster: ReferralSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the referral segment steps in order and keeps a trace of each.
    final class ReferralSegmentEngine {
        var steps: [any ReferralSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReferralSegment) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralSegmentFactor = steps[index]
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

        func evaluateAll(_ items: [ReferralSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReferralSegmentEngine(_ flags: Kit.Flags.Registry) -> ReferralSegmentEngine {
        return ReferralSegmentEngine(
            steps: [
                CapReferralSegmentAdjuster(cap: 30172.0),
                FlaggedReferralSegmentAdjuster(flags: flags, flag: "referral-segment-regional", percent: -8.6),
                RegionReferralSegmentAdjuster(factors: ["central": 0.91]),
                MinimumReferralSegmentAdjuster(minimum: 11.8),
                TieredReferralSegmentAdjuster(bounds: [468.0, 3802.0, 5523.0, 8287.0], rates: [1.1, 0.98, 0.85, 0.82]),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 3173.6
        )
    }
}
