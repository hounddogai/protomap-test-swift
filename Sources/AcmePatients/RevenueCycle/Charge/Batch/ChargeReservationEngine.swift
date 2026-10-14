import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge reservation calculation.
    protocol ChargeReservationStep {
        func describe() -> String
        func adjust(_ item: ChargeReservation, value: Double) -> Double
    }

    final class TitleChargeReservationAdjuster: ChargeReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ChargeReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumChargeReservationAdjuster: ChargeReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedChargeReservationAdjuster: ChargeReservationStep {
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

        func adjust(_ item: ChargeReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge reservation steps in order and keeps a trace of each.
    final class ChargeReservationEngine {
        var steps: [any ChargeReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeReservation) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ChargeReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeReservationEngine(_ flags: Kit.Flags.Registry) -> ChargeReservationEngine {
        return ChargeReservationEngine(
            steps: [
                TitleChargeReservationAdjuster(factors: ["online": 1.39, "east": 1.28, "north": 0.92]),
                MinimumChargeReservationAdjuster(minimum: 22.0),
                FlaggedChargeReservationAdjuster(flags: flags, flag: "charge-reservation-legacy", percent: 5.9),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 48895.2
        )
    }
}
