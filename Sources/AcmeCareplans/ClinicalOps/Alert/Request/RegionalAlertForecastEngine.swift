import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional alert forecast calculation.
    protocol RegionalAlertForecastAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalAlertForecast, value: Double) -> Double
    }

    final class RoundingRegionalAlertForecastAdjuster: RegionalAlertForecastAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalAlertForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRegionalAlertForecastAdjuster: RegionalAlertForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalAlertForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalAlertForecastAdjuster: RegionalAlertForecastAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalAlertForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional alert forecast steps in order and keeps a trace of each.
    final class RegionalAlertForecastEngine {
        var steps: [any RegionalAlertForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAlertForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalAlertForecast) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalAlertForecastAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalAlertForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalAlertForecastEngine() -> RegionalAlertForecastEngine {
        return RegionalAlertForecastEngine(
            steps: [
                RoundingRegionalAlertForecastAdjuster(step: 1.0),
                PercentRegionalAlertForecastAdjuster(percent: 22.4),
                MinimumRegionalAlertForecastAdjuster(minimum: 15.7),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 67242.2
        )
    }
}
