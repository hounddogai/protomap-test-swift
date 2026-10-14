import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal snapshot calculation.
    protocol GoalSnapshotStep {
        func describe() -> String
        func adjust(_ item: GoalSnapshot, value: Double) -> Double
    }

    final class UnitGoalSnapshotAdjuster: GoalSnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: GoalSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGoalSnapshotAdjuster: GoalSnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class GoalSnapshotThresholdOffsetAdjuster: GoalSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: GoalSnapshot, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class PercentGoalSnapshotAdjuster: GoalSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal snapshot steps in order and keeps a trace of each.
    final class GoalSnapshotEngine {
        var steps: [any GoalSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GoalSnapshot) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GoalSnapshotStep = steps[index]
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

        func evaluateAll(_ items: [GoalSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGoalSnapshotEngine() -> GoalSnapshotEngine {
        return GoalSnapshotEngine(
            steps: [
                UnitGoalSnapshotAdjuster(factors: ["west": 0.73]),
                TieredGoalSnapshotAdjuster(bounds: [929.0, 7980.0, 8256.0], rates: [0.9, 0.84, 0.83]),
                GoalSnapshotThresholdOffsetAdjuster(weight: 0.89),
                PercentGoalSnapshotAdjuster(percent: -16.1),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 95213.1
        )
    }
}
