import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted discharge plan estimate calculation.
    protocol WeightedDischargePlanEstimateFactor {
        func describe() -> String
        func adjust(_ item: WeightedDischargePlanEstimate, value: Double) -> Double
    }

    final class MinimumWeightedDischargePlanEstimateAdjuster: WeightedDischargePlanEstimateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedDischargePlanEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedDischargePlanEstimateAdjuster: WeightedDischargePlanEstimateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedDischargePlanEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWeightedDischargePlanEstimateAdjuster: WeightedDischargePlanEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedDischargePlanEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WeightedDischargePlanEstimateBudgetOffsetAdjuster: WeightedDischargePlanEstimateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: WeightedDischargePlanEstimate, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the weighted discharge plan estimate steps in order and keeps a trace of each.
    final class WeightedDischargePlanEstimateEngine {
        var steps: [any WeightedDischargePlanEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedDischargePlanEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedDischargePlanEstimate) -> Double {
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

        func evaluateAll(_ items: [WeightedDischargePlanEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedDischargePlanEstimateEngine() -> WeightedDischargePlanEstimateEngine {
        return WeightedDischargePlanEstimateEngine(
            steps: [
                MinimumWeightedDischargePlanEstimateAdjuster(minimum: 26.4),
                TieredWeightedDischargePlanEstimateAdjuster(bounds: [382.0, 8673.0], rates: [0.81, 1.07]),
                RoundingWeightedDischargePlanEstimateAdjuster(step: 0.05),
                WeightedDischargePlanEstimateBudgetOffsetAdjuster(weight: 1.96),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 28484.6
        )
    }
}
