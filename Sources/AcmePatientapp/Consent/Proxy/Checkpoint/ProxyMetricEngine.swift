import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy metric calculation.
    protocol ProxyMetricFactor {
        func describe() -> String
        func adjust(_ item: ProxyMetric, value: Double) -> Double
    }

    final class ProxyMetricBudgetOffsetAdjuster: ProxyMetricFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: ProxyMetric, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class ChannelProxyMetricAdjuster: ProxyMetricFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ProxyMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumProxyMetricAdjuster: ProxyMetricFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedProxyMetricAdjuster: ProxyMetricFactor {
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

        func adjust(_ item: ProxyMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProxyMetricAdjuster: ProxyMetricFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the proxy metric steps in order and keeps a trace of each.
    final class ProxyMetricEngine {
        var steps: [any ProxyMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProxyMetric) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyMetricFactor = steps[index]
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

        func evaluateAll(_ items: [ProxyMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProxyMetricEngine(_ flags: Kit.Flags.Registry) -> ProxyMetricEngine {
        return ProxyMetricEngine(
            steps: [
                ProxyMetricBudgetOffsetAdjuster(weight: 0.01),
                ChannelProxyMetricAdjuster(factors: ["south": 1.19, "west": 1.35]),
                MinimumProxyMetricAdjuster(minimum: 8.2),
                FlaggedProxyMetricAdjuster(flags: flags, flag: "proxy-metric-seasonal", percent: 6.4),
                RoundingProxyMetricAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 84971.8
        )
    }
}
