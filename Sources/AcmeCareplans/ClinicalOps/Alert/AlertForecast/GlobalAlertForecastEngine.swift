import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global alert forecast calculation.
    protocol GlobalAlertForecastModifier {
        func describe() -> String
        func adjust(_ item: GlobalAlertForecast, value: Double) -> Double
    }

    final class FlaggedGlobalAlertForecastAdjuster: GlobalAlertForecastModifier {
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

        func adjust(_ item: GlobalAlertForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalAlertForecastAdjuster: GlobalAlertForecastModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAlertForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalAlertForecastAdjuster: GlobalAlertForecastModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalAlertForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelGlobalAlertForecastAdjuster: GlobalAlertForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalAlertForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalAlertForecastAdjuster: GlobalAlertForecastModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalAlertForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalAlertForecastAdjuster: GlobalAlertForecastModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalAlertForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global alert forecast steps in order and keeps a trace of each.
    final class GlobalAlertForecastEngine {
        var steps: [any GlobalAlertForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAlertForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalAlertForecast) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalAlertForecastModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalAlertForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalAlertForecastEngine(_ flags: Kit.Flags.Registry) -> GlobalAlertForecastEngine {
        return GlobalAlertForecastEngine(
            steps: [
                FlaggedGlobalAlertForecastAdjuster(
                    flags: flags,
                    flag: "global-alert-forecast-fallback",
                    percent: -5.6
                ),
                TieredGlobalAlertForecastAdjuster(bounds: [1505.0, 2934.0, 3001.0], rates: [1.11, 1.15, 1.01]),
                PercentGlobalAlertForecastAdjuster(percent: -23.7),
                LabelGlobalAlertForecastAdjuster(factors: ["south": 0.82, "online": 1.05, "north": 0.94]),
                CapGlobalAlertForecastAdjuster(cap: 42104.0),
                RoundingGlobalAlertForecastAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 66880.0
        )
    }
}
