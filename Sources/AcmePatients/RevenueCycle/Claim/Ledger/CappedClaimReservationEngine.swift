import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped claim reservation calculation.
    protocol CappedClaimReservationStep {
        func describe() -> String
        func adjust(_ item: CappedClaimReservation, value: Double) -> Double
    }

    final class RoundingCappedClaimReservationAdjuster: CappedClaimReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedClaimReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCappedClaimReservationAdjuster: CappedClaimReservationStep {
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

        func adjust(_ item: CappedClaimReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCappedClaimReservationAdjuster: CappedClaimReservationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedClaimReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedClaimReservationAdjuster: CappedClaimReservationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedClaimReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped claim reservation steps in order and keeps a trace of each.
    final class CappedClaimReservationEngine {
        var steps: [any CappedClaimReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedClaimReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedClaimReservation) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedClaimReservationStep = steps[index]
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

        func evaluateAll(_ items: [CappedClaimReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedClaimReservationEngine(_ flags: Kit.Flags.Registry) -> CappedClaimReservationEngine {
        return CappedClaimReservationEngine(
            steps: [
                RoundingCappedClaimReservationAdjuster(step: 0.05),
                FlaggedCappedClaimReservationAdjuster(
                    flags: flags,
                    flag: "capped-claim-reservation-scheduled",
                    percent: -8.6
                ),
                PercentCappedClaimReservationAdjuster(percent: 20.9),
                TieredCappedClaimReservationAdjuster(
                    bounds: [1522.0, 1536.0, 6260.0, 8358.0],
                    rates: [0.94, 0.84, 1.09, 1.05]
                ),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 99732.9
        )
    }
}
