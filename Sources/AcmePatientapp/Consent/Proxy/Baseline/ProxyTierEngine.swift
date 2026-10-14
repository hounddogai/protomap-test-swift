import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy tier calculation.
    protocol ProxyTierStep {
        func describe() -> String
        func adjust(_ item: ProxyTier, value: Double) -> Double
    }

    final class PercentProxyTierAdjuster: ProxyTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredProxyTierAdjuster: ProxyTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameProxyTierAdjuster: ProxyTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ProxyTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapProxyTierAdjuster: ProxyTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ProxyTierCreatedAtOffsetAdjuster: ProxyTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: ProxyTier, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    /// Runs the proxy tier steps in order and keeps a trace of each.
    final class ProxyTierEngine {
        var steps: [any ProxyTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyTier) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [ProxyTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyTierEngine() -> ProxyTierEngine {
        return ProxyTierEngine(
            steps: [
                PercentProxyTierAdjuster(percent: -15.0),
                TieredProxyTierAdjuster(bounds: [1415.0, 1686.0, 5463.0, 6996.0], rates: [1.18, 1.2, 0.95, 0.97]),
                NameProxyTierAdjuster(factors: ["east": 1.39]),
                CapProxyTierAdjuster(cap: 38876.0),
                ProxyTierCreatedAtOffsetAdjuster(weight: 0.28),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 71374.3
        )
    }
}
