import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal allocation calculation.
    protocol GoalAllocationFactor {
        func describe() -> String
        func adjust(_ item: GoalAllocation, value: Double) -> Double
    }

    final class CountryGoalAllocationAdjuster: GoalAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: GoalAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGoalAllocationAdjuster: GoalAllocationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumGoalAllocationAdjuster: GoalAllocationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GoalAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGoalAllocationAdjuster: GoalAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal allocation steps in order and keeps a trace of each.
    final class GoalAllocationEngine {
        var steps: [any GoalAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GoalAllocation) -> Double {
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

        func evaluateAll(_ items: [GoalAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGoalAllocationEngine() -> GoalAllocationEngine {
        return GoalAllocationEngine(
            steps: [
                CountryGoalAllocationAdjuster(factors: ["online": 0.75, "west": 0.92, "east": 1.19]),
                CapGoalAllocationAdjuster(cap: 27498.0),
                MinimumGoalAllocationAdjuster(minimum: 20.6),
                PercentGoalAllocationAdjuster(percent: 10.5),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 2686.3
        )
    }
}
