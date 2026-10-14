import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task reservation calculation.
    protocol TaskReservationAdjuster {
        func describe() -> String
        func adjust(_ item: TaskReservation, value: Double) -> Double
    }

    final class MinimumTaskReservationAdjuster: TaskReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TaskReservationCapacityOffsetAdjuster: TaskReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: TaskReservation, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class RoundingTaskReservationAdjuster: TaskReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapTaskReservationAdjuster: TaskReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredTaskReservationAdjuster: TaskReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the task reservation steps in order and keeps a trace of each.
    final class TaskReservationEngine {
        var steps: [any TaskReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TaskReservation) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [TaskReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTaskReservationEngine() -> TaskReservationEngine {
        return TaskReservationEngine(
            steps: [
                MinimumTaskReservationAdjuster(minimum: 45.6),
                TaskReservationCapacityOffsetAdjuster(weight: 1.56),
                RoundingTaskReservationAdjuster(step: 0.05),
                CapTaskReservationAdjuster(cap: 39352.0),
                TieredTaskReservationAdjuster(
                    bounds: [425.0, 3564.0, 4802.0, 5896.0],
                    rates: [0.96, 0.83, 1.18, 0.86]
                ),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 46844.4
        )
    }
}
