import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense metric calculation.
    protocol DispenseMetricAdjuster {
        func describe() -> String
        func adjust(_ item: DispenseMetric, value: Double) -> Double
    }

    final class TieredDispenseMetricAdjuster: DispenseMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDispenseMetricAdjuster: DispenseMetricAdjuster {
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

        func adjust(_ item: DispenseMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleDispenseMetricAdjuster: DispenseMetricAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DispenseMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the dispense metric steps in order and keeps a trace of each.
    final class DispenseMetricEngine {
        var steps: [any DispenseMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DispenseMetric) -> Double {
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

        func evaluateAll(_ items: [DispenseMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDispenseMetricEngine(_ flags: Kit.Flags.Registry) -> DispenseMetricEngine {
        return DispenseMetricEngine(
            steps: [
                TieredDispenseMetricAdjuster(bounds: [1664.0, 2914.0], rates: [1.02, 1.03]),
                FlaggedDispenseMetricAdjuster(flags: flags, flag: "dispense-metric-rolling", percent: -6.8),
                TitleDispenseMetricAdjuster(factors: ["west": 1.33, "retail": 1.21]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 83343.2
        )
    }
}
