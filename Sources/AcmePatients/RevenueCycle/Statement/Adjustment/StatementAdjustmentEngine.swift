import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement adjustment calculation.
    protocol StatementAdjustmentStep {
        func describe() -> String
        func adjust(_ item: StatementAdjustment, value: Double) -> Double
    }

    final class RoundingStatementAdjustmentAdjuster: StatementAdjustmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumStatementAdjustmentAdjuster: StatementAdjustmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStatementAdjustmentAdjuster: StatementAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement adjustment steps in order and keeps a trace of each.
    final class StatementAdjustmentEngine {
        var steps: [any StatementAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StatementAdjustment) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementAdjustmentStep = steps[index]
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

        func evaluateAll(_ items: [StatementAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStatementAdjustmentEngine() -> StatementAdjustmentEngine {
        return StatementAdjustmentEngine(
            steps: [
                RoundingStatementAdjustmentAdjuster(step: 0.05),
                MinimumStatementAdjustmentAdjuster(minimum: 16.7),
                PercentStatementAdjustmentAdjuster(percent: -16.7),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 89023.8
        )
    }
}
