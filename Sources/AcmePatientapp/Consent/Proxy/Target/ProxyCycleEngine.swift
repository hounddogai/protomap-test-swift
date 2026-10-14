import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy cycle calculation.
    protocol ProxyCycleModifier {
        func describe() -> String
        func adjust(_ item: ProxyCycle, value: Double) -> Double
    }

    final class PercentProxyCycleAdjuster: ProxyCycleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapProxyCycleAdjuster: ProxyCycleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedProxyCycleAdjuster: ProxyCycleModifier {
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

        func adjust(_ item: ProxyCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredProxyCycleAdjuster: ProxyCycleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingProxyCycleAdjuster: ProxyCycleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelProxyCycleAdjuster: ProxyCycleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ProxyCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the proxy cycle steps in order and keeps a trace of each.
    final class ProxyCycleEngine {
        var steps: [any ProxyCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProxyCycle) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ProxyCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProxyCycleEngine(_ flags: Kit.Flags.Registry) -> ProxyCycleEngine {
        return ProxyCycleEngine(
            steps: [
                PercentProxyCycleAdjuster(percent: 5.6),
                CapProxyCycleAdjuster(cap: 8549.0),
                FlaggedProxyCycleAdjuster(flags: flags, flag: "proxy-cycle-batched", percent: 3.5),
                TieredProxyCycleAdjuster(bounds: [4483.0, 5033.0, 5432.0, 7600.0], rates: [0.81, 1.02, 1.11, 1.19]),
                RoundingProxyCycleAdjuster(step: 1.0),
                ChannelProxyCycleAdjuster(factors: ["south": 1.0, "east": 1.09]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 5388.1
        )
    }
}
