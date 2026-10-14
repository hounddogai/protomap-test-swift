import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default recall forecast calculation.
    protocol DefaultRecallForecastStep {
        func describe() -> String
        func adjust(_ item: DefaultRecallForecast, value: Double) -> Double
    }

    final class PercentDefaultRecallForecastAdjuster: DefaultRecallForecastStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultRecallForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultRecallForecastAdjuster: DefaultRecallForecastStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRecallForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultRecallForecastAdjuster: DefaultRecallForecastStep {
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

        func adjust(_ item: DefaultRecallForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default recall forecast steps in order and keeps a trace of each.
    final class DefaultRecallForecastEngine {
        var steps: [any DefaultRecallForecastStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRecallForecastStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultRecallForecast) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultRecallForecastStep = steps[index]
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

        func evaluateAll(_ items: [DefaultRecallForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultRecallForecastEngine(_ flags: Kit.Flags.Registry) -> DefaultRecallForecastEngine {
        return DefaultRecallForecastEngine(
            steps: [
                PercentDefaultRecallForecastAdjuster(percent: 10.4),
                MinimumDefaultRecallForecastAdjuster(minimum: 46.4),
                FlaggedDefaultRecallForecastAdjuster(
                    flags: flags,
                    flag: "default-recall-forecast-strict",
                    percent: 3.7
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 51367.9
        )
    }
}
