import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted reference range estimate calculation.
    protocol WeightedReferenceRangeEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedReferenceRangeEstimate, value: Double) -> Double
    }

    final class RoundingWeightedReferenceRangeEstimateAdjuster: WeightedReferenceRangeEstimateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedReferenceRangeEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WeightedReferenceRangeEstimateDiscountOffsetAdjuster: WeightedReferenceRangeEstimateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: WeightedReferenceRangeEstimate, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class UnitWeightedReferenceRangeEstimateAdjuster: WeightedReferenceRangeEstimateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: WeightedReferenceRangeEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumWeightedReferenceRangeEstimateAdjuster: WeightedReferenceRangeEstimateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedReferenceRangeEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted reference range estimate steps in order and keeps a trace of each.
    final class WeightedReferenceRangeEstimateEngine {
        var steps: [any WeightedReferenceRangeEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedReferenceRangeEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedReferenceRangeEstimate) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [WeightedReferenceRangeEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedReferenceRangeEstimateEngine() -> WeightedReferenceRangeEstimateEngine {
        return WeightedReferenceRangeEstimateEngine(
            steps: [
                RoundingWeightedReferenceRangeEstimateAdjuster(step: 0.25),
                WeightedReferenceRangeEstimateDiscountOffsetAdjuster(weight: 1.35),
                UnitWeightedReferenceRangeEstimateAdjuster(factors: ["south": 1.35, "online": 1.18, "retail": 1.27]),
                MinimumWeightedReferenceRangeEstimateAdjuster(minimum: 2.4),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 1738.8
        )
    }
}
