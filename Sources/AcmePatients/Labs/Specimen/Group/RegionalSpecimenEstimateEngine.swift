import AcmePlatform
import Foundation

extension Labs {
    /// One step of the regional specimen estimate calculation.
    protocol RegionalSpecimenEstimateModifier {
        func describe() -> String
        func adjust(_ item: RegionalSpecimenEstimate, value: Double) -> Double
    }

    final class RegionalSpecimenEstimateBudgetOffsetAdjuster: RegionalSpecimenEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: RegionalSpecimenEstimate, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class TieredRegionalSpecimenEstimateAdjuster: RegionalSpecimenEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalSpecimenEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelRegionalSpecimenEstimateAdjuster: RegionalSpecimenEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RegionalSpecimenEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRegionalSpecimenEstimateAdjuster: RegionalSpecimenEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalSpecimenEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional specimen estimate steps in order and keeps a trace of each.
    final class RegionalSpecimenEstimateEngine {
        var steps: [any RegionalSpecimenEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalSpecimenEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalSpecimenEstimate) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalSpecimenEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalSpecimenEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalSpecimenEstimateEngine() -> RegionalSpecimenEstimateEngine {
        return RegionalSpecimenEstimateEngine(
            steps: [
                RegionalSpecimenEstimateBudgetOffsetAdjuster(weight: 1.77),
                TieredRegionalSpecimenEstimateAdjuster(
                    bounds: [256.0, 618.0, 4516.0, 5392.0],
                    rates: [1.02, 0.88, 0.85, 1.01]
                ),
                LabelRegionalSpecimenEstimateAdjuster(factors: ["east": 1.22]),
                RoundingRegionalSpecimenEstimateAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 24694.9
        )
    }
}
