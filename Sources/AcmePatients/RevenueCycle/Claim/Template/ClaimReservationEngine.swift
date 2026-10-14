import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim reservation calculation.
    protocol ClaimReservationAdjuster {
        func describe() -> String
        func adjust(_ item: ClaimReservation, value: Double) -> Double
    }

    final class PercentClaimReservationAdjuster: ClaimReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ClaimReservationThresholdOffsetAdjuster: ClaimReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ClaimReservation, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class LabelClaimReservationAdjuster: ClaimReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ClaimReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedClaimReservationAdjuster: ClaimReservationAdjuster {
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

        func adjust(_ item: ClaimReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClaimReservationAdjuster: ClaimReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredClaimReservationAdjuster: ClaimReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the claim reservation steps in order and keeps a trace of each.
    final class ClaimReservationEngine {
        var steps: [any ClaimReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClaimReservation) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ClaimReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClaimReservationEngine(_ flags: Kit.Flags.Registry) -> ClaimReservationEngine {
        return ClaimReservationEngine(
            steps: [
                PercentClaimReservationAdjuster(percent: -15.2),
                ClaimReservationThresholdOffsetAdjuster(weight: 1.65),
                LabelClaimReservationAdjuster(factors: ["west": 1.3]),
                FlaggedClaimReservationAdjuster(flags: flags, flag: "claim-reservation-tiered", percent: 2.3),
                MinimumClaimReservationAdjuster(minimum: 31.3),
                TieredClaimReservationAdjuster(bounds: [914.0, 2035.0, 5865.0], rates: [0.99, 0.97, 1.11]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 22633.8
        )
    }
}
