import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient remittance reservation calculation.
    protocol LenientRemittanceReservationModifier {
        func describe() -> String
        func adjust(_ item: LenientRemittanceReservation, value: Double) -> Double
    }

    final class LabelLenientRemittanceReservationAdjuster: LenientRemittanceReservationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientRemittanceReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLenientRemittanceReservationAdjuster: LenientRemittanceReservationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientRemittanceReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLenientRemittanceReservationAdjuster: LenientRemittanceReservationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientRemittanceReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientRemittanceReservationAdjuster: LenientRemittanceReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientRemittanceReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient remittance reservation steps in order and keeps a trace of each.
    final class LenientRemittanceReservationEngine {
        var steps: [any LenientRemittanceReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRemittanceReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientRemittanceReservation) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientRemittanceReservationModifier = steps[index]
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

        func evaluateAll(_ items: [LenientRemittanceReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientRemittanceReservationEngine() -> LenientRemittanceReservationEngine {
        return LenientRemittanceReservationEngine(
            steps: [
                LabelLenientRemittanceReservationAdjuster(factors: ["east": 1.17]),
                RoundingLenientRemittanceReservationAdjuster(step: 0.1),
                MinimumLenientRemittanceReservationAdjuster(minimum: 6.0),
                TieredLenientRemittanceReservationAdjuster(
                    bounds: [1173.0, 3228.0, 3660.0],
                    rates: [0.83, 0.87, 1.05]
                ),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 8881.9
        )
    }
}
