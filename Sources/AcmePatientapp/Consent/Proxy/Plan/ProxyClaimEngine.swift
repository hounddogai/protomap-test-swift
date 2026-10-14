import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy claim calculation.
    protocol ProxyClaimStep {
        func describe() -> String
        func adjust(_ item: ProxyClaim, value: Double) -> Double
    }

    final class MinimumProxyClaimAdjuster: ProxyClaimStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ProxyClaimUpdatedAtOffsetAdjuster: ProxyClaimStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: ProxyClaim, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class PercentProxyClaimAdjuster: ProxyClaimStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedProxyClaimAdjuster: ProxyClaimStep {
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

        func adjust(_ item: ProxyClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProxyClaimAdjuster: ProxyClaimStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the proxy claim steps in order and keeps a trace of each.
    final class ProxyClaimEngine {
        var steps: [any ProxyClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProxyClaim) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [ProxyClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProxyClaimEngine(_ flags: Kit.Flags.Registry) -> ProxyClaimEngine {
        return ProxyClaimEngine(
            steps: [
                MinimumProxyClaimAdjuster(minimum: 7.5),
                ProxyClaimUpdatedAtOffsetAdjuster(weight: 1.71),
                PercentProxyClaimAdjuster(percent: 17.3),
                FlaggedProxyClaimAdjuster(flags: flags, flag: "proxy-claim-capped", percent: -6.5),
                RoundingProxyClaimAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 71432.4
        )
    }
}
