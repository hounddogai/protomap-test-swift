import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the legacy isolation forecast calculation.
    protocol LegacyIsolationForecastModifier {
        func describe() -> String
        func adjust(_ item: LegacyIsolationForecast, value: Double) -> Double
    }

    final class TieredLegacyIsolationForecastAdjuster: LegacyIsolationForecastModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyIsolationForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLegacyIsolationForecastAdjuster: LegacyIsolationForecastModifier {
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

        func adjust(_ item: LegacyIsolationForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacyIsolationForecastAdjuster: LegacyIsolationForecastModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyIsolationForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLegacyIsolationForecastAdjuster: LegacyIsolationForecastModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyIsolationForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LegacyIsolationForecastUpdatedAtOffsetAdjuster: LegacyIsolationForecastModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: LegacyIsolationForecast, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class NameLegacyIsolationForecastAdjuster: LegacyIsolationForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LegacyIsolationForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy isolation forecast steps in order and keeps a trace of each.
    final class LegacyIsolationForecastEngine {
        var steps: [any LegacyIsolationForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyIsolationForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyIsolationForecast) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [LegacyIsolationForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyIsolationForecastEngine(_ flags: Kit.Flags.Registry) -> LegacyIsolationForecastEngine {
        return LegacyIsolationForecastEngine(
            steps: [
                TieredLegacyIsolationForecastAdjuster(bounds: [1969.0, 6879.0], rates: [0.98, 0.98]),
                FlaggedLegacyIsolationForecastAdjuster(
                    flags: flags,
                    flag: "legacy-isolation-forecast-weighted",
                    percent: -0.8
                ),
                MinimumLegacyIsolationForecastAdjuster(minimum: 43.8),
                RoundingLegacyIsolationForecastAdjuster(step: 0.05),
                LegacyIsolationForecastUpdatedAtOffsetAdjuster(weight: 1.04),
                NameLegacyIsolationForecastAdjuster(factors: ["retail": 0.76]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 9297.9
        )
    }
}
