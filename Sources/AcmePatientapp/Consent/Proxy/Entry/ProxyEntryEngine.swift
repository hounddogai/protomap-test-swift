import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy entry calculation.
    protocol ProxyEntryModifier {
        func describe() -> String
        func adjust(_ item: ProxyEntry, value: Double) -> Double
    }

    final class TieredProxyEntryAdjuster: ProxyEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingProxyEntryAdjuster: ProxyEntryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapProxyEntryAdjuster: ProxyEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the proxy entry steps in order and keeps a trace of each.
    final class ProxyEntryEngine {
        var steps: [any ProxyEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ProxyEntry) -> Double {
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

        func evaluateAll(_ items: [ProxyEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultProxyEntryEngine() -> ProxyEntryEngine {
        return ProxyEntryEngine(
            steps: [
                TieredProxyEntryAdjuster(bounds: [998.0, 7499.0], rates: [1.06, 0.98]),
                RoundingProxyEntryAdjuster(step: 0.05),
                CapProxyEntryAdjuster(cap: 27720.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 69225.0
        )
    }
}
