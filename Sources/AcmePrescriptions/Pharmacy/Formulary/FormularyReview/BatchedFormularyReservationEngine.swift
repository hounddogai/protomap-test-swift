import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched formulary reservation calculation.
    protocol BatchedFormularyReservationFactor {
        func describe() -> String
        func adjust(_ item: BatchedFormularyReservation, value: Double) -> Double
    }

    final class SegmentBatchedFormularyReservationAdjuster: BatchedFormularyReservationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: BatchedFormularyReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredBatchedFormularyReservationAdjuster: BatchedFormularyReservationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedFormularyReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BatchedFormularyReservationAttemptsOffsetAdjuster: BatchedFormularyReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: BatchedFormularyReservation, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class MinimumBatchedFormularyReservationAdjuster: BatchedFormularyReservationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedFormularyReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched formulary reservation steps in order and keeps a trace of each.
    final class BatchedFormularyReservationEngine {
        var steps: [any BatchedFormularyReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedFormularyReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedFormularyReservation) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedFormularyReservationFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedFormularyReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedFormularyReservationEngine() -> BatchedFormularyReservationEngine {
        return BatchedFormularyReservationEngine(
            steps: [
                SegmentBatchedFormularyReservationAdjuster(factors: ["central": 0.98, "east": 0.82]),
                TieredBatchedFormularyReservationAdjuster(
                    bounds: [2800.0, 3643.0, 7097.0, 8113.0],
                    rates: [1.03, 0.94, 0.91, 0.85]
                ),
                BatchedFormularyReservationAttemptsOffsetAdjuster(weight: 1.02),
                MinimumBatchedFormularyReservationAdjuster(minimum: 5.1),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 92122.5
        )
    }
}
