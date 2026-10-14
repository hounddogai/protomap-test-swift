import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched care gap assignment calculation.
    protocol BatchedCareGapAssignmentModifier {
        func describe() -> String
        func adjust(_ item: BatchedCareGapAssignment, value: Double) -> Double
    }

    final class CapBatchedCareGapAssignmentAdjuster: BatchedCareGapAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedCareGapAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceBatchedCareGapAssignmentAdjuster: BatchedCareGapAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: BatchedCareGapAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentBatchedCareGapAssignmentAdjuster: BatchedCareGapAssignmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedCareGapAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched care gap assignment steps in order and keeps a trace of each.
    final class BatchedCareGapAssignmentEngine {
        var steps: [any BatchedCareGapAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCareGapAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedCareGapAssignment) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [BatchedCareGapAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedCareGapAssignmentEngine() -> BatchedCareGapAssignmentEngine {
        return BatchedCareGapAssignmentEngine(
            steps: [
                CapBatchedCareGapAssignmentAdjuster(cap: 10449.0),
                SourceBatchedCareGapAssignmentAdjuster(factors: ["west": 1.36]),
                PercentBatchedCareGapAssignmentAdjuster(percent: 25.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 10567.6
        )
    }
}
