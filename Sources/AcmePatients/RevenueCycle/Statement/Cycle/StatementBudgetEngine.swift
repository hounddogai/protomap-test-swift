import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement budget calculation.
    protocol StatementBudgetStep {
        func describe() -> String
        func adjust(_ item: StatementBudget, value: Double) -> Double
    }

    final class FlaggedStatementBudgetAdjuster: StatementBudgetStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: StatementBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStatementBudgetAdjuster: StatementBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentStatementBudgetAdjuster: StatementBudgetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStatementBudgetAdjuster: StatementBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the statement budget steps in order and keeps a trace of each.
    final class StatementBudgetEngine {
        var steps: [any StatementBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StatementBudget) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [StatementBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStatementBudgetEngine(_ flags: Kit.Flags.Registry) -> StatementBudgetEngine {
        return StatementBudgetEngine(
            steps: [
                FlaggedStatementBudgetAdjuster(flags: flags, flag: "statement-budget-manual", percent: -8.9),
                RoundingStatementBudgetAdjuster(step: 5.0),
                PercentStatementBudgetAdjuster(percent: 15.6),
                MinimumStatementBudgetAdjuster(minimum: 10.5),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 92228.3
        )
    }
}
