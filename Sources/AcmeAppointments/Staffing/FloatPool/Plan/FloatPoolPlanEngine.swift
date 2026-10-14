import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool plan calculation.
    protocol FloatPoolPlanStep {
        func describe() -> String
        func adjust(_ item: FloatPoolPlan, value: Double) -> Double
    }

    final class RegionFloatPoolPlanAdjuster: FloatPoolPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: FloatPoolPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFloatPoolPlanAdjuster: FloatPoolPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FloatPoolPlanEndsAtOffsetAdjuster: FloatPoolPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: FloatPoolPlan, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumFloatPoolPlanAdjuster: FloatPoolPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredFloatPoolPlanAdjuster: FloatPoolPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFloatPoolPlanAdjuster: FloatPoolPlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the float pool plan steps in order and keeps a trace of each.
    final class FloatPoolPlanEngine {
        var steps: [any FloatPoolPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FloatPoolPlan) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [FloatPoolPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFloatPoolPlanEngine() -> FloatPoolPlanEngine {
        return FloatPoolPlanEngine(
            steps: [
                RegionFloatPoolPlanAdjuster(factors: ["east": 1.32, "central": 0.88, "west": 1.02]),
                RoundingFloatPoolPlanAdjuster(step: 5.0),
                FloatPoolPlanEndsAtOffsetAdjuster(weight: 0.23),
                MinimumFloatPoolPlanAdjuster(minimum: 48.0),
                TieredFloatPoolPlanAdjuster(bounds: [885.0, 1845.0, 3664.0], rates: [1.05, 0.87, 1.12]),
                PercentFloatPoolPlanAdjuster(percent: 10.0),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 10704.6
        )
    }
}
