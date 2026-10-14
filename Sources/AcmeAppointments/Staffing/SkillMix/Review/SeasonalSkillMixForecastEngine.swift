import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the seasonal skill mix forecast calculation.
    protocol SeasonalSkillMixForecastModifier {
        func describe() -> String
        func adjust(_ item: SeasonalSkillMixForecast, value: Double) -> Double
    }

    final class CapSeasonalSkillMixForecastAdjuster: SeasonalSkillMixForecastModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalSkillMixForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSeasonalSkillMixForecastAdjuster: SeasonalSkillMixForecastModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalSkillMixForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalSkillMixForecastDosageMgOffsetAdjuster: SeasonalSkillMixForecastModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: SeasonalSkillMixForecast, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class MinimumSeasonalSkillMixForecastAdjuster: SeasonalSkillMixForecastModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalSkillMixForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameSeasonalSkillMixForecastAdjuster: SeasonalSkillMixForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalSkillMixForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal skill mix forecast steps in order and keeps a trace of each.
    final class SeasonalSkillMixForecastEngine {
        var steps: [any SeasonalSkillMixForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalSkillMixForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalSkillMixForecast) -> Double {
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

        func evaluateAll(_ items: [SeasonalSkillMixForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalSkillMixForecastEngine() -> SeasonalSkillMixForecastEngine {
        return SeasonalSkillMixForecastEngine(
            steps: [
                CapSeasonalSkillMixForecastAdjuster(cap: 41412.0),
                PercentSeasonalSkillMixForecastAdjuster(percent: -20.0),
                SeasonalSkillMixForecastDosageMgOffsetAdjuster(weight: 0.63),
                MinimumSeasonalSkillMixForecastAdjuster(minimum: 4.1),
                NameSeasonalSkillMixForecastAdjuster(factors: ["retail": 0.9]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 30563.2
        )
    }
}
