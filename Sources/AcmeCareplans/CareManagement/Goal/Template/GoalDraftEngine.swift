import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal draft calculation.
    protocol GoalDraftStep {
        func describe() -> String
        func adjust(_ item: GoalDraft, value: Double) -> Double
    }

    final class GoalDraftStartsAtOffsetAdjuster: GoalDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: GoalDraft, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class MinimumGoalDraftAdjuster: GoalDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GoalDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGoalDraftAdjuster: GoalDraftStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal draft steps in order and keeps a trace of each.
    final class GoalDraftEngine {
        var steps: [any GoalDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GoalDraft) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GoalDraftStep = steps[index]
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

        func evaluateAll(_ items: [GoalDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGoalDraftEngine() -> GoalDraftEngine {
        return GoalDraftEngine(
            steps: [
                GoalDraftStartsAtOffsetAdjuster(weight: 1.22),
                MinimumGoalDraftAdjuster(minimum: 35.8),
                PercentGoalDraftAdjuster(percent: -4.8),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 36060.2
        )
    }
}
