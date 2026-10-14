import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted formulary estimate calculation.
    protocol WeightedFormularyEstimateStep {
        func describe() -> String
        func adjust(_ item: WeightedFormularyEstimate, value: Double) -> Double
    }

    final class WeightedFormularyEstimateQuantityOffsetAdjuster: WeightedFormularyEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: WeightedFormularyEstimate, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class MinimumWeightedFormularyEstimateAdjuster: WeightedFormularyEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedFormularyEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelWeightedFormularyEstimateAdjuster: WeightedFormularyEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WeightedFormularyEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted formulary estimate steps in order and keeps a trace of each.
    final class WeightedFormularyEstimateEngine {
        var steps: [any WeightedFormularyEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedFormularyEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedFormularyEstimate) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedFormularyEstimateStep = steps[index]
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

        func evaluateAll(_ items: [WeightedFormularyEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedFormularyEstimateEngine() -> WeightedFormularyEstimateEngine {
        return WeightedFormularyEstimateEngine(
            steps: [
                WeightedFormularyEstimateQuantityOffsetAdjuster(weight: 0.56),
                MinimumWeightedFormularyEstimateAdjuster(minimum: 39.3),
                LabelWeightedFormularyEstimateAdjuster(factors: ["north": 0.83, "central": 1.13]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 48799.8
        )
    }
}
