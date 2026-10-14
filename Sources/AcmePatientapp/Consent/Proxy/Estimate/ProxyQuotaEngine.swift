import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy quota calculation.
    protocol ProxyQuotaStep {
        func describe() -> String
        func adjust(_ item: ProxyQuota, value: Double) -> Double
    }

    final class PercentProxyQuotaAdjuster: ProxyQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredProxyQuotaAdjuster: ProxyQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumProxyQuotaAdjuster: ProxyQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the proxy quota steps in order and keeps a trace of each.
    final class ProxyQuotaEngine {
        var steps: [any ProxyQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProxyQuota) -> Double {
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

        func evaluateAll(_ items: [ProxyQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProxyQuotaEngine() -> ProxyQuotaEngine {
        return ProxyQuotaEngine(
            steps: [
                PercentProxyQuotaAdjuster(percent: 7.2),
                TieredProxyQuotaAdjuster(bounds: [5348.0, 6364.0, 6582.0], rates: [0.92, 0.85, 0.95]),
                MinimumProxyQuotaAdjuster(minimum: 8.5),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 76956.0
        )
    }
}
