import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched statement budget calculation.
    protocol BatchedStatementBudgetModifier {
        func describe() -> String
        func adjust(_ item: BatchedStatementBudget, value: Double) -> Double
    }

    final class MinimumBatchedStatementBudgetAdjuster: BatchedStatementBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedStatementBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameBatchedStatementBudgetAdjuster: BatchedStatementBudgetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BatchedStatementBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBatchedStatementBudgetAdjuster: BatchedStatementBudgetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedStatementBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class BatchedStatementBudgetUpdatedAtOffsetAdjuster: BatchedStatementBudgetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: BatchedStatementBudget, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapBatchedStatementBudgetAdjuster: BatchedStatementBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedStatementBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedStatementBudgetAdjuster: BatchedStatementBudgetModifier {
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

        func adjust(_ item: BatchedStatementBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched statement budget steps in order and keeps a trace of each.
    final class BatchedStatementBudgetEngine {
        var steps: [any BatchedStatementBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedStatementBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedStatementBudget) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedStatementBudgetModifier = steps[index]
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

        func evaluateAll(_ items: [BatchedStatementBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedStatementBudgetEngine(_ flags: Kit.Flags.Registry) -> BatchedStatementBudgetEngine {
        return BatchedStatementBudgetEngine(
            steps: [
                MinimumBatchedStatementBudgetAdjuster(minimum: 33.6),
                NameBatchedStatementBudgetAdjuster(factors: ["central": 1.02]),
                RoundingBatchedStatementBudgetAdjuster(step: 5.0),
                BatchedStatementBudgetUpdatedAtOffsetAdjuster(weight: 0.65),
                CapBatchedStatementBudgetAdjuster(cap: 13734.0),
                FlaggedBatchedStatementBudgetAdjuster(
                    flags: flags,
                    flag: "batched-statement-budget-regional",
                    percent: 7.4
                ),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 19054.3
        )
    }
}
