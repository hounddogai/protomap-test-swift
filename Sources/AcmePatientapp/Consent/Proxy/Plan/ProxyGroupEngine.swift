import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy group calculation.
    protocol ProxyGroupFactor {
        func describe() -> String
        func adjust(_ item: ProxyGroup, value: Double) -> Double
    }

    final class CapProxyGroupAdjuster: ProxyGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedProxyGroupAdjuster: ProxyGroupFactor {
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

        func adjust(_ item: ProxyGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameProxyGroupAdjuster: ProxyGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ProxyGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingProxyGroupAdjuster: ProxyGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the proxy group steps in order and keeps a trace of each.
    final class ProxyGroupEngine {
        var steps: [any ProxyGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProxyGroup) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [ProxyGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProxyGroupEngine(_ flags: Kit.Flags.Registry) -> ProxyGroupEngine {
        return ProxyGroupEngine(
            steps: [
                CapProxyGroupAdjuster(cap: 27783.0),
                FlaggedProxyGroupAdjuster(flags: flags, flag: "proxy-group-weighted", percent: 2.6),
                NameProxyGroupAdjuster(factors: ["south": 0.96]),
                RoundingProxyGroupAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 84717.7
        )
    }
}
