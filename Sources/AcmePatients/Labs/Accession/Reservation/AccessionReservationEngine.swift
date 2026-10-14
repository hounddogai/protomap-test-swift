import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession reservation calculation.
    protocol AccessionReservationFactor {
        func describe() -> String
        func adjust(_ item: AccessionReservation, value: Double) -> Double
    }

    final class FlaggedAccessionReservationAdjuster: AccessionReservationFactor {
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

        func adjust(_ item: AccessionReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelAccessionReservationAdjuster: AccessionReservationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AccessionReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAccessionReservationAdjuster: AccessionReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the accession reservation steps in order and keeps a trace of each.
    final class AccessionReservationEngine {
        var steps: [any AccessionReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AccessionReservation) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [AccessionReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAccessionReservationEngine(_ flags: Kit.Flags.Registry) -> AccessionReservationEngine {
        return AccessionReservationEngine(
            steps: [
                FlaggedAccessionReservationAdjuster(
                    flags: flags,
                    flag: "accession-reservation-rolling",
                    percent: -7.4
                ),
                LabelAccessionReservationAdjuster(factors: ["west": 0.88, "central": 0.73, "retail": 0.88]),
                CapAccessionReservationAdjuster(cap: 35718.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 84917.5
        )
    }
}
