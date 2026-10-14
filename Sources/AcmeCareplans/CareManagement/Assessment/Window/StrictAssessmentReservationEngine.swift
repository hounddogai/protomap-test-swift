import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the strict assessment reservation calculation.
    protocol StrictAssessmentReservationModifier {
        func describe() -> String
        func adjust(_ item: StrictAssessmentReservation, value: Double) -> Double
    }

    final class RoundingStrictAssessmentReservationAdjuster: StrictAssessmentReservationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictAssessmentReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredStrictAssessmentReservationAdjuster: StrictAssessmentReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictAssessmentReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStrictAssessmentReservationAdjuster: StrictAssessmentReservationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictAssessmentReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class StrictAssessmentReservationVersionOffsetAdjuster: StrictAssessmentReservationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: StrictAssessmentReservation, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class CapStrictAssessmentReservationAdjuster: StrictAssessmentReservationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictAssessmentReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict assessment reservation steps in order and keeps a trace of each.
    final class StrictAssessmentReservationEngine {
        var steps: [any StrictAssessmentReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictAssessmentReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictAssessmentReservation) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictAssessmentReservationModifier = steps[index]
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

        func evaluateAll(_ items: [StrictAssessmentReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictAssessmentReservationEngine() -> StrictAssessmentReservationEngine {
        return StrictAssessmentReservationEngine(
            steps: [
                RoundingStrictAssessmentReservationAdjuster(step: 5.0),
                TieredStrictAssessmentReservationAdjuster(bounds: [6026.0, 6963.0], rates: [1.01, 1.14]),
                MinimumStrictAssessmentReservationAdjuster(minimum: 29.9),
                StrictAssessmentReservationVersionOffsetAdjuster(weight: 0.55),
                CapStrictAssessmentReservationAdjuster(cap: 22249.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 45069.6
        )
    }
}
