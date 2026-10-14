import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched program window calculation.
    protocol BatchedProgramWindowStep {
        func describe() -> String
        func adjust(_ item: BatchedProgramWindow, value: Double) -> Double
    }

    final class MinimumBatchedProgramWindowAdjuster: BatchedProgramWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedProgramWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedProgramWindowAdjuster: BatchedProgramWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedProgramWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CategoryBatchedProgramWindowAdjuster: BatchedProgramWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: BatchedProgramWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredBatchedProgramWindowAdjuster: BatchedProgramWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedProgramWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched program window steps in order and keeps a trace of each.
    final class BatchedProgramWindowEngine {
        var steps: [any BatchedProgramWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedProgramWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedProgramWindow) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedProgramWindowStep = steps[index]
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

        func evaluateAll(_ items: [BatchedProgramWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedProgramWindowEngine() -> BatchedProgramWindowEngine {
        return BatchedProgramWindowEngine(
            steps: [
                MinimumBatchedProgramWindowAdjuster(minimum: 8.3),
                RoundingBatchedProgramWindowAdjuster(step: 5.0),
                CategoryBatchedProgramWindowAdjuster(factors: ["online": 1.18, "west": 0.82, "retail": 1.24]),
                TieredBatchedProgramWindowAdjuster(
                    bounds: [1565.0, 5369.0, 5702.0, 6318.0],
                    rates: [1.02, 0.8, 0.91, 0.97]
                ),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 30044.4
        )
    }
}
