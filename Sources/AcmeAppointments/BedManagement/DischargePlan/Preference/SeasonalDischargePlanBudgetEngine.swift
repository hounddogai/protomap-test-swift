import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the seasonal discharge plan budget calculation.
    protocol SeasonalDischargePlanBudgetModifier {
        func describe() -> String
        func adjust(_ item: SeasonalDischargePlanBudget, value: Double) -> Double
    }

    final class TieredSeasonalDischargePlanBudgetAdjuster: SeasonalDischargePlanBudgetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalDischargePlanBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumSeasonalDischargePlanBudgetAdjuster: SeasonalDischargePlanBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalDischargePlanBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapSeasonalDischargePlanBudgetAdjuster: SeasonalDischargePlanBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalDischargePlanBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSeasonalDischargePlanBudgetAdjuster: SeasonalDischargePlanBudgetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalDischargePlanBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal discharge plan budget steps in order and keeps a trace of each.
    final class SeasonalDischargePlanBudgetEngine {
        var steps: [any SeasonalDischargePlanBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalDischargePlanBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalDischargePlanBudget) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalDischargePlanBudgetModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalDischargePlanBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalDischargePlanBudgetEngine() -> SeasonalDischargePlanBudgetEngine {
        return SeasonalDischargePlanBudgetEngine(
            steps: [
                TieredSeasonalDischargePlanBudgetAdjuster(bounds: [5576.0, 5831.0], rates: [0.82, 0.97]),
                MinimumSeasonalDischargePlanBudgetAdjuster(minimum: 20.4),
                CapSeasonalDischargePlanBudgetAdjuster(cap: 16095.0),
                PercentSeasonalDischargePlanBudgetAdjuster(percent: -10.8),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 56811.8
        )
    }
}
