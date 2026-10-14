import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result forecast calculation.
    protocol ResultForecastStep {
        func describe() -> String
        func adjust(_ item: ResultForecast, value: Double) -> Double
    }

    final class FlaggedResultForecastAdjuster: ResultForecastStep {
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

        func adjust(_ item: ResultForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingResultForecastAdjuster: ResultForecastStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentResultForecastAdjuster: ResultForecastStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ResultForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumResultForecastAdjuster: ResultForecastStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredResultForecastAdjuster: ResultForecastStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ResultForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the result forecast steps in order and keeps a trace of each.
    final class ResultForecastEngine {
        var steps: [any ResultForecastStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultForecastStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ResultForecast) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [ResultForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultResultForecastEngine(_ flags: Kit.Flags.Registry) -> ResultForecastEngine {
        return ResultForecastEngine(
            steps: [
                FlaggedResultForecastAdjuster(flags: flags, flag: "result-forecast-adaptive", percent: 1.5),
                RoundingResultForecastAdjuster(step: 0.5),
                PercentResultForecastAdjuster(percent: 13.3),
                MinimumResultForecastAdjuster(minimum: 41.8),
                TieredResultForecastAdjuster(bounds: [1112.0, 3829.0], rates: [0.96, 1.18]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 49365.7
        )
    }
}
