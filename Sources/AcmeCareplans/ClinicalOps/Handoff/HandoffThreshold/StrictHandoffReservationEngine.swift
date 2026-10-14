import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict handoff reservation calculation.
    protocol StrictHandoffReservationModifier {
        func describe() -> String
        func adjust(_ item: StrictHandoffReservation, value: Double) -> Double
    }

    final class TieredStrictHandoffReservationAdjuster: StrictHandoffReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictHandoffReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStrictHandoffReservationAdjuster: StrictHandoffReservationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictHandoffReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStrictHandoffReservationAdjuster: StrictHandoffReservationModifier {
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

        func adjust(_ item: StrictHandoffReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryStrictHandoffReservationAdjuster: StrictHandoffReservationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: StrictHandoffReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStrictHandoffReservationAdjuster: StrictHandoffReservationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictHandoffReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict handoff reservation steps in order and keeps a trace of each.
    final class StrictHandoffReservationEngine {
        var steps: [any StrictHandoffReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictHandoffReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictHandoffReservation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictHandoffReservationModifier = steps[index]
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

        func evaluateAll(_ items: [StrictHandoffReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictHandoffReservationEngine(_ flags: Kit.Flags.Registry) -> StrictHandoffReservationEngine {
        return StrictHandoffReservationEngine(
            steps: [
                TieredStrictHandoffReservationAdjuster(bounds: [87.0, 8239.0], rates: [1.06, 1.01]),
                MinimumStrictHandoffReservationAdjuster(minimum: 40.5),
                FlaggedStrictHandoffReservationAdjuster(
                    flags: flags,
                    flag: "strict-handoff-reservation-fallback",
                    percent: 0.9
                ),
                CountryStrictHandoffReservationAdjuster(factors: ["retail": 1.25]),
                CapStrictHandoffReservationAdjuster(cap: 29388.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 75381.6
        )
    }
}
