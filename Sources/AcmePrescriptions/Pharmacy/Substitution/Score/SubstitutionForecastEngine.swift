import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution forecast calculation.
    protocol SubstitutionForecastStep {
        func describe() -> String
        func adjust(_ item: SubstitutionForecast, value: Double) -> Double
    }

    final class RoundingSubstitutionForecastAdjuster: SubstitutionForecastStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSubstitutionForecastAdjuster: SubstitutionForecastStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSubstitutionForecastAdjuster: SubstitutionForecastStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SubstitutionForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SubstitutionForecastDiscountOffsetAdjuster: SubstitutionForecastStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: SubstitutionForecast, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the substitution forecast steps in order and keeps a trace of each.
    final class SubstitutionForecastEngine {
        var steps: [any SubstitutionForecastStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionForecastStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SubstitutionForecast) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionForecastStep = steps[index]
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

        func evaluateAll(_ items: [SubstitutionForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSubstitutionForecastEngine() -> SubstitutionForecastEngine {
        return SubstitutionForecastEngine(
            steps: [
                RoundingSubstitutionForecastAdjuster(step: 0.5),
                MinimumSubstitutionForecastAdjuster(minimum: 31.8),
                TieredSubstitutionForecastAdjuster(bounds: [317.0, 7645.0], rates: [0.9, 1.19]),
                SubstitutionForecastDiscountOffsetAdjuster(weight: 0.75),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 14401.9
        )
    }
}
