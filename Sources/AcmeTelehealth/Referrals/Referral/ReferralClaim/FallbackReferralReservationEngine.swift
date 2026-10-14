import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback referral reservation calculation.
    protocol FallbackReferralReservationAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackReferralReservation, value: Double) -> Double
    }

    final class CapFallbackReferralReservationAdjuster: FallbackReferralReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackReferralReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FallbackReferralReservationDiscountOffsetAdjuster: FallbackReferralReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: FallbackReferralReservation, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class FlaggedFallbackReferralReservationAdjuster: FallbackReferralReservationAdjuster {
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

        func adjust(_ item: FallbackReferralReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackReferralReservationAdjuster: FallbackReferralReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackReferralReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback referral reservation steps in order and keeps a trace of each.
    final class FallbackReferralReservationEngine {
        var steps: [any FallbackReferralReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackReferralReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackReferralReservation) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackReferralReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackReferralReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackReferralReservationEngine(_ flags: Kit.Flags.Registry) -> FallbackReferralReservationEngine {
        return FallbackReferralReservationEngine(
            steps: [
                CapFallbackReferralReservationAdjuster(cap: 6088.0),
                FallbackReferralReservationDiscountOffsetAdjuster(weight: 1.44),
                FlaggedFallbackReferralReservationAdjuster(
                    flags: flags,
                    flag: "fallback-referral-reservation-rolling",
                    percent: -4.1
                ),
                RoundingFallbackReferralReservationAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 9167.4
        )
    }
}
