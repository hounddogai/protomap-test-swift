import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the batched credential schedule calculation.
    protocol BatchedCredentialScheduleStep {
        func describe() -> String
        func adjust(_ item: BatchedCredentialSchedule, value: Double) -> Double
    }

    final class BatchedCredentialSchedulePriorityOffsetAdjuster: BatchedCredentialScheduleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: BatchedCredentialSchedule, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class UnitBatchedCredentialScheduleAdjuster: BatchedCredentialScheduleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: BatchedCredentialSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapBatchedCredentialScheduleAdjuster: BatchedCredentialScheduleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedCredentialSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingBatchedCredentialScheduleAdjuster: BatchedCredentialScheduleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedCredentialSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched credential schedule steps in order and keeps a trace of each.
    final class BatchedCredentialScheduleEngine {
        var steps: [any BatchedCredentialScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCredentialScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedCredentialSchedule) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [BatchedCredentialSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedCredentialScheduleEngine() -> BatchedCredentialScheduleEngine {
        return BatchedCredentialScheduleEngine(
            steps: [
                BatchedCredentialSchedulePriorityOffsetAdjuster(weight: 0.09),
                UnitBatchedCredentialScheduleAdjuster(factors: ["central": 0.73]),
                CapBatchedCredentialScheduleAdjuster(cap: 31849.0),
                RoundingBatchedCredentialScheduleAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 78497.1
        )
    }
}
