import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending goal snapshot calculation.
    protocol PendingGoalSnapshotStep {
        func describe() -> String
        func adjust(_ item: PendingGoalSnapshot, value: Double) -> Double
    }

    final class MinimumPendingGoalSnapshotAdjuster: PendingGoalSnapshotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingGoalSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPendingGoalSnapshotAdjuster: PendingGoalSnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingGoalSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CategoryPendingGoalSnapshotAdjuster: PendingGoalSnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PendingGoalSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPendingGoalSnapshotAdjuster: PendingGoalSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingGoalSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending goal snapshot steps in order and keeps a trace of each.
    final class PendingGoalSnapshotEngine {
        var steps: [any PendingGoalSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingGoalSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingGoalSnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingGoalSnapshotStep = steps[index]
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

        func evaluateAll(_ items: [PendingGoalSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingGoalSnapshotEngine() -> PendingGoalSnapshotEngine {
        return PendingGoalSnapshotEngine(
            steps: [
                MinimumPendingGoalSnapshotAdjuster(minimum: 15.9),
                TieredPendingGoalSnapshotAdjuster(bounds: [5397.0, 7322.0], rates: [1.08, 1.04]),
                CategoryPendingGoalSnapshotAdjuster(factors: ["south": 1.31, "online": 0.91]),
                PercentPendingGoalSnapshotAdjuster(percent: -11.3),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 4097.3
        )
    }
}
