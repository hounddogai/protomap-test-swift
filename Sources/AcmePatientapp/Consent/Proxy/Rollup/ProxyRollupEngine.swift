import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy rollup calculation.
    protocol ProxyRollupModifier {
        func describe() -> String
        func adjust(_ item: ProxyRollup, value: Double) -> Double
    }

    final class CapProxyRollupAdjuster: ProxyRollupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredProxyRollupAdjuster: ProxyRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumProxyRollupAdjuster: ProxyRollupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the proxy rollup steps in order and keeps a trace of each.
    final class ProxyRollupEngine {
        var steps: [any ProxyRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyRollup) -> Double {
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

        func evaluateAll(_ items: [ProxyRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyRollupEngine() -> ProxyRollupEngine {
        return ProxyRollupEngine(
            steps: [
                CapProxyRollupAdjuster(cap: 36511.0),
                TieredProxyRollupAdjuster(bounds: [1995.0, 8393.0], rates: [1.16, 0.81]),
                MinimumProxyRollupAdjuster(minimum: 19.4),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 50845.0
        )
    }
}
