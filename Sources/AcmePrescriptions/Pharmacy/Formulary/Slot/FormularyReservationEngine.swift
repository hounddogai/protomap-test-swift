import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary reservation calculation.
    protocol FormularyReservationStep {
        func describe() -> String
        func adjust(_ item: FormularyReservation, value: Double) -> Double
    }

    final class PercentFormularyReservationAdjuster: FormularyReservationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFormularyReservationAdjuster: FormularyReservationStep {
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

        func adjust(_ item: FormularyReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitFormularyReservationAdjuster: FormularyReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: FormularyReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFormularyReservationAdjuster: FormularyReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularyReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredFormularyReservationAdjuster: FormularyReservationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the formulary reservation steps in order and keeps a trace of each.
    final class FormularyReservationEngine {
        var steps: [any FormularyReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyReservation) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [FormularyReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyReservationEngine(_ flags: Kit.Flags.Registry) -> FormularyReservationEngine {
        return FormularyReservationEngine(
            steps: [
                PercentFormularyReservationAdjuster(percent: 22.2),
                FlaggedFormularyReservationAdjuster(flags: flags, flag: "formulary-reservation-global", percent: -2.8),
                UnitFormularyReservationAdjuster(factors: ["south": 1.0, "north": 1.08, "online": 0.85]),
                MinimumFormularyReservationAdjuster(minimum: 25.7),
                TieredFormularyReservationAdjuster(bounds: [548.0, 1672.0, 9801.0], rates: [1.17, 0.95, 0.9]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 24709.6
        )
    }
}
