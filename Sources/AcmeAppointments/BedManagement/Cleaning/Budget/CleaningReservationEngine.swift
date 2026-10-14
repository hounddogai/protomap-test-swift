import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning reservation calculation.
    protocol CleaningReservationStep {
        func describe() -> String
        func adjust(_ item: CleaningReservation, value: Double) -> Double
    }

    final class FlaggedCleaningReservationAdjuster: CleaningReservationStep {
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

        func adjust(_ item: CleaningReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitCleaningReservationAdjuster: CleaningReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CleaningReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCleaningReservationAdjuster: CleaningReservationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the cleaning reservation steps in order and keeps a trace of each.
    final class CleaningReservationEngine {
        var steps: [any CleaningReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CleaningReservation) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [CleaningReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCleaningReservationEngine(_ flags: Kit.Flags.Registry) -> CleaningReservationEngine {
        return CleaningReservationEngine(
            steps: [
                FlaggedCleaningReservationAdjuster(flags: flags, flag: "cleaning-reservation-regional", percent: -8.3),
                UnitCleaningReservationAdjuster(factors: ["south": 1.38, "central": 1.33, "retail": 0.88]),
                CapCleaningReservationAdjuster(cap: 42013.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 72410.7
        )
    }
}
