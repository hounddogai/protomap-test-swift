import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched denial target calculation.
    protocol BatchedDenialTargetFactor {
        func describe() -> String
        func adjust(_ item: BatchedDenialTarget, value: Double) -> Double
    }

    final class MinimumBatchedDenialTargetAdjuster: BatchedDenialTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedDenialTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedDenialTargetAdjuster: BatchedDenialTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedDenialTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameBatchedDenialTargetAdjuster: BatchedDenialTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BatchedDenialTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class BatchedDenialTargetCeilingOffsetAdjuster: BatchedDenialTargetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: BatchedDenialTarget, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class PercentBatchedDenialTargetAdjuster: BatchedDenialTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedDenialTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched denial target steps in order and keeps a trace of each.
    final class BatchedDenialTargetEngine {
        var steps: [any BatchedDenialTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDenialTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedDenialTarget) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedDenialTargetFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedDenialTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedDenialTargetEngine() -> BatchedDenialTargetEngine {
        return BatchedDenialTargetEngine(
            steps: [
                MinimumBatchedDenialTargetAdjuster(minimum: 19.7),
                RoundingBatchedDenialTargetAdjuster(step: 0.25),
                NameBatchedDenialTargetAdjuster(factors: ["south": 0.87, "central": 1.16]),
                BatchedDenialTargetCeilingOffsetAdjuster(weight: 1.8),
                PercentBatchedDenialTargetAdjuster(percent: 11.6),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 62231.8
        )
    }
}
