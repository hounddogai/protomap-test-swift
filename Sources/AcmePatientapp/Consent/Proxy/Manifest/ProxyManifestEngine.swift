import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy manifest calculation.
    protocol ProxyManifestStep {
        func describe() -> String
        func adjust(_ item: ProxyManifest, value: Double) -> Double
    }

    final class CapProxyManifestAdjuster: ProxyManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredProxyManifestAdjuster: ProxyManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameProxyManifestAdjuster: ProxyManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ProxyManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedProxyManifestAdjuster: ProxyManifestStep {
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

        func adjust(_ item: ProxyManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the proxy manifest steps in order and keeps a trace of each.
    final class ProxyManifestEngine {
        var steps: [any ProxyManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProxyManifest) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [ProxyManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProxyManifestEngine(_ flags: Kit.Flags.Registry) -> ProxyManifestEngine {
        return ProxyManifestEngine(
            steps: [
                CapProxyManifestAdjuster(cap: 10523.0),
                TieredProxyManifestAdjuster(bounds: [7168.0, 7375.0, 8786.0], rates: [1.1, 0.87, 0.99]),
                NameProxyManifestAdjuster(factors: ["retail": 1.3, "online": 0.88]),
                FlaggedProxyManifestAdjuster(flags: flags, flag: "proxy-manifest-batched", percent: -5.1),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 30948.3
        )
    }
}
