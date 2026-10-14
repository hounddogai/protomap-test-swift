import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral reservation calculation.
    protocol ReferralReservationAdjuster {
        func describe() -> String
        func adjust(_ item: ReferralReservation, value: Double) -> Double
    }

    final class FlaggedReferralReservationAdjuster: ReferralReservationAdjuster {
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

        func adjust(_ item: ReferralReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapReferralReservationAdjuster: ReferralReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferralReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumReferralReservationAdjuster: ReferralReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredReferralReservationAdjuster: ReferralReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the referral reservation steps in order and keeps a trace of each.
    final class ReferralReservationEngine {
        var steps: [any ReferralReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferralReservation) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [ReferralReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferralReservationEngine(_ flags: Kit.Flags.Registry) -> ReferralReservationEngine {
        return ReferralReservationEngine(
            steps: [
                FlaggedReferralReservationAdjuster(flags: flags, flag: "referral-reservation-fallback", percent: -2.3),
                CapReferralReservationAdjuster(cap: 4852.0),
                MinimumReferralReservationAdjuster(minimum: 16.5),
                TieredReferralReservationAdjuster(
                    bounds: [2891.0, 4532.0, 6530.0, 8057.0],
                    rates: [1.07, 1.07, 0.98, 1.17]
                ),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 56947.2
        )
    }
}
