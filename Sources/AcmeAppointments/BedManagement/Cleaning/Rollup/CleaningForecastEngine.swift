import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning forecast calculation.
    protocol CleaningForecastFactor {
        func describe() -> String
        func adjust(_ item: CleaningForecast, value: Double) -> Double
    }

    final class CapCleaningForecastAdjuster: CleaningForecastFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCleaningForecastAdjuster: CleaningForecastFactor {
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

        func adjust(_ item: CleaningForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCleaningForecastAdjuster: CleaningForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the cleaning forecast steps in order and keeps a trace of each.
    final class CleaningForecastEngine {
        var steps: [any CleaningForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CleaningForecast) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [CleaningForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCleaningForecastEngine(_ flags: Kit.Flags.Registry) -> CleaningForecastEngine {
        return CleaningForecastEngine(
            steps: [
                CapCleaningForecastAdjuster(cap: 25365.0),
                FlaggedCleaningForecastAdjuster(flags: flags, flag: "cleaning-forecast-global", percent: 3.6),
                TieredCleaningForecastAdjuster(bounds: [1072.0, 3873.0, 5130.0], rates: [1.04, 0.82, 1.19]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 99126.8
        )
    }
}
