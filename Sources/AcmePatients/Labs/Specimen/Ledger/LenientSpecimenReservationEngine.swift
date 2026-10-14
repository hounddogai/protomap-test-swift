import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient specimen reservation calculation.
    protocol LenientSpecimenReservationFactor {
        func describe() -> String
        func adjust(_ item: LenientSpecimenReservation, value: Double) -> Double
    }

    final class CapLenientSpecimenReservationAdjuster: LenientSpecimenReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientSpecimenReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLenientSpecimenReservationAdjuster: LenientSpecimenReservationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientSpecimenReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLenientSpecimenReservationAdjuster: LenientSpecimenReservationFactor {
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

        func adjust(_ item: LenientSpecimenReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient specimen reservation steps in order and keeps a trace of each.
    final class LenientSpecimenReservationEngine {
        var steps: [any LenientSpecimenReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientSpecimenReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientSpecimenReservation) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientSpecimenReservationFactor = steps[index]
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

        func evaluateAll(_ items: [LenientSpecimenReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientSpecimenReservationEngine(_ flags: Kit.Flags.Registry) -> LenientSpecimenReservationEngine {
        return LenientSpecimenReservationEngine(
            steps: [
                CapLenientSpecimenReservationAdjuster(cap: 36094.0),
                TieredLenientSpecimenReservationAdjuster(bounds: [1015.0, 2817.0, 3701.0], rates: [1.09, 0.82, 1.12]),
                FlaggedLenientSpecimenReservationAdjuster(
                    flags: flags,
                    flag: "lenient-specimen-reservation-scheduled",
                    percent: -1.8
                ),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 42862.2
        )
    }
}
