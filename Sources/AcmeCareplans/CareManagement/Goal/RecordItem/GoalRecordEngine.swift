import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal record calculation.
    protocol GoalRecordStep {
        func describe() -> String
        func adjust(_ item: GoalRecord, value: Double) -> Double
    }

    final class MinimumGoalRecordAdjuster: GoalRecordStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GoalRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentGoalRecordAdjuster: GoalRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: GoalRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGoalRecordAdjuster: GoalRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGoalRecordAdjuster: GoalRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGoalRecordAdjuster: GoalRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the goal record steps in order and keeps a trace of each.
    final class GoalRecordEngine {
        var steps: [any GoalRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GoalRecord) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GoalRecordStep = steps[index]
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

        func evaluateAll(_ items: [GoalRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGoalRecordEngine() -> GoalRecordEngine {
        return GoalRecordEngine(
            steps: [
                MinimumGoalRecordAdjuster(minimum: 13.1),
                SegmentGoalRecordAdjuster(factors: ["online": 1.18]),
                PercentGoalRecordAdjuster(percent: -0.6),
                CapGoalRecordAdjuster(cap: 13142.0),
                RoundingGoalRecordAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 96026.0
        )
    }
}
