import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling accession reservation calculation.
    protocol RollingAccessionReservationAdjuster {
        func describe() -> String
        func adjust(_ item: RollingAccessionReservation, value: Double) -> Double
    }

    final class MinimumRollingAccessionReservationAdjuster: RollingAccessionReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingAccessionReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRollingAccessionReservationAdjuster: RollingAccessionReservationAdjuster {
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

        func adjust(_ item: RollingAccessionReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingAccessionReservationAdjuster: RollingAccessionReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingAccessionReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitRollingAccessionReservationAdjuster: RollingAccessionReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RollingAccessionReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRollingAccessionReservationAdjuster: RollingAccessionReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingAccessionReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingAccessionReservationAdjuster: RollingAccessionReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingAccessionReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling accession reservation steps in order and keeps a trace of each.
    final class RollingAccessionReservationEngine {
        var steps: [any RollingAccessionReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingAccessionReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingAccessionReservation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingAccessionReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingAccessionReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingAccessionReservationEngine(_ flags: Kit.Flags.Registry) -> RollingAccessionReservationEngine {
        return RollingAccessionReservationEngine(
            steps: [
                MinimumRollingAccessionReservationAdjuster(minimum: 14.4),
                FlaggedRollingAccessionReservationAdjuster(
                    flags: flags,
                    flag: "rolling-accession-reservation-weighted",
                    percent: -9.9
                ),
                TieredRollingAccessionReservationAdjuster(bounds: [4585.0, 8897.0], rates: [1.18, 0.84]),
                UnitRollingAccessionReservationAdjuster(factors: ["retail": 0.98, "east": 0.93, "south": 1.09]),
                PercentRollingAccessionReservationAdjuster(percent: 15.9),
                RoundingRollingAccessionReservationAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 32574.6
        )
    }
}
