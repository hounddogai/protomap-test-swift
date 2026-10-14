import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the seasonal acuity plan budget calculation.
    protocol SeasonalAcuityPlanBudgetFactor {
        func describe() -> String
        func adjust(_ item: SeasonalAcuityPlanBudget, value: Double) -> Double
    }

    final class FlaggedSeasonalAcuityPlanBudgetAdjuster: SeasonalAcuityPlanBudgetFactor {
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

        func adjust(_ item: SeasonalAcuityPlanBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalAcuityPlanBudgetAdjuster: SeasonalAcuityPlanBudgetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalAcuityPlanBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SeasonalAcuityPlanBudgetUpdatedAtOffsetAdjuster: SeasonalAcuityPlanBudgetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: SeasonalAcuityPlanBudget, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class NameSeasonalAcuityPlanBudgetAdjuster: SeasonalAcuityPlanBudgetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalAcuityPlanBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSeasonalAcuityPlanBudgetAdjuster: SeasonalAcuityPlanBudgetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalAcuityPlanBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalAcuityPlanBudgetAdjuster: SeasonalAcuityPlanBudgetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalAcuityPlanBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal acuity plan budget steps in order and keeps a trace of each.
    final class SeasonalAcuityPlanBudgetEngine {
        var steps: [any SeasonalAcuityPlanBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalAcuityPlanBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalAcuityPlanBudget) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalAcuityPlanBudgetFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalAcuityPlanBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalAcuityPlanBudgetEngine(_ flags: Kit.Flags.Registry) -> SeasonalAcuityPlanBudgetEngine {
        return SeasonalAcuityPlanBudgetEngine(
            steps: [
                FlaggedSeasonalAcuityPlanBudgetAdjuster(
                    flags: flags,
                    flag: "seasonal-acuity-plan-budget-rolling",
                    percent: -1.5
                ),
                MinimumSeasonalAcuityPlanBudgetAdjuster(minimum: 8.3),
                SeasonalAcuityPlanBudgetUpdatedAtOffsetAdjuster(weight: 0.47),
                NameSeasonalAcuityPlanBudgetAdjuster(factors: ["central": 1.33, "east": 0.74, "retail": 0.75]),
                PercentSeasonalAcuityPlanBudgetAdjuster(percent: 8.7),
                CapSeasonalAcuityPlanBudgetAdjuster(cap: 49177.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 63208.8
        )
    }
}
