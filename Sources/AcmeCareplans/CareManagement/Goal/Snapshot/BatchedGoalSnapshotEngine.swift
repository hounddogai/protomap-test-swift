import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched goal snapshot calculation.
    protocol BatchedGoalSnapshotFactor {
        func describe() -> String
        func adjust(_ item: BatchedGoalSnapshot, value: Double) -> Double
    }

    final class CapBatchedGoalSnapshotAdjuster: BatchedGoalSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedGoalSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingBatchedGoalSnapshotAdjuster: BatchedGoalSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedGoalSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentBatchedGoalSnapshotAdjuster: BatchedGoalSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: BatchedGoalSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched goal snapshot steps in order and keeps a trace of each.
    final class BatchedGoalSnapshotEngine {
        var steps: [any BatchedGoalSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedGoalSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedGoalSnapshot) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [BatchedGoalSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedGoalSnapshotEngine() -> BatchedGoalSnapshotEngine {
        return BatchedGoalSnapshotEngine(
            steps: [
                CapBatchedGoalSnapshotAdjuster(cap: 22182.0),
                RoundingBatchedGoalSnapshotAdjuster(step: 0.1),
                SegmentBatchedGoalSnapshotAdjuster(factors: ["north": 0.71, "east": 1.29]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 97894.5
        )
    }
}
