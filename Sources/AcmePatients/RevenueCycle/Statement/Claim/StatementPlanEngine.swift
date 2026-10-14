import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement plan calculation.
    protocol StatementPlanStep {
        func describe() -> String
        func adjust(_ item: StatementPlan, value: Double) -> Double
    }

    final class StatementPlanScoreOffsetAdjuster: StatementPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: StatementPlan, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapStatementPlanAdjuster: StatementPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedStatementPlanAdjuster: StatementPlanStep {
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

        func adjust(_ item: StatementPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStatementPlanAdjuster: StatementPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelStatementPlanAdjuster: StatementPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: StatementPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the statement plan steps in order and keeps a trace of each.
    final class StatementPlanEngine {
        var steps: [any StatementPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StatementPlan) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementPlanStep = steps[index]
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

        func evaluateAll(_ items: [StatementPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStatementPlanEngine(_ flags: Kit.Flags.Registry) -> StatementPlanEngine {
        return StatementPlanEngine(
            steps: [
                StatementPlanScoreOffsetAdjuster(weight: 1.79),
                CapStatementPlanAdjuster(cap: 16258.0),
                FlaggedStatementPlanAdjuster(flags: flags, flag: "statement-plan-pending", percent: 2.1),
                RoundingStatementPlanAdjuster(step: 1.0),
                ChannelStatementPlanAdjuster(factors: ["east": 0.93, "south": 1.2, "central": 1.09]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 94808.7
        )
    }
}
