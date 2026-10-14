import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the batched modality mapping calculation.
    protocol BatchedModalityMappingStep {
        func describe() -> String
        func adjust(_ item: BatchedModalityMapping, value: Double) -> Double
    }

    final class CapBatchedModalityMappingAdjuster: BatchedModalityMappingStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedModalityMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentBatchedModalityMappingAdjuster: BatchedModalityMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedModalityMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameBatchedModalityMappingAdjuster: BatchedModalityMappingStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BatchedModalityMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBatchedModalityMappingAdjuster: BatchedModalityMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedModalityMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedModalityMappingAdjuster: BatchedModalityMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedModalityMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched modality mapping steps in order and keeps a trace of each.
    final class BatchedModalityMappingEngine {
        var steps: [any BatchedModalityMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedModalityMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedModalityMapping) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedModalityMappingStep = steps[index]
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

        func evaluateAll(_ items: [BatchedModalityMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedModalityMappingEngine() -> BatchedModalityMappingEngine {
        return BatchedModalityMappingEngine(
            steps: [
                CapBatchedModalityMappingAdjuster(cap: 35373.0),
                PercentBatchedModalityMappingAdjuster(percent: -8.2),
                NameBatchedModalityMappingAdjuster(factors: ["central": 0.79, "retail": 0.97, "north": 1.26]),
                MinimumBatchedModalityMappingAdjuster(minimum: 41.1),
                RoundingBatchedModalityMappingAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 63799.1
        )
    }
}
