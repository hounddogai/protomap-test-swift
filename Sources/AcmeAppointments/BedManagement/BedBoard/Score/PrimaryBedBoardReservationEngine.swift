import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary bed board reservation calculation.
    protocol PrimaryBedBoardReservationStep {
        func describe() -> String
        func adjust(_ item: PrimaryBedBoardReservation, value: Double) -> Double
    }

    final class NamePrimaryBedBoardReservationAdjuster: PrimaryBedBoardReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PrimaryBedBoardReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPrimaryBedBoardReservationAdjuster: PrimaryBedBoardReservationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryBedBoardReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPrimaryBedBoardReservationAdjuster: PrimaryBedBoardReservationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryBedBoardReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPrimaryBedBoardReservationAdjuster: PrimaryBedBoardReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryBedBoardReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PrimaryBedBoardReservationAttemptsOffsetAdjuster: PrimaryBedBoardReservationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: PrimaryBedBoardReservation, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class RoundingPrimaryBedBoardReservationAdjuster: PrimaryBedBoardReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryBedBoardReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary bed board reservation steps in order and keeps a trace of each.
    final class PrimaryBedBoardReservationEngine {
        var steps: [any PrimaryBedBoardReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryBedBoardReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryBedBoardReservation) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryBedBoardReservationStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryBedBoardReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryBedBoardReservationEngine() -> PrimaryBedBoardReservationEngine {
        return PrimaryBedBoardReservationEngine(
            steps: [
                NamePrimaryBedBoardReservationAdjuster(factors: ["west": 1.25, "north": 1.31, "retail": 1.38]),
                CapPrimaryBedBoardReservationAdjuster(cap: 16958.0),
                TieredPrimaryBedBoardReservationAdjuster(bounds: [7801.0, 8856.0], rates: [1.08, 0.85]),
                MinimumPrimaryBedBoardReservationAdjuster(minimum: 27.8),
                PrimaryBedBoardReservationAttemptsOffsetAdjuster(weight: 1.71),
                RoundingPrimaryBedBoardReservationAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 43821.4
        )
    }
}
