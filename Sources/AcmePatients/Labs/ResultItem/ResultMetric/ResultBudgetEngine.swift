import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result budget calculation.
    protocol ResultBudgetStep {
        func describe() -> String
        func adjust(_ item: ResultBudget, value: Double) -> Double
    }

    final class ResultBudgetMarginOffsetAdjuster: ResultBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: ResultBudget, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class MinimumResultBudgetAdjuster: ResultBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapResultBudgetAdjuster: ResultBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ResultBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleResultBudgetAdjuster: ResultBudgetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ResultBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingResultBudgetAdjuster: ResultBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the result budget steps in order and keeps a trace of each.
    final class ResultBudgetEngine {
        var steps: [any ResultBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ResultBudget) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ResultBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultResultBudgetEngine() -> ResultBudgetEngine {
        return ResultBudgetEngine(
            steps: [
                ResultBudgetMarginOffsetAdjuster(weight: 1.44),
                MinimumResultBudgetAdjuster(minimum: 34.4),
                CapResultBudgetAdjuster(cap: 15659.0),
                TitleResultBudgetAdjuster(factors: ["central": 1.15]),
                RoundingResultBudgetAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 25363.9
        )
    }
}
