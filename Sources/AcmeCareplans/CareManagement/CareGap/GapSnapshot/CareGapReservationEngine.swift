import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap reservation calculation.
    protocol CareGapReservationStep {
        func describe() -> String
        func adjust(_ item: CareGapReservation, value: Double) -> Double
    }

    final class RoundingCareGapReservationAdjuster: CareGapReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitCareGapReservationAdjuster: CareGapReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CareGapReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCareGapReservationAdjuster: CareGapReservationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareGapReservationAdjuster: CareGapReservationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCareGapReservationAdjuster: CareGapReservationStep {
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

        func adjust(_ item: CareGapReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareGapReservationAdjuster: CareGapReservationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the care gap reservation steps in order and keeps a trace of each.
    final class CareGapReservationEngine {
        var steps: [any CareGapReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareGapReservation) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapReservationStep = steps[index]
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

        func evaluateAll(_ items: [CareGapReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareGapReservationEngine(_ flags: Kit.Flags.Registry) -> CareGapReservationEngine {
        return CareGapReservationEngine(
            steps: [
                RoundingCareGapReservationAdjuster(step: 0.1),
                UnitCareGapReservationAdjuster(factors: ["central": 0.83, "south": 1.21]),
                CapCareGapReservationAdjuster(cap: 33133.0),
                PercentCareGapReservationAdjuster(percent: 19.1),
                FlaggedCareGapReservationAdjuster(flags: flags, flag: "care-gap-reservation-default", percent: 3.0),
                TieredCareGapReservationAdjuster(bounds: [6906.0, 8410.0, 9695.0], rates: [1.16, 1.03, 0.81]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 33570.5
        )
    }
}
