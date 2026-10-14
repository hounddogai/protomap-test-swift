import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority budget calculation.
    protocol PriorityBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: PriorityBudget, value: Double) -> Double
    }

    final class NamePriorityBudgetAdjuster: PriorityBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PriorityBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPriorityBudgetAdjuster: PriorityBudgetAdjuster {
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

        func adjust(_ item: PriorityBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPriorityBudgetAdjuster: PriorityBudgetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPriorityBudgetAdjuster: PriorityBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority budget steps in order and keeps a trace of each.
    final class PriorityBudgetEngine {
        var steps: [any PriorityBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PriorityBudget) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityBudgetAdjuster = steps[index]
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

        func evaluateAll(_ items: [PriorityBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPriorityBudgetEngine(_ flags: Kit.Flags.Registry) -> PriorityBudgetEngine {
        return PriorityBudgetEngine(
            steps: [
                NamePriorityBudgetAdjuster(factors: ["north": 1.32]),
                FlaggedPriorityBudgetAdjuster(flags: flags, flag: "priority-budget-rolling", percent: -7.3),
                RoundingPriorityBudgetAdjuster(step: 0.25),
                PercentPriorityBudgetAdjuster(percent: -6.3),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 93804.9
        )
    }
}
