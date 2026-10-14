import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal request calculation.
    protocol GoalRequestStep {
        func describe() -> String
        func adjust(_ item: GoalRequest, value: Double) -> Double
    }

    final class PercentGoalRequestAdjuster: GoalRequestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGoalRequestAdjuster: GoalRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GoalRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGoalRequestAdjuster: GoalRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GoalRequestBatchSizeOffsetAdjuster: GoalRequestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: GoalRequest, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the goal request steps in order and keeps a trace of each.
    final class GoalRequestEngine {
        var steps: [any GoalRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GoalRequest) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [GoalRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGoalRequestEngine() -> GoalRequestEngine {
        return GoalRequestEngine(
            steps: [
                PercentGoalRequestAdjuster(percent: -5.6),
                MinimumGoalRequestAdjuster(minimum: 12.1),
                CapGoalRequestAdjuster(cap: 27382.0),
                GoalRequestBatchSizeOffsetAdjuster(weight: 1.93),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 54555.0
        )
    }
}
