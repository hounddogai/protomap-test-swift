import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive denial forecast calculation.
    protocol AdaptiveDenialForecastAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveDenialForecast, value: Double) -> Double
    }

    final class AdaptiveDenialForecastDurationMinutesOffsetAdjuster: AdaptiveDenialForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: AdaptiveDenialForecast, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class PercentAdaptiveDenialForecastAdjuster: AdaptiveDenialForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveDenialForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAdaptiveDenialForecastAdjuster: AdaptiveDenialForecastAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveDenialForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAdaptiveDenialForecastAdjuster: AdaptiveDenialForecastAdjuster {
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

        func adjust(_ item: AdaptiveDenialForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleAdaptiveDenialForecastAdjuster: AdaptiveDenialForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: AdaptiveDenialForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the adaptive denial forecast steps in order and keeps a trace of each.
    final class AdaptiveDenialForecastEngine {
        var steps: [any AdaptiveDenialForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveDenialForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveDenialForecast) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveDenialForecastAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveDenialForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveDenialForecastEngine(_ flags: Kit.Flags.Registry) -> AdaptiveDenialForecastEngine {
        return AdaptiveDenialForecastEngine(
            steps: [
                AdaptiveDenialForecastDurationMinutesOffsetAdjuster(weight: 1.05),
                PercentAdaptiveDenialForecastAdjuster(percent: -12.7),
                RoundingAdaptiveDenialForecastAdjuster(step: 5.0),
                FlaggedAdaptiveDenialForecastAdjuster(
                    flags: flags,
                    flag: "adaptive-denial-forecast-default",
                    percent: 4.0
                ),
                LocaleAdaptiveDenialForecastAdjuster(factors: ["central": 0.99, "west": 1.16]),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 66365.3
        )
    }
}
