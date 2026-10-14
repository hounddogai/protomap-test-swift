import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling census forecast calculation.
    protocol RollingCensusForecastAdjuster {
        func describe() -> String
        func adjust(_ item: RollingCensusForecast, value: Double) -> Double
    }

    final class TieredRollingCensusForecastAdjuster: RollingCensusForecastAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingCensusForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RollingCensusForecastCopayOffsetAdjuster: RollingCensusForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: RollingCensusForecast, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class CapRollingCensusForecastAdjuster: RollingCensusForecastAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingCensusForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRollingCensusForecastAdjuster: RollingCensusForecastAdjuster {
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

        func adjust(_ item: RollingCensusForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRollingCensusForecastAdjuster: RollingCensusForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingCensusForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling census forecast steps in order and keeps a trace of each.
    final class RollingCensusForecastEngine {
        var steps: [any RollingCensusForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCensusForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingCensusForecast) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [RollingCensusForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingCensusForecastEngine(_ flags: Kit.Flags.Registry) -> RollingCensusForecastEngine {
        return RollingCensusForecastEngine(
            steps: [
                TieredRollingCensusForecastAdjuster(
                    bounds: [1716.0, 2788.0, 8313.0, 9623.0],
                    rates: [1.03, 0.89, 0.91, 1.17]
                ),
                RollingCensusForecastCopayOffsetAdjuster(weight: 1.4),
                CapRollingCensusForecastAdjuster(cap: 22476.0),
                FlaggedRollingCensusForecastAdjuster(
                    flags: flags,
                    flag: "rolling-census-forecast-pending",
                    percent: 4.1
                ),
                PercentRollingCensusForecastAdjuster(percent: 21.2),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 37874.0
        )
    }
}
