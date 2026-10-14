import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict priority plan calculation.
    protocol StrictPriorityPlanStep {
        func describe() -> String
        func adjust(_ item: StrictPriorityPlan, value: Double) -> Double
    }

    final class RoundingStrictPriorityPlanAdjuster: StrictPriorityPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictPriorityPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleStrictPriorityPlanAdjuster: StrictPriorityPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StrictPriorityPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStrictPriorityPlanAdjuster: StrictPriorityPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictPriorityPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict priority plan steps in order and keeps a trace of each.
    final class StrictPriorityPlanEngine {
        var steps: [any StrictPriorityPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictPriorityPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictPriorityPlan) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [StrictPriorityPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictPriorityPlanEngine() -> StrictPriorityPlanEngine {
        return StrictPriorityPlanEngine(
            steps: [
                RoundingStrictPriorityPlanAdjuster(step: 0.25),
                TitleStrictPriorityPlanAdjuster(factors: ["retail": 1.01]),
                TieredStrictPriorityPlanAdjuster(
                    bounds: [516.0, 3606.0, 8777.0, 9511.0],
                    rates: [1.18, 0.92, 1.19, 1.17]
                ),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 53372.2
        )
    }
}
