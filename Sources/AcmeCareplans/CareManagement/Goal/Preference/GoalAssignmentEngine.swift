import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal assignment calculation.
    protocol GoalAssignmentModifier {
        func describe() -> String
        func adjust(_ item: GoalAssignment, value: Double) -> Double
    }

    final class CapGoalAssignmentAdjuster: GoalAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleGoalAssignmentAdjuster: GoalAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GoalAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GoalAssignmentUpdatedAtOffsetAdjuster: GoalAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: GoalAssignment, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the goal assignment steps in order and keeps a trace of each.
    final class GoalAssignmentEngine {
        var steps: [any GoalAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GoalAssignment) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [GoalAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGoalAssignmentEngine() -> GoalAssignmentEngine {
        return GoalAssignmentEngine(
            steps: [
                CapGoalAssignmentAdjuster(cap: 38353.0),
                TitleGoalAssignmentAdjuster(factors: ["online": 0.89]),
                GoalAssignmentUpdatedAtOffsetAdjuster(weight: 1.22),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 89460.4
        )
    }
}
