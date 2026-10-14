import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual network forecast calculation.
    protocol ManualNetworkForecastFactor {
        func describe() -> String
        func adjust(_ item: ManualNetworkForecast, value: Double) -> Double
    }

    final class ManualNetworkForecastMinimumOffsetAdjuster: ManualNetworkForecastFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: ManualNetworkForecast, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class CategoryManualNetworkForecastAdjuster: ManualNetworkForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: ManualNetworkForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumManualNetworkForecastAdjuster: ManualNetworkForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualNetworkForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualNetworkForecastAdjuster: ManualNetworkForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualNetworkForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedManualNetworkForecastAdjuster: ManualNetworkForecastFactor {
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

        func adjust(_ item: ManualNetworkForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentManualNetworkForecastAdjuster: ManualNetworkForecastFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualNetworkForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual network forecast steps in order and keeps a trace of each.
    final class ManualNetworkForecastEngine {
        var steps: [any ManualNetworkForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualNetworkForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualNetworkForecast) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualNetworkForecastFactor = steps[index]
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

        func evaluateAll(_ items: [ManualNetworkForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualNetworkForecastEngine(_ flags: Kit.Flags.Registry) -> ManualNetworkForecastEngine {
        return ManualNetworkForecastEngine(
            steps: [
                ManualNetworkForecastMinimumOffsetAdjuster(weight: 1.88),
                CategoryManualNetworkForecastAdjuster(factors: ["east": 1.3, "north": 0.83]),
                MinimumManualNetworkForecastAdjuster(minimum: 23.4),
                TieredManualNetworkForecastAdjuster(bounds: [4216.0, 8827.0], rates: [1.05, 1.15]),
                FlaggedManualNetworkForecastAdjuster(
                    flags: flags,
                    flag: "manual-network-forecast-primary",
                    percent: 9.9
                ),
                PercentManualNetworkForecastAdjuster(percent: -19.5),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 10692.6
        )
    }
}
