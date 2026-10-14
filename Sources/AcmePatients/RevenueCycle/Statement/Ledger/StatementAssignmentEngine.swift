import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement assignment calculation.
    protocol StatementAssignmentFactor {
        func describe() -> String
        func adjust(_ item: StatementAssignment, value: Double) -> Double
    }

    final class TieredStatementAssignmentAdjuster: StatementAssignmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StatementAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelStatementAssignmentAdjuster: StatementAssignmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StatementAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStatementAssignmentAdjuster: StatementAssignmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStatementAssignmentAdjuster: StatementAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement assignment steps in order and keeps a trace of each.
    final class StatementAssignmentEngine {
        var steps: [any StatementAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StatementAssignment) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [StatementAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStatementAssignmentEngine() -> StatementAssignmentEngine {
        return StatementAssignmentEngine(
            steps: [
                TieredStatementAssignmentAdjuster(
                    bounds: [1432.0, 3600.0, 7861.0, 8611.0],
                    rates: [0.81, 1.09, 1.05, 1.19]
                ),
                LabelStatementAssignmentAdjuster(factors: ["east": 1.25, "central": 1.22, "north": 1.35]),
                MinimumStatementAssignmentAdjuster(minimum: 1.8),
                PercentStatementAssignmentAdjuster(percent: -10.2),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 51788.5
        )
    }
}
