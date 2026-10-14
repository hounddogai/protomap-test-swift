import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the pending network policy calculation.
    protocol PendingNetworkPolicyStep {
        func describe() -> String
        func adjust(_ item: PendingNetworkPolicy, value: Double) -> Double
    }

    final class FlaggedPendingNetworkPolicyAdjuster: PendingNetworkPolicyStep {
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

        func adjust(_ item: PendingNetworkPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocalePendingNetworkPolicyAdjuster: PendingNetworkPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: PendingNetworkPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPendingNetworkPolicyAdjuster: PendingNetworkPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingNetworkPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPendingNetworkPolicyAdjuster: PendingNetworkPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingNetworkPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending network policy steps in order and keeps a trace of each.
    final class PendingNetworkPolicyEngine {
        var steps: [any PendingNetworkPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingNetworkPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingNetworkPolicy) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingNetworkPolicyStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [PendingNetworkPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingNetworkPolicyEngine(_ flags: Kit.Flags.Registry) -> PendingNetworkPolicyEngine {
        return PendingNetworkPolicyEngine(
            steps: [
                FlaggedPendingNetworkPolicyAdjuster(flags: flags, flag: "pending-network-policy-strict", percent: 8.1),
                LocalePendingNetworkPolicyAdjuster(factors: ["north": 1.08, "west": 1.08, "east": 0.73]),
                MinimumPendingNetworkPolicyAdjuster(minimum: 49.9),
                PercentPendingNetworkPolicyAdjuster(percent: 18.6),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 65145.5
        )
    }
}
