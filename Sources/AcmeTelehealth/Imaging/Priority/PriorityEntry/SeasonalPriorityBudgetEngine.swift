import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal priority budget calculation.
    protocol SeasonalPriorityBudgetStep {
        func describe() -> String
        func adjust(_ item: SeasonalPriorityBudget, value: Double) -> Double
    }

    final class CapSeasonalPriorityBudgetAdjuster: SeasonalPriorityBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalPriorityBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSeasonalPriorityBudgetAdjuster: SeasonalPriorityBudgetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalPriorityBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelSeasonalPriorityBudgetAdjuster: SeasonalPriorityBudgetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalPriorityBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalPriorityBudgetAdjuster: SeasonalPriorityBudgetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalPriorityBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal priority budget steps in order and keeps a trace of each.
    final class SeasonalPriorityBudgetEngine {
        var steps: [any SeasonalPriorityBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalPriorityBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalPriorityBudget) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [SeasonalPriorityBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalPriorityBudgetEngine() -> SeasonalPriorityBudgetEngine {
        return SeasonalPriorityBudgetEngine(
            steps: [
                CapSeasonalPriorityBudgetAdjuster(cap: 17395.0),
                PercentSeasonalPriorityBudgetAdjuster(percent: 20.0),
                LabelSeasonalPriorityBudgetAdjuster(factors: ["east": 0.93]),
                TieredSeasonalPriorityBudgetAdjuster(bounds: [270.0, 8632.0, 9420.0], rates: [1.01, 1.04, 0.91]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 21369.2
        )
    }
}
