import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the batched handoff window calculation.
    protocol BatchedHandoffWindowStep {
        func describe() -> String
        func adjust(_ item: BatchedHandoffWindow, value: Double) -> Double
    }

    final class RoundingBatchedHandoffWindowAdjuster: BatchedHandoffWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedHandoffWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumBatchedHandoffWindowAdjuster: BatchedHandoffWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedHandoffWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapBatchedHandoffWindowAdjuster: BatchedHandoffWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedHandoffWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the batched handoff window steps in order and keeps a trace of each.
    final class BatchedHandoffWindowEngine {
        var steps: [any BatchedHandoffWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedHandoffWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedHandoffWindow) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedHandoffWindowStep = steps[index]
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

        func evaluateAll(_ items: [BatchedHandoffWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedHandoffWindowEngine() -> BatchedHandoffWindowEngine {
        return BatchedHandoffWindowEngine(
            steps: [
                RoundingBatchedHandoffWindowAdjuster(step: 5.0),
                MinimumBatchedHandoffWindowAdjuster(minimum: 19.5),
                CapBatchedHandoffWindowAdjuster(cap: 16519.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 34041.3
        )
    }
}
