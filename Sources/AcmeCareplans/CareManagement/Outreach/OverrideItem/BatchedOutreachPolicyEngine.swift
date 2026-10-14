import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched outreach policy calculation.
    protocol BatchedOutreachPolicyFactor {
        func describe() -> String
        func adjust(_ item: BatchedOutreachPolicy, value: Double) -> Double
    }

    final class PercentBatchedOutreachPolicyAdjuster: BatchedOutreachPolicyFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedOutreachPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameBatchedOutreachPolicyAdjuster: BatchedOutreachPolicyFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BatchedOutreachPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBatchedOutreachPolicyAdjuster: BatchedOutreachPolicyFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedOutreachPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched outreach policy steps in order and keeps a trace of each.
    final class BatchedOutreachPolicyEngine {
        var steps: [any BatchedOutreachPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedOutreachPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedOutreachPolicy) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedOutreachPolicyFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedOutreachPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedOutreachPolicyEngine() -> BatchedOutreachPolicyEngine {
        return BatchedOutreachPolicyEngine(
            steps: [
                PercentBatchedOutreachPolicyAdjuster(percent: -11.3),
                NameBatchedOutreachPolicyAdjuster(factors: ["central": 1.13]),
                RoundingBatchedOutreachPolicyAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 46256.1
        )
    }
}
