import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted outreach assignment calculation.
    protocol WeightedOutreachAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedOutreachAssignment, value: Double) -> Double
    }

    final class NameWeightedOutreachAssignmentAdjuster: WeightedOutreachAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedOutreachAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumWeightedOutreachAssignmentAdjuster: WeightedOutreachAssignmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedOutreachAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingWeightedOutreachAssignmentAdjuster: WeightedOutreachAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedOutreachAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWeightedOutreachAssignmentAdjuster: WeightedOutreachAssignmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedOutreachAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted outreach assignment steps in order and keeps a trace of each.
    final class WeightedOutreachAssignmentEngine {
        var steps: [any WeightedOutreachAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedOutreachAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedOutreachAssignment) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedOutreachAssignmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedOutreachAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedOutreachAssignmentEngine() -> WeightedOutreachAssignmentEngine {
        return WeightedOutreachAssignmentEngine(
            steps: [
                NameWeightedOutreachAssignmentAdjuster(factors: ["west": 1.36]),
                MinimumWeightedOutreachAssignmentAdjuster(minimum: 36.6),
                RoundingWeightedOutreachAssignmentAdjuster(step: 0.1),
                PercentWeightedOutreachAssignmentAdjuster(percent: 22.2),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 48295.6
        )
    }
}
