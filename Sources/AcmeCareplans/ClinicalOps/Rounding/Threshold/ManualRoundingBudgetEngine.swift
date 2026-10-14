import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual rounding budget calculation.
    protocol ManualRoundingBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: ManualRoundingBudget, value: Double) -> Double
    }

    final class TieredManualRoundingBudgetAdjuster: ManualRoundingBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualRoundingBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentManualRoundingBudgetAdjuster: ManualRoundingBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualRoundingBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualRoundingBudgetAdjuster: ManualRoundingBudgetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualRoundingBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleManualRoundingBudgetAdjuster: ManualRoundingBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ManualRoundingBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumManualRoundingBudgetAdjuster: ManualRoundingBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRoundingBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual rounding budget steps in order and keeps a trace of each.
    final class ManualRoundingBudgetEngine {
        var steps: [any ManualRoundingBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRoundingBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualRoundingBudget) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [ManualRoundingBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualRoundingBudgetEngine() -> ManualRoundingBudgetEngine {
        return ManualRoundingBudgetEngine(
            steps: [
                TieredManualRoundingBudgetAdjuster(bounds: [6285.0, 8013.0, 9219.0], rates: [1.07, 0.88, 1.19]),
                PercentManualRoundingBudgetAdjuster(percent: 3.6),
                RoundingManualRoundingBudgetAdjuster(step: 0.05),
                TitleManualRoundingBudgetAdjuster(factors: ["retail": 0.84, "central": 1.31]),
                MinimumManualRoundingBudgetAdjuster(minimum: 47.6),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 50113.3
        )
    }
}
