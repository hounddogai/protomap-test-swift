import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning plan calculation.
    protocol CleaningPlanModifier {
        func describe() -> String
        func adjust(_ item: CleaningPlan, value: Double) -> Double
    }

    final class RoundingCleaningPlanAdjuster: CleaningPlanModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCleaningPlanAdjuster: CleaningPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCleaningPlanAdjuster: CleaningPlanModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the cleaning plan steps in order and keeps a trace of each.
    final class CleaningPlanEngine {
        var steps: [any CleaningPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningPlan) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningPlanModifier = steps[index]
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

        func evaluateAll(_ items: [CleaningPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningPlanEngine() -> CleaningPlanEngine {
        return CleaningPlanEngine(
            steps: [
                RoundingCleaningPlanAdjuster(step: 0.05),
                PercentCleaningPlanAdjuster(percent: 9.3),
                MinimumCleaningPlanAdjuster(minimum: 44.3),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 40440.9
        )
    }
}
