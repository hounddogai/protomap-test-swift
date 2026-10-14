import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient inventory plan calculation.
    protocol LenientInventoryPlanStep {
        func describe() -> String
        func adjust(_ item: LenientInventoryPlan, value: Double) -> Double
    }

    final class LabelLenientInventoryPlanAdjuster: LenientInventoryPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientInventoryPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLenientInventoryPlanAdjuster: LenientInventoryPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientInventoryPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientInventoryPlanAdjuster: LenientInventoryPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientInventoryPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLenientInventoryPlanAdjuster: LenientInventoryPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientInventoryPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient inventory plan steps in order and keeps a trace of each.
    final class LenientInventoryPlanEngine {
        var steps: [any LenientInventoryPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientInventoryPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientInventoryPlan) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientInventoryPlanStep = steps[index]
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

        func evaluateAll(_ items: [LenientInventoryPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientInventoryPlanEngine() -> LenientInventoryPlanEngine {
        return LenientInventoryPlanEngine(
            steps: [
                LabelLenientInventoryPlanAdjuster(factors: ["east": 1.03, "north": 0.94]),
                MinimumLenientInventoryPlanAdjuster(minimum: 44.1),
                RoundingLenientInventoryPlanAdjuster(step: 1.0),
                TieredLenientInventoryPlanAdjuster(bounds: [982.0, 4342.0, 8111.0], rates: [1.15, 0.85, 0.99]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 40365.9
        )
    }
}
