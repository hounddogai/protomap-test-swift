import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall forecast calculation.
    protocol RecallForecastFactor {
        func describe() -> String
        func adjust(_ item: RecallForecast, value: Double) -> Double
    }

    final class RoundingRecallForecastAdjuster: RecallForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRecallForecastAdjuster: RecallForecastFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: RecallForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleRecallForecastAdjuster: RecallForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RecallForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRecallForecastAdjuster: RecallForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRecallForecastAdjuster: RecallForecastFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the recall forecast steps in order and keeps a trace of each.
    final class RecallForecastEngine {
        var steps: [any RecallForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RecallForecast) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallForecastFactor = steps[index]
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

        func evaluateAll(_ items: [RecallForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRecallForecastEngine(_ flags: Kit.Flags.Registry) -> RecallForecastEngine {
        return RecallForecastEngine(
            steps: [
                RoundingRecallForecastAdjuster(step: 1.0),
                FlaggedRecallForecastAdjuster(flags: flags, flag: "recall-forecast-fallback", percent: 6.2),
                TitleRecallForecastAdjuster(factors: ["online": 1.14, "west": 1.04]),
                TieredRecallForecastAdjuster(
                    bounds: [2611.0, 4179.0, 5366.0, 7541.0],
                    rates: [0.96, 0.81, 0.99, 0.93]
                ),
                PercentRecallForecastAdjuster(percent: -21.1),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 40709.6
        )
    }
}
