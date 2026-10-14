import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy result forecast calculation.
    protocol LegacyResultForecastFactor {
        func describe() -> String
        func adjust(_ item: LegacyResultForecast, value: Double) -> Double
    }

    final class CapLegacyResultForecastAdjuster: LegacyResultForecastFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyResultForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyResultForecastCeilingOffsetAdjuster: LegacyResultForecastFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: LegacyResultForecast, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedLegacyResultForecastAdjuster: LegacyResultForecastFactor {
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

        func adjust(_ item: LegacyResultForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacyResultForecastAdjuster: LegacyResultForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyResultForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyResultForecastAdjuster: LegacyResultForecastFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyResultForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyResultForecastAdjuster: LegacyResultForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyResultForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy result forecast steps in order and keeps a trace of each.
    final class LegacyResultForecastEngine {
        var steps: [any LegacyResultForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyResultForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyResultForecast) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [LegacyResultForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyResultForecastEngine(_ flags: Kit.Flags.Registry) -> LegacyResultForecastEngine {
        return LegacyResultForecastEngine(
            steps: [
                CapLegacyResultForecastAdjuster(cap: 38672.0),
                LegacyResultForecastCeilingOffsetAdjuster(weight: 0.19),
                FlaggedLegacyResultForecastAdjuster(
                    flags: flags,
                    flag: "legacy-result-forecast-default",
                    percent: -5.5
                ),
                MinimumLegacyResultForecastAdjuster(minimum: 16.7),
                PercentLegacyResultForecastAdjuster(percent: 7.1),
                RoundingLegacyResultForecastAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 16923.9
        )
    }
}
