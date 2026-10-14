import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted formulary plan calculation.
    protocol WeightedFormularyPlanAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedFormularyPlan, value: Double) -> Double
    }

    final class PercentWeightedFormularyPlanAdjuster: WeightedFormularyPlanAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedFormularyPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedFormularyPlanAdjuster: WeightedFormularyPlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedFormularyPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelWeightedFormularyPlanAdjuster: WeightedFormularyPlanAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WeightedFormularyPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingWeightedFormularyPlanAdjuster: WeightedFormularyPlanAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedFormularyPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredWeightedFormularyPlanAdjuster: WeightedFormularyPlanAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedFormularyPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WeightedFormularyPlanSequenceOffsetAdjuster: WeightedFormularyPlanAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: WeightedFormularyPlan, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the weighted formulary plan steps in order and keeps a trace of each.
    final class WeightedFormularyPlanEngine {
        var steps: [any WeightedFormularyPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedFormularyPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedFormularyPlan) -> Double {
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

        func evaluateAll(_ items: [WeightedFormularyPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedFormularyPlanEngine() -> WeightedFormularyPlanEngine {
        return WeightedFormularyPlanEngine(
            steps: [
                PercentWeightedFormularyPlanAdjuster(percent: -22.4),
                MinimumWeightedFormularyPlanAdjuster(minimum: 7.8),
                LabelWeightedFormularyPlanAdjuster(factors: ["south": 1.29, "west": 1.09, "central": 0.84]),
                RoundingWeightedFormularyPlanAdjuster(step: 5.0),
                TieredWeightedFormularyPlanAdjuster(
                    bounds: [973.0, 3134.0, 7719.0, 8025.0],
                    rates: [1.04, 0.94, 1.03, 1.08]
                ),
                WeightedFormularyPlanSequenceOffsetAdjuster(weight: 0.63),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 54040.5
        )
    }
}
