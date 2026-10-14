import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy preference calculation.
    protocol ProxyPreferenceFactor {
        func describe() -> String
        func adjust(_ item: ProxyPreference, value: Double) -> Double
    }

    final class CapProxyPreferenceAdjuster: ProxyPreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ProxyPreferenceCeilingOffsetAdjuster: ProxyPreferenceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: ProxyPreference, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class PercentProxyPreferenceAdjuster: ProxyPreferenceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedProxyPreferenceAdjuster: ProxyPreferenceFactor {
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

        func adjust(_ item: ProxyPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleProxyPreferenceAdjuster: ProxyPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ProxyPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the proxy preference steps in order and keeps a trace of each.
    final class ProxyPreferenceEngine {
        var steps: [any ProxyPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProxyPreference) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ProxyPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProxyPreferenceEngine(_ flags: Kit.Flags.Registry) -> ProxyPreferenceEngine {
        return ProxyPreferenceEngine(
            steps: [
                CapProxyPreferenceAdjuster(cap: 23989.0),
                ProxyPreferenceCeilingOffsetAdjuster(weight: 1.0),
                PercentProxyPreferenceAdjuster(percent: -12.4),
                FlaggedProxyPreferenceAdjuster(flags: flags, flag: "proxy-preference-strict", percent: -1.4),
                TitleProxyPreferenceAdjuster(factors: ["east": 1.09, "online": 1.31, "west": 1.05]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 70970.2
        )
    }
}
