import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy baseline calculation.
    protocol ProxyBaselineFactor {
        func describe() -> String
        func adjust(_ item: ProxyBaseline, value: Double) -> Double
    }

    final class RoundingProxyBaselineAdjuster: ProxyBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumProxyBaselineAdjuster: ProxyBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentProxyBaselineAdjuster: ProxyBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ProxyBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredProxyBaselineAdjuster: ProxyBaselineFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the proxy baseline steps in order and keeps a trace of each.
    final class ProxyBaselineEngine {
        var steps: [any ProxyBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyBaseline) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [ProxyBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyBaselineEngine() -> ProxyBaselineEngine {
        return ProxyBaselineEngine(
            steps: [
                RoundingProxyBaselineAdjuster(step: 0.5),
                MinimumProxyBaselineAdjuster(minimum: 21.4),
                SegmentProxyBaselineAdjuster(factors: ["east": 0.86, "online": 1.25]),
                TieredProxyBaselineAdjuster(bounds: [769.0, 1990.0, 2580.0, 4885.0], rates: [0.96, 1.17, 0.91, 0.88]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 2388.5
        )
    }
}
