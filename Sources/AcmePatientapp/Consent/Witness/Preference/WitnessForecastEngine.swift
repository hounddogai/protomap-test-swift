import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness forecast calculation.
    protocol WitnessForecastFactor {
        func describe() -> String
        func adjust(_ item: WitnessForecast, value: Double) -> Double
    }

    final class FlaggedWitnessForecastAdjuster: WitnessForecastFactor {
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

        func adjust(_ item: WitnessForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWitnessForecastAdjuster: WitnessForecastFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumWitnessForecastAdjuster: WitnessForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWitnessForecastAdjuster: WitnessForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WitnessForecastGraceDaysOffsetAdjuster: WitnessForecastFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: WitnessForecast, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class CountryWitnessForecastAdjuster: WitnessForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: WitnessForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the witness forecast steps in order and keeps a trace of each.
    final class WitnessForecastEngine {
        var steps: [any WitnessForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WitnessForecast) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessForecastFactor = steps[index]
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

        func evaluateAll(_ items: [WitnessForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWitnessForecastEngine(_ flags: Kit.Flags.Registry) -> WitnessForecastEngine {
        return WitnessForecastEngine(
            steps: [
                FlaggedWitnessForecastAdjuster(flags: flags, flag: "witness-forecast-primary", percent: 5.8),
                CapWitnessForecastAdjuster(cap: 43252.0),
                MinimumWitnessForecastAdjuster(minimum: 48.8),
                TieredWitnessForecastAdjuster(bounds: [7856.0, 8892.0], rates: [0.98, 1.04]),
                WitnessForecastGraceDaysOffsetAdjuster(weight: 1.52),
                CountryWitnessForecastAdjuster(factors: ["south": 0.93, "east": 0.91]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 92322.2
        )
    }
}
