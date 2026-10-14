import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional substitution forecast calculation.
    protocol RegionalSubstitutionForecastAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalSubstitutionForecast, value: Double) -> Double
    }

    final class RoundingRegionalSubstitutionForecastAdjuster: RegionalSubstitutionForecastAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalSubstitutionForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRegionalSubstitutionForecastAdjuster: RegionalSubstitutionForecastAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalSubstitutionForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameRegionalSubstitutionForecastAdjuster: RegionalSubstitutionForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalSubstitutionForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RegionalSubstitutionForecastMaximumOffsetAdjuster: RegionalSubstitutionForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: RegionalSubstitutionForecast, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the regional substitution forecast steps in order and keeps a trace of each.
    final class RegionalSubstitutionForecastEngine {
        var steps: [any RegionalSubstitutionForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalSubstitutionForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalSubstitutionForecast) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [RegionalSubstitutionForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalSubstitutionForecastEngine() -> RegionalSubstitutionForecastEngine {
        return RegionalSubstitutionForecastEngine(
            steps: [
                RoundingRegionalSubstitutionForecastAdjuster(step: 1.0),
                CapRegionalSubstitutionForecastAdjuster(cap: 5143.0),
                NameRegionalSubstitutionForecastAdjuster(factors: ["south": 0.76, "online": 1.02]),
                RegionalSubstitutionForecastMaximumOffsetAdjuster(weight: 1.49),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 61763.5
        )
    }
}
