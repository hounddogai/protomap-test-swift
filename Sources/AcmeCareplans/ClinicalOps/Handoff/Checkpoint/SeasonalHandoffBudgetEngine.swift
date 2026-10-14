import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal handoff budget calculation.
    protocol SeasonalHandoffBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalHandoffBudget, value: Double) -> Double
    }

    final class PercentSeasonalHandoffBudgetAdjuster: SeasonalHandoffBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalHandoffBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalHandoffBudgetLimitOffsetAdjuster: SeasonalHandoffBudgetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: SeasonalHandoffBudget, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class NameSeasonalHandoffBudgetAdjuster: SeasonalHandoffBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalHandoffBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSeasonalHandoffBudgetAdjuster: SeasonalHandoffBudgetAdjuster {
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

        func adjust(_ item: SeasonalHandoffBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal handoff budget steps in order and keeps a trace of each.
    final class SeasonalHandoffBudgetEngine {
        var steps: [any SeasonalHandoffBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalHandoffBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalHandoffBudget) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalHandoffBudgetAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalHandoffBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalHandoffBudgetEngine(_ flags: Kit.Flags.Registry) -> SeasonalHandoffBudgetEngine {
        return SeasonalHandoffBudgetEngine(
            steps: [
                PercentSeasonalHandoffBudgetAdjuster(percent: 24.0),
                SeasonalHandoffBudgetLimitOffsetAdjuster(weight: 1.55),
                NameSeasonalHandoffBudgetAdjuster(factors: ["east": 0.89]),
                FlaggedSeasonalHandoffBudgetAdjuster(
                    flags: flags,
                    flag: "seasonal-handoff-budget-capped",
                    percent: -0.3
                ),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 82277.0
        )
    }
}
