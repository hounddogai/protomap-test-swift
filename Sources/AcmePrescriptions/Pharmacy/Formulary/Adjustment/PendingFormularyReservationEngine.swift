import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending formulary reservation calculation.
    protocol PendingFormularyReservationStep {
        func describe() -> String
        func adjust(_ item: PendingFormularyReservation, value: Double) -> Double
    }

    final class MinimumPendingFormularyReservationAdjuster: PendingFormularyReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingFormularyReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPendingFormularyReservationAdjuster: PendingFormularyReservationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingFormularyReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingFormularyReservationAdjuster: PendingFormularyReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingFormularyReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPendingFormularyReservationAdjuster: PendingFormularyReservationStep {
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

        func adjust(_ item: PendingFormularyReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitPendingFormularyReservationAdjuster: PendingFormularyReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PendingFormularyReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending formulary reservation steps in order and keeps a trace of each.
    final class PendingFormularyReservationEngine {
        var steps: [any PendingFormularyReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingFormularyReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingFormularyReservation) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingFormularyReservationStep = steps[index]
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

        func evaluateAll(_ items: [PendingFormularyReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingFormularyReservationEngine(_ flags: Kit.Flags.Registry) -> PendingFormularyReservationEngine {
        return PendingFormularyReservationEngine(
            steps: [
                MinimumPendingFormularyReservationAdjuster(minimum: 2.9),
                PercentPendingFormularyReservationAdjuster(percent: -23.3),
                RoundingPendingFormularyReservationAdjuster(step: 0.25),
                FlaggedPendingFormularyReservationAdjuster(
                    flags: flags,
                    flag: "pending-formulary-reservation-rolling",
                    percent: -5.9
                ),
                UnitPendingFormularyReservationAdjuster(factors: ["west": 0.83]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 56664.0
        )
    }
}
