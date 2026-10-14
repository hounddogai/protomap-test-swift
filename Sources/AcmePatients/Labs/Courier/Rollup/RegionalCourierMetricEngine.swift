import AcmePlatform
import Foundation

extension Labs {
    /// One step of the regional courier metric calculation.
    protocol RegionalCourierMetricFactor {
        func describe() -> String
        func adjust(_ item: RegionalCourierMetric, value: Double) -> Double
    }

    final class TieredRegionalCourierMetricAdjuster: RegionalCourierMetricFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalCourierMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRegionalCourierMetricAdjuster: RegionalCourierMetricFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalCourierMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRegionalCourierMetricAdjuster: RegionalCourierMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalCourierMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryRegionalCourierMetricAdjuster: RegionalCourierMetricFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RegionalCourierMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalCourierMetricAdjuster: RegionalCourierMetricFactor {
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

        func adjust(_ item: RegionalCourierMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional courier metric steps in order and keeps a trace of each.
    final class RegionalCourierMetricEngine {
        var steps: [any RegionalCourierMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCourierMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalCourierMetric) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [RegionalCourierMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalCourierMetricEngine(_ flags: Kit.Flags.Registry) -> RegionalCourierMetricEngine {
        return RegionalCourierMetricEngine(
            steps: [
                TieredRegionalCourierMetricAdjuster(bounds: [4263.0, 7808.0, 8307.0], rates: [1.1, 0.83, 0.99]),
                RoundingRegionalCourierMetricAdjuster(step: 0.05),
                PercentRegionalCourierMetricAdjuster(percent: -19.4),
                CategoryRegionalCourierMetricAdjuster(factors: ["online": 1.07]),
                FlaggedRegionalCourierMetricAdjuster(
                    flags: flags,
                    flag: "regional-courier-metric-weighted",
                    percent: 3.7
                ),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 15922.5
        )
    }
}
