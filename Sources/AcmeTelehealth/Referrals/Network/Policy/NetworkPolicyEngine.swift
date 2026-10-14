import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network policy calculation.
    protocol NetworkPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: NetworkPolicy, value: Double) -> Double
    }

    final class PercentNetworkPolicyAdjuster: NetworkPolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedNetworkPolicyAdjuster: NetworkPolicyAdjuster {
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

        func adjust(_ item: NetworkPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumNetworkPolicyAdjuster: NetworkPolicyAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the network policy steps in order and keeps a trace of each.
    final class NetworkPolicyEngine {
        var steps: [any NetworkPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: NetworkPolicy) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [NetworkPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultNetworkPolicyEngine(_ flags: Kit.Flags.Registry) -> NetworkPolicyEngine {
        return NetworkPolicyEngine(
            steps: [
                PercentNetworkPolicyAdjuster(percent: -20.9),
                FlaggedNetworkPolicyAdjuster(flags: flags, flag: "network-policy-manual", percent: 2.3),
                MinimumNetworkPolicyAdjuster(minimum: 23.4),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 20283.6
        )
    }
}
