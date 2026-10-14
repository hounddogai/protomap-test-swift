import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched dispense policy calculation.
    protocol BatchedDispensePolicyAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedDispensePolicy, value: Double) -> Double
    }

    final class RoundingBatchedDispensePolicyAdjuster: BatchedDispensePolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedDispensePolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class BatchedDispensePolicyCostOffsetAdjuster: BatchedDispensePolicyAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: BatchedDispensePolicy, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class PercentBatchedDispensePolicyAdjuster: BatchedDispensePolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedDispensePolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched dispense policy steps in order and keeps a trace of each.
    final class BatchedDispensePolicyEngine {
        var steps: [any BatchedDispensePolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDispensePolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedDispensePolicy) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedDispensePolicyAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedDispensePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedDispensePolicyEngine() -> BatchedDispensePolicyEngine {
        return BatchedDispensePolicyEngine(
            steps: [
                RoundingBatchedDispensePolicyAdjuster(step: 0.05),
                BatchedDispensePolicyCostOffsetAdjuster(weight: 0.39),
                PercentBatchedDispensePolicyAdjuster(percent: 17.5),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 76712.5
        )
    }
}
