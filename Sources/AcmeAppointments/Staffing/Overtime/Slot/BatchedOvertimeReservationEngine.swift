import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the batched overtime reservation calculation.
    protocol BatchedOvertimeReservationStep {
        func describe() -> String
        func adjust(_ item: BatchedOvertimeReservation, value: Double) -> Double
    }

    final class MinimumBatchedOvertimeReservationAdjuster: BatchedOvertimeReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedOvertimeReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleBatchedOvertimeReservationAdjuster: BatchedOvertimeReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedOvertimeReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class BatchedOvertimeReservationLimitOffsetAdjuster: BatchedOvertimeReservationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: BatchedOvertimeReservation, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class RoundingBatchedOvertimeReservationAdjuster: BatchedOvertimeReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedOvertimeReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredBatchedOvertimeReservationAdjuster: BatchedOvertimeReservationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedOvertimeReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched overtime reservation steps in order and keeps a trace of each.
    final class BatchedOvertimeReservationEngine {
        var steps: [any BatchedOvertimeReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedOvertimeReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedOvertimeReservation) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedOvertimeReservationStep = steps[index]
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

        func evaluateAll(_ items: [BatchedOvertimeReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedOvertimeReservationEngine() -> BatchedOvertimeReservationEngine {
        return BatchedOvertimeReservationEngine(
            steps: [
                MinimumBatchedOvertimeReservationAdjuster(minimum: 19.7),
                TitleBatchedOvertimeReservationAdjuster(factors: ["north": 1.23, "online": 1.26]),
                BatchedOvertimeReservationLimitOffsetAdjuster(weight: 0.56),
                RoundingBatchedOvertimeReservationAdjuster(step: 0.05),
                TieredBatchedOvertimeReservationAdjuster(bounds: [2128.0, 3146.0, 5792.0], rates: [1.02, 0.8, 1.14]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 14580.6
        )
    }
}
