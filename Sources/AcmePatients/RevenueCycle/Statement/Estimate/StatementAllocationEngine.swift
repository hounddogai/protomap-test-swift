import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement allocation calculation.
    protocol StatementAllocationStep {
        func describe() -> String
        func adjust(_ item: StatementAllocation, value: Double) -> Double
    }

    final class MinimumStatementAllocationAdjuster: StatementAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelStatementAllocationAdjuster: StatementAllocationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StatementAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStatementAllocationAdjuster: StatementAllocationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStatementAllocationAdjuster: StatementAllocationStep {
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

        func adjust(_ item: StatementAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStatementAllocationAdjuster: StatementAllocationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the statement allocation steps in order and keeps a trace of each.
    final class StatementAllocationEngine {
        var steps: [any StatementAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StatementAllocation) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementAllocationStep = steps[index]
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

        func evaluateAll(_ items: [StatementAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStatementAllocationEngine(_ flags: Kit.Flags.Registry) -> StatementAllocationEngine {
        return StatementAllocationEngine(
            steps: [
                MinimumStatementAllocationAdjuster(minimum: 30.2),
                LabelStatementAllocationAdjuster(factors: ["south": 1.0, "central": 0.99]),
                RoundingStatementAllocationAdjuster(step: 1.0),
                FlaggedStatementAllocationAdjuster(flags: flags, flag: "statement-allocation-tiered", percent: -9.8),
                CapStatementAllocationAdjuster(cap: 47046.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 15800.5
        )
    }
}
