import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the legacy cleaning forecast calculation.
    protocol LegacyCleaningForecastAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyCleaningForecast, value: Double) -> Double
    }

    final class RoundingLegacyCleaningForecastAdjuster: LegacyCleaningForecastAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyCleaningForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleLegacyCleaningForecastAdjuster: LegacyCleaningForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacyCleaningForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLegacyCleaningForecastAdjuster: LegacyCleaningForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyCleaningForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy cleaning forecast steps in order and keeps a trace of each.
    final class LegacyCleaningForecastEngine {
        var steps: [any LegacyCleaningForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCleaningForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyCleaningForecast) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyCleaningForecastAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyCleaningForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyCleaningForecastEngine() -> LegacyCleaningForecastEngine {
        return LegacyCleaningForecastEngine(
            steps: [
                RoundingLegacyCleaningForecastAdjuster(step: 0.5),
                TitleLegacyCleaningForecastAdjuster(factors: ["north": 1.07, "south": 1.18, "central": 1.17]),
                PercentLegacyCleaningForecastAdjuster(percent: -5.8),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 25448.1
        )
    }
}
