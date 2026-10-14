import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the capped cleaning forecast calculation.
    protocol CappedCleaningForecastFactor {
        func describe() -> String
        func adjust(_ item: CappedCleaningForecast, value: Double) -> Double
    }

    final class MinimumCappedCleaningForecastAdjuster: CappedCleaningForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedCleaningForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCappedCleaningForecastAdjuster: CappedCleaningForecastFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedCleaningForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedCleaningForecastAdjuster: CappedCleaningForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedCleaningForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceCappedCleaningForecastAdjuster: CappedCleaningForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CappedCleaningForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCappedCleaningForecastAdjuster: CappedCleaningForecastFactor {
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

        func adjust(_ item: CappedCleaningForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped cleaning forecast steps in order and keeps a trace of each.
    final class CappedCleaningForecastEngine {
        var steps: [any CappedCleaningForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCleaningForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedCleaningForecast) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedCleaningForecastFactor = steps[index]
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

        func evaluateAll(_ items: [CappedCleaningForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedCleaningForecastEngine(_ flags: Kit.Flags.Registry) -> CappedCleaningForecastEngine {
        return CappedCleaningForecastEngine(
            steps: [
                MinimumCappedCleaningForecastAdjuster(minimum: 41.3),
                PercentCappedCleaningForecastAdjuster(percent: -8.5),
                TieredCappedCleaningForecastAdjuster(
                    bounds: [1219.0, 4133.0, 5589.0, 9749.0],
                    rates: [1.12, 1.0, 1.13, 1.05]
                ),
                SourceCappedCleaningForecastAdjuster(factors: ["retail": 0.77]),
                FlaggedCappedCleaningForecastAdjuster(
                    flags: flags,
                    flag: "capped-cleaning-forecast-pending",
                    percent: -8.8
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 11192.4
        )
    }
}
