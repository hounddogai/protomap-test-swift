import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning batch calculation.
    protocol CleaningBatchStep {
        func describe() -> String
        func adjust(_ item: CleaningBatch, value: Double) -> Double
    }

    final class CleaningBatchQuantityOffsetAdjuster: CleaningBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: CleaningBatch, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class PercentCleaningBatchAdjuster: CleaningBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCleaningBatchAdjuster: CleaningBatchStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the cleaning batch steps in order and keeps a trace of each.
    final class CleaningBatchEngine {
        var steps: [any CleaningBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CleaningBatch) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CleaningBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCleaningBatchEngine() -> CleaningBatchEngine {
        return CleaningBatchEngine(
            steps: [
                CleaningBatchQuantityOffsetAdjuster(weight: 0.66),
                PercentCleaningBatchAdjuster(percent: -22.1),
                RoundingCleaningBatchAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 49422.5
        )
    }
}
